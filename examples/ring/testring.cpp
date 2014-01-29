#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "StdDMAIndication.h"
#include "RingIndicationWrapper.h"
#include "RingRequestProxy.h"
#include "DMARequestProxy.h"
#include "GeneratedTypes.h"



RingRequestProxy *ring = 0;new RingRequestProxy(IfcNames_RingRequest);
DMARequestProxy *dma = 0; new DMARequestProxy(IfcNames_DMARequest);

PortalAlloc *cmdAlloc;
PortalAlloc *statusAlloc;
PortalAlloc *scratchAlloc;

char *cmdBuffer = 0;
char *statusBuffer = 0;
char *scratchBuffer = 0;

size_t cmd_ring_sz = 4096;
size_t status_ring_sz = 4096;
size_t scratch_sz = 1<<20; /* 1 MB */

#define CMD_NOP 0
#define CMD_COPY 1
#define CMD_ECHO 2

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
  virtual void setResult(long unsigned int cmd, long unsigned int regist, long unsigned int addr) {
    fprintf(stderr, "setResult(cmd %ld regist %ld addr %llx)\n", 
	    cmd, regist, addr);
    sem_post(&conf_sem);
  }
  virtual void getResult(long unsigned int cmd, long unsigned int regist, long unsigned int addr) {
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

RingIndication *ringIndication = 0;
DMAIndication *dmaIndication = 0;

struct SWRing {
  unsigned int ref;
  char *base;
  unsigned first;
  unsigned last;
  size_t size;
  unsigned cached_space;
  int ringid;
};

/* accessors for get and set calls */
#define REG_BASE 0
#define REG_END 1
#define REG_FIRST 2
#define REG_LAST 3
#define REG_MASK 4
#define REG_HANDLE 5

struct SWRing cmd_ring;
struct SWRing status_ring;

void ring_init(struct SWRing *r, int ringid, unsigned int ref, void * base, size_t size)
{
  r->size = size;
  r->base = (char *) base;
  r->first = 0;
  r->last = 0;
  r->ref = ref;
  r->cached_space = size - 64;
  r->ringid = ringid;
  ring->set(ringid, REG_BASE, 0);         // bufferbase, relative to base
  ring->set(ringid, REG_END, size);      // bufferend
  ring->set(ringid, REG_FIRST, 0);         // bufferfirst
  ring->set(ringid, REG_LAST, 0);         // bufferlast 
  ring->set(ringid, REG_MASK, size - 1);  // buffermask
  ring->set(ringid, REG_HANDLE, ref);       // memhandle
}

uint64_t *ring_next(struct SWRing *r)
{
  uint64_t *p = (uint64_t *) (r->base + r->last);
  if (p[7] == 0) return (0);
  return (p);
}

void ring_pop(struct SWRing *r)
{
  uint64_t *p = (uint64_t *) r->base;
  unsigned last = r->last;
  p = (uint64_t *) ((char *) p + last);
  p[7] = 0;
  /* wmb */
  last += 64;
  if (last >= r->size) last  = 0;
  r->last = last;
}

unsigned ring_estimated_space_left(struct SWRing *r)
{
  return(r->cached_space);
}

void update_space_cache(struct SWRing *r)
{
}

void ring_send(struct SWRing *r, uint64_t *cmd)
{
  unsigned next_first;
  assert(ring_estimated_space_left(r) > 0);
  assert(r->first < r->size);
  next_first = r->first + 64;
  if (next_first == r->size) next_first = 0;
  r->first = next_first;
  r->cached_space -= 64;
}

int main(int argc, const char **argv)
{
  void *v;
  int i;
  uint64_t tcmd[8];

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  if(sem_init(&conf_sem, 1, 0)){
    fprintf(stderr, "failed to init conf_sem\n");
    return -1;
  }

  ring = new RingRequestProxy(IfcNames_RingRequest);
  dma = new DMARequestProxy(IfcNames_DMARequest);
  dmaIndication = new DMAIndication(IfcNames_DMAIndication);
  ringIndication = new RingIndication(IfcNames_RingIndication);

  fprintf(stderr, "allocating memory...\n");
  dma->alloc(cmd_ring_sz, &cmdAlloc);
  dma->alloc(status_ring_sz, &statusAlloc);
  dma->alloc(scratch_sz, &scratchAlloc);

  v = mmap(0, cmd_ring_sz, PROT_READ|PROT_WRITE, MAP_SHARED, cmdAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  cmdBuffer = (char *) v;

  v = mmap(0, status_ring_sz, PROT_READ|PROT_WRITE, MAP_SHARED, statusAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  statusBuffer = (char *) v;
  v = mmap(0, scratch_sz, PROT_READ|PROT_WRITE, MAP_SHARED, scratchAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  scratchBuffer = (char *) v;


  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  unsigned int ref_cmdAlloc = dma->reference(cmdAlloc);
  unsigned int ref_statusAlloc = dma->reference(statusAlloc);
  unsigned int ref_scratchAlloc = dma->reference(scratchAlloc);

  dma->dCacheFlushInval(cmdAlloc, cmdBuffer);
  dma->dCacheFlushInval(statusAlloc, statusBuffer);
  dma->dCacheFlushInval(scratchAlloc, scratchBuffer);


  fprintf(stderr, "flush and invalidate complete\n");
  ring_init(&cmd_ring, 0, ref_cmdAlloc, cmdBuffer, cmd_ring_sz);
  ring_init(&status_ring, 1, ref_statusAlloc, statusBuffer, status_ring_sz);

  fprintf(stderr, "main about to issue requests\n");

  for (i = 0; i < 256; i += 1) {
    scratchBuffer[i] = i;
   }
  for (i = 0; i < 10; i += 1) {
    tcmd[0] = ((unsigned long) CMD_NOP) << 56;
    ring_send(&cmd_ring, tcmd);
    tcmd[0] = ((unsigned long) CMD_COPY) << 56;
    tcmd[0] |= 0x2000 + i; // tag
    tcmd[1] = (((long unsigned) ref_scratchAlloc) << 32)
      | (256 * i);
    tcmd[2] = (((long unsigned) ref_scratchAlloc) << 32)
      | (256 * (i + 1));
    tcmd[3] = 256; // byte count
    ring_send(&cmd_ring, tcmd);
    tcmd[0] = ((unsigned long) CMD_ECHO) << 56;
    tcmd[7] = tcmd[0] + i;
    ring_send(&cmd_ring, tcmd);
  }
  sleep(1);
  for (i = 0; i < 256; i += 1) {
    if (scratchBuffer[i + 2560] != i) {
      printf("loc %d got %d should be %d\n",
	     i + 2560, scratchBuffer[i + 2560], i);
    }
  }


  
  fprintf(stderr, "main going to sleep\n");
  while(true){sleep(1);}
}
