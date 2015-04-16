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

#define NUMBER_OF_TESTS 8


class Main : public MainRequestWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == NUMBER_OF_TESTS)
      exit(0);
  }
  virtual void write_rf(uint16_t address, uint16_t data) {
    fprintf(stderr, "write_rf(%d 0x%02x)\n", address, data);
    incr_cnt();
  }
  virtual void read_rf(uint16_t address, uint16_t data) {
    fprintf(stderr, "read_rf(%d 0x%02x)\n", address, data);
    incr_cnt();
  }
  Main(unsigned int id) : MainRequestWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  Main *indication = new Main(IfcNames_MainRequestH2S);
  MainRequestProxy *device = new MainRequestProxy(IfcNames_MainRequestS2H);
  device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  fprintf(stderr, "Main::calling write_rf(11, 22, 33, 44)\n");
  device->write_rf(0, 0x11);
  device->write_rf(1, 0x22);
  device->write_rf(2, 0x33);
  device->write_rf(3, 0x44);
  fprintf(stderr, "Main::calling read_rf(0, 1, 2, 3)\n");
  device->read_rf(0,0);
  device->read_rf(1,0);
  device->read_rf(2,0);
  device->read_rf(3,0);
  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
