
#include "Memcpy.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>

#include <sys/syscall.h>
#define cacheflush(a, b, c)    syscall(__ARM_NR_cacheflush, (a), (b), (c))

Memcpy *device = 0;
PortalAlloc srcAlloc;
PortalAlloc dstAlloc;
int srcFd = -1;
int dstFd = -1;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
int numWords = 32;
size_t size = numWords*sizeof(unsigned int);

sem_t sem;
bool fail = false;
unsigned int dmv = false;
unsigned int dmc=0;
unsigned int iterCnt=1024;

typedef struct{
  unsigned long long data;
  bool valid;
} ret_val;

ret_val cwt;
int cw_cnt = 0;
unsigned int offset = 0;
void check_word(unsigned long long v){
  if(!cwt.valid){
    cwt.data = v;
    cwt.valid = true;
  } else {
    fail |= cwt.data != v;
    if(!(cw_cnt++ % 128))
      fprintf(stderr, "check_word: cw_cnt=%d offset=%d status=%s\n", cw_cnt, offset, cwt.data == v ? "pass" : "fail XXXXXXXXXXXXXXXXXX");
    cwt.valid = false;
  }
}


void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s: ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len); i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class TestMemcpyIndications : public MemcpyIndications
{
  virtual void started() {
    // fprintf(stderr, "started\n");
  }
  virtual void started1(unsigned long src, unsigned long srcLimit, unsigned long dst, unsigned long dstLimit){
    // fprintf(stderr, "started1:  srcPhys=%lx\n", src);
    // fprintf(stderr, "started1: srcLimit=%lx\n", srcLimit);
    // fprintf(stderr, "started1:  dstPhys=%lx\n", dst);
    // fprintf(stderr, "started1: dstLimit=%lx\n", dstLimit);
  }
  virtual void traceData(long long unsigned int){}
  virtual void sampleCount(long unsigned int){}
  virtual void srcPhys(unsigned long src) {
    fprintf(stderr, "srcPhys: %lx\n", src);
  }
  virtual void dataMismatch(unsigned long v){
    if(!(dmc%128))
      fprintf(stderr, "dataMismatch(%d): %lx\n", dmc,v);
    dmv |= v;
    if(++dmc >= iterCnt){
      fprintf(stderr, "exiting test, result = %s, dmv=%d\n", fail ? "fail" : "pass",dmv);
      exit(0);
    }
  }
  virtual void dstCompPtr(unsigned long v){
    fprintf(stderr, "dstCompPtr: %lx\n", v);
  }
  virtual void srcLimit(unsigned long limit) {
    fprintf(stderr, "srcLimit: %lx\n", limit);
  }
  virtual void dstPhys(unsigned long dst) {
    fprintf(stderr, "dstPhys: %lx\n", dst);
  }
  virtual void dstLimit(unsigned long limit) {
    fprintf(stderr, "dstLimit: %lx\n", limit);
  }
  virtual void src(unsigned long src) {
    fprintf(stderr, "src: %lx\n", src);
  }
  virtual void dst(unsigned long dst) {
    fprintf(stderr, "dst: %lx\n", dst);
  }
  virtual void rData(unsigned long long v) {
    dump("rData: ", (char*)&v, sizeof(v));
  }
  virtual void readWordResult ( unsigned long addr, unsigned long long v ){
    // fprintf(stderr, "readWordResult (%lx): ", addr);
    // dump("", (char*)&v, sizeof(v));
    check_word(v);
  }
  virtual void done(unsigned long v) {
    offset = (rand() % numWords); // *sizeof(unsigned int);
    //fprintf(stderr, "memcpy done: %lx %d\n", v, offset);
    device->readWord(srcAlloc.entries[0].dma_address + offset*4);
    device->readWord(dstAlloc.entries[0].dma_address + offset*4);
    // fprintf(stderr, "memcmp src=%lx dst=%lx success=%s\n",
    // 	    srcBuffer, dstBuffer, memcmp(srcBuffer, dstBuffer, size) == 0 ? "yes" : "no");
    // dump("src", srcBuffer, size);
    // dump("dst", dstBuffer, size);
    sem_post(&sem);
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
  cwt.valid = false;
  unsigned int srcGen = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = Memcpy::createMemcpy("fpga0", new TestMemcpyIndications);

  if(sem_init(&sem, 1, 1)){
    fprintf(stderr, "failed to init sem\n");
    return -1;
  }

  PortalInterface::alloc(size, &srcFd, &srcAlloc);
  PortalInterface::alloc(size, &dstFd, &dstAlloc);

  srcBuffer = (unsigned int *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcFd, 0);
  dstBuffer = (unsigned int *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstFd, 0);


  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  PortalInterface::exec, NULL)){
    fprintf(stderr, "error creating exec thread\n");
    exit(1);
  }

  while (srcGen < iterCnt*numWords){
    sem_wait(&sem);
    for (int i = 0; i < numWords; i++){
      srcBuffer[i] = srcGen++;
      dstBuffer[i] = 5;
    }
    
    DATA_SYNC_BARRIER;
    
    // I'm not sure that this actually invalidates the dstBuffer
    // at some point, invocations to cacheflush will be replaced by:
    // in order to do this, we first need to move this functionality
    // from cache-v7.S:ENTRY(v7_coherent_user_range) to portal.c
    int rv = cacheflush(dstBuffer, dstBuffer+size, 0);
    // fprintf(stderr, "cacheflush=%d\n", rv);
    
    PortalInterface::dCacheFlushInval(&dstAlloc);
    //device->reset(8);

    // fprintf(stderr, "starting mempcy src:%x dst:%x numWords:%x\n",
    // 	    srcAlloc.entries[0].dma_address,
    // 	    dstAlloc.entries[0].dma_address,
    // 	    numWords);
    
    //device->readWord(srcAlloc.entries[0].dma_address);
    //device->readWord(srcAlloc.entries[0].dma_address + (numWords-1)*4);

    device->memcpy(dstAlloc.entries[0].dma_address,
		   srcAlloc.entries[0].dma_address,
		   numWords);
  }
  
  
  // PortalInterface::free(srcFd);
  // PortalInterface::free(dstFd);
  // sem_destroy(&sem);
  // fprintf(stderr, "leaving test, result=%s\n", fail ? "fail" : "pass");
  // return 0;
  while(1);
}
