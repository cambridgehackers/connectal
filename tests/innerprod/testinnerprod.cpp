/* Copyright (c) 2015 The Connectal Project
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

#include "InnerProdRequest.h"
#include "InnerProdIndication.h"

const int NUMBER_OF_TESTS = 1;

class InnerProd : public InnerProdIndicationWrapper
{  
    int cnt;
public:
  void incr_cnt(){
    if (++cnt == NUMBER_OF_TESTS)
      exit(0);
  }
  void innerProd(uint64_t v) {
    fprintf(stderr, "innerProd v=%llx\n", (long long)v);
  }
    InnerProd(unsigned int id) : InnerProdIndicationWrapper(id), cnt(0) {}
};

int main(int argc, const char **argv)
{
    InnerProd ind(IfcNames_InnerProdIndicationH2S);
    InnerProdRequestProxy device(IfcNames_InnerProdRequestS2H);
    device.pint.busyType = BUSY_SPIN;

    fprintf(stderr, "[%s:%d] waiting for response\n", __FILE__, __LINE__);
    int alumode = 0x35;
    int inmode = 0;
    int opmode = 0;
    device.innerProd(0x0080, 0x0f80, 1, 1, alumode, inmode, opmode);
    device.innerProd(0xa5a5, 0x5a5a, 1, 1, alumode, inmode, opmode);
    for (int times = 0; times < 100; times++)
	sleep(1);
    device.finish();
}

