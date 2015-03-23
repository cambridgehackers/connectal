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
#include <assert.h>

#include "MainRequest.h"

#define NUMBER_OF_TESTS 1


int v2a = 2;
int v2b = 4;



class Main : public MainRequestWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == NUMBER_OF_TESTS)
      exit(0);
  }
  virtual void write_rf(uint16_t address, uint16_t data) {
    fprintf(stderr, "write_rf(%d %d)\n", address, data);
    incr_cnt();
  }
  virtual void read_rf(uint16_t address, uint16_t data) {
    fprintf(stderr, "read_rf(%d %d)\n", address, data);
    incr_cnt();
  }
  Main(unsigned int id) : MainRequestWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  Main *indication = new Main(IfcNames_MainRequestH2S);
  MainRequestProxy *device = new MainRequestProxy(IfcNames_MainRequestS2H);
  device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  portalExec_start();

  v2a = 1;
  v2b = 0x11;
  fprintf(stderr, "Main::calling write_rf(%d, %d)\n", v2a,v2b);
  device->write_rf(v2a, v2b);
  fprintf(stderr, "Main::calling read_rf(%d, %d)\n", v2a,v2b);
  device->read_rf(v2a,0);
  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
