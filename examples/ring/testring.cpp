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
#include <assert.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/queue.h>
#include <sys/time.h>

#include "StdDmaIndication.h"
#include "RingIndication.h"
#include "RingRequest.h"
#include "MemServerRequest.h"
#include "MMURequest.h"

RingRequestProxy *ring = 0;
MMURequestProxy *dmap = 0;

int cmdAlloc;
int statusAlloc;
int scratchAlloc;

char *cmdBuffer = 0;
char *statusBuffer = 0;
char *scratchBuffer = 0;

unsigned int cmdPointer;
unsigned int statusPointer;
unsigned int scratchPointer;

size_t cmd_ring_sz = 8192;
size_t status_ring_sz = 8192;
size_t scratch_sz = 1<<20; /* 1 MB */

int ring_init_done = 0;

#define CMD_NOP 0
#define CMD_COPY 1
#define CMD_ECHO 2
#define CMD_FILL 3

extern void StatusPoll(void);  // forward

/* The finish function is called with arg and the event */

struct Ring_Completion {
  STAILQ_ENTRY(Ring_Completion) entries;
  int tag;     /* which completion is this */
  int in_use; /* boolean for completed */
  void (*finish)(void *, uint64_t *);
  void *arg;
};

struct Ring_Completion completion[1024];

STAILQ_HEAD(completionlisthead, Ring_Completion) completionfreelist;

char setresult_flag = 0;
char getresult_flag = 0;

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
#define REG_LASTFETCH 3
#define REG_MASK 4
#define REG_HANDLE 5
#define REG_LASTACK 6

struct SWRing cmd_ring;
struct SWRing status_ring;

void completion_list_init()
{
  int i;
  STAILQ_INIT(&completionfreelist);
  for (i = 1; i < 1024; i += 1) 
    {
      completion[i].tag = i;  /* non zero! */
      completion[i].in_use = 0;
      completion[i].finish = NULL;
      completion[i].arg = NULL;
      STAILQ_INSERT_TAIL(&completionfreelist, &completion[i], entries);
    }
}

struct Ring_Completion *get_free_completion()
{
  struct Ring_Completion *p;
  if STAILQ_EMPTY(&completionfreelist) return(NULL);
  p = STAILQ_FIRST(&completionfreelist);
  STAILQ_REMOVE_HEAD(&completionfreelist, entries);
  assert(p->in_use == 0);
  p->in_use = 1;
  return(p);
}

void Ring_Handle_Completion(uint64_t *event)
{
  struct Ring_Completion *p;
  unsigned tag = event[7] & 0xffff;
  assert(tag < 1024);
  p = &completion[tag];
  assert(p->in_use == 1);
  p->in_use = 0;
  if (p->finish) (*p->finish)(p->arg, event);
  event[7] = 0L;  /* mark unused for next time around */
  //  printf("tag %d returned last %d\n", tag, status_ring.last);
  STAILQ_INSERT_TAIL(&completionfreelist, p, entries);
}

class RingIndication : public RingIndicationWrapper
{
public:
  virtual void setResult(uint32_t cmd, uint32_t regist, uint64_t addr) {
    fprintf(stderr, "setResult(cmd %d regist %d addr %llx)\n", 
	    cmd, regist, (long long)addr);
    setresult_flag = 1;
  }
  virtual void getResult(uint32_t cmd, uint32_t regist, uint64_t addr) {
    //fprintf(stderr, "getResult(cmd %d regist %d addr %llx)\n", 
    //	    cmd, regist, (long long)addr);
    /* returning query about last pointer of cmd ring */
    if ((cmd == cmd_ring.ringid) && (regist == REG_LASTACK)) {
      //fprintf(stderr, "update cmd_ring.last %zx\n", addr);
      cmd_ring.last = addr;
    }
    getresult_flag = 1;
  }
  RingIndication(unsigned int id) : RingIndicationWrapper(id){}
};

RingIndication *ringIndication = 0;

uint64_t fetch(uint64_t *p) {
  return (p[0]);
}

void waitforflag(char* f)
{
  while (*f == 0) StatusPoll();
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
  setresult_flag = 0;
  ring->set(ringid, REG_BASE, 0);         // bufferbase, relative to base
  waitforflag(&setresult_flag);
  setresult_flag = 0;
  ring->set(ringid, REG_END, size);      // bufferend
  waitforflag(&setresult_flag);
  if (ringid == 0) {
    ring->setCmdFirst(0);         // bufferfirst
    ring->setCmdLast(0);
  } else {
    ring->setStatusFirst(0);         // bufferfirst
    ring->setStatusLast(0);
  }
  setresult_flag = 0;
  ring->set(ringid, REG_MASK, size - 1);  // buffermask
  waitforflag(&setresult_flag);
  setresult_flag = 0;
  ring->set(ringid, REG_HANDLE, ref);       // memhandle
  waitforflag(&setresult_flag);
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
  /* update hardware version of r->last every 1/4 way around the ring */
  if ((r->last % (r->size >> 2)) == 0) {
    if (r->ringid == 0) {
      ring->setCmdLast(r->last);         // bufferlast 
    } else {
      ring->setStatusLast(r->last);         // bufferlast 
    }
  }
}

void StatusPollRingOnly(void)
{
  int i;
  uint64_t *msg;
  for (;;) {
    msg = ring_next(&status_ring);
    if (msg == NULL) break;
    Ring_Handle_Completion((uint64_t *) msg);
    ring_pop(&status_ring);
  }
}

void StatusPoll(void)
{
  int i;
  uint64_t *msg;
  long int rc;
  rc = (long int) portalExec_poll(0);
  if ((long)rc >= 0)
      rc = (long int) portalExec_event();
  assert(rc == 0);
  if (ring_init_done) {
    msg = ring_next(&status_ring);
    if (msg == NULL) return;
    // printf("Received %lx %lx\n", (long) msg[0], (long) msg[7]);
    Ring_Handle_Completion((uint64_t *) msg);
    ring_pop(&status_ring);
  }
}

/*
void *statusThreadProc(void *arg)
{
  int i;
  long int rc;
  uint64_t *msg;
  printf("Status thread running\n");
  for (;;) {
    StatusPoll();
    rc = (long int) portalExec_poll(0);
    if ((long)rc >= 0)
        rc = (long int) portalExec_event();
    assert(rc == 0);
  }
}
*/
int portalThreadRun;

void *myPortalThreadProc(void *arg)
{
  printf("Status thread running\n");
  while (portalThreadRun) {
    StatusPoll();
  }
  printf("status thread stopping\n");
}


/* XXX this isn't right, I think the SWRing* has to be volatile, so that
 * the compiler will know to refetch
 */

void ring_send(struct SWRing *r, uint64_t *cmd, void (*fp)(void *, uint64_t *), void *arg)
{
  unsigned next_first;
  struct Ring_Completion *p;
  assert(r->first < r->size);
  /* send an inquiry every 1/4 way around the ring */
  while ((r->cached_space % (r->size >> 2)) == 0) {
    getresult_flag = 0;
    ring->get(r->ringid, REG_LASTACK);         // bufferlast 
    waitforflag(&getresult_flag);
    r->cached_space = ((r->size + r->last - r->first - 64) % r->size);
    if (r->cached_space != 0) break;
  }
  p = get_free_completion();
  assert(p != NULL);
  p->finish = fp;
  p->arg = arg;
  cmd[7] = p->tag;
  //  printf("tag %d used first %d\n", p->tag, r->first);

  memcpy(&r->base[r->first], cmd, 64);
  next_first = r->first + 64;
  if (next_first == r->size) next_first = 0;
  r->first = next_first;
  r->cached_space -= 64;
}

#define STARTRING() do { ring->setCmdFirst(cmd_ring.first); } while (0);

void flag_finish(void *arg, uint64_t *event)
{
  volatile char *p = (volatile char *) arg;
  *p = 1;
}


void hw_copy(void *from, void *to, unsigned count)
{
  uint64_t tcmd[8];
  char flag = 0;
  tcmd[0] = ((uint64_t) CMD_COPY) << 56;
  tcmd[1] = scratchPointer;
  tcmd[2] = (uint64_t) from;
  tcmd[3] = scratchPointer;
  tcmd[4] = (uint64_t) to;
  tcmd[5] = count; // byte count
  ring_send(&cmd_ring, tcmd, flag_finish, &flag);
  STARTRING();
  while (flag == 0) StatusPoll();
}

void hw_copy_nb(void *from, void *to, unsigned count, char *flag)
{
  uint64_t tcmd[8];
  tcmd[0] = ((uint64_t) CMD_COPY) << 56;
  tcmd[1] = scratchPointer;
  tcmd[2] = (uint64_t) from;
  tcmd[3] = scratchPointer;
  tcmd[4] = (uint64_t) to;
  tcmd[5] = count; // byte count
  ring_send(&cmd_ring, tcmd, flag_finish, flag);
  STARTRING();
}

int totalCompletions;

struct CompletionEvent {
  uint64_t exp_a, exp_b;  // expected values
  uint64_t got_a, got_b;  // actual
  char flag;
};

struct CompletionEvent echoCompletion[16384];

void echo_finish(void *arg, uint64_t *event)
{
  struct CompletionEvent *p = (struct CompletionEvent *) arg;
  assert(p != NULL);
  p->got_a = event[1];
  p->got_b = event[2];
  p->flag = 1;
  totalCompletions += 1;
}


long long deltatime( struct timeval start, struct timeval stop)
{
  long long diff = ((long long) (stop.tv_sec - start.tv_sec)) * 1000000;
  diff = diff + ((long long) (stop.tv_usec - start.tv_usec));
  return (diff);
}

int fast_echo_test()
{
  struct timeval start, stop;
  struct CompletionEvent *p;
  uint64_t tcmd[8];
  unsigned loops = 1;
  unsigned int i;
  long long interval;
  fprintf(stderr, "fast echo test  ");
  for(;;) {
    fprintf(stderr, " %d", loops);
    for (i = 0; i < loops; i += 1) {
      p = &echoCompletion[i];
      // initialize the number of completion events needed
      p->exp_a = 0xaaa000L + (long) i;
      p->exp_b = 0xbbb000L + (long) i;
      p->flag = 0;
    }
    totalCompletions = 0;
    gettimeofday(&start, NULL);
    for (i = 0; i < loops; i += 1) {
      p = &echoCompletion[i];
      tcmd[0] = ((uint64_t) CMD_ECHO) << 56;
      tcmd[1] = (uint64_t) p->exp_a;
      tcmd[2] = (uint64_t) p->exp_b;
      ring_send(&cmd_ring, tcmd, echo_finish, p);
      if ((i & 15) == 0) STARTRING();
      StatusPollRingOnly();
    }
    STARTRING();
    while(totalCompletions != loops) StatusPollRingOnly();
    gettimeofday(&stop, NULL);
    for (i = 0; i < loops; i += 1) {
      p = &echoCompletion[i];
      if ((p->exp_a != p->got_a)
	  || (p->exp_b != p->got_b)) {
	printf("echo failed iteration %d got %lx %lx exp %lx %lx\n",
	       i, (long)p->got_a, (long)p->got_b, (long)p->exp_a, (long)p->exp_b);
      }
    }
    interval = deltatime(start, stop);
    if ((interval >= 500000) || (loops >= 16384)) break;
    loops <<= 1;
  }
  fprintf(stderr, "\n  microseconds %f\n", (double) interval / (double)loops); 
}


void hw_echo(long unsigned a, long unsigned b)
{
  struct CompletionEvent myevent;
  uint64_t tcmd[8];
  myevent.exp_a = a;
  myevent.exp_b = b;
  myevent.flag = 0;
  tcmd[0] = ((uint64_t) CMD_ECHO) << 56;
  tcmd[1] = (uint64_t) a;
  tcmd[2] = (uint64_t) b;
  ring_send(&cmd_ring, tcmd, echo_finish, &myevent);
  STARTRING();
  while (myevent.flag == 0) StatusPoll();
  if ((myevent.got_a != a) || (myevent.got_b != b)) {
    printf("echo failed a=%lx b= %lx got %llx %llx\n",
	   a, b, (long long)myevent.got_a, (long long)myevent.got_b);
  }
  
}

void hw_nop()
{
  uint64_t tcmd[8];
  tcmd[0] = ((uint64_t) CMD_NOP) << 56;
  tcmd[1] = (uint64_t) 17;
  tcmd[2] = (uint64_t) 34;
  ring_send(&cmd_ring, tcmd, NULL, NULL);
  STARTRING();
}

int main(int argc, const char **argv)
{
  void *v;
  int i;
  long int rc;
  uint64_t tcmd[8];
  volatile char flag[10];

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  completion_list_init();
  ring = new RingRequestProxy(IfcNames_RingRequest);
  ringIndication = new RingIndication(IfcNames_RingIndication);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);

  fprintf(stderr, "allocating memory...\n");
  cmdAlloc = portalAlloc(cmd_ring_sz);
  statusAlloc = portalAlloc(status_ring_sz);
  scratchAlloc = portalAlloc(scratch_sz);

  v = portalMmap(cmdAlloc, cmd_ring_sz);
  assert(v != MAP_FAILED);
  cmdBuffer = (char *) v;

  v = portalMmap(statusAlloc, status_ring_sz);
  assert(v != MAP_FAILED);
  statusBuffer = (char *) v;
  v = portalMmap(scratchAlloc, scratch_sz);
  assert(v != MAP_FAILED);
  scratchBuffer = (char *) v;

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  portalThreadRun = 1;
  if(pthread_create(&tid, NULL,  myPortalThreadProc, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  rc = (long int) portalExec_init();
  assert(rc == 0);
  cmdPointer = dma->reference(cmdAlloc);
  statusPointer = dma->reference(statusAlloc);
  scratchPointer = dma->reference(scratchAlloc);

  /*   portalDCacheFlushInval(cmdAlloc, cmd_ring_sz, cmdBuffer);
  portalDCacheFlushInval(statusAlloc, status_ring_sz, statusBuffer);
  portalDCacheFlushInval(scratchAlloc, scratch_sz, scratchBuffer);
  fprintf(stderr, "flush and invalidate complete\n");
  */
  portalThreadRun = 0;

  ring_init(&cmd_ring, 0, cmdPointer, cmdBuffer, cmd_ring_sz);
  ring_init(&status_ring, 1, statusPointer, statusBuffer, status_ring_sz);
  ring_init_done = 1;
  /*
  pthread_t ltid;
  fprintf(stderr, "creating status thread\n");
  if(pthread_create(&ltid, NULL,  statusThreadProc, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }
  */
  ring->hwenable(1);  /* turn on engines */
  fprintf(stderr, "main about to issue requests\n");

  /* pass 1, a few blocking tests to see if it works at all
   * pass 2, non blocking tests
   * pass 3, a lot of tests, to check ring wrapping
   */
  /* pass 1, blocking tests */
  for (i = 0; i < 256; i += 1) {
    scratchBuffer[i] = i;
  }
  for (i = 0; i < 10; i += 1) {
    uint64_t ul1;
    uint64_t ul2;
    fprintf(stderr, "main hwcopy %d\n", i);
    hw_copy((void *) (256L * i),
	    (void *) (256L * (i + 1)),
	    0x100);
    ul1 = (0x111LL << 32) + (long) i;
    ul2 = (0x222LL << 32) + (long) i;
    hw_echo(ul1, ul2);
  }
  for (i = 0; i < 10; i += 1) {
    if (scratchBuffer[i + 2560] != i) {
      printf("loc %d got %d should be %d\n",
	     i + 2560, scratchBuffer[i + 2560], i);
    }
  }
  /* pass 2, non blocking tests */
  memset(scratchBuffer, 0, scratch_sz);
  for (i = 0; i < 256; i += 1) {
    scratchBuffer[i] = i;
  }
  for (i = 0; i < 10; i += 1) {
    flag[i] = 0;
  }
  for (i = 0; i < 10; i += 1) {
    uint64_t ul1;
    uint64_t ul2;
    hw_copy_nb((void *) (256L * i),
	    (void *) (256L * (i + 1)),
	       0x100, (char *) &flag[i]);
  }
  fprintf(stderr, "main waiting for pass 2 completions\n");
  {
    int done = 0;
    while(done < 10) {
      while (flag[done] == 0) StatusPoll();
      done += 1;
      fprintf(stderr, "done %d\n", done);
    }
  }
  /* pass 3 */
  for (i = 0; i < 512; i += 1) {
    uint64_t ul1;
    uint64_t ul2;
    ul1 = (0x333LL << 32) + (long) i;
    ul2 = (0x444LL << 32) + (long) i;
    hw_echo(ul1, ul2);
  }

  fast_echo_test();

}
