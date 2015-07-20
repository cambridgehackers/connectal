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
#include <assert.h>
#include "MifoTestIndication.h"
#include "MifoTestRequest.h"

static uint32_t vs[4] = { 22, 0, 1, 2};

class MifoTestIndication : public MifoTestIndicationWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == (32+0))
      exit(0);
  }
  virtual void mifo32(uint32_t a) {
    uint32_t ea = vs[cnt % 4];
    fprintf(stderr, "mifo32(%d expected %d)\n", a, ea);
    assert(a == ea);
    incr_cnt();
  }
  virtual void mifo64(uint32_t a, uint32_t b) {
    uint32_t ea = vs[cnt % 4];
    uint32_t eb = vs[(cnt+1) % 4];
    fprintf(stderr, "mifo64(%d,%d) expected (%d,%d)\n", a, b, ea, eb);
    assert(a == ea);
    assert(b == eb);
    incr_cnt();
    incr_cnt();
  }
  virtual void fimo64(uint32_t a, uint32_t b) {
    uint32_t ea = 68;
    uint32_t eb = 47;
    fprintf(stderr, "fimo64(%d,%d) expected (%d,%d)\n", a, b, ea, eb);
    assert(a == ea);
    assert(b == eb);
    //incr_cnt();
    //incr_cnt();
  }
  virtual void fimo96(uint32_t a, uint32_t b, uint32_t c) {
    uint32_t ea = 68;
    uint32_t eb = 47;
    uint32_t ec = 22;
    fprintf(stderr, "fimo96(%d,%d,%d) expected (%d,%d,%d)\n", a, b, c, ea, eb, ec);
    assert(a == ea);
    assert(b == eb);
    assert(c == ec);
    //incr_cnt();
    //incr_cnt();
  }
  virtual void fimo128(uint32_t a, uint32_t b, uint32_t c, uint32_t d) {
    uint32_t ea = 68;
    uint32_t eb = 47;
    uint32_t ec = 22;
    uint32_t ed = 23;
    fprintf(stderr, "fimo128(%d,%d,%d,%d) expected (%d,%d,%d,%d)\n", a, b, c, d, ea, eb, ec, ed);
    assert(a == ea);
    assert(b == eb);
    assert(c == ec);
    assert(d == ed);
    //incr_cnt();
    //incr_cnt();
  }

  MifoTestIndication(unsigned int id) : MifoTestIndicationWrapper(id), cnt(0){}
};

int main(int argc, const char **argv)
{
  MifoTestIndication indication(IfcNames_MifoTestIndicationH2S);
  MifoTestRequestProxy *device = new MifoTestRequestProxy(IfcNames_MifoTestRequestS2H);

  device->fimo32(68);
  sleep(1);
  device->fimo32(47);
  sleep(1);
  device->fimo32(22);
  sleep(1);
  device->fimo32(23);
  sleep(1);

  fprintf(stderr, "Main::calling mifo32(%d)\n", 22);
  device->mifo32(4, 22, 0, 1, 2);
  sleep(1);

  device->mifo32(1, 22, 7, 7, 7);
  sleep(1);
  device->mifo32(1, 0, 7, 7, 7);
  sleep(1);
  device->mifo32(1, 1, 7, 7, 7);
  sleep(1);
  device->mifo32(1, 2, 7, 7, 7);
  sleep(1);

  device->mifo32(2, 22, 0, 7, 7);
  sleep(1);
  device->mifo32(2, 1, 2, 7, 7);
  sleep(1);
  device->mifo32(1, 22, 7, 7, 7);
  sleep(1);
  device->mifo32(3, 0, 1, 2, 7);
  sleep(1);

  device->mifo64(4, 22, 0, 1, 2);
  sleep(1);

  device->mifo64(1, 22, 7, 7, 7);
  sleep(1);
  device->mifo64(1, 0, 7, 7, 7);
  sleep(1);
  device->mifo64(1, 1, 7, 7, 7);
  sleep(1);
  device->mifo64(1, 2, 7, 7, 7);
  sleep(1);

  device->mifo64(1, 22, 7, 7, 7);
  sleep(1);
  device->mifo64(3, 0, 1, 2, 7);
  sleep(1);
  device->mifo64(3, 22, 0, 1, 7);
  sleep(1);
  device->mifo64(1, 2, 7, 7, 7);
  sleep(1);

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
