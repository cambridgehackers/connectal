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
#include <monkit.h>
#include "dmaManager.h"
#include "MemreadRequest.h"
#include "MemreadIndication.h"

sem_t test_sem;

#ifdef PCIE
int burstLen = 32;
#else
int burstLen = 16;
#endif

#ifndef SIMULATION
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
#else
int numWords = 0x1240/4;
#endif

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
int mismatchCount = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (unsigned int i = 0; i < (len > 16 ? 16 : len) ; i++)
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
  MemreadIndication(int id) : MemreadIndicationWrapper(id){}
};

int runtest(int argc, const char ** argv)
{
  int test_result = 0;
  int srcAlloc;
  unsigned int *srcBuffer = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);
  MemreadRequestProxy *device = new MemreadRequestProxy(IfcNames_MemreadRequestS2H);
  MemreadIndication deviceIndication(IfcNames_MemreadIndicationH2S);
  DmaManager *dma = platformInit();

  fprintf(stderr, "Main::allocating memory...\n");
  srcAlloc = portalAlloc(alloc_sz, 0);
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);

#ifdef FPGA0_CLOCK_FREQ
  long req_freq = FPGA0_CLOCK_FREQ;
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
#endif

  for (int i = 0; i < numWords; i++){
    srcBuffer[i] = i;
  }

  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);

  if(true) {
    fprintf(stderr, "Main::test read %08x\n", numWords);
    // first attempt should get the right answer
    device->startRead(ref_srcAlloc, 0, numWords, burstLen);
    sem_wait(&test_sem);
    if (mismatchCount) {
      fprintf(stderr, "Main::first test failed to match %d.\n", mismatchCount);
      test_result++;     // failed
    }
  }

  int err = 5;
  switch (err){
  case 0:
    {
      fprintf(stderr, "Main: attempt to use a de-referenced sglist\n");
      dma->dereference(ref_srcAlloc);
      device->startRead(ref_srcAlloc, 0, numWords, burstLen);
      break;
    } 
  case 1:
    {
      fprintf(stderr, "Main: attempt to use an out-of-range sglist\n");
      device->startRead(ref_srcAlloc+32, 0, numWords, burstLen);
      break;
    }
  case 2:
    {
      fprintf(stderr, "Main: attempt to use an invalid sglist\n");
      device->startRead(ref_srcAlloc+1, 0, numWords, burstLen);
      break;
    }
  case 3:
    {
      fprintf(stderr, "Main: attempt to use an invalid mmusel\n");
      device->startRead(ref_srcAlloc | (1<<16), 0, numWords, burstLen);
      break;
    }
  case 4:
    {
      fprintf(stderr, "Main: attempt to read off the end of the region\n");
      device->startRead(ref_srcAlloc, numWords<<2, burstLen, burstLen);
      break;
    }
  default:
    {
      device->startRead(ref_srcAlloc, 0, numWords, burstLen);
    }
  }

  sem_wait(&test_sem);
  if (mismatchCount) {
    fprintf(stderr, "Main::first test failed to match %d.\n", mismatchCount);
    test_result++;     // failed
  }
  return test_result;
}

int main(int argc, const char **argv)
{
  int ret = runtest(argc, argv);
  exit(ret ? 1 : 0);
}
