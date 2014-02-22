#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>
#include "StdDmaIndication.h"

#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "MempokeIndicationWrapper.h"
#include "MempokeRequestProxy.h"

int numWords = 16 << 3;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
sem_t done_sem;


class MempokeIndication : public MempokeIndicationWrapper
{
public:
  MempokeIndication(int id) : MempokeIndicationWrapper(id){}

  virtual void readWordResult (const S0 &s){
    fprintf(stderr, "readWordResult(S0{a:%d,b:%d})\n", s.a, s.b);
    sem_post(&done_sem);    
  }
  virtual void writeWordResult (const S0 &s){
    fprintf(stderr, "writeWordResult(S0{a:%d,b:%d})\n", s.a, s.b);
    sem_post(&done_sem);    
  }
};

int main(int argc, const char **argv)
{
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  MempokeRequestProxy *device = 0;
  DmaConfigProxy *dma = 0;
  
  MempokeIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  PortalAlloc *dstAlloc;
  unsigned int *dstBuffer = 0;

  if(sem_init(&done_sem, 1, 0)){
    fprintf(stderr, "failed to init done_sem\n");
    exit(1);
  }

  device = new MempokeRequestProxy(IfcNames_MempokeRequest);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);

  deviceIndication = new MempokeIndication(IfcNames_MempokeIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  fprintf(stderr, "allocating memory...\n");
  dma->alloc(alloc_sz, &dstAlloc);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc->header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = i;
  }
    
  dma->dCacheFlushInval(dstAlloc, dstBuffer);
  fprintf(stderr, "flush and invalidate complete\n");
  fprintf(stderr, "main about to issue requests\n");

  device->readWord(ref_dstAlloc, 5*8);
  sem_wait(&done_sem);
  S0 s = {3,4};
  device->writeWord(ref_dstAlloc, 6*8, s);
  sem_wait(&done_sem);
  device->readWord(ref_dstAlloc, 6*8);
  sem_wait(&done_sem);
  return 0;
}
