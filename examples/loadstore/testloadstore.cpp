#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>

#include "GeneratedTypes.h"
#include "LoadStoreIndicationWrapper.h"
#include "LoadStoreRequestProxy.h"
#include "DMAIndicationWrapper.h"
#include "DMARequestProxy.h"

PortalAlloc *srcAlloc;
unsigned int *srcBuffer = 0;
size_t alloc_sz = 8192;

class DMAIndication : public DMAIndicationWrapper
{

public:
  DMAIndication(const char* devname, unsigned int addrbits) : DMAIndicationWrapper(devname,addrbits){}

  virtual void reportStateDbg(const DmaDbgRec& rec){
    fprintf(stderr, "reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void configResp(unsigned long channelId){
    fprintf(stderr, "configResp: %lx\n", channelId);
  }
  virtual void sglistResp(unsigned long channelId){
    fprintf(stderr, "sglistResp: %lx\n", channelId);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "parefResp: %lx\n", channelId);
  }
};

class LoadStoreIndication : public LoadStoreIndicationWrapper
{
public:
  virtual void loadValue ( const unsigned long long value ) {
    fprintf(stderr, "loadValue value=%lx, loading %lx\n", value, srcAlloc->entries[0].dma_address);
  }
  LoadStoreIndication(const char* devname, unsigned int addrbits) : LoadStoreIndicationWrapper(name,addrbits){}
};

LoadStoreRequestProxy *loadStoreRequestProxy = 0;
LoadStoreIndication *loadStoreIndication = 0;
DMARequestProxy *dma = 0;
DMAIndication *dmaIndication = 0;

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  loadStoreRequestProxy = new LoadStoreRequestProxy("fpga2", 16);
  loadStoreIndication = new LoadStoreIndication("fpga1", 16);

  dma = new DMARequestProxy("fpga5", 16);
  dmaIndication = new DMAIndication("fpga6", 16);

  fprintf(stderr, "allocating memory...\n");

  int rc = dma->alloc(alloc_sz, &srcAlloc);
  fprintf(stderr, "alloc rc=%d fd=%d dma_address=%08lx\n", rc, srcAlloc->header.fd, srcAlloc->entries[0].dma_address);

  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
  fprintf(stderr, "srcBuffer=%p\n", srcBuffer);
  *srcBuffer = 0x69abba72;
  rc = dma->dCacheFlushInval(srcAlloc, srcBuffer);

  fprintf(stderr, "cache flushed rc=%d\n", rc);
  loadStoreRequestProxy->load(srcAlloc->entries[0].dma_address, 4);
  loadStoreRequestProxy->load(srcAlloc->entries[0].dma_address, 1);
  portalExec(0);
}
