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
#include <monkit.h>

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "MemreadRequest.h"
#include "MemreadIndication.h"

sem_t test_sem;

int burstLen = 16;

#ifdef BSIM
int numWords = 0x124000/4; // make sure to allocate at least one entry of each size
#else
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
#endif

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

void dump(const char *prefix, char *buf, size_t len)
{
    printf( "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	printf( "%02x", (unsigned char)buf[i]);
    printf( "\n");
}

class MemreadIndication : public MemreadIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(uint32_t v){
    printf( "Memread::readDone(mismatch = %x)\n", v);
    sem_post(&test_sem);
  }
  MemreadIndication(int id, int tile) : MemreadIndicationWrapper(id,tile){}
};

int main(int argc, const char **argv)
{
  MemreadRequestProxy *device = new MemreadRequestProxy(TileNames_MemreadRequestS2H, 1);
  MemreadIndication *deviceIndication = new MemreadIndication(TileNames_MemreadIndicationH2S, 1);

  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(PlatformNames_MemServerRequestS2H);
  MMURequestProxy *dmap = new MMURequestProxy(PlatformNames_MMURequestS2H);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, PlatformNames_MemServerIndicationH2S);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, PlatformNames_MMUIndicationH2S);

  int srcAlloc;
  srcAlloc = portalAlloc(alloc_sz);
  unsigned int *srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);

  portalExec_start();
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;
  portalDCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  printf( "Main::starting read %08x\n", numWords);
  device->startRead(ref_srcAlloc, numWords, burstLen, 1);
  sem_wait(&test_sem);
  return 0;
}
