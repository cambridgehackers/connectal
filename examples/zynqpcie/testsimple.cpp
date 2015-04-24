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

#include "Simple.h"
#include "GeneratedTypes.h"


int v1a = 42;

int v2a = 2;
int v2b = 4;

S2 s2 = {7, 8, 9};

S1 s1 = {3, 6};

uint32_t v5a = 0x00000000;
uint64_t v5b = 0xDEADBEEFFECAFECA;
uint32_t v5c = 0x00000001;

uint32_t v6a = 0xBBBBBBBB;
uint64_t v6b = 0x000000EFFECAFECA;
uint32_t v6c = 0xCCCCCCCC;

uint32_t v7a = 0xDADADADA;
E1 v7b = E1_E1Choice2;
S3 s3 = { a: v7a, e1: v7b };


class Simple : public SimpleWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 7)
      exit(0);
  }
  virtual void say1(uint32_t a) {
    fprintf(stderr, "say1(%d)\n", a);
    assert(a == v1a);
    incr_cnt();
  }
  virtual void say2(uint32_t a, uint32_t b) {
    fprintf(stderr, "say2(%d %d)\n", a, b);
    assert(a == v2a);
    assert(b == v2b);
    incr_cnt();
  }
  virtual void say3(S1 s){
    fprintf(stderr, "say3(S1{a:%d,b:%d})\n", s.a, s.b);
    assert(s.a == s1.a);
    assert(s.b == s1.b);
    incr_cnt();
  }
  virtual void say4(S2 s){
    fprintf(stderr, "say4(S2{a:%d,b:%d,c:%d})\n", s.a,s.b,s.c);
    assert(s.a == s2.a);
    assert(s.b == s2.b);
    assert(s.c == s2.c);
    incr_cnt();
  }
  virtual void say5(uint32_t a, uint64_t b, uint32_t c) {
    fprintf(stderr, "say5(%08x, %016llx, %08x)\n", a, (long long)b, c);
    assert(a == v5a);
    assert(b == v5b);
    assert(c == v5c);
    incr_cnt();
  }
  virtual void say6(uint32_t a, uint64_t b, uint32_t c) {
    fprintf(stderr, "say6(%08x, %016llx, %08x)\n", a, (long long)b, c);
    assert(a == v6a);
    assert(b == v6b);
    assert(c == v6c);
    incr_cnt();
  }
  virtual void say7(S3 v) {
    fprintf(stderr, "say7(%08x, %08x)\n", v.a, v.e1);
    assert(v.a == v7a);
    assert(v.e1 == v7b);
    incr_cnt();
  }
  virtual void say8 ( const bsvvector_Luint32_t_L128 v ) {
    fprintf(stderr, "say8\n");
    for (int i = 0; i < 128; i++)
        fprintf(stderr, "    [%d] = 0x%x\n", i, v[i]);
    incr_cnt();
  }
  Simple(unsigned int id) : SimpleWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  Simple *indication = new Simple(IfcNames_SimpleIndication);
  SimpleProxy *device = new SimpleProxy(IfcNames_SimpleRequest);
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

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
