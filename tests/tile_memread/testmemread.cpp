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

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "ReadTestRequest.h"
#include "ReadTestIndication.h"

sem_t test_sem;

int burstLen = 16;

#ifdef BSIM
int numWords = 0x12400/4; // make sure to allocate at least one entry of each size
#else
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
#endif
#define TILE_NUMBER 1

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

void dump(const char *prefix, char *buf, size_t len)
{
    printf( "%s ", prefix);
    for (unsigned int i = 0; i < (len > 16 ? 16 : len) ; i++)
	printf( "%02x", (unsigned char)buf[i]);
    printf( "\n");
}

class ReadTestIndication : public ReadTestIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(uint32_t v){
    printf( "ReadTest::readDone(mismatch = %x)\n", v);
    sem_post(&test_sem);
  }
  ReadTestIndication(int id, int tile) : ReadTestIndicationWrapper(id,tile){}
};

int main(int argc, const char **argv)
{
  ReadTestRequestProxy *device = new ReadTestRequestProxy(ReadTestRequestS2H, TILE_NUMBER);
  ReadTestIndication deviceIndication(ReadTestIndicationH2S, TILE_NUMBER);

  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(MemServerRequestS2H);
  MMURequestProxy *dmap = new MMURequestProxy(MMURequestS2H);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication hostMemServerIndication(hostMemServerRequest, MemServerIndicationH2S);
  MMUIndication hostMMUIndication(dma, MMUIndicationH2S);

  int srcAlloc;
  srcAlloc = portalAlloc(alloc_sz, 0);
  unsigned int *srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);

  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;
  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  printf( "Main::starting read %08x\n", numWords);
  device->startRead(ref_srcAlloc, numWords, burstLen, 1);
  sem_wait(&test_sem);
  printf("%s: all done!\n", __FUNCTION__);
  return 0;
}
