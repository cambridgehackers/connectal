#include "Ring.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>

CoreRequest *device = 0;
DMARequest *dma = 0;
PortalAlloc *dstAlloc;
unsigned int *dstBuffer = 0;
int numWords = 16 << 3;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
sem_t conf_sem;

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
    fprintf(stderr, "reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void configResp(unsigned long channelId){
    fprintf(stderr, "configResp: %lx\n", channelId);
    sem_post(&conf_sem);
  }
  virtual void sglistResp(unsigned long channelId){
    fprintf(stderr, "sglistResp: %lx\n", channelId);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "parefResp: %lx\n", channelId);
  }
};

class TestCoreIndication : public CoreIndication
{
  virtual void readWordResult (unsigned long long s){
    fprintf(stderr, "readWordResult(%llx)\n", s);
    sem_post(&conf_sem);
  }
  virtual void writeWordResult (unsigned long long s){
    fprintf(stderr, "writeWordResult(%llx)\n", s);
    sem_post(&conf_sem);
  }
  virtual void setResult(unsigned long cmd, unsigned long regist, unsigned long long addr) {
    fprintf(stderr, "setResult(cmd %ld regist %ld addr %llx)\n", 
	    cmd, regist, addr);
    sem_post(&conf_sem);
  }
  virtual void getResult(unsigned long cmd, unsigned long regist, unsigned long long addr) {
    fprintf(stderr, "getResult(cmd %ld regist %ld addr %llx)\n", 
	    cmd, regist, addr);
    sem_post(&conf_sem);
  }
  virtual void completion(unsigned long cmd, unsigned long token) {
    fprintf(stderr, "getResult(cmd %ld token %lx)\n", 
	    cmd, token);
    sem_post(&conf_sem);
  }
};


int main(int argc, const char **argv)
{
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = CoreRequest::createCoreRequest(new TestCoreIndication);
  dma = DMARequest::createDMARequest(new TestDMAIndication);

  if(sem_init(&conf_sem, 1, 0)){
    fprintf(stderr, "failed to init conf_sem\n");
    return -1;
  }

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
      
  dma->configChan(1, 0, ref_dstAlloc, 2);
  sem_wait(&conf_sem);
  
  dma->configChan(0, 0, ref_dstAlloc, 2);
  sem_wait(&conf_sem);

  dma->configChan(1, 2, ref_dstAlloc, 2);
  sem_wait(&conf_sem);
  
  dma->configChan(0, 2, ref_dstAlloc, 2);
  sem_wait(&conf_sem);

  fprintf(stderr, "main about to issue requests\n");
  device->set(0, 0, 0x1000);
  sem_wait(&conf_sem);
  device->set(0, 1, 0x1001);
  sem_wait(&conf_sem);
  device->set(0, 2, 0x1002);
  sem_wait(&conf_sem);
  device->set(0, 3, 0x1003);
  sem_wait(&conf_sem);
  device->set(1, 0, 0x1010);
  sem_wait(&conf_sem);
  device->set(1, 1, 0x1011);
  sem_wait(&conf_sem);
  device->set(1, 2, 0x1012);
  sem_wait(&conf_sem);
  device->set(1, 3, 0x1013);
  sem_wait(&conf_sem);
  device->get(0, 0);
  sem_wait(&conf_sem);
  device->get(0, 1);
  sem_wait(&conf_sem);
  device->get(0, 2);
  sem_wait(&conf_sem);
  device->get(0, 3);
  sem_wait(&conf_sem);
  device->get(1, 0);
  sem_wait(&conf_sem);
  device->get(1, 1);
  sem_wait(&conf_sem);
  device->get(1, 2);
  sem_wait(&conf_sem);
  device->get(1, 3);
  sem_wait(&conf_sem);

  device->readWord(5*8);
  sem_wait(&conf_sem);
  unsigned long long s = 0x123456789abcdef;
  device->writeWord(6*8,s);
  sem_wait(&conf_sem);
  device->readWord(6*8);
  sem_wait(&conf_sem);

  CommandStruct ci = { 1, 0x12345, 0x100, 0x200, 0x20 };
  device->doCommandImmediate(ci);
  fprintf(stderr, "main started dma copy\n");
  sem_wait(&conf_sem);
  
  fprintf(stderr, "main going to sleep\n");
  while(true){sleep(1);}
}
