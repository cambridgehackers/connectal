#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include "StdDmaIndication.h"

#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "NandSimIndicationWrapper.h"
#include "NandSimRequestProxy.h"

int srcAlloc;
unsigned int *srcBuffer = 0;
size_t numBytes = 1 << 12;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class NandSimIndication : public NandSimIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(uint32_t v){
    fprintf(stderr, "NandSim::readDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void writeDone(uint32_t v){
    fprintf(stderr, "NandSim::writeDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void eraseDone(uint32_t v){
    fprintf(stderr, "NandSim::eraseDone v=%x\n", v);
    sem_post(&sem);
  }

  NandSimIndication(int id) : NandSimIndicationWrapper(id) {
    sem_init(&sem, 0, 0);
  }
  void wait() {
    sem_wait(&sem);
  }
private:
  sem_t sem;

};

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  NandSimRequestProxy *device = 0;
  DmaConfigProxy *dmap = 0;
  
  NandSimIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new NandSimRequestProxy(IfcNames_NandSimRequest);
  dmap = new DmaConfigProxy(IfcNames_DmaConfig);
  DmaManager *dma = new DmaManager(dmap);

  deviceIndication = new NandSimIndication(IfcNames_NandSimIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  fprintf(stderr, "Main::allocating memory...\n");
  srcAlloc = DmaManager_alloc(numBytes);
  fprintf(stderr, "fd=%d\n", srcAlloc);
  srcBuffer = (unsigned int *)DmaManager_mmap(srcAlloc, numBytes);
  fprintf(stderr, "srcBuffer=%p\n", srcBuffer);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  for (int i = 0; i < numBytes/sizeof(srcBuffer[0]); i++){
    srcBuffer[i] = srcGen++;
  }
    
  dmap->dCacheFlushInval(srcAlloc, numBytes, srcBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");
  sleep(1);

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);

  fprintf(stderr, "Main::starting write %08zx\n", numBytes);
  device->startWrite(ref_srcAlloc, 0, 0, numBytes, 1);
  deviceIndication->wait();

  fprintf(stderr, "Main::starting read %08zx\n", numBytes);
  device->startRead(ref_srcAlloc, 0, 0, numBytes, 1);
  deviceIndication->wait();

  fprintf(stderr, "Main::starting erase %08zx\n", numBytes);
  device->startErase(0, numBytes);
  deviceIndication->wait();

  fprintf(stderr, "Main::starting read %08zx\n", numBytes);
  device->startRead(ref_srcAlloc, 0, 0, numBytes, 1);
  deviceIndication->wait();

  exit(0);
}
