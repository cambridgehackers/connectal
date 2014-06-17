#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include "StdDmaIndication.h"
#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "FMComms1RequestProxy.h"
#include "FMComms1IndicationWrapper.h"

sem_t read_sem;
sem_t write_sem;

int readBurstLen = 16;
int writeBurstLen = 16;


#ifdef MMAP_HW
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
#else
int numWords = 0x124000/4;
#endif

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

class FMComms1Indication : public FMComms1IndicationWrapper
{

public:
  FMComms1Indication(unsigned int id) : FMComm1IndicationWrapper(id){}

  virtual void readStatus(unsigned iterCount, unsigned running){
    fprintf(stderr, "read %d %d\n", iterCount, running);
    sem_post(&read_sem);
  }
  virtual void writeStatus(unsigned iterCount, unsigned running){
    fprintf(stderr, "write %d %d\n", iterCount, running);
    sem_post(&write_sem);
  }
};

int main(int argc, const char **argv)
{
  PortalAlloc *srcAlloc;
  PortalAlloc *dstAlloc;
  unsigned int *srcBuffer = 0;
  unsigned int *dstBuffer = 0;

  MemreadRequestProxy *device = 0;
  DmaConfigProxy *dma = 0;
  
  MemreadIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new FMComms1RequestProxy(IfcNames_FMComms1Request);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);

  deviceIndication = new FMComms1Indication(IfcNames_FMComms1Indication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  fprintf(stderr, "Main::allocating memory...\n");
  dma->alloc(alloc_sz, &srcAlloc);

  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
  dma->alloc(alloc_sz, &dstAlloc);

  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc->header.fd, 0);


  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

    
  dma->dCacheFlushInval(srcAlloc, srcBuffer);
  dma->dCacheFlushInval(dstAlloc, dstBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");


  device->getReadStatus();
  device->getWriteStatus();
  sem_wait(&read_sem);
  sem_wait(&write_sem);
  fprintf(stderr, "Main::after getStateDbg\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  fprintf(stderr, "ref_dstAlloc=%d\n", ref_dstAlloc);

  fprintf(stderr, "Main::starting read %08x\n", numWords);

  device->startRead(ref_srcAlloc, numWords, burstLen, 1);
  device->startWrite(ref_dstAlloc, numWords, burstLen, 1);
  sem_wait(&read_sem);



   sleep(5);
  device->getReadStatus();
  device->getWriteStatus();
  sem_wait(&read_sem);
  sem_wait(&write_sem);
   sleep(5);
  fprintf(stderr, "Main::stopping reads\n");
  fprintf(stderr, "Main::stopping writes\n");
  device->startRead(ref_srcAlloc, numWords, burstLen, 0);
  device->startWrite(ref_dstAlloc, numWords, burstLen, 0);
  sem_wait(&read_sem);
  sem_wait(&write_sem);

  exit(0);
}
