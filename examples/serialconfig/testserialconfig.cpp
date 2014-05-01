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

  virtual void writeack(uint32_t a) {
    fprintf(stderr, "writeack %p\n", a);
    sem_post(&test_sem);
  }
  virtual void readdata(uint32_t a, uint32_t d) {
    fprintf(stderr, "writeack %p %p\n", a, d);
    sem_post(&test_sem);
  }
};


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
    
    init_timer();
    start_timer(0);


    fprintf(stderr, "elapsed time (hw cycles): %zd\n", lap_timer(0));
    

    device->write(0x12345, 0xdeadbeef);
    sem_wait(&test_sem);

    device->read(0xfeedface);
    sem_wait(&test_sem);

    uint64_t cycles;
    uint64_t beats;

    fprintf(stderr, "starting algorithm A\n");

    init_timer();
    start_timer(0);

    cycles = lap_timer(0);

    fprintf(stderr, "hw cycles: %f\n", (float)cycles);

  }


