/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/select.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "portal.h"
#include "GeneratedTypes.h" 

static int trace_memory;// = 1;

static int local_manager_handle = 1;
static sem_t localmanager_confSem;
static sem_t localmanager_mtSem;
static sem_t localmanager_dbgSem;
static uint64_t localmanager_mtCnt;
static DmaDbgRec localmanager_dbgRec;

#define MAX_INDARRAY 4
typedef int (*INDFUNC)(PortalInternal *p, unsigned int channel);
static PortalInternal *intarr[MAX_INDARRAY];
static INDFUNC indfn[MAX_INDARRAY];

static sem_t test_sem;
static int burstLen = 16;
static int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
static size_t test_sz  = numWords*sizeof(unsigned int);
static size_t alloc_sz = test_sz;
void DmaConfigProxyStatusputFailed_cb (  struct PortalInternal *p, const uint32_t v )
{
        const char* methodNameStrings[] = {"sglist", "region", "addrRequest", "getStateDbg", "getMemoryTraffic"};
        fprintf(stderr, "putFailed: %s\n", methodNameStrings[v]);
}
void MemreadRequestProxyStatusputFailed_cb (  struct PortalInternal *p, const uint32_t v )
{
        const char* methodNameStrings[] = {"startRead"};
        fprintf(stderr, "putFailed: %s\n", methodNameStrings[v]);
}
void MemreadIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t mismatchCount )
{
         printf( "Memread_readDone(mismatch = %x)\n", mismatchCount);
         sem_post(&test_sem);
}
void DmaIndicationWrapperconfigResp_cb (  struct PortalInternal *p, const uint32_t pointer, const uint64_t msg )
{
        //fprintf(stderr, "configResp: %x, %"PRIx64"\n", pointer, msg);
        //fprintf(stderr, "configResp %d\n", pointer);
        sem_post(&localmanager_confSem);
}
void DmaIndicationWrapperaddrResponse_cb (  struct PortalInternal *p, const uint64_t physAddr )
{
        fprintf(stderr, "DmaIndication_addrResponse(physAddr=%"PRIx64")\n", physAddr);
}
void DmaIndicationWrapperbadPointer_cb (  struct PortalInternal *p, const uint32_t pointer )
{
        fprintf(stderr, "DmaIndication_badPointer(pointer=%x)\n", pointer);
}
void DmaIndicationWrapperbadAddrTrans_cb (  struct PortalInternal *p, const uint32_t pointer, const uint64_t offset, const uint64_t barrier )
{
        fprintf(stderr, "DmaIndication_badAddrTrans(pointer=%x, offset=%"PRIx64" barrier=%"PRIx64"\n", pointer, offset, barrier);
}
void DmaIndicationWrapperbadPageSize_cb (  struct PortalInternal *p, const uint32_t pointer, const uint32_t sz )
{
        fprintf(stderr, "DmaIndication_badPageSize(pointer=%x, len=%x)\n", pointer, sz);
}
void DmaIndicationWrapperbadNumberEntries_cb (  struct PortalInternal *p, const uint32_t pointer, const uint32_t sz, const uint32_t idx )
{
        fprintf(stderr, "DmaIndication_badNumberEntries(pointer=%x, len=%x, idx=%x)\n", pointer, sz, idx);
}
void DmaIndicationWrapperbadAddr_cb (  struct PortalInternal *p, const uint32_t pointer, const uint64_t offset, const uint64_t physAddr )
{
        fprintf(stderr, "DmaIndication_badAddr(pointer=%x offset=%"PRIx64" physAddr=%"PRIx64")\n", pointer, offset, physAddr);
}
void DmaIndicationWrapperreportStateDbg_cb (  struct PortalInternal *p, const DmaDbgRec& rec )
{
        //fprintf(stderr, "reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", rec.x,rec.y,rec.z,rec.w);
        localmanager_dbgRec = rec;
        fprintf(stderr, "dbgResp: %08x %08x %08x %08x\n", localmanager_dbgRec.x, localmanager_dbgRec.y, localmanager_dbgRec.z, localmanager_dbgRec.w);
        sem_post(&localmanager_dbgSem);
}
void DmaIndicationWrapperreportMemoryTraffic_cb (  struct PortalInternal *p, const uint64_t words )
{
        //fprintf(stderr, "reportMemoryTraffic: words=%"PRIx64"\n", words);
        localmanager_mtCnt = words;
        sem_post(&localmanager_mtSem);
}
void DmaIndicationWrappertagMismatch_cb (  struct PortalInternal *p, const ChannelType& x, const uint32_t a, const uint32_t b )
{
        fprintf(stderr, "tagMismatch: %s %d %d\n", x==ChannelType_Read ? "Read" : "Write", a, b);
}

static void manual_event(void)
{
    for (int i = 0; i < MAX_INDARRAY; i++) {
      PortalInternal *instance = intarr[i];
      volatile unsigned int *map_base = instance->map_base;
      unsigned int queue_status;
      while ((queue_status= READL(instance, &map_base[IND_REG_QUEUE_STATUS]))) {
        unsigned int int_src = READL(instance, &map_base[IND_REG_INTERRUPT_FLAG]);
        unsigned int int_en  = READL(instance, &map_base[IND_REG_INTERRUPT_MASK]);
        unsigned int ind_count  = READL(instance, &map_base[IND_REG_INTERRUPT_COUNT]);
        fprintf(stderr, "(%d:%s) about to receive messages int=%08x en=%08x qs=%08x\n", i, instance->name, int_src, int_en, queue_status);
        if (indfn[i])
            indfn[i](instance, queue_status-1);
      }
    }
}

static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (1) {
        struct timeval timeout;
        timeout.tv_sec = 0;
        timeout.tv_usec = 10000;
        manual_event();
        select(0, NULL, NULL, NULL, &timeout);
    }
    return rc;
}

static int local_manager_reference(PortalAlloc* pa)
{
  const int PAGE_SHIFT0 = 12;
  const int PAGE_SHIFT4 = 16;
  const int PAGE_SHIFT8 = 20;
  uint64_t regions[3] = {0,0,0};
  uint64_t shifts[3] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0};
  int id = local_manager_handle++;
  int ne = pa->header.numEntries;
  int size_accum = 0;
  // HW interprets zeros as end of sglist
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries++;
  if (trace_memory)
    fprintf(stderr, "local_manager_reference id=%08x, numEntries:=%d len=%08lx)\n", id, ne, pa->header.size);
  for(int i = 0; i < pa->header.numEntries; i++){
    DmaEntry *e = &(pa->entries[i]);
    switch (e->length) {
    case (1<<PAGE_SHIFT0):
      regions[2]++;
      break;
    case (1<<PAGE_SHIFT4):
      regions[1]++;
      break;
    case (1<<PAGE_SHIFT8):
      regions[0]++;
      break;
    case (0):
      break;
    default:
      fprintf(stderr, "local_manager_unsupported sglist size %x\n", e->length);
    }
    dma_addr_t addr = e->dma_address;
    if (trace_memory)
      fprintf(stderr, "local_manager_sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, (long)addr, e->length);
    DmaConfigProxy_sglist (intarr[2] , id, addr, e->length);
    size_accum += e->length;
    // fprintf(stderr, "%s:%d sem_wait\n", __FILE__, __LINE__);
    sem_wait(&localmanager_confSem);
  }
  uint64_t border = 0;
  unsigned char entryCount = 0;
  struct {
    uint64_t border;
    unsigned char idxOffset;
  } borders[3];
  for(int i = 0; i < 3; i++){
    if (i == 0)
      borders[i].idxOffset = 0;
    else
      borders[i].idxOffset = entryCount - ((border >> shifts[i])&0xff);

    border += regions[i]*(1<<shifts[i]);
    borders[i].border = border;
    entryCount += regions[i];
  }
  if (trace_memory) {
    fprintf(stderr, "regions %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,regions[0], regions[1], regions[2]);
    fprintf(stderr, "borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borders[0].border, borders[1].border, borders[2].border);
  }
  DmaConfigProxy_region(intarr[2], id, borders[0].border, borders[0].idxOffset,
       borders[1].border, borders[1].idxOffset, borders[2].border, borders[2].idxOffset);
  sem_wait(&localmanager_confSem);
  return id;
}

int main(int argc, const char **argv)
{
  intarr[0] = new PortalInternal(IfcNames_DmaIndication);     // fpga1
  intarr[1] = new PortalInternal(IfcNames_MemreadIndication); // fpga2
  intarr[2] = new PortalInternal(IfcNames_DmaConfig);         // fpga3
  intarr[3] = new PortalInternal(IfcNames_MemreadRequest);    // fpga4
  indfn[0] = DmaIndicationWrapper_handleMessage;
  indfn[1] = MemreadIndicationWrapper_handleMessage;
  indfn[2] = DmaConfigProxyStatus_handleMessage;
  indfn[3] = MemreadRequestProxyStatus_handleMessage;

  PortalAlloc *srcAlloc = (PortalAlloc *)malloc(sizeof(PortalAlloc));
  memset(srcAlloc, 0, sizeof(PortalAlloc));
  srcAlloc->header.size = alloc_sz;

#ifndef __KERNEL__ ///////////////////////// userspace version
  int portalmem_fd = open("/dev/portalmem", O_RDWR);
  if (portalmem_fd < 0)
    fprintf(stderr, "Failed to open /dev/portalmem portalmem_fd=%d errno=%d\n", portalmem_fd, errno);
  int rc = ioctl(portalmem_fd, PA_ALLOC, srcAlloc);
  if (!rc){
      long mb = ((long)srcAlloc->header.size)/(long)(1<<20);
      fprintf(stderr, "alloc size=%lxMB rc=%d fd=%d numEntries=%d\n", mb, rc, srcAlloc->header.fd, srcAlloc->header.numEntries);
      srcAlloc = (PortalAlloc *)realloc(srcAlloc, sizeof(PortalAlloc)+((srcAlloc->header.numEntries+1)*sizeof(DmaEntry)));
      rc = ioctl(portalmem_fd, PA_DMA_ADDRESSES, srcAlloc);
  }
  unsigned int *srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
#else   /// kernel version
  {
    // code for PA_ALLOC
    size_t align = 4096;
    printk("%s, srcAlloc.size=%zd\n", __FUNCTION__, srcAlloc.size);
    srcAlloc.size = PAGE_ALIGN(round_up(srcAlloc.size, align));
    struct dma_buf *dmabuf = portalmem_dmabuffer_create(srcAlloc.size, align);
    if (IS_ERR(dmabuf))
      return PTR_ERR(dmabuf);
    printk("pa_get_dma_buf %p %zd\n", dmabuf->file, dmabuf->file->f_count.counter);
    srcAlloc.numEntries = ((struct pa_buffer *)dmabuf->priv)->sg_table->nents;
    srcAlloc.fd = dma_buf_fd(dmabuf, O_CLOEXEC);
    if (srcAlloc.fd < 0)
      dma_buf_put(dmabuf);
  }
  {
    // code for PA_DMA_ADDRESSES
    struct scatterlist *sg;
    int i;
    struct file *f = fget(srcAlloc.fd);
    struct sg_table *sgtable = ((struct pa_buffer *)((struct dma_buf *)f->private_data)->priv)->sg_table;
    for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
      srcAlloc.entries[i].dma_address = sg_phys(sg);
      srcAlloc.entries[i].length = sg->length;
    }
    fput(f);
  }
#endif ////////////////////////////////
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }

  pthread_t tid;
  printf( "Main: creating exec thread\n");
  if(pthread_create(&tid, NULL,  pthread_worker, NULL)){
   printf( "error creating exec thread\n");
   exit(1);
  }
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;
#ifndef __KERNEL__   //////////////// userspace code for flushing dcache for srcAlloc
  {
#if defined(__arm__)
    int rc = ioctl(portalmem_fd, PA_DCACHE_FLUSH_INVAL, srcAlloc);
    if (rc){
      fprintf(stderr, "portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
      return rc;
    }
#elif defined(__i386__) || defined(__x86_64__)
    // not sure any of this is necessary (mdk)
    for(int i = 0; i < srcAlloc->header.size; i++){
      char foo = *(((volatile char *)srcBuffer)+i);
      asm volatile("clflush %0" :: "m" (foo));
    }
    asm volatile("mfence");
#else
#error("dCAcheFlush not defined for unspecified architecture")
#endif
  //fprintf(stderr, "dcache flush\n");
  }
#endif /////////////////////
  unsigned int ref_srcAlloc = local_manager_reference(srcAlloc);
  printf( "Main: starting read %08x\n", numWords);
  MemreadRequestProxy_startRead (intarr[3] , ref_srcAlloc, numWords, burstLen, 1);
  sem_wait(&test_sem);
  return 0;
}
