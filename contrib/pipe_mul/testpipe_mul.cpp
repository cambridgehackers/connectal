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

#include "PipeMulIndication.h"
#include "PipeMulRequest.h"
#include "GeneratedTypes.h"


class PipeMulIndication : public PipeMulIndicationWrapper
{
public:
    virtual void res(uint32_t v) {
      fprintf(stderr, "res: %d\n", v);
      exit(0);
    }
    PipeMulIndication(unsigned int id) : PipeMulIndicationWrapper(id) {}
};


int main(int argc, const char **argv)
{
  PipeMulIndication *indication = new PipeMulIndication(IfcNames_PipeMulIndication);
  PipeMulRequestProxy *device = new PipeMulRequestProxy(IfcNames_PipeMulRequest);
  device->mul(3,4);  
  while(true);
}
