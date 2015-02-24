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
#include <semaphore.h>

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "FMComms1Request.h"
#include "FMComms1Indication.h"
#include "BlueScopeEventPIORequest.h"
#include "BlueScopeEventPIOIndication.h"

sem_t read_sem;
sem_t write_sem;
sem_t cv_sem;

int readBurstLen = 16;
int writeBurstLen = 16;


#ifndef BSIM
int numWords = 0x4096; // make sure to allocate at least one entry of each size
#else
int numWords = 0x4096;
#endif

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

class FMComms1Indication : public FMComms1IndicationWrapper
{

public:
  FMComms1Indication(unsigned int id) : FMComms1IndicationWrapper(id){}

  virtual void readStatus(unsigned iterCount, unsigned running){
    fprintf(stderr, "read %d %d\n", iterCount, running);
    sem_post(&read_sem);
  }
  virtual void writeStatus(unsigned iterCount, unsigned running){
    fprintf(stderr, "write %d %d\n", iterCount, running);
    sem_post(&write_sem);
  }
};

uint32_t counter_value = 0;

class BlueScopeEventPIOIndication : public BlueScopeEventPIOIndicationWrapper
{
public:
  BlueScopeEventPIOIndication(unsigned int id) : BlueScopeEventPIOIndicationWrapper(id){}

  virtual void reportEvent(uint32_t v, uint32_t timestamp ){
    fprintf(stderr, "BlueScopeEventPIO::reportEvent(%08x, %08x)\n", v, timestamp);
  }
  virtual void counterValue(uint32_t v){
    counter_value = v;
    sem_post(&cv_sem);
    fprintf(stderr, "BlueScopeEventPIO::counterValue value=%u\n", v);
    
  }
};


int main(int argc, const char **argv)
{
  int srcAlloc;
  int dstAlloc;
  unsigned int *srcBuffer = 0;
  unsigned int *dstBuffer = 0;


  FMComms1RequestProxy *device = 0;
  FMComms1Indication *deviceIndication = 0;
  BlueScopeEventPIORequestProxy *bluescope = 0;
  BlueScopeEventPIOIndication *bluescopeIndication = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  if(sem_init(&cv_sem, 1, 0)){
    fprintf(stderr, "failed to init cv_sem\n");
    exit(1);
  }

  device = new FMComms1RequestProxy(IfcNames_FMComms1Request);


  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);

  deviceIndication = new FMComms1Indication(IfcNames_FMComms1Indication);

  bluescope = new BlueScopeEventPIORequestProxy(IfcNames_BlueScopeEventPIORequest);
  bluescopeIndication = new BlueScopeEventPIOIndication(IfcNames_BlueScopeEventPIOIndication);

  fprintf(stderr, "NEW Main::portalExec_start()...\n");
  portalExec_start();

  fprintf(stderr, "Main::allocating memory...\n");
  srcAlloc = portalAlloc(alloc_sz);

  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  if ((char *) srcBuffer == MAP_FAILED) perror("srcBuffer mmap failed");
  assert ((char *) srcBuffer != MAP_FAILED);

  dstAlloc = portalAlloc(alloc_sz);

  dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  if ((char *) dstBuffer == MAP_FAILED) perror("dstBuffer mmap failed");
  assert ((char *) dstBuffer != MAP_FAILED);

  int status;
  status = setClockFrequency(0, 100000000, 0);
  /* FMComms1 refclk should be 30 MHz */
  status = setClockFrequency(1,  30000000, 0);
    
  portalDCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
  portalDCacheFlushInval(dstAlloc, alloc_sz, dstBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  bluescope->doReset();
  bluescope->setTriggerMask (0xFFFFFFFF);
  bluescope->getCounterValue();
  bluescope->enableIndications(1);
  sem_wait(&cv_sem);
  fprintf(stderr, "Main::initial BlueScopeEventPIO counterValue: %d\n", counter_value);

  device->getReadStatus();
  device->getWriteStatus();
  sem_wait(&read_sem);
  sem_wait(&write_sem);
  fprintf(stderr, "Main::after getStateDbg\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  fprintf(stderr, "ref_dstAlloc=%d\n", ref_dstAlloc);

  fprintf(stderr, "Main::starting read %08x\n", numWords);

  device->startRead(ref_srcAlloc, numWords, readBurstLen, 1);
  device->startWrite(ref_dstAlloc, numWords, writeBurstLen, 1);
  sem_wait(&read_sem);



   sleep(5);
  device->getReadStatus();
  device->getWriteStatus();
  sem_wait(&read_sem);
  sem_wait(&write_sem);
   sleep(5);
  fprintf(stderr, "Main::stopping reads\n");
  fprintf(stderr, "Main::stopping writes\n");
  device->startRead(ref_srcAlloc, numWords, readBurstLen, 0);
  device->startWrite(ref_dstAlloc, numWords, writeBurstLen, 0);
  sem_wait(&read_sem);
  sem_wait(&write_sem);

  bluescope->getCounterValue();
  fprintf(stderr, "Main::getCounter\n");
 
  sem_wait(&cv_sem);
  fprintf(stderr, "Main::final BlueScopeEventPIO counterValue: %d\n", counter_value);

  exit(0);
}
