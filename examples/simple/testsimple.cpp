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
#include "SimpleRequest.h"

#if 1
#define TEST_ASSERT(A) assert(A)
#else
#define TEST_ASSERT(A) {}
#endif

#define NUMBER_OF_TESTS 12

uint32_t v1a = 42;
uint32_t v2a = 2;
uint32_t v2b = 4;
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

class Simple : public SimpleRequestWrapper
{  
public:
  uint32_t cnt;
  uint32_t times;
  void incr_cnt(){
    if (++cnt == NUMBER_OF_TESTS)
      exit(0);
  }
  void say1(uint32_t a) {
    fprintf(stderr, "say1(%d)\n", a);
    TEST_ASSERT(a == v1a);
    incr_cnt();
  }
  void say2(uint16_t a, uint16_t b) {
    fprintf(stderr, "say2(%d %d)\n", a, b);
    TEST_ASSERT(a == v2a);
    TEST_ASSERT(b == v2b);
    incr_cnt();
  }
  void say3(S1 s){
    fprintf(stderr, "say3(S1{a:%d,b:%d})\n", s.a, s.b);
    TEST_ASSERT(s.a == s1.a);
    TEST_ASSERT(s.b == s1.b);
    incr_cnt();
  }
  void say4(S2 s){
    fprintf(stderr, "say4(S2{a:%d,b:%d,c:%d})\n", s.a,s.b,s.c);
    TEST_ASSERT(s.a == s2.a);
    TEST_ASSERT(s.b == s2.b);
    TEST_ASSERT(s.c == s2.c);
    incr_cnt();
  }
  void say5(uint32_t a, uint64_t b, uint32_t c) {
    fprintf(stderr, "say5(%08x, %016llx, %08x)\n", a, (long long)b, c);
    TEST_ASSERT(a == v5a);
    TEST_ASSERT(b == v5b);
    TEST_ASSERT(c == v5c);
    incr_cnt();
  }
  void say6(uint32_t a, uint64_t b, uint32_t c) {
    fprintf(stderr, "say6(%08x, %016llx, %08x)\n", a, (long long)b, c);
    TEST_ASSERT(a == v6a);
    TEST_ASSERT(b == v6b);
    TEST_ASSERT(c == v6c);
    incr_cnt();
  }
  void say7(S3 v) {
    fprintf(stderr, "say7(%08x, %08x)\n", v.a, v.e1);
    TEST_ASSERT(v.a == v7a);
    TEST_ASSERT(v.e1 == v7b);
    incr_cnt();
  }
  void say8 ( const bsvvector_Luint32_t_L128 v ) {
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
  Simple(unsigned int id) : SimpleRequestWrapper(id), cnt(0){}
};

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
  device->reftest1 ( 0xaabbcc, 0x11223344, 0xddeeff, 0x44332211, 0x123456, 0x87654321, 0x12, 0x34, 0x123456, 0x7654321, 0x34, 0x56, 0x77);
  fprintf(stderr, "Main::about to go to sleep\n");
  while(1)
    sleep(10);
}
