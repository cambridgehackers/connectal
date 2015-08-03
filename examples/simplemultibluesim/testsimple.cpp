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

#include <GeneratedTypes.h>
#include "SimpleRequest.h"
#include "LinkRequest.h"

#define NUMBER_OF_TESTS 8

uint32_t v1a = 42;

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
E1 v7b = E1Choice2;
S3 s3 = { a: v7a, e1: v7b };


class SimpleRequest : public SimpleRequestWrapper
{
public:
  uint32_t cnt;
  void incr_cnt(){
    cnt++;
    fprintf(stderr, "saw %d responses\n", cnt);
    if (cnt == NUMBER_OF_TESTS)
      exit(0);
  }
  virtual void say1(uint32_t a) {
    fprintf(stderr, "say1(%d)\n", a);
    assert(a == v1a);
    incr_cnt();
  }
  virtual void say2(uint16_t a, uint16_t b) {
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
  void sayv1(const int32_t*arg1, const int32_t*arg2) {
    fprintf(stderr, "sayv1\n");
    for (int i = 0; i < 4; i++)
        fprintf(stderr, "    [%d] = 0x%x, 0x%x\n", i, arg1[i], arg2[i]);
    incr_cnt();
  }
  void sayv2(const int16_t* v) {
    fprintf(stderr, "sayv2\n");
    for (int i = 0; i < 16; i++)
        fprintf(stderr, "    [%d] = 0x%x\n", i, v[i] & 0xffff);
    incr_cnt();
  }
  void sayv3(const int16_t* v, int16_t count) {
    fprintf(stderr, "sayv3: count 0x%x\n", count);
    for (int i = 0; i < 16; i++)
        fprintf(stderr, "    [%d] = 0x%x\n", i, v[i] & 0xffff);
    incr_cnt();
  }
  void reftest1 ( const Address dst, const Intptr dst_stride, const Address src1, const Intptr i_src_stride1, const Address src2, const Intptr i_src_stride2, const Byte i_width, const Byte i_height, const int qpelInt, const int hasWeight, const Byte i_offset, const Byte i_scale, const Byte i_denom ) {
    fprintf(stderr, "reftest1: %x, %x, %x, %x, %x, %x, %x, %x, %x, %x, %x, %x, %x\n",
       (uint32_t)dst, (uint32_t)dst_stride, (uint32_t)src1, (uint32_t)i_src_stride1, (uint32_t)src2, (uint32_t)i_src_stride2, (uint32_t)i_width, (uint32_t)i_height, (uint32_t)qpelInt, (uint32_t)hasWeight, (uint32_t)i_offset, (uint32_t)i_scale, (uint32_t)i_denom );
    incr_cnt();
  }
  SimpleRequest(unsigned int id) : SimpleRequestWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  LinkRequestProxy linkRequest(IfcNames_LinkRequestS2H);
  SimpleRequest indication(IfcNames_SimpleRequestH2S);
  SimpleRequestProxy device(IfcNames_SimpleRequestS2H);
  linkRequest.pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */
  device.pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  const char *socketName = getenv("BLUESIM_SOCKET_NAME");
  if (!socketName) {
    fprintf(stderr, "Specify name of link socket to use BLUESIM_SOCKET_NAME");
    exit(1);
  }
  int listening = (strcmp(socketName, "socket1") == 0);

  fprintf(stderr, "linkRequest.start(%d) [socketName=%s]\n", listening, socketName);
  linkRequest.start(listening);

  if (1) {
    fprintf(stderr, "Main::calling say1(%d)\n", v1a);
    device.say1(v1a);
    fprintf(stderr, "Main::calling say2(%d, %d)\n", v2a,v2b);
    device.say2(v2a,v2b);
    fprintf(stderr, "Main::calling say3(S1{a:%d,b:%d})\n", s1.a,s1.b);
    device.say3(s1);
    fprintf(stderr, "Main::calling say4(S2{a:%d,b:%d,c:%d})\n", s2.a,s2.b,s2.c);
    device.say4(s2);
    fprintf(stderr, "Main::calling say5(%08x, %016llx, %08x)\n", v5a, (long long)v5b, v5c);
    device.say5(v5a, v5b, v5c);
    fprintf(stderr, "Main::calling say6(%08x, %016llx, %08x)\n", v6a, (long long)v6b, v6c);
    device.say6(v6a, v6b, v6c);
    fprintf(stderr, "Main::calling say7(%08x, %08x)\n", s3.a, s3.e1);
    device.say7(s3);
    bsvvector_Luint32_t_L128 vect;
    for (int i = 0; i < 128; i++)
      vect[i] = -i*32;
    fprintf(stderr, "Main::calling say8\n");
    device.say8(vect);
  }
  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
