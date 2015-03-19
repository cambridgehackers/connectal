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


#ifndef _TESTMEMWRITE_H_
#define _TESTMEMWRITE_H_

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

void child(int rd_sock)
{
  int fd;
  bool mismatch = false;
  int again = 0;
  fprintf(stderr, "[%s:%d] child waiting for fd via rd_sock %d\n", __FUNCTION__, __LINE__, rd_sock);
  do {
    int msg;
    sock_fd_read(rd_sock, &msg, sizeof(msg), &fd);
    again = (fd < 0 && errno == EAGAIN);
  } while (again);
  fprintf(stderr, "[%s:%d] child got fd %d errno=%d\n", __FUNCTION__, __LINE__, fd, (fd >= 0) ? 0 : errno);

  if (fd == -1)
    exit(EINVAL);

  unsigned int *dstBuffer = (unsigned int *)portalMmap(fd, alloc_sz);
  fprintf(stderr, "child::dstBuffer = %p\n", dstBuffer);
  if (dstBuffer == (unsigned int *)-1)
    exit(ENODEV);

  unsigned int sg = 0;
  for (int i = 0; i < numWords; i++){
    mismatch |= (dstBuffer[i] != sg++);
    //fprintf(stderr, "%08x, %08x\n", dstBuffer[i], sg-1);
  }
  fprintf(stderr, "child::writeDone mismatch=%d\n", mismatch);
  munmap(dstBuffer, alloc_sz);
  close(fd);
  exit(mismatch);
}

void parent(int wr_sock)
{
  
  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "error: failed to init test_sem\n");
    exit(1);
  }

  fprintf(stderr, "parent::%s %s\n", __DATE__, __TIME__);

  device = new MemwriteRequestProxy(TileNames_MemwriteRequestS2H,1);
  deviceIndication = new MemwriteIndication(TileNames_MemwriteIndicationH2S,1);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(PlatformNames_MemServerRequestS2H);
  MMURequestProxy *dmap = new MMURequestProxy(PlatformNames_MMURequestS2H);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, PlatformNames_MemServerIndicationH2S);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, PlatformNames_MMUIndicationH2S);
  
  fprintf(stderr, "parent::allocating memory...\n");
  dstAlloc = portalAlloc(alloc_sz);
  dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  
  portalExec_start();

#ifdef FPGA0_CLOCK_FREQ
  long req_freq = FPGA0_CLOCK_FREQ;
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
#endif
  
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  
  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = 0xDEADBEEF;
  }
  
  portalDCacheFlushInval(dstAlloc, alloc_sz, dstBuffer);
  fprintf(stderr, "parent::flush and invalidate complete\n");

  // for(int i = 0; i < dstAlloc->header.numEntries; i++)
  //   fprintf(stderr, "%lx %lx\n", dstAlloc->entries[i].dma_address, dstAlloc->entries[i].length);

  // sleep(1);
  // dmap->addrRequest(ref_dstAlloc, 2*sizeof(unsigned int));
  // sleep(1);

  bool orig_test = true;

  if (orig_test){
    fprintf(stderr, "parent::starting write %08x\n", numWords);
    portalTimerStart(0);
    device->startWrite(ref_dstAlloc, 0, numWords, burstLen, iterCnt);
    sem_wait(&test_sem);
    uint64_t cycles = portalTimerLap(0);
    hostMemServerRequest->memoryTraffic(ChannelType_Write);
    uint64_t beats = hostMemServerIndication->receiveMemoryTraffic();
    float write_util = (float)beats/(float)cycles;
    fprintf(stderr, "   beats: %"PRIx64"\n", beats);
    fprintf(stderr, "numWords: %x\n", numWords);
    fprintf(stderr, "     est: %"PRIx64"\n", (beats*2)/iterCnt);
    fprintf(stderr, "memory write utilization (beats/cycle): %f\n", write_util);
    
    MonkitFile("perf.monkit")
      .setHwCycles(cycles)
      .setWriteBwUtil(write_util)
      .writeFile();

  } else {
    fprintf(stderr, "parent::new_test read %08x\n", numWords);
    int chunk = numWords >> 4;
    for(int i = 0; i < numWords; i+=chunk){
      device->startWrite(ref_dstAlloc, i, chunk, burstLen, 1);
      sem_wait(&test_sem);
    }
  }

  fprintf(stderr, "[%s:%d] send fd to child %d via wr_sock %d\n", __FUNCTION__, __LINE__, (int)dstAlloc, wr_sock);
  int msg = 22;
  sock_fd_write(wr_sock, &msg, sizeof(msg), (int)dstAlloc);
  munmap(dstBuffer, alloc_sz);
  close(dstAlloc);
}

#endif // _TESTMEMWRITE_H_
