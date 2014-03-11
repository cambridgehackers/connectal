#include <stdio.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>
#include <monkit.h>
#include "sock_fd.h"
#include "StdDmaIndication.h"

#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "MemwriteIndicationWrapper.h"
#include "MemwriteRequestProxy.h"

sem_t done_sem;
#ifdef MMAP_HW
int numWords = 16 << 18;
#else
int numWords = 16 << 10;
#endif
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

class MemwriteIndication : public MemwriteIndicationWrapper
{
public:
  MemwriteIndication(int id) : MemwriteIndicationWrapper(id){}

  virtual void started(uint32_t words){
    fprintf(stderr, "Memwrite::started: words=%x\n", words);
  }
  virtual void writeDone ( uint32_t srcGen ){
    fprintf(stderr, "Memwrite::writeDone (%08x)\n", srcGen);
    sem_post(&done_sem);
  }
  virtual void reportStateDbg(uint32_t streamWrCnt, uint32_t srcGen){
    fprintf(stderr, "Memwrite::reportStateDbg: streamWrCnt=%08x srcGen=%d\n", streamWrCnt, srcGen);
  }  

};

MemwriteRequestProxy *device = 0;
DmaConfigProxy *dma = 0;

MemwriteIndication *deviceIndication = 0;
DmaIndication *dmaIndication = 0;

PortalAlloc *dstAlloc;
unsigned int *dstBuffer = 0;

void child(int rd_sock)
{
  int fd;
  bool mismatch = false;
  sock_fd_read(rd_sock, &fd);

  unsigned int *dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
  fprintf(stderr, "child::dstBuffer = %p\n", dstBuffer);

  unsigned int sg = 0;
  for (int i = 0; i < numWords; i++){
    mismatch |= (dstBuffer[i] != sg++);
    //fprintf(stderr, "%08x, %08x\n", dstBuffer[i], sg-1);
  }
  fprintf(stderr, "child::writeDone mismatch=%d\n", mismatch);
  munmap(dstBuffer, alloc_sz);
  close(fd);
  exit(mismatch);
}

void parent(int rd_sock, int wr_sock)
{
  
  if(sem_init(&done_sem, 1, 0)){
    fprintf(stderr, "error: failed to init done_sem\n");
    exit(1);
  }

  fprintf(stderr, "parent::%s %s\n", __DATE__, __TIME__);

  device = new MemwriteRequestProxy(IfcNames_MemwriteRequest);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);

  deviceIndication = new MemwriteIndication(IfcNames_MemwriteIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);
  
  fprintf(stderr, "parent::allocating memory...\n");
  dma->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc->header.fd, 0);
  
  pthread_t tid;
  fprintf(stderr, "parent::creating portalExec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "error: creating exec thwrite\n");
    exit(1);
  }
  
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  
  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = 0xDEADBEEF;
  }
  
  dma->dCacheFlushInval(dstAlloc, dstBuffer);
  fprintf(stderr, "parent::flush and invalidate complete\n");

  // for(int i = 0; i < dstAlloc->header.numEntries; i++)
  //   fprintf(stderr, "%lx %lx\n", dstAlloc->entries[i].dma_address, dstAlloc->entries[i].length);

  sleep(1);
  dma->addrRequest(ref_dstAlloc, 2*sizeof(unsigned int));
  sleep(1);


  fprintf(stderr, "parent::starting write %08x\n", numWords);
  start_timer(0);
  int burstLen = 16;
#ifdef MMAP_HW
  int iterCnt = 64;
#else
  int iterCnt = 2;
#endif
  device->startWrite(ref_dstAlloc, numWords, burstLen, iterCnt);
  sem_wait(&done_sem);
  uint64_t cycles = lap_timer(0);
  uint64_t beats = dma->show_mem_stats(ChannelType_Write);
  float write_util = (float)beats/(float)cycles;
  fprintf(stderr, "memory write utilization (beats/cycle): %f\n", write_util);

  MonkitFile("perf.monkit")
    .setHwCycles(cycles)
    .setWriteBwUtil(write_util)
    .writeFile();

  sock_fd_write(wr_sock, dstAlloc->header.fd);
  munmap(dstBuffer, alloc_sz);
  close(dstAlloc->header.fd);
}

int main(int argc, const char **argv)
{
  int sv[2];
  int pid;
  int status;
  
  if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sv) < 0) {
    perror("error: socketpair");
    exit(1);
  }
  switch ((pid = fork())) {
  case 0:
    close(sv[0]);
    child(sv[1]);
    break;
  case -1:
    perror("error: fork");
    exit(1);
  default:
    parent(sv[1],sv[0]);
    waitpid(pid, &status, 0);
    break;
  }
  exit(status);
}
