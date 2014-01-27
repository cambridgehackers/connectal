#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "StdDMAIndication.h"
#include "RingIndicationWrapper.h"
#include "RingRequestProxy.h"
#include "DMARequestProxy.h"
#include "GeneratedTypes.h"



RingRequestProxy *ring = new RingRequestProxy(IfcNames_RingRequest);
DMARequestProxy *dma = new DMARequestProxy(IfcNames_DMARequest);

PortalAlloc *cmdAlloc;
unsigned int *cmdBuffer = 0;
PortalAlloc *statusAlloc;
unsigned int *statusBuffer = 0;
PortalAlloc *scratchAlloc;
unsigned int *scratchBuffer = 0;

size_t cmd_ring_sz 4096;
size_t status_ring_sz 4096;
size_t scratch_sz 1<<20; /* 1 MB */
size_t scratch_words = scratch_sz >> 8;


sem_t conf_sem;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class RingIndication : public RingIndicationWrapper
{
public:
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
  RingIndication(unsigned int id) : RingIndicationWrapper(id){}
};

struct SWRing_struct {
  unsigned int ref;
  void *base;
  void *first;
  size_t size;
};

struct SWRing cmd_ring;
struct SWRing status_ring;

void ring_init(struct SWRing *r, int ringid, unsigned int ref, void * base, size_t size)
{
  r->size = size;
  r->base = base;
  r->first = base;
  r->ref = ref;
  ring->set(ringid, 0, 0);         // bufferbase, relative to base
  ring->set(ringid, 1, size);      // bufferend
  ring->set(ringid, 2, 0);         // bufferfirst
  ring->set(ringid, 3, 0);         // bufferlast 
  ring->set(ringid, 4, size - 1);  // buffermask
  ring->set(ringid, 5, ref);       // memhandle
}

void * ring_next(


int main(int argc, const char **argv)
{
  void *v;
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  if(sem_init(&conf_sem, 1, 0)){
    fprintf(stderr, "failed to init conf_sem\n");
    return -1;
  }

  fprintf(stderr, "allocating memory...\n");
  dma->alloc(cmd_ring_sz, &cmdAlloc);
  dma->alloc(status_ring_sz, &statusAlloc);
  dma->alloc(scratch_ring_sz, &scratchAlloc);

  v = mmap(0, cmd_sz, PROT_READ|PROT_WRITE, MAP_SHARED, cmdAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  cmdBuffer = (unsigned int *) v;

  v = mmap(0, status_sz, PROT_READ|PROT_WRITE, MAP_SHARED, statusAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  statusBuffer = (unsigned int *) = v;
  v = mmap(0, scratch_sz, PROT_READ|PROT_WRITE, MAP_SHARED, scratchAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  scratchBuffer = (unsigned int *) = v;


  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  unsigned int ref_cmdAlloc = dma->reference(cmdAlloc);
  unsigned int ref_statusAlloc = dma->reference(statusAlloc);
  unsigned int ref_scratchAlloc = dma->reference(scratchAlloc);

  for (int i = 0; i < scratch_words; i += 1){
    scratchBuffer[i] = i;
  }
    
  dma->dCacheFlushInval(cmdAlloc, cmdBuffer);
  dma->dCacheFlushInval(statusAlloc, statusBuffer);
  dma->dCacheFlushInval(scratchAlloc, scratchBuffer);

  fprintf(stderr, "flush and invalidate complete\n");
      

  fprintf(stderr, "main about to issue requests\n");

  ring->set(0, 0, 0x1000);
  sem_wait(&conf_sem);
  ring->set(0, 1, 0x1001);
  sem_wait(&conf_sem);
  ring->set(0, 2, 0x1002);
  sem_wait(&conf_sem);
  ring->set(0, 3, 0x1003);
  sem_wait(&conf_sem);
  ring->set(1, 0, 0x1010);
  sem_wait(&conf_sem);
  ring->set(1, 1, 0x1011);
  sem_wait(&conf_sem);
  ring->set(1, 2, 0x1012);
  sem_wait(&conf_sem);
  ring->set(1, 3, 0x1013);
  sem_wait(&conf_sem);
  ring->get(0, 0);
  sem_wait(&conf_sem);
  ring->get(0, 1);
  sem_wait(&conf_sem);
  ring->get(0, 2);
  sem_wait(&conf_sem);
  ring->get(0, 3);
  sem_wait(&conf_sem);
  ring->get(1, 0);
  sem_wait(&conf_sem);
  ring->get(1, 1);
  sem_wait(&conf_sem);
  ring->get(1, 2);
  sem_wait(&conf_sem);
  ring->get(1, 3);
  sem_wait(&conf_sem);



  //  ring->doCommandImmediate(ci);
  fprintf(stderr, "main started dma copy\n");
  sem_wait(&conf_sem);
  
  fprintf(stderr, "main going to sleep\n");
  while(true){sleep(1);}
}
