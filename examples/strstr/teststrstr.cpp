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

#include "StrstrIndicationWrapper.h"
#include "StrstrRequestProxy.h"
#include "DmaDebugRequestProxy.h"
#include "MMUConfigRequestProxy.h"


sem_t test_sem;
sem_t setup_sem;
int sw_match_cnt = 0;
int hw_match_cnt = 0;

class StrstrIndication : public StrstrIndicationWrapper
{
public:
  StrstrIndication(unsigned int id) : StrstrIndicationWrapper(id){};

  virtual void setupComplete() {
    sem_post(&setup_sem);
  }

  virtual void searchResult (int v){
    fprintf(stderr, "searchResult = %d\n", v);
    if (v == -1)
      sem_post(&test_sem);
    else 
      hw_match_cnt++;
  }
};


int main(int argc, const char **argv)
{
  StrstrRequestProxy *device = 0;
  StrstrIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new StrstrRequestProxy(IfcNames_StrstrRequest);
  deviceIndication = new StrstrIndication(IfcNames_StrstrIndication);
  DmaDebugRequestProxy *hostmemDmaDebugRequest = new DmaDebugRequestProxy(IfcNames_HostDmaDebugRequest);
  MMUConfigRequestProxy *dmap = new MMUConfigRequestProxy(IfcNames_HostMMUConfigRequest);
  DmaManager *dma = new DmaManager(hostmemDmaDebugRequest, dmap);
  DmaDebugIndication *hostmemDmaDebugIndication = new DmaDebugIndication(dma, IfcNames_HostDmaDebugIndication);
  MMUConfigIndication *hostMMUConfigIndication = new MMUConfigIndication(dma, IfcNames_HostMMUConfigIndication);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  if(sem_init(&setup_sem, 1, 0)){
    fprintf(stderr, "failed to init setup_sem\n");
    return -1;
  }

  portalExec_start();

  if(1){
    fprintf(stderr, "simple tests\n");
    int needleAlloc;
    int haystackAlloc;
    int mpNextAlloc;
    unsigned int alloc_len = 16 << 2;
    
    needleAlloc = portalAlloc(alloc_len);
    mpNextAlloc = portalAlloc(alloc_len);
    haystackAlloc = portalAlloc(alloc_len);

    char *needle = (char *)portalMmap(needleAlloc, alloc_len);
    char *haystack = (char *)portalMmap(haystackAlloc, alloc_len);
    int *mpNext = (int *)portalMmap(mpNextAlloc, alloc_len);
    
    const char *needle_text = "ababab";
    const char *haystack_text = "acabcabacababacababababababcacabcabacababacabababc";
    
    assert(strlen(haystack_text) < alloc_len);
    assert(strlen(needle_text)*4 < alloc_len);

    strncpy(needle, needle_text, alloc_len);
    strncpy(haystack, haystack_text, alloc_len);

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

    int iter_cnt = 1;

    portalTimerStart(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, iter_cnt, &sw_match_cnt);
    fprintf(stderr, "elapsed time (hw cycles): %lld\n", (long long)portalTimerLap(0));
    
    portalDCacheFlushInval(needleAlloc, alloc_len, needle);
    portalDCacheFlushInval(mpNextAlloc, alloc_len, mpNext);

    unsigned int ref_needleAlloc = dma->reference(needleAlloc);
    unsigned int ref_mpNextAlloc = dma->reference(mpNextAlloc);
    unsigned int ref_haystackAlloc = dma->reference(haystackAlloc);

    fprintf(stderr, "about to invoke device\n");
    device->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
    sem_wait(&setup_sem);
    portalTimerStart(0);
    device->search(ref_haystackAlloc, haystack_len, iter_cnt);
    sem_wait(&test_sem);
    uint64_t cycles = portalTimerLap(0);
    uint64_t beats = dma->show_mem_stats(ChannelType_Read);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", ((float)beats)/((float)cycles));

    close(needleAlloc);
    close(haystackAlloc);
    close(mpNextAlloc);
  }

  if(0){
    fprintf(stderr, "benchmarks\n");
    int needleAlloc;
    int haystackAlloc;
    int mpNextAlloc;
    const char *needle_text = "I have control\n";
#ifndef BSIM
    unsigned int BENCHMARK_INPUT_SIZE = 16 << 18;
#else
    unsigned int BENCHMARK_INPUT_SIZE = 16 << 4;
#endif
    unsigned int haystack_alloc_len = BENCHMARK_INPUT_SIZE;
    unsigned int needle_alloc_len = strlen(needle_text);
    unsigned int mpNext_alloc_len = needle_alloc_len*4;
    
    needleAlloc = portalAlloc(needle_alloc_len);
    haystackAlloc = portalAlloc(haystack_alloc_len);
    mpNextAlloc = portalAlloc(mpNext_alloc_len);

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

#ifndef BSIM
    int iter_cnt = 8;
#else
    int iter_cnt = 3;
#endif

    portalTimerStart(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, iter_cnt, &sw_match_cnt);
    uint64_t sw_cycles = portalTimerLap(0);
    fprintf(stderr, "sw_cycles:%llx\n", (long long)sw_cycles);

    portalDCacheFlushInval(needleAlloc, needle_alloc_len, needle);
    portalDCacheFlushInval(mpNextAlloc, mpNext_alloc_len, mpNext);

    

    fprintf(stderr, "about to invoke device\n");
    device->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
    sem_wait(&setup_sem);
    portalTimerStart(0);
    device->search(ref_haystackAlloc, haystack_len, iter_cnt);
    sem_wait(&test_sem);
    uint64_t hw_cycles = portalTimerLap(0);
    uint64_t beats = dma->show_mem_stats(ChannelType_Read);
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

  fprintf(stderr, "sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
