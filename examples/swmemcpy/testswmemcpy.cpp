#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "portal.h"
#include "sock_fd.h"

int numWords = 16;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

class TestPM : public PortalMemory
{
public:
  virtual void sglist(unsigned long off, unsigned long long addr, unsigned long len) {}
  virtual void paref(unsigned long off, unsigned long ref) {}
  TestPM() : PortalMemory(){}
};

void* child(void* prd_sock)
{
  int fd;
  int rd_sock = *((int*)prd_sock);
  sock_fd_read(rd_sock, &fd);

  unsigned int *dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
  fprintf(stderr, "child::mmap %08x\n", dstBuffer);  

  int j = 0;
  do{
    unsigned int sg = 0;
    bool mismatch = false;
    for (int i = 0; i < numWords; i++){
      mismatch |= (dstBuffer[i] != sg++);
      fprintf(stderr, "%08x, %08x\n", dstBuffer[i], sg-1);
    }
    fprintf(stderr, "child::writeDone mismatch=%d (%d)\n", mismatch, j++);
  }while(false);

  munmap(dstBuffer, alloc_sz);
  close(fd);
  return NULL;
}


void* parent(void* pwr_sock)
{
  int wr_sock = *((int*)pwr_sock);
  PortalAlloc dstAlloc;
  unsigned int *dstBuffer = 0;
  class TestPM *pm = new TestPM();
  
  fprintf(stderr, "parent::allocating memory...\n");
  pm->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc.header.fd, 0);
  fprintf(stderr, "parent::mmap %08x\n", dstBuffer);  

  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = i;
  }
  
  pm->dCacheFlushInval(&dstAlloc, dstBuffer);
  fprintf(stderr, "parent::flush and invalidate complete\n");

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
