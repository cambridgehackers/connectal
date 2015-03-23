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
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>
#include <monkit.h>
#include <sys/socket.h>

#include <errno.h>
#include "sock_utils.h"
#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "MemwriteIndication.h"
#include "MemwriteRequest.h"
#include "dmaManager.h"


sem_t test_sem;
#ifndef BSIM
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
#else
int numWords = 0x124000/4;
#endif
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

#ifdef PCIE
int burstLen = 32;
#else
int burstLen = 16;
#endif
#ifndef BSIM
int iterCnt = 128;
#else
int iterCnt = 2;
#endif


class MemwriteIndication : public MemwriteIndicationWrapper
{
public:
 MemwriteIndication(int id, int tile) : MemwriteIndicationWrapper(id, tile){}

  virtual void started(uint32_t words){
    fprintf(stderr, "Memwrite::started: words=%x\n", words);
  }
  virtual void writeDone ( uint32_t srcGen ){
    fprintf(stderr, "Memwrite::writeDone (%08x)\n", srcGen);
    sem_post(&test_sem);
  }
  virtual void reportStateDbg(uint32_t streamWrCnt, uint32_t srcGen){
    fprintf(stderr, "Memwrite::reportStateDbg: streamWrCnt=%08x srcGen=%d\n", streamWrCnt, srcGen);
  }  

};

MemwriteRequestProxy *device = 0;
MMURequestProxy *dmap = 0;
MemwriteIndication *deviceIndication = 0;
int dstAlloc;
unsigned int *dstBuffer = 0;


int main(int argc, const char **argv)
{

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "error: failed to init test_sem\n");
    exit(1);
  }

  device = new MemwriteRequestProxy(TileNames_MemwriteRequestS2H,1);
  deviceIndication = new MemwriteIndication(TileNames_MemwriteIndicationH2S,1);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(PlatformNames_MemServerRequestS2H);
  MMURequestProxy *dmap = new MMURequestProxy(PlatformNames_MMURequestS2H);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, PlatformNames_MemServerIndicationH2S);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, PlatformNames_MMUIndicationH2S);
  
  fprintf(stderr, "main::allocating memory...\n");
  dstAlloc = portalAlloc(alloc_sz);
  dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  
  portalExec_start();

  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  
  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = 0xDEADBEEF;
  }
  
  portalDCacheFlushInval(dstAlloc, alloc_sz, dstBuffer);
  fprintf(stderr, "main::flush and invalidate complete\n");


  device->startWrite(ref_dstAlloc, 0, numWords, burstLen, iterCnt);
  sem_wait(&test_sem);

  bool mismatch = false;
  unsigned int sg = 0;
  for (int i = 0; i < numWords; i++)
    mismatch |= (dstBuffer[i] != sg++);

  fprintf(stderr, "main::mismatch=%d\n", mismatch);
  munmap(dstBuffer, alloc_sz);
  exit(mismatch);
}
