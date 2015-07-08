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
#include <sys/time.h>
#include <semaphore.h>
#include "dmaManager.h"
#include "PerfIndication.h"
#include "PerfRequest.h"

sem_t copy_sem;

PerfRequestProxy *device = 0;
MMURequestProxy *dmap = 0;
  
int srcAlloc;
int dstAlloc;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
int numWords;
size_t test_sz  = (1 << 20) *sizeof(unsigned int);
size_t alloc_sz = test_sz;
unsigned int finishedCount;
unsigned int ref_srcAlloc;
unsigned int ref_dstAlloc;

bool memcmp_fail = false;
unsigned int memcmp_count = 0;
unsigned int start_count = 0;
unsigned int copy_size = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < len ; i++) {
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
	if (i % 32 == 31)
	  fprintf(stderr, "\n");
    }
    fprintf(stderr, "\n");
}

class PerfIndication : public PerfIndicationWrapper
{

public:
  PerfIndication(unsigned int id) : PerfIndicationWrapper(id){}


  virtual void started(uint32_t words){
    // fprintf(stderr, "started: words=%ld\n", words);
    start_count += 1;
    if (copy_size == 0) sem_post(&copy_sem);
  }
  virtual void readWordResult ( uint32_t v ){
    dump("readWordResult: ", (char*)&v, sizeof(v));
  }
  virtual void done(uint32_t v) {
    finishedCount += 1;
    sem_post(&copy_sem);
  }
  virtual void rData ( uint64_t v ){
    dump("rData: ", (char*)&v, sizeof(v));
  }
  virtual void readReq(uint32_t v){
    //fprintf(stderr, "readReq %lx\n", v);
  }
  virtual void writeReq(uint32_t v){
    //fprintf(stderr, "writeReq %lx\n", v);
  }
  virtual void writeAck(uint32_t v){
    //fprintf(stderr, "writeAck %lx\n", v);
  }
  virtual void reportStateDbg(uint32_t srcGen, uint32_t streamRdCnt, 
			      uint32_t streamWrCnt, uint32_t writeInProg, 
			      uint32_t dataMismatch){
    fprintf(stderr, "Perf::reportStateDbg: srcGen=%d, streamRdCnt=%d, streamWrCnt=%d, writeInProg=%d, dataMismatch=%d\n", 
	    srcGen, streamRdCnt, streamWrCnt, writeInProg, dataMismatch);
  }  
};
PerfIndication *deviceIndication = 0;


// we can use the data synchronization barrier instead of flushing the 
// cache only because the ps7 is configured to run in buffered-write mode
//
// an opc2 of '4' and CRm of 'c10' encodes "CP15DSB, Data Synchronization Barrier 
// operation". this is a legal instruction to execute in non-privileged mode (mdk)
//
// #define DATA_SYNC_BARRIER   __asm __volatile( "MCR p15, 0, %0, c7, c10, 4" ::  "r" (0) );

long long deltatime( struct timeval start, struct timeval stop)
{
  long long diff = ((long long) (stop.tv_sec - start.tv_sec)) * 1000000;
  diff = diff + ((long long) (stop.tv_usec - start.tv_usec));
  return (diff);
}

int dotest(unsigned size, unsigned repeatCount)
{
  struct timeval start, stop;
  unsigned loops = 1;
  unsigned int i;
  long long interval;
  fprintf(stderr, "repeat %d size %d loop ", repeatCount, size);
  for(;;) {
    finishedCount = 0;
    copy_size = size;
    fprintf(stderr, " %d", loops);
    gettimeofday(&start, NULL);
    for (i = 0; i < loops; i += 1) {
      device->startCopy(ref_dstAlloc, ref_srcAlloc, numWords, repeatCount);
      sem_wait(&copy_sem);
    }
    gettimeofday(&stop, NULL);
    interval = deltatime(start, stop);
    if (interval >= 500000) break;
    loops <<= 1;
  }
  fprintf(stderr, "\n  block size %d microseconds %lld\n", size*16, interval / loops); 
}

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;
  unsigned repeatCount = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

    DmaManager *dma = platformInit();
  device = new PerfRequestProxy(IfcNames_PerfRequest);
  deviceIndication = new PerfIndication(IfcNames_PerfIndication);

  fprintf(stderr, "Main::allocating memory...\n");

  srcAlloc = portalAlloc(alloc_sz, 0);
  dstAlloc = portalAlloc(alloc_sz, 0);

  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);

  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  ref_srcAlloc = dma->reference(srcAlloc);
  ref_dstAlloc = dma->reference(dstAlloc);
  fprintf(stderr, "ref_srcAlloc %d\n", ref_srcAlloc);
  fprintf(stderr, "ref_dstAlloc %d\n", ref_dstAlloc);
  //fprintf(stderr, "Main::starting mempcy numWords:%d\n", 0);
  
  //dotest(0);
  for (repeatCount = 1; repeatCount <= 16; repeatCount <<= 1) {
    fprintf(stderr, "Main::starting mempcy repeatCount:%d\n", repeatCount);
    for (numWords = 16; numWords < (1 << 16); numWords <<= 1){
    
      //fprintf(stderr, "Main::starting mempcy numWords:%d\n", numWords);
      
      dotest(numWords, repeatCount);
    }
  }

  device->getStateDbg();
  fprintf(stderr, "Main::exiting\n");
}
