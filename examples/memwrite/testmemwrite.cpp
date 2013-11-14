#include "Memwrite.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "sock_fd.h"

int numWords = 16 << 2;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
sem_t done_sem;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class TestDMAIndication : public DMAIndication
{
  virtual void reportStateDbg(DmaDbgRec& rec){
    fprintf(stderr, "DMA::reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void configResp(unsigned long channelId){
    fprintf(stderr, "DMA::configResp: %lx\n", channelId);
  }
  virtual void sglistResp(unsigned long channelId){
    fprintf(stderr, "DMA::sglistResp: %lx\n", channelId);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "DMA::parefResp: %lx\n", channelId);
  }
};

class TestCoreIndication : public CoreIndication
{
  virtual void writeReq(unsigned long v){
    fprintf(stderr, "Core::writeReq %lx\n", v);
  }
  virtual void started(unsigned long words){
    fprintf(stderr, "Core::started: words=%lx\n", words);
  }
  virtual void writeDone ( unsigned long srcGen ){
    fprintf(stderr, "Core::writeDone (%08lx)\n", srcGen);
    sem_post(&done_sem);    
  }
  virtual void reportStateDbg(unsigned long streamWrCnt, unsigned long srcGen){
    fprintf(stderr, "Core::reportStateDbg: streamWrCnt=%08lx srcGen=%ld\n", streamWrCnt, srcGen);
  }  
};

void child(int rd_sock)
{
  int fd;
  sock_fd_read(rd_sock, &fd);

  unsigned int *dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
  fprintf(stderr, "child::dstBuffer = %08lx\n", (unsigned long)dstBuffer);

  unsigned int sg = 0;
  bool mismatch = false;
  for (int i = 0; i < numWords; i++){
    mismatch |= (dstBuffer[i] != sg++);
    //fprintf(stderr, "%08x, %08x\n", dstBuffer[i], sg-1);
  }
  fprintf(stderr, "child::writeDone mismatch=%d\n", mismatch);
  munmap(dstBuffer, alloc_sz);
  close(fd);
}

void parent(int rd_sock, int wr_sock)
{
  CoreRequest *device = 0;
  DMARequest *dma = 0;
  PortalAlloc dstAlloc;
  unsigned int *dstBuffer = 0;
  
  if(sem_init(&done_sem, 1, 0)){
    fprintf(stderr, "failed to init done_sem\n");
    exit(1);
  }
  
  fprintf(stderr, "parent::%s %s\n", __DATE__, __TIME__);
  device = CoreRequest::createCoreRequest(new TestCoreIndication);
  dma = DMARequest::createDMARequest(new TestDMAIndication);
  
  fprintf(stderr, "parent::allocating memory...\n");
  dma->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc.header.fd, 0);
  
  pthread_t tid;
  fprintf(stderr, "parent::creating portalExec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "error creating exec thwrite\n");
    exit(1);
  }
  
  unsigned int ref_dstAlloc = dma->reference(&dstAlloc);
  
  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = 0xDEADBEEF;
  }
  
  dma->dCacheFlushInval(&dstAlloc, dstBuffer);
  fprintf(stderr, "parent::flush and invalidate complete\n");

  // write channel 0 is write source
  dma->configWriteChan(0, ref_dstAlloc, 16);

  fprintf(stderr, "parent::starting write %08x\n", numWords);
  device->startWrite(numWords);

  sem_wait(&done_sem);
  
  sock_fd_write(wr_sock, dstAlloc.header.fd);
  munmap(dstBuffer, alloc_sz);
  close(dstAlloc.header.fd);
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
    child(sv[1]);
    break;
  case -1:
    perror("fork");
    exit(1);
  default:
    parent(sv[1],sv[0]);
    break;
  }
}
