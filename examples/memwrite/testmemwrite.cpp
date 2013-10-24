#include "Memwrite.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

CoreRequest *device = 0;
DMARequest *dma = 0;
PortalAlloc dstAlloc;
unsigned int *dstBuffer = 0;

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
    fprintf(stderr, "DMA::reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void configResp(unsigned long channelId){
    fprintf(stderr, "DMA::configResp: %x\n", channelId);
  }
  virtual void sglistResp(unsigned long channelId){
    fprintf(stderr, "DMA::sglistResp: %x\n", channelId);
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
    fprintf(stderr, "Core::writeDone (%08x): ", srcGen);
    unsigned int sg = 0;
    bool mismatch = false;
    for (int i = 0; i < numWords; i++){
      mismatch |= (dstBuffer[i] != sg++);
    }
    fprintf(stderr, "Core::writeDone mismatch=%d\n", mismatch);
    
  }
  virtual void reportStateDbg(unsigned long streamWrCnt, unsigned long srcGen){
    fprintf(stderr, "Core::reportStateDbg: streamWrCnt=%08x srcGen=%d\n", streamWrCnt, srcGen);
  }  
};

int main(int argc, const char **argv)
{
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);
  device = CoreRequest::createCoreRequest(new TestCoreIndication);
  dma = DMARequest::createDMARequest(new TestDMAIndication);

  fprintf(stderr, "Main::allocating memory...\n");
  dma->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc.fd, 0);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thwrite\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thwrite\n");
   exit(1);
  }

  unsigned int ref_dstAlloc = dma->reference(&dstAlloc);

  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = 0xDEADBEEF;
  }
    
  dma->dCacheFlushInval(&dstAlloc);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  // write channel 0 is write source
  dma->configWriteChan(0, ref_dstAlloc, 16);
  sleep(2);

  fprintf(stderr, "Main::starting write %08x\n", numWords);
  device->startWrite(numWords);

  while(1){
    //dma->getWriteStateDbg();
    device->getStateDbg();
    sleep(1);
  }
}
