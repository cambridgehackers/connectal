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
#include <fcntl.h>
#include <assert.h>
#include "dmaManager.h"
#include "StrstrIndication.h"
#include "StrstrRequest.h"
#include "strstr.h"
#include "mp.h"

int sw_match_cnt = 0;

int main(int argc, const char **argv)
{
  StrstrRequestProxy *device = 0;
  StrstrIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new StrstrRequestProxy(IfcNames_StrstrRequestS2H);
  deviceIndication = new StrstrIndication(IfcNames_StrstrIndicationH2S);
    DmaManager *dma = platformInit();

  if(1){
    fprintf(stderr, "simple tests\n");
    int needleAlloc;
    int haystackAlloc;
    int mpNextAlloc;
    unsigned int alloc_len = 4096;
    
    needleAlloc = portalAlloc(alloc_len, 0);
    mpNextAlloc = portalAlloc(alloc_len, 0);
    haystackAlloc = portalAlloc(alloc_len, 0);

    char *needle = (char *)portalMmap(needleAlloc, alloc_len);
    char *haystack = (char *)portalMmap(haystackAlloc, alloc_len);
    struct MP *mpNext = (struct MP *)portalMmap(mpNextAlloc, alloc_len);
    
    const char *needle_text = "ababab";
    const char *haystack_text = "acabcabacababacababababababcacabcabacababacabababc";
    const int hmul = 1;
    
    assert(strlen(haystack_text)*hmul < alloc_len);
    assert(strlen(needle_text)*4 < alloc_len);

    strncpy(needle, needle_text, alloc_len);
    for (int i = 0; i < hmul; i++)
      strcpy(haystack+(i*strlen(haystack_text)), haystack_text);

    int needle_len = strlen(needle);
    int haystack_len = strlen(haystack);
    int border[needle_len+1];

    compute_borders(needle, border, needle_len);
    compute_MP_next(needle, mpNext, needle_len);

    assert(mpNext[1].index == 0);
    assert(border[1] == 0);
    for (int i = 2; i < needle_len+1; i++)
      assert(mpNext[i].index == border[i-1]+1);

    for (int i = 0; i < needle_len; i++)
      fprintf(stderr, "needle[%d]=%x mpNext[%d]=%d\n", i, needle[i], i+1, ((int *)mpNext)[i+1]);

    portalTimerStart(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, &sw_match_cnt);
    fprintf(stderr, "elapsed time (hw cycles): %lld\n", (long long)portalTimerLap(0));
    
    for (int i = 0; i < needle_len; i++)
      fprintf(stderr, "needle[%d]=%x mpNext[%d]=%x\n", i, needle[i], i+1, ((int *)mpNext)[i+1]);

    portalCacheFlush(needleAlloc, needle, alloc_len, 1);
    portalCacheFlush(mpNextAlloc, mpNext, alloc_len, 1);

    unsigned int ref_needle = dma->reference(needleAlloc);
    unsigned int ref_mpNext = dma->reference(mpNextAlloc);
    unsigned int ref_haystack = dma->reference(haystackAlloc);

    fprintf(stderr, "about to invoke device ref_needle=%d ref_mpNext=%d ref_haystack=%d\n",
	    ref_needle, ref_mpNext, ref_haystack);
    device->setup(ref_needle, ref_mpNext, needle_len);
    sleep(2);
    portalTimerStart(0);
    device->search(ref_haystack, haystack_len);
    deviceIndication->wait();
    //uint64_t cycles = portalTimerLap(0);
    //uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    //fprintf(stderr, "memory read utilization (beats/cycle): %f\n", ((float)beats)/((float)cycles));

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
#ifdef SIMULATION
    int BENCHMARK_INPUT_SIZE = 16 << 15;
#else
    int BENCHMARK_INPUT_SIZE = 16 << 18;
#endif
    int haystack_alloc_len = BENCHMARK_INPUT_SIZE;
    int needle_alloc_len = (strlen(needle_text)+4095)&~4095l;
    int mpNext_alloc_len = needle_alloc_len*4;
    
    needleAlloc = portalAlloc(needle_alloc_len, 0);
    haystackAlloc = portalAlloc(haystack_alloc_len, 0);
    mpNextAlloc = portalAlloc(mpNext_alloc_len, 0);

    char *needle = (char *)portalMmap(needleAlloc, needle_alloc_len);
    char *haystack = (char *)portalMmap(haystackAlloc, haystack_alloc_len);
    struct MP *mpNext = (struct MP *)portalMmap(mpNextAlloc, mpNext_alloc_len);

    int ref_needle = dma->reference(needleAlloc);
    int ref_haystack = dma->reference(haystackAlloc);
    int ref_mpNext = dma->reference(mpNextAlloc);

    int fp = open("/dev/urandom", O_RDONLY);
    int rv = read(fp, haystack, BENCHMARK_INPUT_SIZE);
    if (rv != BENCHMARK_INPUT_SIZE) {
        printf("[%s:%d] /dev/urandom failed?\n", __FUNCTION__, __LINE__);
    }
    strncpy(needle, needle_text, needle_alloc_len);
    
    int needle_len = strlen(needle);
    int haystack_len = haystack_alloc_len;
    int border[needle_len+1];

    compute_borders(needle, border, needle_len);
    compute_MP_next(needle, mpNext, needle_len);

    assert(mpNext[1].index == 0);
    assert(border[1] == 0);
    for (int i = 2; i < needle_len+1; i++)
      assert(mpNext[i].index == border[i-1]+1);

    fprintf(stderr, "about to invoke device ref_needle=%d ref_mpNext=%d ref_haystack=%d needle_len=%d needle_alloc_len=%d haystack_len=%d\n",
	    ref_needle, ref_mpNext, ref_haystack, needle_len, needle_alloc_len, haystack_len);

    portalTimerStart(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, &sw_match_cnt);
    uint64_t sw_cycles = portalTimerLap(0);
    fprintf(stderr, "sw_cycles:%llx\n", (long long)sw_cycles);

    portalCacheFlush(needleAlloc, needle, needle_alloc_len, 1);
    portalCacheFlush(mpNextAlloc, mpNext, mpNext_alloc_len, 1);

    device->setup(ref_needle, ref_mpNext, needle_len);
    portalTimerStart(0);
    device->search(ref_haystack, haystack_len);
    deviceIndication->wait();
    //uint64_t hw_cycles = portalTimerLap(0);
    //uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    //float read_util = (float)beats/(float)hw_cycles;
    //fprintf(stderr, "hw_cycles:%llx\n", (long long)hw_cycles);
    //fprintf(stderr, "memory read utilization (beats/cycle): %f\n", read_util);
    //fprintf(stderr, "speedup: %f\n", ((float)sw_cycles)/((float)hw_cycles));

    //MonkitFile("perf.monkit")
      //.setHwCycles(hw_cycles)
      //.setSwCycles(sw_cycles)
      //.setReadBwUtil(read_util)
      //.writeFile();
  }
  int hw_match_cnt = deviceIndication->match_cnt;
  fprintf(stderr, "teststrstr: Done, sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
