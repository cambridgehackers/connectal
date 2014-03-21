
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

#include <errno.h>
#include <fcntl.h>
#include <linux/ioctl.h>
#include <linux/types.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <assert.h>
#include <time.h>

#include "PortalMemory.h"
#include "sock_utils.h"
#include "sock_fd.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

void PortalMemory::InitSemaphores()
{
  if (sem_init(&confSem, 1, 0)){
    fprintf(stderr, "failed to init confSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&mtSem, 0, 0)){
    fprintf(stderr, "failed to init mtSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&dbgSem, 0, 0)){
    fprintf(stderr, "failed to init dbgSem errno=%d:%s\n", errno, strerror(errno));
  }
}

void PortalMemory::InitFds()
{
#ifndef MMAP_HW
  snprintf(p_fd.read.path, sizeof(p_fd.read.path), "fd_sock_rc");
  connect_socket(&(p_fd.read));
  snprintf(p_fd.write.path, sizeof(p_fd.write.path), "fd_sock_wc");
  connect_socket(&(p_fd.write));
#endif
}

PortalMemory::PortalMemory(int id)
  : PortalInternal(id),
    handle(1)
{
  InitFds();
  const char* path = "/dev/portalmem";
  this->pa_fd = ::open(path, O_RDWR);
  if (this->pa_fd < 0){
    fprintf(stderr, "Failed to open %s pa_fd=%d errno=%d\n", path, this->pa_fd, errno);
  }
  InitSemaphores();
}

void *PortalMemory::mmap(PortalAlloc *portalAlloc)
{
  void *virt = ::mmap(0, portalAlloc->header.size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, portalAlloc->header.fd, 0);
  return virt;
}

int PortalMemory::dCacheFlushInval(PortalAlloc *portalAlloc, void *__p)
{
#if defined(__arm__)
  int rc = ioctl(this->pa_fd, PA_DCACHE_FLUSH_INVAL, portalAlloc);
  if (rc){
    fprintf(stderr, "portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
#elif defined(__i386__) || defined(__x86_64__)
  // not sure any of this is necessary (mdk)
  for(int i = 0; i < portalAlloc->header.size; i++){
    char foo = *(((volatile char *)__p)+i);
    asm volatile("clflush %0" :: "m" (foo));
  }
  asm volatile("mfence");
#else
#error("dCAcheFlush not defined for unspecified architecture")
#endif
  fprintf(stderr, "dcache flush\n");
  return 0;

}

uint64_t PortalMemory::show_mem_stats(ChannelType rc)
{
  uint64_t rv = 0;
  getStateDbg(rc);
  sem_wait(&dbgSem);
  for(int i = dbgRec.x; i > 0; i--){ 
    getMemoryTraffic(rc, i-1);
    sem_wait(&mtSem);
    rv += mtCnt;
  }
  return rv;
}

int PortalMemory::reference(PortalAlloc* pa)
{
  const int PAGE_SHIFT0 = 12;
  const int PAGE_SHIFT4 = 16;
  const int PAGE_SHIFT8 = 20;
  uint64_t regions[3] = {0,0,0};
  uint64_t shifts[3] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0};
  int id = handle++;
  int ne = pa->header.numEntries;
  int size_accum = 0;
  // HW interprets zeros as end of sglist
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries++;
  // fprintf(stderr, "PortalMemory::reference id=%08x, numEntries:=%d len=%08lx)\n", id, ne, pa->header.size);
#ifndef MMAP_HW
  sock_fd_write(p_fd.write.s2, pa->header.fd);
#endif
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
      fprintf(stderr, "PortalMemory::unsupported sglist size %x\n", e->length);
    }
#ifdef MMAP_HW
    //fprintf(stderr, "PortalMemory::sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, e->dma_address, e->length);
    sglist(id, e->dma_address, e->length);
#else
    int addr = (e->length > 0) ? size_accum : 0;
    // fprintf(stderr, "PortalMemory::sglist(id=%08x, i=%d dma_addr=%08x, len=%08x)\n", id, i, addr, e->length);
    sglist(id, addr , e->length);
#endif
    size_accum += e->length;
    // fprintf(stderr, "%s:%d sem_wait\n", __FILE__, __LINE__);
    sem_wait(&confSem);
  }
  uint64_t border = 0;
  unsigned char entryCount = 0;
  struct {
    uint64_t border;
    unsigned char idxOffset;
  } borders[3];
  for(int i = 0; i < 3; i++){
    

    // fprintf(stderr, "i=%d entryCount=%d border=%zx shifts=%zd shifted=%zx masked=%zx idxOffset=%zx added=%zx\n",
    // 	    i, entryCount, border, shifts[i], border >> shifts[i], (border >> shifts[i]) &0xFF,
    // 	    (entryCount - ((border >> shifts[i])&0xff)) & 0xff,
    // 	    (((border >> shifts[i])&0xff) + (entryCount - ((border >> shifts[i])&0xff)) & 0xff) & 0xff);

    if (i == 0)
      borders[i].idxOffset = 0;
    else
      borders[i].idxOffset = entryCount - ((border >> shifts[i])&0xff);

    border += regions[i]*(1<<shifts[i]);
    borders[i].border = border;
    entryCount += regions[i];
  }
  //fprintf(stderr, "regions %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,regions[0], regions[1], regions[2]);
  //fprintf(stderr, "borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borders[0].border, borders[1].border, borders[2].border);
  region(id,
	 borders[0].border, borders[0].idxOffset,
	 borders[1].border, borders[1].idxOffset,
	 borders[2].border, borders[2].idxOffset);
  //fprintf(stderr, "%s:%d sem_wait\n", __FILE__, __LINE__);
  sem_wait(&confSem);
  return id;
}

void PortalMemory::mtResp(uint64_t words)
{
  mtCnt = words;
  sem_post(&mtSem);
}

void PortalMemory::dbgResp(const DmaDbgRec& rec)
{
  dbgRec = rec;
  sem_post(&dbgSem);
}

void PortalMemory::confResp(uint32_t channelId)
{
  // fprintf(stderr, "configResp %d\n", channelId);
  sem_post(&confSem);
}

int PortalMemory::alloc(size_t size, PortalAlloc **ppa)
{
  PortalAlloc *portalAlloc = (PortalAlloc *)malloc(sizeof(PortalAlloc));
  memset(portalAlloc, 0, sizeof(PortalAlloc));
  portalAlloc->header.size = size;
  int rc = ioctl(this->pa_fd, PA_ALLOC, portalAlloc);
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  float mb = (float)portalAlloc->header.size/(float)(1<<20);
  fprintf(stderr, "alloc size=%fMB rc=%d fd=%d numEntries=%d\n", 
	  mb, rc, portalAlloc->header.fd, portalAlloc->header.numEntries);
  portalAlloc = (PortalAlloc *)realloc(portalAlloc, sizeof(PortalAlloc)+((portalAlloc->header.numEntries+1)*sizeof(DmaEntry)));
  rc = ioctl(this->pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  *ppa = portalAlloc;
  return 0;
}

