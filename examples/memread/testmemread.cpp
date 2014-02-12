#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <monkit.h>
#include "StdDmaIndication.h"

#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "MemreadIndicationWrapper.h"
#include "MemreadRequestProxy.h"

sem_t test_sem;
int numWords = 16 << 18;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
int mismatchCount;
int mismatchesReceived;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class MemreadIndication : public MemreadIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readReq(unsigned long v){
    fprintf(stderr, "Memread::readReq %lx\n", v);
  }
  virtual void readDone(unsigned long v){
    fprintf(stderr, "Memread::readDone mismatch=%lx\n", v);
    mismatchCount = v;
    sem_post(&test_sem);
  }
  virtual void started(unsigned long words){
    fprintf(stderr, "Memread::started: words=%lx\n", words);
  }
  virtual void rData ( unsigned long long v ){
    fprintf(stderr, "rData (%08x): ", rDataCnt++);
    dump("", (char*)&v, sizeof(v));
  }
  virtual void reportStateDbg(unsigned long streamRdCnt, unsigned long dataMismatch){
    fprintf(stderr, "Memread::reportStateDbg: streamRdCnt=%08lx dataMismatch=%ld\n", streamRdCnt, dataMismatch);
  }  
  virtual void mismatch(unsigned long offset, unsigned long long ev, unsigned long long v) {
    fprintf(stderr, "Mismatch at %lx %llx != %llx\n", offset, ev, v);
    mismatchesReceived++;
  }
  MemreadIndication(const char* devname, unsigned int addrbits) : MemreadIndicationWrapper(devname,addrbits){}
};

int main(int argc, const char **argv)
{
  PortalAlloc *srcAlloc;
  unsigned int *srcBuffer = 0;

  unsigned int srcGen = 0;

  MemreadRequestProxy *device = 0;
  DmaConfigProxy *dma = 0;
  
  MemreadIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new MemreadRequestProxy("fpga1", 16);
  dma = new DmaConfigProxy("fpga3", 16);

  deviceIndication = new MemreadIndication("fpga2", 16);
  dmaIndication = new DmaIndication(dma, "fpga4", 16);

  fprintf(stderr, "Main::allocating memory...\n");
  dma->alloc(alloc_sz, &srcAlloc);
  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  for (int i = 0; i < numWords; i++){
    srcBuffer[i] = srcGen++;
  }
    
  dma->dCacheFlushInval(srcAlloc, srcBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);

  fprintf(stderr, "Main::starting read %08x\n", numWords);
  dma->show_mem_stats(ChannelType_Read);
  start_timer(0);
  device->startRead(ref_srcAlloc, numWords, 16);
  sem_wait(&test_sem);
  unsigned long long cycles = stop_timer(0);
  unsigned long long beats = dma->show_mem_stats(ChannelType_Read);

  fprintf(stderr, "memory read utilization (beats/cycle): %f\n", ((float)beats)/((float)cycles));

  MonkitFile("perf.monkit")
    .setCycles(cycles)
    .setBeats(beats)
    .writeFile();

  while(mismatchesReceived != mismatchCount){sleep(1);}
  exit(mismatchCount ? 1 : 0);
}
