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
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/time.h>
#include <semaphore.h>
#include "StdDmaIndication.h"

#include "DmaConfigProxy.h"
#include "GeneratedTypes.h"
#include "PerfIndicationWrapper.h"
#include "PerfRequestProxy.h"

sem_t copy_sem;

PerfRequestProxy *device = 0;
DmaConfigProxy *dma = 0;
  
PortalAlloc *srcAlloc;
PortalAlloc *dstAlloc;
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

void exit_test()
{
  fprintf(stderr, "testperf finished count=%d memcmp_fail=%d\n", finishedCount, memcmp_fail);
  exit(memcmp_fail);
}

class PerfIndication : public PerfIndicationWrapper
{

public:
  PerfIndication(const char* devname, unsigned int addrbits) : PerfIndicationWrapper(devname,addrbits){}
  PerfIndication(unsigned int id) : PerfIndicationWrapper(id){}


  virtual void started(unsigned long words){
    // fprintf(stderr, "started: words=%ld\n", words);
  }
  virtual void readWordResult ( unsigned long v ){
    dump("readWordResult: ", (char*)&v, sizeof(v));
  }
  virtual void done(unsigned long v) {
    finishedCount += 1;
    sem_post(&copy_sem);
  }
  virtual void rData ( unsigned long long v ){
    dump("rData: ", (char*)&v, sizeof(v));
  }
  virtual void readReq(unsigned long v){
    //fprintf(stderr, "readReq %lx\n", v);
  }
  virtual void writeReq(unsigned long v){
    //fprintf(stderr, "writeReq %lx\n", v);
  }
  virtual void writeAck(unsigned long v){
    //fprintf(stderr, "writeAck %lx\n", v);
  }
  virtual void reportStateDbg(unsigned long srcGen, unsigned long streamRdCnt, 
			      unsigned long streamWrCnt, unsigned long writeInProg, 
			      unsigned long dataMismatch){
    fprintf(stderr, "Perf::reportStateDbg: srcGen=%ld, streamRdCnt=%ld, streamWrCnt=%ld, writeInProg=%ld, dataMismatch=%ld\n", 
	    srcGen, streamRdCnt, streamWrCnt, writeInProg, dataMismatch);
  }  
};
PerfIndication *deviceIndication = 0;
DmaIndication *dmaIndication = 0;


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

int dotest(unsigned size)
{
  struct timeval start, stop;
  unsigned loops = 1;
  unsigned int i;
  long long interval;
  for(;;) {
    finishedCount = 0;
    fprintf(stderr, "loop = %d\n", loops);
    gettimeofday(&start, NULL);
    for (i = 0; i < loops; i += 1) {
      device->startCopy(ref_dstAlloc, ref_srcAlloc, numWords);
      sem_wait(&copy_sem);
    }
    gettimeofday(&stop, NULL);
    interval = deltatime(start, stop);
    if (interval >= 500000) break;
    loops <<= 1;
  }
  fprintf(stderr, "block size %d microseconds %lld\n", size*16, interval / loops); 
}

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;


  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  device = new PerfRequestProxy(IfcNames_PerfRequest);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);

  deviceIndication = new PerfIndication(IfcNames_PerfIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  fprintf(stderr, "Main::allocating memory...\n");

  dma->alloc(alloc_sz, &srcAlloc);
  dma->alloc(alloc_sz, &dstAlloc);

  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
  dstBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstAlloc->header.fd, 0);

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "error creating exec thread\n");
    exit(1);
  }


  dma->dCacheFlushInval(srcAlloc, srcBuffer);
  dma->dCacheFlushInval(dstAlloc, dstBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  ref_srcAlloc = dma->reference(srcAlloc);
  ref_dstAlloc = dma->reference(dstAlloc);
  
  for (numWords = 16; numWords < (1 << 20); numWords <<= 1){
    
    fprintf(stderr, "Main::starting mempcy numWords:%d\n", numWords);
 
    dotest(numWords);
  }

  device->getStateDbg();
  fprintf(stderr, "Main::sleeping\n");
  while(1){sleep(1);}
}
