#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "../../cpp/portal.h"
#include "../../cpp/sock_fd.h"

int numWords = 16;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
sem_t parent_done;

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

  fprintf(stderr, "child::waiting for parent_done\n");
  sem_wait(&parent_done);
  fprintf(stderr, "child::acquired for parent_done\n");

  unsigned int *dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
  fprintf(stderr, "child::dstBuffer = %08lx\n", (unsigned long)dstBuffer);

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
  //munmap(dstBuffer, alloc_sz);
  //close(fd);
  return NULL;
}


void waste_space() 
{
 // Allocate 80M. Set much larger then L2
  const int size = 80*1024*1024;
  char *c = (char *)malloc(size);
  for (int i = 0xfffe; i < 0xffff; i++)
    for (int j = 0; j < size; j++)
      c[j] = i*j;
  free(c);
}


void* parent(void* pwr_sock)
{
  int wr_sock = *((int*)pwr_sock);
  PortalAlloc dstAlloc;
  unsigned int *dstBuffer = 0;
  class TestPM *pm = new TestPM();
  
  fprintf(stderr, "parent::%s %s\n", __DATE__, __TIME__);
  
  fprintf(stderr, "parent::allocating memory...\n");
  pm->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc.header.fd, 0);
  
  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = i;
  }
  
  pm->dCacheFlushInval(&dstAlloc, dstBuffer);
  //fprintf(stderr, "parent::flush and invalidate complete\n");
  waste_space();

  sock_fd_write(wr_sock, dstAlloc.header.fd);
  // munmap(dstBuffer, alloc_sz);
  // close(dstAlloc.header.fd);
  if(sem_post(&parent_done)){
    fprintf(stderr, "parent::sem_post error\n");
  } else {
    fprintf(stderr, "parent::sem_post success\n");
  }
  while(true);
  return NULL;
}

int main(int argc, const char **argv)
{
  int sv[2];
  int pid;
  pthread_t tid;
    
  if(sem_init(&parent_done, 1, 0) < 0){
    fprintf(stderr, "failed to init parent_done\n");
    exit(1);
  }

  if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sv) < 0) {
    perror("socketpair");
    exit(1);
  }

  if(pthread_create(&tid, NULL, child, (void*)&sv[1])){
    fprintf(stderr, "error creating child pthread\n");
    exit(1);
  }

  if(pthread_create(&tid, NULL, parent, (void*)&sv[0])){
    fprintf(stderr, "error creating parent pthread\n");
    exit(1);
  }

  while(1);  
}
