
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <semaphore.h>
#include <sys/mman.h>


#include "StdDmaIndication.h"
#include "DmaConfigProxy.h"
#include "PcieTestBenchIndicationWrapper.h"
#include "PcieTestBenchRequestProxy.h"
#include "GeneratedTypes.h"


sem_t test_sem;
int numWords = 0x12400/4;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
int burstLen = 16;


class PcieTestBenchIndication : public PcieTestBenchIndicationWrapper
{  
public:
  PcieTestBenchRequestProxy *device;
  virtual void finished(uint32_t v){
    fprintf(stderr, "finished(%x)\n", v);
    sem_post(&test_sem);
  }
  virtual void started(uint32_t words){
    fprintf(stderr, "started(%x)\n", words);
  }
  void tlpout(const TLPData16 &tlp) {
    fprintf(stderr, "Received tlp: %08x%08x%08x%08x\n", tlp.data3, tlp.data2, tlp.data1, tlp.data0);
    TLPData16 resp;
    device->tlpin(resp);
  }
  PcieTestBenchIndication(PcieTestBenchRequestProxy *device, unsigned int id) : PcieTestBenchIndicationWrapper(id), device(device){}
};



int main(int argc, const char **argv)
{
  PcieTestBenchRequestProxy *device = new PcieTestBenchRequestProxy(IfcNames_PcieTestBenchRequest);
  PcieTestBenchIndication *deviceIndication = new PcieTestBenchIndication(device, IfcNames_PcieTestBenchIndication);

  DmaConfigProxy *dma = new DmaConfigProxy(IfcNames_DmaConfig);
  DmaIndication *dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  PortalAlloc *srcAlloc;
  unsigned int *srcBuffer = 0;

  dma->alloc(alloc_sz, &srcAlloc);
  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  dma->dCacheFlushInval(srcAlloc, srcBuffer);
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);

  device->startRead(ref_srcAlloc, numWords, burstLen);
  sem_wait(&test_sem);
}
