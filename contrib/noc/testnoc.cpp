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

#include "NocIndication.h"
#include "NocRequest.h"
#include "GeneratedTypes.h"

sem_t test_sem;

uint32_t lastheardby;
uint32_t lastto;
uint32_t lastmsg;

  NocRequestProxy *dev = 0;

class NocIndication : public NocIndicationWrapper
{
public:
  NocIndication(unsigned int id) : NocIndicationWrapper(id){};

  virtual void ack(uint32_t heardby, uint32_t to, uint32_t msg) {
    fprintf(stderr, "ack h %d t %d msg %08x\n", heardby, to, msg);
    lastheardby = heardby;
    lastto = to;
    lastmsg = msg;
    sem_post(&test_sem);
  }
};

void lastheardbyshouldbe(uint32_t heardby)
{
  if (lastheardby != heardby)
    printf("error, expected data %08x got %08x\n", heardby, lastheardby);
}

void lastmsgshouldbe(uint32_t msg)
{
  if (lastmsg != msg)
    printf("error, expected data %08x got %08x\n", msg, lastmsg);
}

void lasttoshouldbe(uint32_t to)
{
  if (lastto != to)
    printf("error, expected to address %08x got %08x\n", to, lastto);
}

void dosend(uint32_t from, uint32_t to, uint32_t msg)
{
  dev->send(from, to, msg);
  sem_wait(&test_sem);
  lastheardbyshouldbe(to);
  lasttoshouldbe(to);
  lastmsgshouldbe(msg);
}

void dotest()
{
  uint32_t from, to, msg;
  for (from = 0; from < 4; from += 1) {
    for (to = 0; to < 4; to += 1) {
      printf("send from %d to %d v %08x\n", from, to, (from << 16) + to);
      dosend(from, to, (from << 16) + to);
    }
  }
}

int main(int argc, const char **argv)
{
  
  NocIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  dev = new NocRequestProxy(IfcNames_NocRequest);

  deviceIndication = new NocIndication(IfcNames_NocIndication);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

    fprintf(stderr, "simple tests\n");
    
    dotest();
}
