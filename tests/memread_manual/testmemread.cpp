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
#include "MemreadRequestProxy.h"
#include "MemreadIndicationWrapper.h"

sem_t test_sem;

int burstLen = 16;

int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

void dump(const char *prefix, char *buf, size_t len)
{
    printf( "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	printf( "%02x", (unsigned char)buf[i]);
    printf( "\n");
}

class MemreadIndication : public MemreadIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(uint32_t v){
    printf( "Memread::readDone(mismatch = %x)\n", v);
    sem_post(&test_sem);
  }
  virtual void started(uint32_t words){
    printf( "Memread::started(%x)\n", words);
  }
  virtual void rData ( uint64_t v ){
    printf( "rData(%08x): ", rDataCnt++);
    dump("", (char*)&v, sizeof(v));
  }
  virtual void reportStateDbg(uint32_t streamRdCnt, uint32_t dataMismatch){
    printf( "Memread::reportStateDbg(%08x, %d)\n", streamRdCnt, dataMismatch);
  }  
  MemreadIndication(int id) : MemreadIndicationWrapper(id){}
};

int main(int argc, const char **argv)
{
  PortalAlloc *srcAlloc;
  unsigned int *srcBuffer = 0;
  MemreadRequestProxy *device = 0;
  DmaConfigProxy *dma = 0;
  MemreadIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  printf( "Main::%s %s\n", __DATE__, __TIME__);

  device = new MemreadRequestProxy(IfcNames_MemreadRequest);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);
  deviceIndication = new MemreadIndication(IfcNames_MemreadIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  printf( "Main::allocating memory...\n");
  dma->alloc(alloc_sz, &srcAlloc);
  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);

  pthread_t tid;
  printf( "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   printf( "error creating exec thread\n");
   exit(1);
  }
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;
  dma->dCacheFlushInval(srcAlloc, srcBuffer);
  printf( "Main::flush and invalidate complete\n");
  device->getStateDbg();
  printf( "Main::after getStateDbg\n");
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  printf( "ref_srcAlloc=%d\n", ref_srcAlloc);
  printf( "Main::starting read %08x\n", numWords);
  device->startRead(ref_srcAlloc, numWords, burstLen, 1);
  sem_wait(&test_sem);
  return 0;
}
