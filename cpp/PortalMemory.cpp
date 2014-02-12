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

void PortalMemory::InitSemaphores()
{
  if (sem_init(&sglistSem, 1, 0)){
    fprintf(stderr, "failed to init sglistSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&mtSem, 0, 0)){
    fprintf(stderr, "failed to init mtSem errno=%d:%s\n", errno, strerror(errno));
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
PortalMemory::PortalMemory(const char *devname, unsigned int addrbits)
  : PortalProxy(devname, addrbits)
  , handle(1)
  , callBacksRegistered(false)
{
  InitFds();
  const char* path = "/dev/portalmem";
  this->pa_fd = ::open(path, O_RDWR);
  if (this->pa_fd < 0){
    fprintf(stderr, "Failed to open %s pa_fd=%ld errno=%d\n", path, (long)this->pa_fd, errno);
  }
  InitSemaphores();
}

PortalMemory::PortalMemory(int id)
  : PortalProxy(id),
    handle(1)
{
  InitFds();
  const char* path = "/dev/portalmem";
  this->pa_fd = ::open(path, O_RDWR);
  if (this->pa_fd < 0){
    fprintf(stderr, "Failed to open %s pa_fd=%ld errno=%d\n", path, (long)this->pa_fd, errno);
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

void PortalMemory::show_mem_stats(ChannelType rc)
{
  getMemoryTraffic(rc);
  if (callBacksRegistered) {
    sem_wait(&mtSem);
  } else {
    fprintf(stderr, "ugly hack\n");
    sleep(1);
  }
}

int PortalMemory::reference(PortalAlloc* pa)
{
  int id = handle++;
  int ne = pa->header.numEntries;
  int size_accum = 0;
  // HW interprets zeros as end of sglist
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries++;
  fprintf(stderr, "PortalMemory::reference id=%08x, numEntries:=%d len=%08lx)\n", id, ne, pa->header.size);
#ifndef MMAP_HW
  sock_fd_write(p_fd.write.s2, pa->header.fd);
#endif
  for(int i = 0; i < pa->header.numEntries; i++){
    DmaEntry *e = &(pa->entries[i]);
#ifdef MMAP_HW
    //fprintf(stderr, "PortalMemory::sglist(id=%08x, i=%d dma_addr=%08lx, len=%08lx)\n", id, i, e->dma_address, e->length);
    sglist(id, e->dma_address, e->length);
#else
    int addr = (e->length > 0) ? size_accum : 0;
    //fprintf(stderr, "PortalMemory::sglist(id=%08x, i=%d dma_addr=%08lx, len=%08lx)\n", id, i, addr, e->length);
    sglist(id, addr , e->length);
#endif
    size_accum += e->length;
    if (callBacksRegistered) {
      //fprintf(stderr, "sem_wait\n");
      sem_wait(&sglistSem);
    } else {
      fprintf(stderr, "ugly hack\n");
      sleep(1);
    }
  }
  return id;
}

void PortalMemory::reportMemoryTraffic(unsigned long long words)
{
  sem_post(&mtSem);
}

void PortalMemory::configResp(unsigned long channelId)
{
  sem_post(&sglistSem);
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
  fprintf(stderr, "alloc size=%ld rc=%d fd=%d numEntries=%d\n", 
	  (long)portalAlloc->header.size, rc, portalAlloc->header.fd, portalAlloc->header.numEntries);
  portalAlloc = (PortalAlloc *)realloc(portalAlloc, sizeof(PortalAlloc)+((portalAlloc->header.numEntries+1)*sizeof(DmaEntry)));
  rc = ioctl(this->pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  *ppa = portalAlloc;
  return 0;
}

