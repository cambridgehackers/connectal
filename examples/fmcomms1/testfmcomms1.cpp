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
#include <sys/mman.h>
#include <assert.h>
#include "dmaManager.h"
#include "FMComms1Request.h"
#include "FMComms1Indication.h"
#include "BlueScopeEventPIORequest.h"
#include "BlueScopeEventPIOIndication.h"
#include "fmci2c.h"

sem_t read_sem;
sem_t write_sem;
sem_t cv_sem;

int readBurstLen = 16;
int writeBurstLen = 16;

#define WHERE(x) fprintf(stdout, "at %s:%d\n",__FILE__, __LINE__)

#ifndef SIMULATION
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
    fprintf(stdout, "read %d %d\n", iterCount, running);
    sem_post(&read_sem);
  }
  virtual void writeStatus(unsigned iterCount, unsigned running){
    fprintf(stdout, "write %d %d\n", iterCount, running);
    sem_post(&write_sem);
  }
};

#define NUMEVENTS 4096
uint32_t counter_value = 0;
uint32_t events[NUMEVENTS];
uint32_t timestamps[NUMEVENTS];
int eventcount = 0;

class BlueScopeEventPIOIndication : public BlueScopeEventPIOIndicationWrapper
{
public:
  BlueScopeEventPIOIndication(unsigned int id) : BlueScopeEventPIOIndicationWrapper(id){}

  virtual void reportEvent(uint32_t v, uint32_t timestamp ){
    if (eventcount < NUMEVENTS) {
      events[eventcount] = v;
      timestamps[eventcount] = timestamp;
      eventcount += 1;
    }
  }
  virtual void counterValue(uint32_t v){
    counter_value = v;
    sem_post(&cv_sem);
    fprintf(stdout, "BlueScopeEventPIO::counterValue value=%u\n", v);
    
  }
};


int main(int argc, const char **argv)
{
  int i;
  int srcAlloc;
  int dstAlloc;
  unsigned int *srcBuffer = 0;
  unsigned int *dstBuffer = 0;


  FMComms1RequestProxy *device = 0;
  FMComms1Indication *deviceIndication = 0;
  BlueScopeEventPIORequestProxy *bluescope = 0;
  BlueScopeEventPIOIndication *bluescopeIndication = 0;

  fprintf(stdout, "Main::%s %s\n", __DATE__, __TIME__);

  if(sem_init(&cv_sem, 1, 0)){
    fprintf(stdout, "failed to init cv_sem\n");
    exit(1);
  }

  if(sem_init(&read_sem, 1, 0)){
    fprintf(stdout, "failed to init read_sem\n");
    exit(1);
  }

  if(sem_init(&write_sem, 1, 0)){
    fprintf(stdout, "failed to init write_sem\n");
    exit(1);
  }

  device = new FMComms1RequestProxy(IfcNames_FMComms1Request);
  DmaManager *dma = platformInit();
  deviceIndication = new FMComms1Indication(IfcNames_FMComms1Indication);
  bluescope = new BlueScopeEventPIORequestProxy(IfcNames_BlueScopeEventPIORequest);
  bluescopeIndication = new BlueScopeEventPIOIndication(IfcNames_BlueScopeEventPIOIndication);

  fprintf(stdout, "Main::allocating memory...\n");
  srcAlloc = portalAlloc(alloc_sz, 0);

  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  if ((char *) srcBuffer == MAP_FAILED) perror("srcBuffer mmap failed");
  assert ((char *) srcBuffer != MAP_FAILED);

  dstAlloc = portalAlloc(alloc_sz, 0);

  dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  if ((char *) dstBuffer == MAP_FAILED) perror("dstBuffer mmap failed");
  assert ((char *) dstBuffer != MAP_FAILED);

  int status;
  status = setClockFrequency(0, 100000000, 0);
  /* FMComms1 refclk should be 30 MHz */
  status = setClockFrequency(1,  30000000, 0);
    
  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
  fprintf(stdout, "Main::flush and invalidate complete\n");

  bluescope->doReset();
  WHERE();
  bluescope->setTriggerMask (0xFFFFFFFF);
  WHERE();
  bluescope->getCounterValue();
  WHERE();
  bluescope->enableIndications(1);
  WHERE();
  sem_wait(&cv_sem);
  fprintf(stdout, "Main::initial BlueScopeEventPIO counterValue: %d\n", counter_value);

  device->getReadStatus();
  device->getWriteStatus();
  sem_wait(&read_sem);
  sem_wait(&write_sem);
  fprintf(stdout, "Main::after getStateDbg\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stdout, "ref_srcAlloc=%d\n", ref_srcAlloc);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  fprintf(stdout, "ref_dstAlloc=%d\n", ref_dstAlloc);

  fprintf(stdout, "Main::starting read %08x\n", numWords);

  device->startRead(ref_srcAlloc, numWords, readBurstLen, 1);
  device->startWrite(ref_dstAlloc, numWords, writeBurstLen, 1);
  sem_wait(&read_sem);



   sleep(5);
  device->getReadStatus();
  device->getWriteStatus();
  sem_wait(&read_sem);
  sem_wait(&write_sem);
   sleep(5);
  fprintf(stdout, "Main::stopping reads\n");
  device->startRead(ref_srcAlloc, numWords, readBurstLen, 0);
  fprintf(stdout, "Main::stopping writes\n");
  device->startWrite(ref_dstAlloc, numWords, writeBurstLen, 0);
  device->getReadStatus();
  device->getWriteStatus();
  sem_wait(&read_sem);
  sem_wait(&write_sem);
  testi2c("/dev/i2c-1", 0x58);

  bluescope->getCounterValue();
  fprintf(stdout, "Main::getCounter\n");
 
  sem_wait(&cv_sem);
  
  fprintf(stdout, "Main::final BlueScopeEventPIO counterValue: %d\n", counter_value);
  fprintf(stdout, "received %d events\n", eventcount);
  for (i = 0; i < eventcount; i += 1) {
      fprintf(stdout, "reportEvent(0x%08x, 0x%08x)\n", events[i], timestamps[i]);
  }

  exit(0);
}
