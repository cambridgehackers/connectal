
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <pthread.h>

#include "YuvIndication.h"
#include "YuvRequest.h"
#include "GeneratedTypes.h"

struct rgb {
  unsigned char r;
  unsigned char g;
  unsigned char b;
  int operator==(const struct rgb &o) { return r == o.r && g == o.g && b == o.b; }
};
struct yuv {
  unsigned char y;
  unsigned char u;
  unsigned char v;
  int operator==(const struct yuv &o) { return y == o.y && u == o.u && v == o.v; }
};

struct rgb expected_rgb;
struct yuv expected_yuv;

static int numTests = 0;
class YuvIndication : public YuvIndicationWrapper
{  
public:
  int cnt;
  void incr_cnt(){
    if (++cnt >= numTests)
      exit(0);
  }
  void rgb(uint8_t r, uint8_t g, uint8_t b) {
    fprintf(stderr, "rgb(%d,%d,%d)\n", r, g, b);
    struct rgb answer = {r, g, b};
    assert(expected_rgb == answer);
    incr_cnt();
  }
  void yuv(uint8_t y, uint8_t u, uint8_t v) {
    fprintf(stderr, "yuv(%d,%d,%d)\n", y, u, v);
    struct yuv answer = {y,u,v};
    assert(expected_yuv == answer);
    incr_cnt();
  }
  void yyuv(uint8_t yy, uint8_t uv) {
    fprintf(stderr, "yyuv(%d,%d)\n", yy, uv);
    //    assert(a == v1a);
    incr_cnt();
  }

  YuvIndication(unsigned int id) : YuvIndicationWrapper(id), cnt(0){}
};

struct yuv rgbtoyuv(unsigned short r, unsigned short g, unsigned short b)
{
  unsigned char y = ( 77*r + 150*g +  29*b + 0) >> 8;
  unsigned char u = (-43*r -  85*g + 128*b + 128) >> 8;
  unsigned char v = (128*r - 107*g -  21*b + 128) >> 8;
  fprintf(stderr, "rgb %d,%d,%d -> yuv %d,%d,%d\n", r, g, b, y, u, v);
  struct yuv yuvret;
  yuvret.y = y;
  yuvret.u = u;
  yuvret.v = v;
  return yuvret;
}

int main(int argc, const char **argv)
{
  YuvIndication indication(IfcNames_YuvIndicationH2S);
  YuvRequestProxy *device = new YuvRequestProxy(IfcNames_YuvRequestS2H);

  struct rgb tests[] = {
    { 0, 0, 0 },
    { 1, 2, 3 },
    { 128, 0, 0 },
    { 0, 128, 0 },
    { 0, 0, 128 },
    { 255, 0, 0 },
    { 0, 255, 0 },
    { 0, 0, 255 },
    { 255, 255, 255 },
  };

  numTests++;

  for (unsigned int i = 0; i < sizeof(tests)/sizeof(struct rgb); i++) {
    expected_rgb = tests[i];
    expected_yuv = rgbtoyuv(tests[i].r, tests[i].g, tests[i].b);
    numTests++; device->toRgb(tests[i].r, tests[i].g, tests[i].b);
    numTests++; device->toYuv(tests[i].r, tests[i].g, tests[i].b);
    numTests++; device->toYyuv(tests[i].r, tests[i].g, tests[i].b);
    sleep(1);
  }

  expected_rgb = tests[0];
  device->toRgb(tests[0].r, tests[0].g, tests[0].b); // now we're done

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
