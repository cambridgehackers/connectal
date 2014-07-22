
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

#include "dmaManager.h"
#include "sock_utils.h"

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

static int trace_memory;// = 1;

void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *argDevice)
{
  priv->handle = 1;
  priv->device = argDevice;
#ifndef MMAP_HW
  connect_socket(&priv->write, "fd_sock_wc", 0);
#endif
  const char* path = "/dev/portalmem";
  priv->pa_fd = ::open(path, O_RDWR);
  if (priv->pa_fd < 0){
    fprintf(stderr, "Failed to open %s pa_fd=%d errno=%d\n", path, priv->pa_fd, errno);
  }
  if (sem_init(&priv->confSem, 1, 0)){
    fprintf(stderr, "failed to init confSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&priv->mtSem, 0, 0)){
    fprintf(stderr, "failed to init mtSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&priv->dbgSem, 0, 0)){
    fprintf(stderr, "failed to init dbgSem errno=%d:%s\n", errno, strerror(errno));
  }
}

int DmaManager_dCacheFlushInval(DmaManagerPrivate *priv, PortalAlloc *portalAlloc, void *__p)
{
#if defined(__arm__)
  int rc = ioctl(priv->pa_fd, PA_DCACHE_FLUSH_INVAL, portalAlloc);
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
  //fprintf(stderr, "dcache flush\n");
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
  uint64_t regions[3] = {0,0,0};
  uint64_t shifts[3] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0};
  int id = priv->handle++;
  int ne = pa->header.numEntries;
  int size_accum = 0;
  // HW interprets zeros as end of sglist
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries++;
  if (trace_memory)
    fprintf(stderr, "DmaManager::reference id=%08x, numEntries:=%d len=%08lx)\n", id, ne, pa->header.size);
#ifndef MMAP_HW
  sock_fd_write(priv->write, pa->header.fd);
#endif
  for(int i = 0; i < pa->header.numEntries; i++){
    DmaEntry *e = &(pa->entries[i]);
#ifdef MMAP_HW
    dma_addr_t addr = e->dma_address;
#else
    long addr = (e->length > 0) ? size_accum : 0;
#endif
#ifdef BSIM
    addr |= ((long)id) << 32; //[39:32] = truncate(pref);
#endif

    switch (e->length) {
    case (1<<PAGE_SHIFT0):
      regions[2]++;
      addr >>= PAGE_SHIFT0;
      break;
    case (1<<PAGE_SHIFT4):
      regions[1]++;
      addr >>= PAGE_SHIFT4;
      break;
    case (1<<PAGE_SHIFT8):
      regions[0]++;
      addr >>= PAGE_SHIFT8;
      break;
    case (0):
      break;
    default:
      fprintf(stderr, "DmaManager::unsupported sglist size %x\n", e->length);
    }
    if (trace_memory)
      fprintf(stderr, "DmaManager::sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, (long)addr, e->length);
    DMAsglist(priv->device, id-1, addr, e->length);
    size_accum += e->length;
    // fprintf(stderr, "%s:%d sem_wait\n", __FILE__, __LINE__);
    sem_wait(&priv->confSem);
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
  if (trace_memory) {
    fprintf(stderr, "regions %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,regions[0], regions[1], regions[2]);
    fprintf(stderr, "borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borders[0].border, borders[1].border, borders[2].border);
  }
  DMAregion(priv->device, id-1,
	 (borders[0].border << 8) | borders[0].idxOffset,
	 (borders[1].border << 8) | borders[1].idxOffset,
	 (borders[2].border << 8) | borders[2].idxOffset);
  //fprintf(stderr, "%s:%d sem_wait\n", __FILE__, __LINE__);
  sem_wait(&priv->confSem);
  return id;
}

int DmaManager_alloc(DmaManagerPrivate *priv, size_t size, PortalAlloc **ppa)
{
  PortalAlloc localPortalAlloc;
  memset(&localPortalAlloc, 0, sizeof(localPortalAlloc));
  localPortalAlloc.header.size = size;
  int rc = ioctl(priv->pa_fd, PA_ALLOC, &localPortalAlloc);
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  long mb = localPortalAlloc.header.size/(1L<<20);
  fprintf(stderr, "alloc size=%ldMB fd=%d numEntries=%d\n", 
	  mb, localPortalAlloc.header.fd, localPortalAlloc.header.numEntries);
  PortalAlloc *portalAlloc = (PortalAlloc *)malloc(sizeof(PortalAlloc)+((localPortalAlloc.header.numEntries+1)*sizeof(DmaEntry)));
  memcpy(portalAlloc, &localPortalAlloc, sizeof(localPortalAlloc));
  rc = ioctl(priv->pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  *ppa = portalAlloc;
  return 0;
}

#ifndef NO_CPP_PORTAL_CODE
DmaManager::DmaManager(PortalInternalCpp *argDevice)
{
  DmaManager_init(&priv, &argDevice->pint);
}
int DmaManager::dCacheFlushInval(PortalAlloc *portalAlloc, void *__p)
{
    return DmaManager_dCacheFlushInval(&priv, portalAlloc, __p);
}

uint64_t DmaManager::show_mem_stats(ChannelType rc)
{
    return DmaManager_show_mem_stats(&priv, rc);
}

int DmaManager::reference(PortalAlloc* pa)
{
    return DmaManager_reference(&priv, pa);
}
int DmaManager::alloc(size_t size, PortalAlloc **ppa)
{
   return DmaManager_alloc(&priv, size, ppa);
}

void DmaManager::mtResp(uint64_t words)
{
  priv.mtCnt = words;
  sem_post(&priv.mtSem);
}

void DmaManager::dbgResp(const DmaDbgRec& dbgRec)
{
  fprintf(stderr, "dbgResp: %08x %08x %08x %08x\n", dbgRec.x, dbgRec.y, dbgRec.z, dbgRec.w);
  sem_post(&priv.dbgSem);
}

void DmaManager::confResp(uint32_t channelId)
{
  //fprintf(stderr, "configResp %d\n", channelId);
  sem_post(&priv.confSem);
}
#endif
