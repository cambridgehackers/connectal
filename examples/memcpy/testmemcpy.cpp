#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>

#include "BlueScopeIndicationWrapper.h"
#include "BlueScopeRequestProxy.h"
#include "DMAIndicationWrapper.h"
#include "DMARequestProxy.h"
#include "GeneratedTypes.h"
#include "MemcpyIndicationWrapper.h"
#include "MemcpyRequestProxy.h"

PortalAlloc *srcAlloc;
PortalAlloc *dstAlloc;
PortalAlloc *bsAlloc;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
unsigned int *bsBuffer  = 0;
int numWords = 128;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

sem_t iter_sem;
sem_t conf_sem;
bool memcmp_fail = false;
unsigned int memcmp_count = 0;
unsigned int iterCnt=1;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class DMAIndication : public DMAIndicationWrapper
{

public:
  DMAIndication(const char* devname, unsigned int addrbits) : DMAIndicationWrapper(devname,addrbits){}

  virtual void reportStateDbg(const DmaDbgRec& rec){
    fprintf(stderr, "reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void sglistResp(unsigned long channelId){
    fprintf(stderr, "sglistResp: %lx\n", channelId);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "parefResp: %lx\n", channelId);
  }
};

class MemcpyIndication : public MemcpyIndicationWrapper
{

public:
  MemcpyIndication(const char* devname, unsigned int addrbits) : MemcpyIndicationWrapper(devname,addrbits){}

  virtual void started(unsigned long words){
    fprintf(stderr, "started: words=%ld\n", words);
  }
  virtual void readWordResult ( unsigned long long v ){
    dump("readWordResult: ", (char*)&v, sizeof(v));
  }
  virtual void done(unsigned long v) {
    unsigned int mcf = memcmp(srcBuffer, dstBuffer, test_sz);
    memcmp_fail |= mcf;
    if(true){
      fprintf(stderr, "memcpy done: %lx\n", v);
      fprintf(stderr, "(%d) memcmp src=%lx dst=%lx success=%s\n", memcmp_count, (long)srcBuffer, (long)dstBuffer, mcf == 0 ? "pass" : "fail");
      dump("src", (char*)srcBuffer, test_sz);
      dump("dst", (char*)dstBuffer, test_sz);
    }
    sem_post(&iter_sem);
    if(iterCnt == ++memcmp_count){
      fprintf(stderr, "testmemcpy finished count=%d memcmp_fail=%d\n", memcmp_count, memcmp_fail);
      exit(0);
    }
  }
  virtual void rData ( unsigned long long v ){
    dump("rData: ", (char*)&v, sizeof(v));
  }
  virtual void readReq(unsigned long v){
    //fprintf(stderr, "readReq %lx\n", v);
  }
  virtual void writeReq(unsigned long v){
    //fprintf(stderr, "writeReq %lx\n", v);
  }
  virtual void writeAck(unsigned long v){
    //fprintf(stderr, "writeAck %lx\n", v);
  }
  virtual void reportStateDbg(unsigned long srcGen, unsigned long streamRdCnt, 
			      unsigned long streamWrCnt, unsigned long writeInProg, 
			      unsigned long dataMismatch){
    fprintf(stderr, "Memcpy::reportStateDbg: srcGen=%ld, streamRdCnt=%ld, streamWrCnt=%ld, writeInProg=%ld, dataMismatch=%ld\n", 
	    srcGen, streamRdCnt, streamWrCnt, writeInProg, dataMismatch);
  }  
};

class BlueScopeIndication : public BlueScopeIndicationWrapper
{
public:
  BlueScopeIndication(const char* devname, unsigned int addrbits) : BlueScopeIndicationWrapper(devname,addrbits){}

  virtual void triggerFired( ){
    fprintf(stderr, "BlueScope::triggerFired\n");
  }
  virtual void reportStateDbg(unsigned long long mask, unsigned long long value){
    //fprintf(stderr, "BlueScope::reportStateDbg mask=%016llx, value=%016llx\n", mask, value);
    fprintf(stderr, "BlueScope::reportStateDbg\n");
    dump("    mask =", (char*)&mask, sizeof(mask));
    dump("   value =", (char*)&value, sizeof(value));
  }
};

// we can use the data synchronization barrier instead of flushing the 
// cache only because the ps7 is configured to run in buffered-write mode
//
// an opc2 of '4' and CRm of 'c10' encodes "CP15DSB, Data Synchronization Barrier 
// operation". this is a legal instruction to execute in non-privileged mode (mdk)
//
// #define DATA_SYNC_BARRIER   __asm __volatile( "MCR p15, 0, %0, c7, c10, 4" ::  "r" (0) );

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  MemcpyRequestProxy *device = 0;
  BlueScopeRequestProxy *bluescope = 0;
  DMARequestProxy *dma = 0;
  
  MemcpyIndication *deviceIndication = 0;
  BlueScopeIndication *bluescopeIndication = 0;
  DMAIndication *dmaIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  device = new MemcpyRequestProxy("fpga1", 16);
  bluescope = new BlueScopeRequestProxy("fpga3", 16);
  dma = new DMARequestProxy("fpga5", 16);

  deviceIndication = new MemcpyIndication("fpga2", 16);
  bluescopeIndication = new BlueScopeIndication("fpga4", 16);
  dmaIndication = new DMAIndication("fpga6", 16);

  if(sem_init(&iter_sem, 1, 1)){
    fprintf(stderr, "failed to init iter_sem\n");
    return -1;
  }
  if(sem_init(&conf_sem, 1, 0)){
    fprintf(stderr, "failed to init conf_sem\n");
    return -1;
  }

  fprintf(stderr, "allocating memory...\n");

  dma->alloc(alloc_sz, &srcAlloc);
  dma->alloc(alloc_sz, &dstAlloc);
  dma->alloc(alloc_sz, &bsAlloc);

  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc->header.fd, 0);
  bsBuffer  = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, bsAlloc->header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  unsigned int ref_bsAlloc  = dma->reference(bsAlloc);

  while (srcGen < iterCnt*numWords){

    sem_wait(&iter_sem);
    for (int i = 0; i < numWords; i++){
      srcBuffer[i] = srcGen++;
      dstBuffer[i] = 5;
    }
    
    dma->dCacheFlushInval(srcAlloc, srcBuffer);
    dma->dCacheFlushInval(dstAlloc, dstBuffer);
    dma->dCacheFlushInval(bsAlloc,  bsBuffer);
    fprintf(stderr, "flush and invalidate complete\n");

    fprintf(stderr, "starting mempcy numWords:%d\n", numWords);
    bluescope->reset();
    bluescope->setTriggerMask (0xFFFFFFFF);
    bluescope->setTriggerValue(0x00000002);
    bluescope->start(ref_bsAlloc);

    //bluescope->getStateDbg();
    //device->getStateDbg();
    sleep(1);

    // initiate the transfer
    device->startCopy(ref_dstAlloc, ref_srcAlloc, numWords);
  } 
  while(1){sleep(1);}
}
