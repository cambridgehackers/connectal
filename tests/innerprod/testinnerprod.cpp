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
    if (++cnt == NUMBER_OF_TILES)
      exit(0);
  }
  void innerProd(uint16_t t, uint16_t v) {
    fprintf(stderr, "%d: t=%03d innerProd v=%x\n", cnt, t, v);
    incr_cnt();
  }
    InnerProd(unsigned int id) : InnerProdIndicationWrapper(id), cnt(0) {}
};

int main(int argc, const char **argv)
{
    InnerProd ind(IfcNames_InnerProdIndicationH2S);
    InnerProdRequestProxy device(IfcNames_InnerProdRequestS2H);
    device.pint.busyType = BUSY_SPIN;

    fprintf(stderr, "[%s:%d] waiting for response\n", __FILE__, __LINE__);
    for (int tile = 0; tile < NUMBER_OF_TILES; tile++) {
      device.innerProd(tile, 0x0080, 1, 0, 1);
      device.innerProd(tile, 0x0000, 0, 0, 1);
      device.innerProd(tile, 0x0100, 0, 0, 1);
      device.innerProd(tile, 0x0080, 0, 0, 1);
      device.innerProd(tile, 0x0100, 0, 0, 1);
      device.innerProd(tile, 0x0200, 0, 1, 1);
    }
    for (int tile = 0; tile < NUMBER_OF_TILES; tile++) {
      device.innerProd(tile, 0x0080, 1, 0, 0);
      device.innerProd(tile, 0x0000, 0, 0, 0);
      device.innerProd(tile, 0x0080, 0, 0, 0);
      device.innerProd(tile, 0x0080, 0, 0, 0);
      device.innerProd(tile, 0x1000, 0, 0, 0);
      device.innerProd(tile, 0x1000, 0, 1, 0);
    }
    for (int times = 0; times < 40; times++)
	sleep(1);
    device.finish();
}

