
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

#ifdef __KERNEL__
#define PRIx64 "llx"
#define sem_wait(A)
#else
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "sock_utils.h"
#include "portalmem.h"
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#if defined(__arm__)
#include "zynqportal.h"
#endif
#endif

static int trace_memory;// = 1;

void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *argDevice)
{
  memset(priv, 0, sizeof(*priv));
  priv->device = argDevice;
#ifndef __KERNEL__
#ifndef MMAP_HW
  connect_socket(&priv->write, "fd_sock_wc", 0);
#endif
  priv->pa_fd = open("/dev/portalmem", O_RDWR);
  if (priv->pa_fd < 0){
    PORTAL_PRINTF("Failed to open /dev/portalmem pa_fd=%d errno=%d\n", priv->pa_fd, errno);
  }
  if (sem_init(&priv->confSem, 1, 0)){
    PORTAL_PRINTF("failed to init confSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&priv->mtSem, 0, 0)){
    PORTAL_PRINTF("failed to init mtSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&priv->dbgSem, 0, 0)){
    PORTAL_PRINTF("failed to init dbgSem errno=%d:%s\n", errno, strerror(errno));
  }
#endif
}

#ifndef __KERNEL__
int DmaManager_dCacheFlushInval(DmaManagerPrivate *priv, PortalAlloc *portalAlloc, void *__p)
{
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
  //PORTAL_PRINTF("dcache flush\n");
  return 0;

}
#endif
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
  int i;
  uint64_t regions[3] = {0,0,0};
  uint64_t shifts[3] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0};
  int id = priv->handle++;
  int ne = pa->header.numEntries;
  int size_accum = 0;
  uint64_t border = 0;
  unsigned char entryCount = 0;
  struct {
    uint64_t border;
    unsigned char idxOffset;
  } borders[3];

  // HW interprets zeros as end of sglist
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries++;
  if (trace_memory)
    PORTAL_PRINTF("DmaManager_reference id=%08x, numEntries:=%d len=%08lx)\n", id, ne, (long)pa->header.size);
#ifndef MMAP_HW
  sock_fd_write(priv->write, pa->header.fd);
#endif
  for(i = 0; i < pa->header.numEntries; i++){
    DmaEntry *e = &(pa->entries[i]);
    long addr;
#ifdef MMAP_HW
    addr = e->dma_address;
#else
    addr = (e->length > 0) ? size_accum : 0;
#endif
#ifdef BSIM
    addr |= ((long)id+1) << 32; //[39:32] = truncate(pref);
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
      PORTAL_PRINTF("DmaManager:unsupported sglist size %x\n", e->length);
    }
    if (trace_memory)
      PORTAL_PRINTF("DmaManager:sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, (long)addr, e->length);
    DMAsglist(priv->device, id, addr, e->length);
    size_accum += e->length;
    // PORTAL_PRINTF("%s:%d sem_wait\n", __FILE__, __LINE__);
    sem_wait(&priv->confSem);
  }
  for(i = 0; i < 3; i++){
    

    // PORTAL_PRINTF("i=%d entryCount=%d border=%zx shifts=%zd shifted=%zx masked=%zx idxOffset=%zx added=%zx\n",
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
    PORTAL_PRINTF("regions %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,regions[0], regions[1], regions[2]);
    PORTAL_PRINTF("borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borders[0].border, borders[1].border, borders[2].border);
  }
  DMAregion(priv->device, id,
	 (borders[0].border << 8) | borders[0].idxOffset,
	 (borders[1].border << 8) | borders[1].idxOffset,
	 (borders[2].border << 8) | borders[2].idxOffset);
  //PORTAL_PRINTF("%s:%d sem_wait\n", __FILE__, __LINE__);
  sem_wait(&priv->confSem);
  return id+1;
}

int DmaManager_alloc(DmaManagerPrivate *priv, size_t size, PortalAlloc **ppa)
{
  PortalAlloc localPortalAlloc;
  PortalAlloc *portalAlloc = NULL;
  memset(&localPortalAlloc, 0, sizeof(localPortalAlloc));
  localPortalAlloc.header.size = size;
#ifndef __KERNEL__
  int rc = ioctl(priv->pa_fd, PA_ALLOC, &localPortalAlloc);
  if (rc){
    PORTAL_PRINTF("portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  long mb = localPortalAlloc.header.size/(1L<<20);
  PORTAL_PRINTF("alloc size=%ldMB fd=%d numEntries=%d\n", 
	  mb, localPortalAlloc.header.fd, localPortalAlloc.header.numEntries);
  portalAlloc = (PortalAlloc *)malloc(sizeof(PortalAlloc)+((localPortalAlloc.header.numEntries+1)*sizeof(DmaEntry)));
  memcpy(portalAlloc, &localPortalAlloc, sizeof(localPortalAlloc));
  rc = ioctl(priv->pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    PORTAL_PRINTF("portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
#endif
  *ppa = portalAlloc;
  return 0;
}
