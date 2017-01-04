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
#include "dmaManager.h"
#include "manualMMUIndication.h"

#if 1
#define TEST_ASSERT(A) assert(A)
#else
#define TEST_ASSERT(A) {}
#endif

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

class Simple : public SimpleRequestWrapper
{  
public:
  uint32_t cnt;
  uint32_t times;
  sem_t sem;
  void wait() {
    sem_wait(&sem);
    cnt = 0;
  }
  void incr_cnt(){
    if (++cnt == 7*times)
      sem_post(&sem);
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
  Simple(unsigned int id, unsigned int numtimes=1, PortalTransportFunctions *item=0, void *param = 0) : SimpleRequestWrapper(id, item, param), cnt(0), times(numtimes) {
    sem_init(&sem, 0, 0);
  }
};

DmaManager *dma;
Simple *indication;
int main(int argc, const char **argv)
{
    int verbose = 1;
    int numtimes = 10;
    int wait_per_iter = 1;
    uint32_t alloc_sz = 32768;
    dma = platformInit();

//#define FF {dma}
#define FF SHARED_DMA(PlatformIfcNames_MMURequestS2H, PlatformIfcNames_MMUIndicationH2S)
    PortalSharedParam parami = {FF, alloc_sz, SHARED_HARDWARE(IfcNames_SimpleRequestPipesH2S)};
    indication = new Simple(IfcNames_SimpleRequestH2S,
			    (wait_per_iter) ? 1 : numtimes
			    , &transportShared, &parami
			    );
    PortalSharedParam paramr = {FF, alloc_sz, SHARED_HARDWARE(IfcNames_SimpleRequestPipesS2H)};
    SimpleRequestProxy *device = new SimpleRequestProxy(IfcNames_SimpleRequestS2H, &transportShared, &paramr);

    // currently no interrupts on shared memory portals, so timeout after 1ms
    defaultPoller->timeout = 100;

    for (int i = 0; i < numtimes; i++) {
      if (verbose) fprintf(stderr, "Main::calling say1(%d)\n", v1a);
      device->say1(v1a);  
      if (verbose) fprintf(stderr, "Main::calling say2(%d, %d)\n", v2a,v2b);
      device->say2(v2a,v2b);
      if (verbose) fprintf(stderr, "Main::calling say3(S1{a:%d,b:%d})\n", s1.a,s1.b);
      device->say3(s1);
      if (verbose) fprintf(stderr, "Main::calling say4(S2{a:%d,b:%d,c:%d})\n", s2.a,s2.b,s2.c);
      device->say4(s2);
      if (verbose) fprintf(stderr, "Main::calling say5(%08x, %016llx, %08x)\n", v5a, (long long)v5b, v5c);
      device->say5(v5a, v5b, v5c);  
      if (verbose) fprintf(stderr, "Main::calling say6(%08x, %016llx, %08x)\n", v6a, (long long)v6b, v6c);
      device->say6(v6a, v6b, v6c);  
      if (verbose) fprintf(stderr, "Main::calling say7(%08x, %08x)\n", s3.a, s3.e1);
      device->say7(s3);  
      if (wait_per_iter)
	fprintf(stderr, "Waiting for iter %d responses\n", i);
	indication->wait();
	fprintf(stderr, "Received iter %d responses\n", i);
    }
    if (!wait_per_iter)
      indication->wait();
    return 0;
}
