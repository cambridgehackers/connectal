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
#ifndef _TESTMEMRW_H_
#define _TESTMEMRW_H_
#include "dmaManager.h"
#include "MemrwIndication.h"
#include "MemrwRequest.h"

sem_t read_done_sem;
sem_t write_done_sem;
int srcAlloc;
int dstAlloc;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
#ifndef BSIM
int numWords = 16 << 18;
#else
int numWords = 16 << 10;
#endif
size_t alloc_sz = numWords*sizeof(unsigned int);
bool finished = false;
uint64_t read_cycles;
uint64_t write_cycles;

class MemrwIndication : public MemrwIndicationWrapper
{

public:
  MemrwIndication(unsigned int id) : MemrwIndicationWrapper(id){}

  virtual void started(){
    fprintf(stderr, "started\n");
  }
  virtual void readDone() {
    read_cycles = portalTimerLap(0);
    sem_post(&read_done_sem);
    fprintf(stderr, "readDone\n");
  }
  virtual void writeDone() {
    write_cycles = portalTimerLap(0);
    sem_post(&write_done_sem);
    fprintf(stderr, "writeDone\n");
  }
};


// we can use the data synchronization barrier instead of flushing the 
// cache only because the ps7 is configured to run in buffered-write mode
//
// an opc2 of '4' and CRm of 'c10' encodes "CP15DSB, Data Synchronization Barrier 
// operation". this is a legal instruction to execute in non-privileged mode (mdk)
//
// #define DATA_SYNC_BARRIER   __asm __volatile( "MCR p15, 0, %0, c7, c10, 4" ::  "r" (0) );

int runtest(int argc, const char **argv)
{
  MemrwRequestProxy *device = 0;
  MemrwIndication *deviceIndication = 0;

  if(sem_init(&read_done_sem, 1, 0)){
    fprintf(stderr, "failed to init read_done_sem\n");
    exit(1);
  }
  if(sem_init(&write_done_sem, 1, 0)){
    fprintf(stderr, "failed to init write_done_sem\n");
    exit(1);
  }

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  device = new MemrwRequestProxy(IfcNames_MemrwRequestS2H);
  deviceIndication = new MemrwIndication(IfcNames_MemrwIndicationH2S);
  DmaManager *dma = platformInit();

  fprintf(stderr, "Main::allocating memory...\n");

  srcAlloc = portalAlloc(alloc_sz, 0);
  dstAlloc = portalAlloc(alloc_sz, 0);

  // for(int i = 0; i < srcAlloc->header.numEntries; i++)
  //   fprintf(stderr, "%lx %lx\n", srcAlloc->entries[i].dma_address, srcAlloc->entries[i].length);
  // for(int i = 0; i < dstAlloc->header.numEntries; i++)
  //   fprintf(stderr, "%lx %lx\n", dstAlloc->entries[i].dma_address, dstAlloc->entries[i].length);

  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);

  for (int i = 0; i < numWords; i++){
    srcBuffer[i] = i;
    dstBuffer[i] = 0x5a5abeef;
  }

  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  
  sleep(1);
  //hostMemServerRequest->addrRequest(ref_srcAlloc, 1*sizeof(unsigned int));
  //sleep(1);
  //hostMemServerRequest->addrRequest(ref_dstAlloc, 2*sizeof(unsigned int));
  //sleep(1);
  
  fprintf(stderr, "Main::starting mempcy numWords:%d\n", numWords);
  int burstLen = 16;
#ifndef BSIM
  int iterCnt = 64;
#else
  int iterCnt = 2;
#endif
  portalTimerStart(0);
  device->start(ref_dstAlloc, ref_srcAlloc, numWords, burstLen, iterCnt);
  sem_wait(&read_done_sem);
  sem_wait(&write_done_sem);
  uint64_t hw_cycles = portalTimerLap(0); 
  uint64_t read_beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
  uint64_t write_beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Write);
  float read_util = (float)read_beats/(float)read_cycles;
  float write_util = (float)write_beats/(float)write_cycles;

  fprintf(stderr, "memory read utilization (beats/cycle): %f\n", read_util);
  fprintf(stderr, "memory write utilization (beats/cycle): %f\n", write_util);

  MonkitFile("perf.monkit")
    .setHwCycles(hw_cycles)
    .setReadBwUtil(read_util)
    .setWriteBwUtil(write_util)
    .writeFile();

}

#endif //_TESTMEMRW_H_
