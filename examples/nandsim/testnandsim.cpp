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

PortalAlloc *srcAlloc;
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

  NandSimIndication(const char* devname, unsigned int addrbits) : NandSimIndicationWrapper(devname,addrbits) {
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
  DmaConfigProxy *dma = 0;
  
  NandSimIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new NandSimRequestProxy("fpga1", 16);
  dma = new DmaConfigProxy("fpga3", 16);

  deviceIndication = new NandSimIndication("fpga2", 16);
  dmaIndication = new DmaIndication(dma, "fpga4", 16);

  fprintf(stderr, "Main::allocating memory...\n");
  dma->alloc(numBytes, &srcAlloc);
  fprintf(stderr, "fd=%d\n", srcAlloc->header.fd);
  srcBuffer = (unsigned int *)mmap(0, numBytes, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
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
    
  dma->dCacheFlushInval(srcAlloc, srcBuffer);
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
