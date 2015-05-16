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
#include <unistd.h>
#include <pthread.h>
#include <monkit.h>

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "MemreadRequest.h"
#include "MemreadIndication.h"

sem_t test_sem;


#ifdef PCIE
int burstLen = 32;
#else
int burstLen = 16;
#endif

#if !defined(BSIM) && !defined(BOARD_xsim)
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
int iterCnt = 64;
#else
int numWords = 0x124000/4;
int iterCnt = 3;
//int numWords = 0x20/4;
//int iterCnt = 1;
#endif

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
int mismatchCount = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (size_t i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class MemreadIndication : public MemreadIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(uint32_t v){
    fprintf(stderr, "Memread::readDone(%x)\n", v);
    mismatchCount += v;
    sem_post(&test_sem);
  }
  virtual void started(uint32_t words){
    fprintf(stderr, "Memread::started(%x)\n", words);
  }
  virtual void rData ( uint64_t v ){
    fprintf(stderr, "rData(%08x): ", rDataCnt++);
    dump("", (char*)&v, sizeof(v));
  }
  virtual void reportStateDbg(uint32_t reportType, uint32_t finished, uint32_t dataPipeNotEmpty){
    fprintf(stderr, "Memread::reportStateDbg(%08x, finished=%08x dataPipeNotEmpty=%08x)\n", reportType, finished, dataPipeNotEmpty);
  }  
  void reportStateDbg ( const uint32_t streamRdCnt, const uint32_t mismatchCount ) {
  }
  MemreadIndication(int id) : MemreadIndicationWrapper(id){}
};

MemreadRequestProxy *device = 0;

static volatile int running = 1;

void *debugWorker(void *ptr)
{
  while (running) {
    device->getStateDbg();
    sleep(5);
  }
  return ptr;
}

int main(int argc, const char ** argv)
{

  int test_result = 0;
  int srcAlloc;
  unsigned int *srcBuffer = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new MemreadRequestProxy(IfcNames_MemreadRequestS2H);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_MemServerRequestS2H);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_MMURequestS2H);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_MemServerIndicationH2S);
  MemreadIndication memReadIndication(IfcNames_MemreadIndicationH2S);
  MMUIndication mmuIndication(dma, IfcNames_MMUIndicationH2S);

  fprintf(stderr, "Main::allocating memory...\n");
  srcAlloc = portalAlloc(alloc_sz, 0);
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);

  pthread_t debug_thread;
  pthread_create(&debug_thread, 0, debugWorker, 0);

#ifdef FPGA0_CLOCK_FREQ
  long req_freq = FPGA0_CLOCK_FREQ;
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
#endif

  /* Test 1: check that match is ok */
  for (int i = 0; i < numWords; i++){
    srcBuffer[i] = i;
  }
    
  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");
  device->getStateDbg();
  fprintf(stderr, "Main::after getStateDbg\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);

  bool orig_test = true;

  if (orig_test){
    fprintf(stderr, "Main::orig_test read %08x\n", numWords);
    portalTimerStart(0);
    device->startRead(ref_srcAlloc, 0, numWords, burstLen, iterCnt);
    sem_wait(&test_sem);
    if (mismatchCount) {
      fprintf(stderr, "Main::first test failed to match %d.\n", mismatchCount);
      test_result++;     // failed
    }
    uint64_t cycles = portalTimerLap(0);
    hostMemServerRequest->memoryTraffic(ChannelType_Read);
    uint64_t beats = hostMemServerIndication->receiveMemoryTraffic();
    float read_util = (float)beats/(float)cycles;
    fprintf(stderr, " iterCnt: %d\n", iterCnt);
    fprintf(stderr, "   beats: %"PRIx64"\n", beats);
    fprintf(stderr, "numWords: %x\n", numWords);
    fprintf(stderr, "     est: %"PRIx64"\n", (beats*2)/iterCnt);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", read_util);

    /* Test 2: check that mismatch is detected */
    srcBuffer[0] = -1;
    srcBuffer[numWords/2] = -1;
    srcBuffer[numWords-1] = -1;
    portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);

    fprintf(stderr, "Starting second read, mismatches expected\n");
    mismatchCount = 0;
    device->startRead(ref_srcAlloc, 0, numWords, burstLen, iterCnt);
    sem_wait(&test_sem);
    if (mismatchCount != 3/*number of errors introduced above*/ * iterCnt) {
      fprintf(stderr, "Main::second test failed to match mismatchCount=%d (expected %d) iterCnt=%d numWords=%d.\n",
	      mismatchCount, 3*iterCnt,
	      iterCnt, numWords);
      test_result++;     // failed
    }

    running = 0;

#if 0
    MonkitFile pmf("perf.monkit");
    pmf.setHwCycles(cycles)
      .setReadBwUtil(read_util)
      .writeFile();
#endif

    return test_result; 
  } else {
    fprintf(stderr, "Main::new_test read %08x\n", numWords);
    int chunk = numWords >> 4;
    for(int i = 0; i < numWords; i+=chunk){
      device->startRead(ref_srcAlloc, i, chunk, burstLen, 1);
      sem_wait(&test_sem);
    }
    if (mismatchCount) {
      fprintf(stderr, "Main::new_test failed to match %08x.\n", mismatchCount);
      test_result++;     // failed
    }
    running = 0;
    return test_result;
  }
}

