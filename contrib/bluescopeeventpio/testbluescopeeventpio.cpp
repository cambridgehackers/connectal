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
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <monkit.h>
#include <semaphore.h>

#include "BlueScopeEventPIOIndication.h"
#include "BlueScopeEventPIORequest.h"
#include "SignalGenIndication.h"
#include "SignalGenRequest.h"

sem_t done_sem;
sem_t cv_sem;
unsigned int counter_value = 0;

bool finished = false;


void exit_test()
{
  fprintf(stderr, "test finished\n");
  exit(0);
}

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

class SignalGenIndication : public SignalGenIndicationWrapper
{
public:
  SignalGenIndication(unsigned int id) : SignalGenIndicationWrapper(id){}

  virtual void ack1(unsigned int d1 ){
    fprintf(stderr, "SignalGen::ack1(%d)\n", d1);
  }
};

// we can use the data synchronization barrier instead of flushing the 
// cache only because the ps7 is configured to run in buffered-write mode
//
// an opc2 of '4' and CRm of 'c10' encodes "CP15DSB, Data Synchronization Barrier 
// operation". this is a legal instruction to execute in non-privileged mode (mdk)
//
// #define DATA_SYNC_BARRIER   __asm __volatile( "MCR p15, 0, %0, c7, c10, 4" ::  "r" (0) );

int main(int argc, const char **argv)
{
  BlueScopeEventPIORequestProxy *bluescope = 0;
  BlueScopeEventPIOIndication *bluescopeIndication = 0;
  SignalGenRequestProxy *signalgen = 0;
  SignalGenIndication *signalgenIndication = 0;
  int i;

  if(sem_init(&done_sem, 1, 0)){
    fprintf(stderr, "failed to init done_sem\n");
    exit(1);
  }
  if(sem_init(&cv_sem, 1, 0)){
    fprintf(stderr, "failed to init cv_sem\n");
    exit(1);
  }

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  bluescope = new BlueScopeEventPIORequestProxy(IfcNames_BlueScopeEventPIORequest);

  bluescopeIndication = new BlueScopeEventPIOIndication(IfcNames_BlueScopeEventPIOIndication);

  signalgen = new SignalGenRequestProxy(IfcNames_SignalGenRequest);
  signalgenIndication = new SignalGenIndication(IfcNames_SignalGenIndication);

  bluescope->doReset();
  bluescope->setTriggerMask (0xFFFFFFFF);
  bluescope->getCounterValue();
  bluescope->enableIndications(1);
  sem_wait(&cv_sem);
  fprintf(stderr, "Main::initial BlueScopeEventPIO counterValue: %d\n", counter_value);

  sleep(1);
  signalgen->send1(0x1);
  fprintf(stderr, "Main::send1\n");
  signalgen->send1(0x2);
  fprintf(stderr, "Main::send1\n");
  signalgen->send1(0x3);
  fprintf(stderr, "Main::send1\n");
  signalgen->send1(0x4);
  fprintf(stderr, "Main::send1\n");
  bluescope->getCounterValue();
  fprintf(stderr, "Main::getCounter\n");
 
  sem_wait(&cv_sem);
  fprintf(stderr, "Main::final BlueScopeEventPIO counterValue: %d\n", counter_value);

  // test here
  // XXX print event buffer
  sleep(2);
  exit_test();
}
