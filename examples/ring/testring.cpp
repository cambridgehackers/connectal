/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/queue.h>
#include <semaphore.h>

#include "StdDmaIndication.h"
#include "RingIndicationWrapper.h"
#include "RingRequestProxy.h"
#include "DmaConfigProxy.h"
#include "GeneratedTypes.h"

RingRequestProxy *ring = 0;
DmaConfigProxy *dma = 0;

PortalAlloc *cmdAlloc;
PortalAlloc *statusAlloc;
PortalAlloc *scratchAlloc;

char *cmdBuffer = 0;
char *statusBuffer = 0;
char *scratchBuffer = 0;

size_t cmd_ring_sz = 8192;
size_t status_ring_sz = 8192;
size_t scratch_sz = 1<<20; /* 1 MB */

#define CMD_NOP 0
#define CMD_COPY 1
#define CMD_ECHO 2
#define CMD_FILL 3

/* The finish function is called with arg and the event */

struct Ring_Completion {
  LIST_ENTRY(Ring_Completion) entries;
  int tag;     /* which completion is this */
  int finished; /* boolean for completed */
  void (*finish)(void *, uint64_t *);
  void *arg;
};

struct Ring_Completion completion[1024];

LIST_HEAD(completionlisthead, Ring_Completion) completionfreelist;

void completion_list_init()
{
  int i;
  LIST_INIT(&completionfreelist);
  for (i = 1; i < 1024; i += 1) 
    {
      completion[i].tag = i;  /* non zero! */
      completion[i].finished = 1;
      completion[i].finish = NULL;
      completion[i].arg = NULL;
      LIST_INSERT_HEAD(&completionfreelist, &completion[i], entries);
    }
}

struct Ring_Completion *get_free_completion()
{
  struct Ring_Completion *p;
  p = LIST_FIRST(&completionfreelist);
  if (p) LIST_REMOVE(p, entries);
  return(p);
}

void Ring_Handle_Completion(uint64_t *event)
{
  struct Ring_Completion *p;
  unsigned tag = event[7] & 0xffff;
  assert(tag < 1024);
  p = &completion[tag];
  assert(p->finished == 0);
  p->finished = 1;
  if (p->finish) (*p->finish)(p->arg, event);
  LIST_INSERT_HEAD(&completionfreelist, p, entries);
}


sem_t conf_sem;

DmaIndication *dmaIndication = 0;

struct SWRing {
  unsigned int ref;
  char *base;
  unsigned first;
  volatile unsigned last;
  size_t size;
  size_t slots;
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
 pthread_mutex_t cmd_lock = PTHREAD_MUTEX_INITIALIZER;

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
    fprintf(stderr, "setResult(cmd %ld regist %ld addr %lx)\n", 
	    cmd, regist, addr);
    sem_post(&conf_sem);
  }
  virtual void getResult(long unsigned int cmd, long unsigned int regist, long unsigned int addr) {
    fprintf(stderr, "getResult(cmd %ld regist %ld addr %lx)\n", 
	    cmd, regist, addr);
    /* returning query about last pointer of cmd ring */
    if ((cmd = cmd_ring.ringid) && (regist == REG_LAST)) {
      cmd_ring.last = addr;
    }
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

uint64_t fetch(uint64_t *p) {
  return (p[0]);
}

void ring_init(struct SWRing *r, int ringid, unsigned int ref, void * base, size_t size)
{
  r->size = size;
  r->slots = r->size / 64;
  r->base = (char *) base;
  r->first = 0;
  r->last = 0;
  r->ref = ref;
  r->cached_space = size - 64;
  r->ringid = ringid;
  ring->set(ringid, REG_BASE, 0);         // bufferbase, relative to base
  sem_wait(&conf_sem);
  ring->set(ringid, REG_END, size);      // bufferend
  sem_wait(&conf_sem);
  ring->set(ringid, REG_FIRST, 0);         // bufferfirst
  sem_wait(&conf_sem);
  ring->set(ringid, REG_LAST, 0);         // bufferlast 
  sem_wait(&conf_sem);
  ring->set(ringid, REG_MASK, size - 1);  // buffermask
  sem_wait(&conf_sem);
  ring->set(ringid, REG_HANDLE, ref);       // memhandle
  sem_wait(&conf_sem);
}

uint64_t *ring_next(struct SWRing *r)
{
  volatile uint64_t *p = (uint64_t *) (r->base + (long) r->last);
  if (p[7] == 0) return (NULL);
  return ((uint64_t *) p);
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

/* XXX this isn't right, I think the SWRing* has to be volatile, so that
 * the compiler will know to refetch
 */

void ring_send(struct SWRing *r, uint64_t *cmd, void (*fp)(void *, uint64_t *), void *arg)
{
  unsigned next_first;
  struct Ring_Completion *p;
  pthread_mutex_lock(&cmd_lock);
  assert(r->first < r->size);
  /* send an inquiry every 1/4 way around the ring */
  if ((r->cached_space % (r->size >> 2)) == 0) {
    ring->get(r->ringid, REG_LAST);         // bufferlast 
    while (r->cached_space == 0) {
      pthread_mutex_unlock(&cmd_lock);
      r->cached_space = ((r->size + r->last - r->first - 64) % r->size);
      pthread_mutex_lock(&cmd_lock);
    }
  }
  p = get_free_completion();
  p->finish = fp;
  p->arg = arg;
  assert (p != NULL);
  cmd[7] = p->tag;
  memcpy(&r->base[r->first], cmd, 64);
  next_first = r->first + 64;
  if (next_first == r->size) next_first = 0;
  r->first = next_first;
  r->cached_space -= 64;
  ring->set(r->ringid, REG_FIRST, r->first);         // bufferfirst
  pthread_mutex_unlock(&cmd_lock);
  sem_wait(&conf_sem);
}

void *statusThreadProc(void *arg)
{
  int i;
  uint64_t *msg;
  printf("Status thread running\n");
  for (;;) {
    while ((msg = ring_next(&status_ring)) == NULL);
    printf("Received %lx %lx\n", (long) msg[0], (long) msg[7]);
    Ring_Handle_Completion((uint64_t *) msg);
    ring_pop(&status_ring);
  }
}

void sem_finish(void *arg, uint64_t *event)
{
  sem_t *p = (sem_t *) arg;
  sem_post(p);
}


void hw_copy(void *from, void *to, unsigned count)
{
  uint64_t tcmd[8];
  sem_t my_sem;
  assert(sem_init(&my_sem, 1, 0) == 0);
  tcmd[0] = ((uint64_t) CMD_COPY) << 56;
  tcmd[1] = (uint64_t) from;
  tcmd[2] = (uint64_t) to;
  tcmd[3] = count; // byte count
  ring_send(&cmd_ring, tcmd, sem_finish, &my_sem);
  sem_wait(&my_sem);
  sem_destroy(&my_sem);
}

struct CompletionEvent {
  uint64_t event[8];
  sem_t sem;
};


void echo_finish(void *arg, uint64_t *event)
{
  struct CompletionEvent *p = (struct CompletionEvent *) arg;
  assert(p != NULL);
  memcpy(&p->event, event, 8 * sizeof(uint64_t));
  sem_post(&p->sem);
}


void hw_echo(long unsigned a, long unsigned b)
{
  struct CompletionEvent myevent;
  uint64_t tcmd[8];
  sem_init(&myevent.sem, 1, 0);
  tcmd[0] = ((uint64_t) CMD_ECHO) << 56;
  tcmd[1] = (uint64_t) a;
  tcmd[2] = (uint64_t) b;
  ring_send(&cmd_ring, tcmd, echo_finish, &myevent);
  sem_wait(&myevent.sem);
  if ((myevent.event[1] != a) || (myevent.event[2] != b)) {
    printf("echo failed a=%lx b= %lx got %lx %lx\n",
	   a, b, myevent.event[1], myevent.event[2]);
  }
  sem_destroy(&myevent.sem);
  
}

void hw_nop()
{
  uint64_t tcmd[8];
  tcmd[0] = ((uint64_t) CMD_NOP) << 56;
  tcmd[1] = (uint64_t) 17;
  tcmd[2] = (uint64_t) 34;
  ring_send(&cmd_ring, tcmd, NULL, NULL);
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
  dma = new DmaConfigProxy(IfcNames_DmaRequest);
  dmaIndication = new DmaIndication(IfcNames_DmaIndication);
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

  /*   dma->dCacheFlushInval(cmdAlloc, cmdBuffer);
  dma->dCacheFlushInval(statusAlloc, statusBuffer);
  dma->dCacheFlushInval(scratchAlloc, scratchBuffer);
  */

  fprintf(stderr, "flush and invalidate complete\n");
  ring_init(&cmd_ring, 0, ref_cmdAlloc, cmdBuffer, cmd_ring_sz);
  ring_init(&status_ring, 1, ref_statusAlloc, statusBuffer, status_ring_sz);

  pthread_t ltid;
  fprintf(stderr, "creating status thread\n");
  if(pthread_create(&ltid, NULL,  statusThreadProc, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }
  ring->hwenable(1);  /* turn on engines */
  fprintf(stderr, "main about to issue requests\n");

  for (i = 0; i < 256; i += 1) {
    scratchBuffer[i] = i;
   }
  for (i = 0; i < 10; i += 1) {
    uint64_t ul1;
    uint64_t ul2;
    hw_copy((void *) ((((uint64_t) ref_scratchAlloc) << 32) | (256 * i)),
		      (void *) ((((uint64_t) ref_scratchAlloc) << 32) | (256 * (i + 1))),
	    0x100);
    ul1 = (0x111L << 32) + (long) i;
    ul2 = (0x222L << 32) + (long) i;
    hw_echo(ul1, ul2);
  }
  sleep(1);
  for (i = 0; i < 10; i += 1) {
    if (scratchBuffer[i + 2560] != i) {
      printf("loc %d got %d should be %d\n",
	     i + 2560, scratchBuffer[i + 2560], i);
    }
  }
  
  fprintf(stderr, "main going to sleep\n");
  while(true){sleep(1);}
}
