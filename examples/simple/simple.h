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

#if 1
#define TEST_ASSERT(A) assert(A)
#else
#define TEST_ASSERT(A) {}
#endif

#define NUMBER_OF_TESTS 13

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
E1 v7b = E1Choice2;
S3 s3 = { a: v7a, e1: v7b };

bsvvector_Luint32_t_L2 xs = { 0xa1, 0xa2 };
bsvvector_Luint32_t_L2 ys = { 0xb1, 0xb2 };
bsvvector_Luint32_t_L2 zs = { 0xc1, 0xc2 };

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
  void saypixels ( const bsvvector_Luint32_t_L2 indxs, const bsvvector_Luint32_t_L2 indys, const bsvvector_Luint32_t_L2 indzs ) {
      fprintf(stderr, "saypixels\n");
      for (int i = 0; i < 2; i++) {
          fprintf(stderr, "xs[%d] = %08x ys[%d] = %08x zs[%d] = %08x\n",
                  i, indxs[i], i, indys[i], i, indzs[i]);
      }
      incr_cnt();
  }
  void reftest1 ( const Address dst, const Intptr dst_stride, const Address src1, const Intptr i_src_stride1, const Address src2, const Intptr i_src_stride2, const Byte i_width, const Byte i_height, const int qpelInt, const int hasWeight, const Byte i_offset, const Byte i_scale, const Byte i_denom ) {
    fprintf(stderr, "reftest1: %x, %x, %x, %x, %x, %x, %x, %x, %x, %x, %x, %x, %x\n",
       (uint32_t)dst, (uint32_t)dst_stride, (uint32_t)src1, (uint32_t)i_src_stride1, (uint32_t)src2, (uint32_t)i_src_stride2, (uint32_t)i_width, (uint32_t)i_height, (uint32_t)qpelInt, (uint32_t)hasWeight, (uint32_t)i_offset, (uint32_t)i_scale, (uint32_t)i_denom );
    incr_cnt();
  }
  Simple(unsigned int id, PortalTransportFunctions *transport = 0, void *param = 0, PortalPoller *poller = 0)
    : SimpleRequestWrapper(id, transport, param, poller), cnt(0){}
};
