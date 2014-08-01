#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "portal.h"
#include "dmaManager.h"
#include "sock_utils.h"

int numWords = 16;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

class TestPM : public PortalMemory
{
public:
  virtual void sglist(uint32_t off, uint64_t addr, uint32_t len) {}
  virtual void paref(uint32_t off, uint32_t ref) {}
  TestPM() : PortalMemory(){}
};

void* child(void* prd_sock)
{
  int fd;
  int rd_sock = *((int*)prd_sock);
  sock_fd_read(rd_sock, &fd);

  unsigned int *dstBuffer = (unsigned int *)DmaManager_mmap(fd, alloc_sz);
  //fprintf(stderr, "child::mmap %08x\n", dstBuffer);  

  unsigned int sg = 0;
  bool mismatch = false;
  for (int i = 0; i < numWords; i++){
    mismatch |= (dstBuffer[i] != sg++);
    fprintf(stderr, "%08x, %08x\n", dstBuffer[i], sg-1);
  }
  fprintf(stderr, "child::writeDone mismatch=%d\n", mismatch);
  munmap(dstBuffer, alloc_sz);
  close(fd);
  return NULL;
}


void* parent(void* pwr_sock)
{
  int wr_sock = *((int*)pwr_sock);
  PortalAlloc dstAlloc;
  unsigned int *dstBuffer = 0;
  unsigned int *dba = 0;
  class TestPM *pm = new TestPM();
  
  fprintf(stderr, "parent::allocating memory...\n");
  pm->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)DmaManager_mmap(dstAlloc.header.fd, alloc_sz);
  fprintf(stderr, "parent::mmap %p\n", dstBuffer);  

  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = i;
  }
  
  pm->dCacheFlushInval(dstAlloc->header.fd, alloc_sz, dstBuffer);
  fprintf(stderr, "parent::flush and invalidate complete\n");

  int rc = ioctl(pm->pa_fd, PA_DEBUG_PK, &dstAlloc);
  fprintf(stderr, "parent::debug ioctl complete (%d)\n",rc);

  dba = (unsigned int *)DmaManager_mmap(dstAlloc.header.fd, alloc_sz);
  fprintf(stderr, "parent::mmap %p\n", dba);  

  unsigned int sg = 0;
  bool mismatch = false;
  for (int i = 0; i < numWords; i++){
    mismatch |= (dba[i] != sg++);
    fprintf(stderr, "%08x, %08x\n", dba[i], dstBuffer[i]);
  }
  fprintf(stderr, "parent::writeDone mismatch=%d\n", mismatch);

  sock_fd_write(wr_sock, dstAlloc.header.fd);
  munmap(dstBuffer, alloc_sz);
  close(dstAlloc.header.fd);
  return NULL;
}

int main(int argc, const char **argv)
{
  int sv[2];
  int pid;

  if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sv) < 0) {
    perror("socketpair");
    exit(1);
  }
    
  switch ((pid = fork())) {
  case 0:
    close(sv[0]);
    child(&sv[1]);
    break;
  case -1:
    perror("fork");
    exit(1);
  default:
    close(sv[1]);
    parent(&sv[0]);
    break;
  }
}
