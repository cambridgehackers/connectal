#include "Mempoke.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>

CoreRequest *device = 0;
DMARequest *dma = 0;
PortalAlloc dstAlloc;
unsigned int *dstBuffer = 0;
int numWords = 16 << 8;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
sem_t conf_sem;

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
    fprintf(stderr, "reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void configResp(unsigned long channelId){
    fprintf(stderr, "configResp: %lx\n", channelId);
    sem_post(&conf_sem);
  }
  virtual void sglistResp(unsigned long channelId){
    fprintf(stderr, "sglistResp: %lx\n", channelId);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "parefResp: %lx\n", channelId);
  }
};

class TestCoreIndication : public CoreIndication
{
  virtual void readWordResult (S0 &s){
    fprintf(stderr, "readWordResult(S0{a:%ld,b:%ld})\n", s.a, s.b);
  }
  virtual void writeWordResult (S0 &s){
    fprintf(stderr, "writeWordResult(S0{a:%ld,b:%ld})\n", s.a, s.b);
  }
};

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = CoreRequest::createCoreRequest(new TestCoreIndication);
  dma = DMARequest::createDMARequest(new TestDMAIndication);

  if(sem_init(&conf_sem, 1, 0)){
    fprintf(stderr, "failed to init conf_sem\n");
    return -1;
  }

  fprintf(stderr, "allocating memory...\n");
  dma->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc.header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  unsigned int ref_dstAlloc = dma->reference(&dstAlloc);

  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = i;
  }
    
  dma->dCacheFlushInval(&dstAlloc, dstBuffer);
  fprintf(stderr, "flush and invalidate complete\n");
      
  dma->configWriteChan(0, ref_dstAlloc, 2);
  sem_wait(&conf_sem);
  
  dma->configReadChan(0, ref_dstAlloc, 2);
  sem_wait(&conf_sem);

  device->readWord(5);
  sleep(1);
  S0 s = {3,4};
  device->writeWord(6,s);
  sleep(1);
  device->readWord(6);
  while(true){sleep(1);}
}
