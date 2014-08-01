
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

#ifndef __KERNEL__
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#if defined(__arm__)
#include "zynqportal.h"
#else
#include "pcieportal.h"
#endif
#endif

#if 1 //def NO_CPP_PORTAL_CODE
#include "GeneratedTypes.h" // generated in project directory
#define DMAGetMemoryTraffic(P,A) DmaConfigProxy_getMemoryTraffic((P), (A))
#else
#include "DmaConfigProxy.h" // generated in project directory
#define DMAGetMemoryTraffic(P,A) ((DmaConfigProxy *)((P)->parent))->getMemoryTraffic((A))
#endif

#define KERNEL_REFERENCE

static int trace_memory;// = 1;

#include "dmaSendFd.h"

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

int DmaManager_dCacheFlushInval(PortalInternal *priv, int fd, long size, void *__p)
{
#ifndef __KERNEL__
#if defined(__arm__)
  int rc = ioctl(priv->fpga_fd, PORTAL_DCACHE_FLUSH_INVAL, fd);
  if (rc){
    PORTAL_PRINTF("portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
#elif defined(__i386__) || defined(__x86_64__)
  // not sure any of this is necessary (mdk)
  for(unsigned int i = 0; i < size; i++){
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
  int id = priv->handle++;
  int rc = 0;
#if defined(KERNEL_REFERENCE) && !defined(BSIM) && !defined(__KERNEL__)
#ifdef ZYNQ
  PortalSendFd sendFd;
  sendFd.fd = pa->header.fd;
  sendFd.id = id;
  rc = ioctl(priv->device->fpga_fd, PORTAL_SEND_FD, &sendFd);
#else
  tSendFd sendFd;
  sendFd.fd = pa->header.fd;
  sendFd.id = id;
  rc = ioctl(priv->device->fpga_fd, PCIE_SEND_FD, &sendFd);
#endif
  if (!rc)
    sem_wait(&priv->confSem);
  rc = id;
#else // KERNEL_REFERENCE
  rc = send_fd_to_portal(priv->device, pa->header.fd, id, priv->pa_fd);
  if (rc <= 0) {
    //PORTAL_PRINTF("%s:%d sem_wait\n", __FUNCTION__, __LINE__);
    sem_wait(&priv->confSem);
  }
#endif // KERNEL_REFERENCE
  return rc;
}

int DmaManager_alloc(DmaManagerPrivate *priv, size_t size, PortalAlloc **ppa)
{
  int rc = 0;
  PortalAlloc *portalAlloc = (PortalAlloc *)PORTAL_MALLOC(sizeof(PortalAlloc));

  *ppa = portalAlloc;
  if (!portalAlloc) {
    PORTAL_PRINTF("DmaManager_alloc: malloc failed\n");
    return -1;
  }
  memset(portalAlloc, 0, sizeof(*portalAlloc));
#ifdef __KERNEL__
  portalAlloc->header.fd = portalmem_dmabuffer_create(size);
#else
  portalAlloc->header.fd = ioctl(priv->pa_fd, PA_MALLOC, size);
#endif
  PORTAL_PRINTF("alloc size=%ldMB fd=%d\n", size/(1L<<20), portalAlloc->header.fd);
  return rc;
}

void *DmaManager_mmap(int fd, size_t size)
{
  void *retptr;
#ifdef __KERNEL__
  struct file *fmem = fget(fd);
  retptr = dma_buf_vmap(fmem->private_data);
  fput(fmem);
#else      ///////////////////////// userspace version
  retptr = (unsigned int *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
#endif
  return retptr;
}
