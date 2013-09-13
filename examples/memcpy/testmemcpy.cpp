#include "Memcpy.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>

CoreRequest *device = 0;
BlueScopeRequest *bluescope = 0;
PortalAlloc srcAlloc;
PortalAlloc dstAlloc;
PortalAlloc bsAlloc;
int srcFd = -1;
int dstFd = -1;
int bsFd  = -1;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
unsigned int *bsBuffer  = 0;
int numWords = 32;
size_t size = numWords*sizeof(unsigned int);

sem_t sem;
bool memcmp_fail = false;
unsigned int memcmp_count = 0;
unsigned int iterCnt=32;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s: ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class TestCoreIndication : public CoreIndication
{
  virtual void started(unsigned long words){
    fprintf(stderr, "started: words=%lx\n", words);
  }
  virtual void readWordResult ( unsigned long long v ){
    dump("readWordResult: ", (char*)&v, sizeof(v));
  }
  virtual void done(unsigned long v) {
    unsigned int mcf = memcmp(srcBuffer, dstBuffer, size);
    memcmp_fail |= mcf;
    if(true){
      fprintf(stderr, "memcpy done: %lx\n", v);
      fprintf(stderr, "(%d) memcmp src=%lx dst=%lx success=%s\n", memcmp_count, srcBuffer, dstBuffer, mcf == 0 ? "pass" : "fail");
      dump("src", (char*)srcBuffer, size);
      dump("dst", (char*)dstBuffer, size);
    }
    sem_post(&sem);
    if(iterCnt == ++memcmp_count){
      fprintf(stderr, "testmemcpy finished count=%d memcmp_fail=%d\n", memcmp_count, memcmp_fail);
      exit(0);
    }
  }
  virtual void rData ( unsigned long long v ){
    dump("rData: ", (char*)&v, sizeof(v));
  }
  virtual void readReq(unsigned long v){
    fprintf(stderr, "readReq %lx\n", v);
  }
  virtual void writeReq(unsigned long v){
    fprintf(stderr, "writeReq %lx\n", v);
  }
  virtual void writeAck(unsigned long v){
    fprintf(stderr, "writeAck %lx\n", v);
  }
  virtual void configResp(unsigned long chanId, unsigned long pa, unsigned long numWords){
    fprintf(stderr, "configResp %d, %lx, %d\n", chanId, pa, numWords);
  }
  virtual void reportStateDbg(unsigned long srcGen, unsigned long streamRdCnt, 
			      unsigned long streamWrCnt, unsigned long writeInProg, 
			      unsigned long dataMismatch){
    fprintf(stderr, "reportStateDbg: srcGen=%d, streamRdCnt=%d, streamWrCnt=%d, writeInProg=%d, dataMismatch=%d\n", 
	    srcGen, streamRdCnt, streamWrCnt, writeInProg, dataMismatch);
  }  
};

class TestBlueScopeIndication : public BlueScopeIndication
{
  virtual void triggerFired( ){
    fprintf(stderr, "triggerFired\n");
  }
};

// we can use the data synchronization barrier instead of flushing the 
// cache only because the ps7 is configured to run in buffered-write mode
//
// an opc2 of '4' and CRm of 'c10' encodes "CP15DSB, Data Synchronization Barrier 
// operation". this is a legal instruction to execute in non-privileged mode (mdk)
//
#define DATA_SYNC_BARRIER   __asm __volatile( "MCR p15, 0, %0, c7, c10, 4" ::  "r" (0) );

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = CoreRequest::createCoreRequest("fpga0", new TestCoreIndication);
  bluescope = BlueScopeRequest::createBlueScopeRequest("fpga0", new TestBlueScopeIndication);

  if(sem_init(&sem, 1, 1)){
    fprintf(stderr, "failed to init sem\n");
    return -1;
  }

  PortalMemory::alloc(size, &srcFd, &srcAlloc);
  PortalMemory::alloc(size, &dstFd, &dstAlloc);
  PortalMemory::alloc(size, &bsFd,  &bsAlloc);

  srcBuffer = (unsigned int *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcFd, 0);
  dstBuffer = (unsigned int *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstFd, 0);
  bsBuffer  = (unsigned int *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, bsFd, 0);

  // workaround for a latent bug somewhere in the SW stack
  PortalMemory::dCacheFlushInval(&srcAlloc);
  PortalMemory::dCacheFlushInval(&dstAlloc);
  PortalMemory::dCacheFlushInval(&bsAlloc);

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "error creating exec thread\n");
    exit(1);
  }

  device->getStateDbg();
  while (srcGen < iterCnt*numWords){
    sem_wait(&sem);
    for (int i = 0; i < numWords; i++){
      srcBuffer[i] = srcGen++;
      dstBuffer[i] = 5;
    }
    
    PortalMemory::dCacheFlushInval(&srcAlloc);
    PortalMemory::dCacheFlushInval(&dstAlloc);
    PortalMemory::dCacheFlushInval(&bsAlloc);
    DATA_SYNC_BARRIER;
          
    // write channel 0 is dma destination
    device->configDmaWriteChan(0, dstAlloc.entries[0].dma_address, numWords/2);
    // read channel 0 is dma source
    device->configDmaReadChan(0, srcAlloc.entries[0].dma_address, numWords/2);
    // read channel 1 is readWord source
    device->configDmaReadChan(1, srcAlloc.entries[0].dma_address, 2);
    // write channel 1 is Bluescope desgination
    device->configDmaWriteChan(1, bsAlloc.entries[0].dma_address, 4);

    fprintf(stderr, "starting mempcy src:%x dst:%x numWords:%d\n",
    	    srcAlloc.entries[0].dma_address,
    	    dstAlloc.entries[0].dma_address,
    	    numWords);

    // initiate the transfer
    device->startDMA(numWords);

  }  
  while(1);
}
