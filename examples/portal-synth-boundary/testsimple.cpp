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
#include <unistd.h>
#include <assert.h>

#include "SimpleIndication.h"
#include "SimpleRequest.h"
#include "GeneratedTypes.h"


int v1a = 42;


class SimpleIndication : public SimpleIndicationWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 1)
      exit(0);
  }
  virtual void heard1(uint32_t a) {
    fprintf(stderr, "heard1(%d)\n", a);
    assert(a == v1a);
    incr_cnt();
  }
  SimpleIndication(unsigned int id) : SimpleIndicationWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  SimpleIndication *indication = new SimpleIndication(IfcNames_SimpleIndication);
  SimpleRequestProxy *device = new SimpleRequestProxy(IfcNames_SimpleRequest);

  fprintf(stderr, "Main::calling say1(%d)\n", v1a);
  device->say1(v1a);  

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
