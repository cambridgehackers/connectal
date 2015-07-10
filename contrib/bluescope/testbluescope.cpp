/* Copyright (c) 2013 Quanta Research Cambridge, Inc
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
#include <monkit.h>
#include <semaphore.h>
#include "dmaManager.h"
#include "BlueScopeIndication.h"
#include "BlueScopeRequest.h"
#include "MemcpyIndication.h"
#include "MemcpyRequest.h"

sem_t done_sem;
int srcAlloc;
int dstAlloc;
int bsAlloc;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
unsigned int *bsBuffer  = 0;
int numWords = 128; //16 << 10;
size_t alloc_sz = numWords*sizeof(unsigned int);
bool trigger_fired = false;
bool finished = false;
bool memcmp_fail = false;
unsigned int memcmp_count = 0;

static void memdump(void *p, int len, const char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                fprintf(stderr, "\n");
            fprintf(stderr, "%s: ",title);
        }
        fprintf(stderr, "%02x ", *(unsigned char *)p);
        p = (unsigned char *)p + 1;
        i++;
        len--;
    }
    fprintf(stderr, "\n");
}

void exit_test()
{
  fprintf(stderr, "testmemcpy finished count=%d memcmp_fail=%d, trigger_fired=%d\n", memcmp_count, memcmp_fail, trigger_fired);
  exit(memcmp_fail || !trigger_fired);
}

class MemcpyIndication : public MemcpyIndicationWrapper
{

public:
  MemcpyIndication(unsigned int id) : MemcpyIndicationWrapper(id){}


  virtual void started(){
    fprintf(stderr, "started");
  }
  virtual void done() {
    sem_post(&done_sem);
    finished = true;
    unsigned int mcf = memcmp(srcBuffer, dstBuffer, numWords*sizeof(unsigned int));
    memcmp_fail |= mcf;
    fprintf(stderr, "memcpy done:\n");
    fprintf(stderr, "(%d) memcmp src=%lx dst=%lx success=%s\n", memcmp_count, (long)srcBuffer, (long)dstBuffer, mcf == 0 ? "pass" : "fail");
    memdump(srcBuffer, 128, "src");
    memdump(dstBuffer, 128, "dst");
    memdump(bsBuffer,  128, "dbg");
  }
};

class BlueScopeIndication : public BlueScopeIndicationWrapper
{
public:
  BlueScopeIndication(unsigned int id) : BlueScopeIndicationWrapper(id){}

  virtual void done( ){
    fprintf(stderr, "BlueScope::done\n");
  }
  virtual void triggerFired( ){
    fprintf(stderr, "BlueScope::triggerFired\n");
    trigger_fired = true;
  }
  virtual void reportStateDbg(uint64_t mask, uint64_t value){
    fprintf(stderr, "BlueScope::reportStateDbg mask=%" PRIu64 ", value=%" PRIu64 "\n", mask, value);
  }
};

// we can use the data synchronization barrier instead of flushing the 
// cache only because the ps7 is configured to run in buffered-write mode
//
// an opc2 of '4' and CRm of 'c10' encodes "CP15DSB, Data Synchronization Barrier 
// operation". this is a legal instruction to execute in non-privileged mode (mdk)
//
// #define DATA_SYNC_BARRIER   __asm __volatile( "MCR p15, 0, %0, c7, c10, 4" ::  "r" (0) );

int main(int argc, const char **argv)
{
  MemcpyRequestProxy *device = 0;
  BlueScopeRequestProxy *bluescope = 0;
  MemcpyIndication *deviceIndication = 0;
  BlueScopeIndication *bluescopeIndication = 0;

  if(sem_init(&done_sem, 1, 0)){
    fprintf(stderr, "failed to init done_sem\n");
    exit(1);
  }

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  device = new MemcpyRequestProxy(IfcNames_MemcpyRequest);
  bluescope = new BlueScopeRequestProxy(IfcNames_BluescopeRequest);
    DmaManager *dma = platformInit();
  deviceIndication = new MemcpyIndication(IfcNames_MemcpyIndication);
  bluescopeIndication = new BlueScopeIndication(IfcNames_BluescopeIndication);

  fprintf(stderr, "Main::allocating memory of size=%d...\n", (int)alloc_sz);

  srcAlloc = portalAlloc(alloc_sz, 0);
  dstAlloc = portalAlloc(alloc_sz, 0);
  bsAlloc = portalAlloc(alloc_sz, 0);

  // for(int i = 0; i < srcAlloc->header.numEntries; i++)
  //   fprintf(stderr, "%lx %lx\n", srcAlloc->entries[i].dma_address, srcAlloc->entries[i].length);
  // for(int i = 0; i < dstAlloc->header.numEntries; i++)
  //   fprintf(stderr, "%lx %lx\n", dstAlloc->entries[i].dma_address, dstAlloc->entries[i].length);
  // for(int i = 0; i < bsAlloc->header.numEntries; i++)
  //   fprintf(stderr, "%lx %lx\n", bsAlloc->entries[i].dma_address, bsAlloc->entries[i].length);


  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  bsBuffer  = (unsigned int *)portalMmap(bsAlloc, alloc_sz);

  for (int i = 0; i < numWords; i++){
    srcBuffer[i] = i;
    dstBuffer[i] = 0x5a5abeef;
    bsBuffer[i]  = 0x5a5abeef;
  }

  portalCacheFlush(bsAlloc, bsBuffer, alloc_sz, 1);
  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  unsigned int ref_bsAlloc  = dma->reference(bsAlloc);
  
  bluescope->reset();
  bluescope->setTriggerMask (0xFFFFFFFF);
  bluescope->setTriggerValue(0x00000008);
  bluescope->start(ref_bsAlloc, alloc_sz);

  sleep(1);
  //hostMemServerRequest->addrRequest(ref_srcAlloc, 1*sizeof(unsigned int));
  sleep(1);
  //hostMemServerRequest->addrRequest(ref_dstAlloc, 2*sizeof(unsigned int));
  sleep(1);
  //hostMemServerRequest->addrRequest(ref_bsAlloc, 3*sizeof(unsigned int));
  sleep(1);
  
  fprintf(stderr, "Main::starting mempcy numWords:%d\n", numWords);
  int burstLen = 16;
  device->startCopy(ref_dstAlloc, ref_srcAlloc, numWords, burstLen);
  sem_wait(&done_sem);
  sleep(2);
  exit_test();
}
