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
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <semaphore.h>
#include <ctime>
#include <monkit.h>
#include <mp.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "SerialconfigIndicationWrapper.h"
#include "SerialconfigRequestProxy.h"
#include "GeneratedTypes.h"

sem_t test_sem;

class SerialconfigIndication : public SerialconfigIndicationWrapper
{
public:
  SerialconfigIndication(unsigned int id) : SerialconfigIndicationWrapper(id){};

  virtual void sendack(uint32_t tms, uint32_t tdi) {
    fprintf(stderr, "writeack tms %d tdi %d\n", tms,i);
    sem_post(&test_sem);
  }
  virtual void recvack(uint32_t tdo) {
    fprintf(stderr, "recvack tdo %d\n", tdo);
    sem_post(&test_sem);
  }
  virtual void stateack(uint32_t s1, uint32_t s2) {
    fprintf(stderr, "stateack s1 %d s2 %d\n", s1, s2);
    sem_post(&test_sem);
  }
};


void doreset(SerialconfigRequestProxy *dev)
{
  dev->write(1, 1);
  sem_wait(&test_sem);
  dev->write(1, 1);
  sem_wait(&test_sem);
  dev->write(1, 1);
  sem_wait(&test_sem);
  dev->write(1, 1);
  sem_wait(&test_sem);
  dev->write(1, 1);
  sem_wait(&test_sem);
}

int main(int argc, const char **argv)
{
  SerialconfigRequestProxy *device = 0;
  
  SerialconfigIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new SerialconfigRequestProxy(IfcNames_SerialconfigRequest);

  deviceIndication = new SerialconfigIndication(IfcNames_SerialconfigIndication);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

    fprintf(stderr, "simple tests\n");
    
    doreset();
    device->getstate
    device->write(0x12345, 0xdeadbeef);
    sem_wait(&test_sem);

    device->read(0xfeedface);
    sem_wait(&test_sem);


  }


