#include "Memread.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

CoreRequest *device = 0;
DMARequest *dma = 0;
PortalAlloc srcAlloc;
unsigned int *srcBuffer = 0;

int numWords = 16 << 8;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

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
  unsigned int rDataCnt;
  virtual void readReq(unsigned long v){
    //fprintf(stderr, "Core::readReq %lx\n", v);
  }
  virtual void readDone(unsigned long v){
    fprintf(stderr, "Core::readDone %lx\n", v);
    exit(0);
  }
  virtual void started(unsigned long words){
    fprintf(stderr, "Core::started: words=%lx\n", words);
  }
  virtual void rData ( unsigned long long v ){
    fprintf(stderr, "rData (%08x): ", rDataCnt++);
    dump("", (char*)&v, sizeof(v));
  }
  virtual void reportStateDbg(unsigned long streamRdCnt, unsigned long dataMismatch){
    fprintf(stderr, "Core::reportStateDbg: streamRdCnt=%08lx dataMismatch=%ld\n", streamRdCnt, dataMismatch);
  }  
public:
  TestCoreIndication()
    : rDataCnt(0){}
};

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);
  device = CoreRequest::createCoreRequest(new TestCoreIndication);
  dma = DMARequest::createDMARequest(new TestDMAIndication);

  fprintf(stderr, "Main::allocating memory...\n");
  dma->alloc(alloc_sz, &srcAlloc);
  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc.header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  unsigned int ref_srcAlloc = dma->reference(&srcAlloc);

  for (int i = 0; i < numWords; i++){
    srcBuffer[i] = srcGen++;
  }
    
  dma->dCacheFlushInval(&srcAlloc, srcBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  // read channel 0 is read source
  dma->configChan(0, 0, ref_srcAlloc, 16);
  sleep(2);

  fprintf(stderr, "Main::starting read %08x\n", numWords);
  device->startRead(numWords);

  //dma->getReadStateDbg();
  device->getStateDbg();
  while(true){sleep(1);}
}
