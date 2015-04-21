/* Copyright (c) 2013 Quanta Research Cambridge, Inc
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
#include <sys/mman.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <semaphore.h>
#include <ctime>
#include <monkit.h>
#include <mp.h>
#include "StdDmaIndication.h"

#include "StrstrIndication.h"
#include "StrstrRequest.h"
#include "MemServerRequest.h"
#include "MMURequest.h"

#include "strstr.h"

int sw_match_cnt = 0;

int main(int argc, const char **argv)
{
  StrstrRequestProxy *device = 0;
  StrstrIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new StrstrRequestProxy(IfcNames_StrstrRequestS2H);
  deviceIndication = new StrstrIndication(IfcNames_StrstrIndicationH2S);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_MemServerRequestS2H);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_MMURequestS2H);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_MemServerIndicationH2S);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_MMUIndicationH2S);

  if(1){
    fprintf(stderr, "simple tests\n");
    int needleAlloc;
    int haystackAlloc;
    int mpNextAlloc;
    unsigned int alloc_len = 16 << 8;
    
    needleAlloc = portalAlloc(alloc_len, 0);
    mpNextAlloc = portalAlloc(alloc_len, 0);
    haystackAlloc = portalAlloc(alloc_len, 0);

    char *needle = (char *)portalMmap(needleAlloc, alloc_len);
    char *haystack = (char *)portalMmap(haystackAlloc, alloc_len);
    int *mpNext = (int *)portalMmap(mpNextAlloc, alloc_len);
    
    const char *needle_text = "ababab";
    const char *haystack_text = "acabcabacababacababababababcacabcabacababacabababc";
    const int hmul = DEGPAR;
    
    assert(strlen(haystack_text)*hmul < alloc_len);
    assert(strlen(needle_text)*4 < alloc_len);

    strncpy(needle, needle_text, alloc_len);
    for(int i = 0; i < hmul; i++)
      strcpy(haystack+(i*strlen(haystack_text)), haystack_text);

    int needle_len = strlen(needle);
    int haystack_len = strlen(haystack);
    int border[needle_len+1];

    compute_borders(needle, border, needle_len);
    compute_MP_next(needle, mpNext, needle_len);

    assert(mpNext[1] == 0);
    assert(border[1] == 0);
    for(int i = 2; i < needle_len+1; i++)
      assert(mpNext[i] == border[i-1]+1);

    for(int i = 0; i < needle_len; i++)
      fprintf(stderr, "%d %d\n", needle[i], mpNext[i]);

    portalTimerStart(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, &sw_match_cnt);
    fprintf(stderr, "elapsed time (hw cycles): %lld\n", (long long)portalTimerLap(0));
    
    portalDCacheFlushInval(needleAlloc, alloc_len, needle);
    portalDCacheFlushInval(mpNextAlloc, alloc_len, mpNext);

    unsigned int ref_needleAlloc = dma->reference(needleAlloc);
    unsigned int ref_mpNextAlloc = dma->reference(mpNextAlloc);
    unsigned int ref_haystackAlloc = dma->reference(haystackAlloc);

    fprintf(stderr, "about to invoke device\n");
    device->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
    portalTimerStart(0);
    device->search(ref_haystackAlloc, haystack_len);
    deviceIndication->wait();
    uint64_t cycles = portalTimerLap(0);
    uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", ((float)beats)/((float)cycles));

    close(needleAlloc);
    close(haystackAlloc);
    close(mpNextAlloc);
  }

  if(1){
    fprintf(stderr, "benchmarks\n");
    int needleAlloc;
    int haystackAlloc;
    int mpNextAlloc;
    const char *needle_text = "I have control\n";
#ifndef BSIM
    unsigned int BENCHMARK_INPUT_SIZE = 16 << 18;
#else
    unsigned int BENCHMARK_INPUT_SIZE = 16 << 15;
#endif
    unsigned int haystack_alloc_len = BENCHMARK_INPUT_SIZE;
    unsigned int needle_alloc_len = strlen(needle_text);
    unsigned int mpNext_alloc_len = needle_alloc_len*4;
    
    needleAlloc = portalAlloc(needle_alloc_len, 0);
    haystackAlloc = portalAlloc(haystack_alloc_len, 0);
    mpNextAlloc = portalAlloc(mpNext_alloc_len, 0);

    char *needle = (char *)portalMmap(needleAlloc, needle_alloc_len);
    char *haystack = (char *)portalMmap(haystackAlloc, haystack_alloc_len);
    int *mpNext = (int *)portalMmap(mpNextAlloc, mpNext_alloc_len);

    unsigned int ref_needleAlloc = dma->reference(needleAlloc);
    unsigned int ref_haystackAlloc = dma->reference(haystackAlloc);
    unsigned int ref_mpNextAlloc = dma->reference(mpNextAlloc);

    FILE* fp = fopen("/dev/urandom", "r");
    size_t rv = fread(haystack, 1, BENCHMARK_INPUT_SIZE, fp);
    strncpy(needle, needle_text, needle_alloc_len);
    
    int needle_len = strlen(needle);
    int haystack_len = haystack_alloc_len;
    int border[needle_len+1];

    compute_borders(needle, border, needle_len);
    compute_MP_next(needle, mpNext, needle_len);

    assert(mpNext[1] == 0);
    assert(border[1] == 0);
    for(int i = 2; i < needle_len+1; i++)
      assert(mpNext[i] == border[i-1]+1);

    portalTimerStart(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, &sw_match_cnt);
    uint64_t sw_cycles = portalTimerLap(0);
    fprintf(stderr, "sw_cycles:%llx\n", (long long)sw_cycles);

    portalDCacheFlushInval(needleAlloc, needle_alloc_len, needle);
    portalDCacheFlushInval(mpNextAlloc, mpNext_alloc_len, mpNext);

    fprintf(stderr, "about to invoke device\n");
    device->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
    portalTimerStart(0);
    device->search(ref_haystackAlloc, haystack_len);
    deviceIndication->wait();
    uint64_t hw_cycles = portalTimerLap(0);
    uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    float read_util = (float)beats/(float)hw_cycles;
    fprintf(stderr, "hw_cycles:%llx\n", (long long)hw_cycles);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", read_util);
    fprintf(stderr, "speedup: %f\n", ((float)sw_cycles)/((float)hw_cycles));

    MonkitFile("perf.monkit")
      .setHwCycles(hw_cycles)
      .setSwCycles(sw_cycles)
      .setReadBwUtil(read_util)
      .writeFile();

    close(needleAlloc);
    close(haystackAlloc);
    close(mpNextAlloc);
  }

  int hw_match_cnt = deviceIndication->match_cnt;
  fprintf(stderr, "teststrstr: Done, sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
