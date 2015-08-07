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
#include "dmaManager.h"
#include "MemlatencyIndication.h"
#include "MemlatencyRequest.h"

sem_t read_done_sem;
sem_t write_done_sem;
int srcAlloc;
int dstAlloc;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
int numWords = 16 << 10;
size_t alloc_sz = numWords*sizeof(unsigned int);

unsigned int rd_latency = 0;
unsigned int num_reads = 0;

unsigned int wr_latency = 0;
unsigned int num_writes = 0;


class MemlatencyIndication : public MemlatencyIndicationWrapper
{

public:
  MemlatencyIndication(unsigned int id) : MemlatencyIndicationWrapper(id){}

  virtual void started(){
    fprintf(stderr, "started\n");
  }
  virtual void readLatency(uint32_t l) {
    fprintf(stderr, "readLatency %d\n", l);
    rd_latency += l;
    num_reads++;
  }
  virtual void writeLatency(uint32_t l){
    fprintf(stderr, "writeLatency %d\n", l);
    wr_latency += l;
    num_writes++;
  }
  virtual void readDone() {
    sem_post(&read_done_sem);
    fprintf(stderr, "readDone\n");
  }
  virtual void writeDone() {
    sem_post(&write_done_sem);
    fprintf(stderr, "writeDone\n");
  }
};


MemlatencyIndication *deviceIndication = 0;

int main(int argc, const char **argv)
{
  if(sem_init(&read_done_sem, 1, 0)){
    fprintf(stderr, "failed to init read_done_sem\n");
    exit(1);
  }
  if(sem_init(&write_done_sem, 1, 0)){
    fprintf(stderr, "failed to init write_done_sem\n");
    exit(1);
  }

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  MemlatencyRequestProxy device(IfcNames_MemlatencyRequestS2H);
  DmaManager *dma = platformInit();
  deviceIndication = new MemlatencyIndication(IfcNames_MemlatencyIndicationH2S);

  fprintf(stderr, "Main::allocating memory...\n");

  srcAlloc = portalAlloc(alloc_sz, 0);
  dstAlloc = portalAlloc(alloc_sz, 0);

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
    
  fprintf(stderr, "Main::starting mempcy numWords:%d\n", numWords);
  int burstLen = 16;
  device.start(ref_dstAlloc, ref_srcAlloc, burstLen);
  sem_wait(&read_done_sem);
  sem_wait(&write_done_sem);

  fprintf(stderr, "average read latency:  %d\n", (unsigned int)(((float)rd_latency)/((float)num_reads)));
  fprintf(stderr, "average write latency: %d\n", (unsigned int)(((float)wr_latency)/((float)num_writes)));

  return 0;
}
