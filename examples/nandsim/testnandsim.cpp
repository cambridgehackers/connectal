#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include "StdDMAIndication.h"

#include "DMARequestProxy.h"
#include "GeneratedTypes.h" 
#include "NandSimIndicationWrapper.h"
#include "NandSimRequestProxy.h"

PortalAlloc *srcAlloc;
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

class NandSimIndication : public NandSimIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(unsigned long v){
    fprintf(stderr, "NandSim::readDone v=%lx\n", v);
    sem_post(&sem);
  }
  virtual void writeDone(unsigned long v){
    fprintf(stderr, "NandSim::writeDone v=%lx\n", v);
    sem_post(&sem);
  }
  virtual void eraseDone(unsigned long v){
    fprintf(stderr, "NandSim::eraseDone v=%lx\n", v);
    sem_post(&sem);
  }

  NandSimIndication(const char* devname, unsigned int addrbits) : NandSimIndicationWrapper(devname,addrbits) {
    sem_init(&sem, 1, 0);
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
  DMARequestProxy *dma = 0;
  
  NandSimIndication *deviceIndication = 0;
  DMAIndication *dmaIndication = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new NandSimRequestProxy("fpga1", 16);
  dma = new DMARequestProxy("fpga3", 16);

  deviceIndication = new NandSimIndication("fpga2", 16);
  dmaIndication = new DMAIndication(dma, "fpga4", 16);

  fprintf(stderr, "Main::allocating memory...\n");
  dma->alloc(alloc_sz, &srcAlloc);
  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  for (int i = 0; i < numWords; i++){
    srcBuffer[i] = srcGen++;
  }
    
  dma->dCacheFlushInval(srcAlloc, srcBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");
  sleep(1);

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);
  sleep(1);

  for (int i = 0; i < 12; i++) {
    dma->readSglist(ChannelType_Read, ref_srcAlloc, i*0x1000);
    sleep(1);
  }
  fprintf(stderr, "Main::starting write %08x\n", numWords);
  device->startWrite(ref_srcAlloc, 0, 0, 32, 1);
  deviceIndication->wait();

  fprintf(stderr, "Main::starting read %08x\n", numWords);
  device->startRead(ref_srcAlloc, 0, 0, 32, 1);
  deviceIndication->wait();

  exit(0);
}
