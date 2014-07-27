
// Copyright (c) 2013,2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include "dmaManager.h"
#include "sock_utils.h"

#ifdef __KERNEL__
#include <linux/slab.h>
#include <linux/dma-buf.h>
extern struct dma_buf *portalmem_dmabuffer_create(unsigned long len, unsigned long align);
#define PORTAL_MALLOC(A) vmalloc(A)
#define PORTAL_FREE(A) vfree(A)
#else
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "portalmem.h"

#if defined(__arm__)
#include "zynqportal.h"
#endif
#define PORTAL_MALLOC(A) malloc(A)
#define PORTAL_FREE(A) free(A)
#endif

static int trace_memory;// = 1;

void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *argDevice)
{
  memset(priv, 0, sizeof(*priv));
  priv->device = argDevice;
#ifndef __KERNEL__
  priv->pa_fd = open("/dev/portalmem", O_RDWR);
  if (priv->pa_fd < 0){
    PORTAL_PRINTF("Failed to open /dev/portalmem pa_fd=%d errno=%d\n", priv->pa_fd, errno);
  }
#endif
  if (sem_init(&priv->confSem, 0, 0)){
    PORTAL_PRINTF("failed to init confSem\n");
  }
  if (sem_init(&priv->mtSem, 0, 0)){
    PORTAL_PRINTF("failed to init mtSem\n");
  }
  if (sem_init(&priv->dbgSem, 0, 0)){
    PORTAL_PRINTF("failed to init dbgSem\n");
  }
}

int DmaManager_dCacheFlushInval(DmaManagerPrivate *priv, PortalAlloc *portalAlloc, void *__p)
{
#ifndef __KERNEL__
#if defined(__arm__)
  int rc = ioctl(priv->pa_fd, PA_DCACHE_FLUSH_INVAL, portalAlloc);
  if (rc){
    PORTAL_PRINTF("portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
#elif defined(__i386__) || defined(__x86_64__)
  // not sure any of this is necessary (mdk)
  for(unsigned int i = 0; i < portalAlloc->header.size; i++){
    char foo = *(((volatile char *)__p)+i);
    asm volatile("clflush %0" :: "m" (foo));
  }
  asm volatile("mfence");
#else
#error("dCAcheFlush not defined for unspecified architecture")
#endif
#endif // __KERNEL__
  //PORTAL_PRINTF("dcache flush\n");
  return 0;
}
uint64_t DmaManager_show_mem_stats(DmaManagerPrivate *priv, ChannelType rc)
{
  uint64_t rv = 0;
  DMAGetMemoryTraffic(priv->device, rc);
  sem_wait(&priv->mtSem);
  rv += priv->mtCnt;
  return rv;
}

int DmaManager_reference(DmaManagerPrivate *priv, PortalAlloc* pa)
{
  const int PAGE_SHIFT0 = 12;
  const int PAGE_SHIFT4 = 16;
  const int PAGE_SHIFT8 = 20;
  int i, j, rc = 0;
  uint64_t regions[3] = {0,0,0};
  uint64_t shifts[3] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0};
  int id = priv->handle++;
  int ne = pa->header.numEntries;
  int size_accum = 0;
  uint64_t border = 0;
  unsigned char entryCount = 0;
  uint64_t borderVal[3];
  unsigned char idxOffset;
  PortalAlloc *portalAlloc = (PortalAlloc *)PORTAL_MALLOC(sizeof(PortalAlloc)+((pa->header.numEntries+1)*sizeof(DmaEntry)));
#ifdef __KERNEL__
  struct sg_table *sgtable;
  struct scatterlist *sg;
#endif

  memcpy(portalAlloc, pa, sizeof(*pa));
#ifndef __KERNEL__
  rc = ioctl(priv->pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    PORTAL_PRINTF("portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    goto retlab;
  }
#else
  sgtable = ((struct pa_buffer *)((struct dma_buf *)portalAlloc->header.fd)->priv)->sg_table;
  for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
      portalAlloc->entries[i].dma_address = sg_phys(sg);
      portalAlloc->entries[i].length = sg->length;
  }
#endif
  if (trace_memory)
    PORTAL_PRINTF("DmaManager_reference id=%08x, numEntries:=%d len=%08lx)\n", id, ne, (long)portalAlloc->header.size);
#ifndef MMAP_HW
  bluesim_sock_fd_write(portalAlloc->header.fd);
#endif
  for(i = 0; i < portalAlloc->header.numEntries; i++){
    DmaEntry *e = &(portalAlloc->entries[i]);
    long addr;
#ifdef MMAP_HW
    addr = e->dma_address;
#else
    addr = size_accum;
//#endif
//#ifdef BSIM
    addr |= ((long)id+1) << 32; //[39:32] = truncate(pref);
#endif
    for(j = 0; j < 3; j++)
        if (e->length == 1<<shifts[j]) {
          regions[j]++;
          addr >>= shifts[j];
          break;
        }
    if (j >= 3)
      PORTAL_PRINTF("DmaManager:unsupported sglist size %x\n", e->length);
    if (trace_memory)
      PORTAL_PRINTF("DmaManager:sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, (long)addr, e->length);
    DMAsglist(priv->device, (id << 8) + i, addr, e->length);
    size_accum += e->length;
    //PORTAL_PRINTF("%s:%d sem_wait\n", __FUNCTION__, __LINE__);
    sem_wait(&priv->confSem);
  }
  // HW interprets zeros as end of sglist
  DMAsglist(priv->device, (id << 8) + i, 0, 0); // end list
  sem_wait(&priv->confSem);

  for(i = 0; i < 3; i++){
    idxOffset = entryCount - (border >> shifts[i]);
    entryCount += regions[i];
    border += regions[i]<<shifts[i];
    borderVal[i] = (border << 8) | idxOffset;
  }
  if (trace_memory) {
    PORTAL_PRINTF("regions %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,regions[0], regions[1], regions[2]);
    PORTAL_PRINTF("borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borderVal[0], borderVal[1], borderVal[2]);
  }
  DMAregion(priv->device, id, borderVal[0], borderVal[1], borderVal[2]);
  //PORTAL_PRINTF("%s:%d sem_wait\n", __FUNCTION__, __LINE__);
  sem_wait(&priv->confSem);
  rc = id+1;
retlab:
  PORTAL_FREE(portalAlloc);
  return rc;
}

int DmaManager_alloc(DmaManagerPrivate *priv, size_t size, PortalAlloc **ppa)
{
  int rc = 0;
#ifdef __KERNEL__
  size_t align = 4096;
  struct dma_buf *dmabuf;
#endif

  PortalAlloc *portalAlloc = (PortalAlloc *)PORTAL_MALLOC(sizeof(PortalAlloc));
  memset(portalAlloc, 0, sizeof(*portalAlloc));
  portalAlloc->header.size = size;
#ifndef __KERNEL__
  rc = ioctl(priv->pa_fd, PA_ALLOC, portalAlloc);
  if (rc)
    PORTAL_PRINTF("portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
#else
  portalAlloc->header.size = PAGE_ALIGN(round_up(portalAlloc->header.size, align));
  dmabuf = portalmem_dmabuffer_create(portalAlloc->header.size, align);
  if (IS_ERR(dmabuf)) {
      PORTAL_PRINTF("%s: portalmem_dmabuffer_create error\n", __FUNCTION__);
      return PTR_ERR(dmabuf);
  }
  PORTAL_PRINTF("pa_get_dma_buf %p %zd\n", dmabuf->file, dmabuf->file->f_count.counter);
  portalAlloc->header.numEntries = ((struct pa_buffer *)dmabuf->priv)->sg_table->nents;
  portalAlloc->header.fd = (long)dmabuf;
#endif
  PORTAL_PRINTF("alloc size=%ldMB fd=%ld numEntries=%d\n", 
      portalAlloc->header.size/(1L<<20), portalAlloc->header.fd, portalAlloc->header.numEntries);
  *ppa = portalAlloc;
  return rc;
}
