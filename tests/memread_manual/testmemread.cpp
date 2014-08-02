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
  MemreadIndication(int id) : MemreadIndicationWrapper(id){}
};

int main(int argc, const char **argv)
{
  MemreadRequestProxy *device = new MemreadRequestProxy(IfcNames_MemreadRequest);
  DmaConfigProxy *dmap = new DmaConfigProxy(IfcNames_DmaConfig);
  DmaManager *dma = new DmaManager(dmap);
  MemreadIndication *deviceIndication = new MemreadIndication(IfcNames_MemreadIndication);
  DmaIndication *dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  int srcAlloc;
  srcAlloc = DmaManager_alloc(alloc_sz);
  unsigned int *srcBuffer = (unsigned int *)DmaManager_mmap(srcAlloc, alloc_sz);

  pthread_t tid;
  printf( "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   printf( "error creating exec thread\n");
   exit(1);
  }
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;
  portalDCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  printf( "Main::starting read %08x\n", numWords);
  device->startRead(ref_srcAlloc, numWords, burstLen, 1);
  sem_wait(&test_sem);
  return 0;
}
