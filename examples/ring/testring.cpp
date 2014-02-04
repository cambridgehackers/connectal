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

volatile uint64_t *ring_next(struct SWRing *r)
{
  volatile uint64_t *p = (uint64_t *) (r->base + (long) r->last);
  if (p[7] == 0) return (NULL);
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

void ring_send(struct SWRing *r, uint64_t *cmd)
{
  unsigned next_first;
  assert(r->first < r->size);
  /* send an inquiry every 1/4 way around the ring */
  if ((r->cached_space % (r->size >> 2)) == 0) {
    ring->get(r->ringid, REG_LAST, 0);         // bufferlast 
    while (r->cached_space == 0) {
      r->cached_space = ((r->size + r->last - r->first - 64) % r->size);
    }
  }
  
  memcpy(&r->base[r->first], cmd, 64);
  next_first = r->first + 64;
  if (next_first == r->size) next_first = 0;
  r->first = next_first;
  r->cached_space -= 64;
  ring->set(r->ringid, REG_FIRST, r->first);         // bufferfirst
  sem_wait(&conf_sem);
}

void *statusThreadProc(void *arg)
{
  int i;
  volatile uint64_t *msg;
  printf("Status thread running\n");
  for (;;) {
    while ((msg = ring_next(&status_ring)) == NULL);
    printf("Received %x %x\n", msg[0], msg[7]);
    ring_pop(&status_ring);
  }
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

  v = mmap(0, cmd_ring_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, cmdAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  cmdBuffer = (char *) v;

  v = mmap(0, status_ring_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, statusAlloc->header.fd, 0);
  assert(v != MAP_FAILED);
  statusBuffer = (char *) v;
  v = mmap(0, scratch_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, scratchAlloc->header.fd, 0);
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
    tcmd[0] = ((uint64_t) CMD_COPY) << 56;
    tcmd[0] |= 0x20000000 + i; // tag
    tcmd[1] = (((uint64_t) ref_scratchAlloc) << 32)
      | (256 * i);
    tcmd[2] = (((uint64_t) ref_scratchAlloc) << 32)
      | (256 * (i + 1));
    tcmd[3] = 256; // byte count
    tcmd[4] = 0xdeadbeef;
    tcmd[5] = 0xfeedface;
    tcmd[6] = 0x012345789abcdefL;
    tcmd[7] = 0xfedcba9876543210L;
    ring_send(&cmd_ring, tcmd);
    tcmd[0] = ((uint64_t) CMD_ECHO) << 56;
    tcmd[1] = 0x111;
    tcmd[2] = 0x222;
    tcmd[3] = 0x333;
    tcmd[4] = 0x444;
    tcmd[5] = 0x555;
    tcmd[6] = 0x666;
    tcmd[7] = 0xf0000000 | i;
    ring_send(&cmd_ring, tcmd);
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
