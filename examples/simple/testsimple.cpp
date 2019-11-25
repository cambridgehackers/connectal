/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 * Copyright (c) 2016 Connectal Project
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
#include "SimpleRequest.h"
#include "simple.h"

int main(int argc, const char **argv)
{
  int32_t testval = 0x1234abcd, v1arg1[4], v1arg2[4];
  int16_t v2v[16];
  Simple indication(IfcNames_SimpleRequestH2S);
  SimpleRequestProxy *device = new SimpleRequestProxy(IfcNames_SimpleRequestS2H);
  device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  fprintf(stderr, "Main::calling say1(%d)\n", v1a);
  device->say1(v1a);  
  fprintf(stderr, "Main::calling say2(%d, %d)\n", v2a,v2b);
  device->say2(v2a,v2b);
  fprintf(stderr, "Main::calling say3(S1{a:%d,b:%d})\n", s1.a,s1.b);
  device->say3(s1);
  fprintf(stderr, "Main::calling say4(S2{a:%d,b:%d,c:%d})\n", s2.a,s2.b,s2.c);
  device->say4(s2);
  fprintf(stderr, "Main::calling say5(%08x, %016llx, %08x)\n", v5a, (long long)v5b, v5c);
  device->say5(v5a, v5b, v5c);  
  fprintf(stderr, "Main::calling say6(%08x, %016llx, %08x)\n", v6a, (long long)v6b, v6c);
  device->say6(v6a, v6b, v6c);  
  fprintf(stderr, "Main::calling say7(%08x, %08x)\n", s3.a, s3.e1);
  device->say7(s3);  
  bsvvector_Luint32_t_L128 vect;
  for (int i = 0; i < 128; i++)
    vect[i] = -i*32;
  fprintf(stderr, "Main::calling say8\n");
  device->say8(vect);  
  for (int i = 0; i < 4; i++) {
    v1arg1[i] = testval;
    v1arg2[i] = ~testval;
    testval = (testval << 4) | ((testval >> 28) & 0xf);
  }
  device->sayv1(v1arg1, v1arg2);
  testval = 0x12349876;
  for (int i = 0; i < 16; i++) {
    v2v[i] = testval;
    testval = (testval << 4) | ((testval >> 28) & 0xf);
  }
  device->sayv2(v2v);
  device->sayv3(v2v, 44);
  device->saypixels(xs, ys, zs);
  device->reftest1 ( 0xaabbcc, 0x11223344, 0xddeeff, 0x44332211, 0x123456, 0x87654321, 0x12, 0x34, 0x123456, 0x7654321, 0x34, 0x56, 0x77);
  fprintf(stderr, "Main::about to go to sleep\n");
  while(1)
    sleep(10);
}
