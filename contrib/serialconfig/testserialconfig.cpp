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
#include <sys/types.h>
#include <sys/stat.h>

#include "SerialconfigIndication.h"
#include "SerialconfigRequest.h"
#include "GeneratedTypes.h"

sem_t test_sem;

uint32_t lasta;
uint32_t lastd;

static SerialconfigRequestProxy *serialconfigRequestProxy = 0;

class SerialconfigIndication : public SerialconfigIndicationWrapper
{
public:
  SerialconfigIndication(unsigned int id) : SerialconfigIndicationWrapper(id){};

  virtual void ack(uint32_t a, uint32_t d) {
    fprintf(stderr, "ack a %x d %x\n", a, d);
    lasta = a;
    lastd = d;
    sem_post(&test_sem);
  }
};

void lastdshouldbe(uint32_t v)
{
  if (lastd != v)
    printf("error, expected data %08x got %08x\n", v, lastd);
}
void lastashouldbe(uint32_t a)
{
  if ((lasta & ~1) != a)
    printf("error, expected address %08x got %08x\n", a, lasta & ~1);
}

void doread(uint32_t a, uint32_t expect)
{
  serialconfigRequestProxy->send(a & ~1, 0xfeedface);
  sem_wait(&test_sem);
  lastashouldbe(a);
  lastdshouldbe(expect);
}

void dowrite(uint32_t a, uint32_t d)
{
  serialconfigRequestProxy->send(a | 1, d);
  sem_wait(&test_sem);
  lastashouldbe(a);
  lastdshouldbe(d);
}

void dotest()
{
  dowrite(0x0, 0xf00f00);

  dowrite(0x11110000, 0x00000000);
  dowrite(0x22220000, 0x00000000);
  dowrite(0x33330000, 0x00000000);
  dowrite(0x44440000, 0x00000000);

  doread(0x11110000, 0x00000000);
  doread(0x22220000, 0x00000000);
  doread(0x33330000, 0x00000000);
  doread(0x44440000, 0x00000000);


  dowrite(0x11110000, 0x11111111);
  dowrite(0x22220000, 0x22222222);
  dowrite(0x33330000, 0x33333333);
  dowrite(0x44440000, 0x44444444);

  doread(0x11110000, 0x11111111);
  doread(0x22220000, 0x00222222);
  doread(0x33330000, 0x00003333);
  doread(0x44440000, 0x00000044);


  dowrite(0x0, 0xdeadbeef);
  doread(0x0, 0xfeedface);
}

int main(int argc, const char **argv)
{
  
  SerialconfigIndication serialconfigIndication(IfcNames_SerialconfigIndicationH2S);

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);

  serialconfigRequestProxy = new SerialconfigRequestProxy(IfcNames_SerialconfigRequestS2H);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

    fprintf(stderr, "simple tests\n");
    dotest();
}
