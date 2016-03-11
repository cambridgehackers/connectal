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
#include <stdlib.h>
#include <semaphore.h>
#include <unistd.h>

#include "FibIndication.h"
#include "FibRequest.h"
#include "GeneratedTypes.h"

sem_t test_sem;

class FibIndication : public FibIndicationWrapper
{
public:
    virtual void fibresult(uint32_t v) {
      fprintf(stderr, "fibresult: %d\n", v);
	sem_post(&test_sem);
    }
    FibIndication(unsigned int id) : FibIndicationWrapper(id) {}
};

static FibRequestProxy *fibRequestProxy = 0;
FibIndication *fibIndication;


int main(int argc, const char **argv)
{
  int i;
  // these use the default poller

  fibIndication = new FibIndication(IfcNames_FibIndicationH2S);
  fibRequestProxy = new FibRequestProxy(IfcNames_FibRequestS2H);
  
  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }
  for (i = 0; i < 20; i += 1) {
    fprintf(stderr, "fib(%d)\n", i);
    fibRequestProxy->fib(i);
    sem_wait(&test_sem);
  }

  return 0;
}
