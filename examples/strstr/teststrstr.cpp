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

/*
 * Implementation of:
 *    MP algorithm on pages 7-11 from "Pattern Matching Algorithms" by
 *       Alberto Apostolico, Zvi Galil, 1997
 *
 *    procedure MP(x, t: string; m, n: integer);
 *    begin
 *        i := 1; j := 1;
 *        while j <= n do begin
 *            while (i = m + 1) or (i > 0 and x[i] != t[j]) do j := MP_next[i];
 *            i := i + 1; j := j + 1;
 *            if i = m + 1 then writeln('x occurs in t at position ', j - i + 1);
 *        end;
 *    end;
 *    
 *    procedure Compute_borders(x: string; m: integer);
 *    begin
 *        Border[0] := -1;
 *        for i := 1 to m do begin
 *            j := Border[i - 1];
 *            while j >= 0 and x[i] != x[j + 1] do j := Border[j];
 *            Border[i] := j + 1;
 *        end;
 *    end;
 *    
 *    procedure Compute_MP_next(x: string; m: integer);
 *    begin
 *        MP_next[i] := 0; j := 0;
 *        for i := 1 to m do begin
 *            { at this point, we have j = MP_next[i] }
 *            while j > 0 and x[i] != x[j] do j := MP_next[j];
 *            j := j + 1;
 *            MP_next[i + 1] := j;
 *        end;
 *    end;
 *
 */

#include <stdio.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <semaphore.h>
#include <ctime>
#include "StdDmaIndication.h"

#include "StrstrIndicationWrapper.h"
#include "StrstrRequestProxy.h"
#include "GeneratedTypes.h"
#include "DmaConfigProxy.h"


sem_t test_sem;
sem_t setup_sem;
unsigned int sw_match_cnt = 0;
unsigned int hw_match_cnt = 0;

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

void compute_borders(const char *x, int *border, int m)
{
  border[0] = -1;
  for(int i = 1; i <=m; i++){
    int j = border[i-1];
    while ((j>=0) && (x[i] != x[j+1]))
      j = border[j];
    border[i] = j+1;
  }
}

void compute_MP_next(const char *x, int *MP_next, int m)
{
  MP_next[1] = 0;
  int j = 0;
  for(int i = 1; i <= m; i++){
    while ((j>0) && (x[i] != x[j]))
      j = MP_next[j];
    j = j+1;
    MP_next[i+1] = j;
  }
}

void MP(const char *x, const char *t, int *MP_next, int m, int n, int iter_cnt)
{
  while(iter_cnt--){
    int i = 1;
    int j = 1;
    fprintf(stderr, "MP starting\n");
    while (j <= n) {
      while ((i==m+1) || ((i>0) && (x[i-1] != t[j-1]))){
	//fprintf(stderr, "char mismatch %d %d MP_next[i]=%d\n", i,j,MP_next[i]);
	i = MP_next[i];
      }
      //fprintf(stderr, "   char match %d %d\n", i, j);
      i = i+1;
      j = j+1;
      if (i==m+1){
	fprintf(stderr, "%s occurs in t at position %d\n", x, j-i);
	i = 1;
	sw_match_cnt++;
      }
    }
  }
  fprintf(stderr, "MP exiting\n");
}

int main(int argc, const char **argv)
{
  StrstrRequestProxy *device = 0;
  DmaConfigProxy *dma = 0;
  
  StrstrIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new StrstrRequestProxy(IfcNames_StrstrRequest);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);

  deviceIndication = new StrstrIndication(IfcNames_StrstrIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  if(sem_init(&setup_sem, 1, 0)){
    fprintf(stderr, "failed to init setup_sem\n");
    return -1;
  }

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

#ifndef MMAP_HW
  if(1){
    fprintf(stderr, "simple tests\n");
    PortalAlloc *needleAlloc;
    PortalAlloc *haystackAlloc;
    PortalAlloc *mpNextAlloc;
    unsigned int alloc_len = 16 << 2;
    
    dma->alloc(alloc_len, &needleAlloc);
    dma->alloc(alloc_len, &mpNextAlloc);
    dma->alloc(alloc_len, &haystackAlloc);

    char *needle = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, needleAlloc->header.fd, 0);
    char *haystack = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, haystackAlloc->header.fd, 0);
    int *mpNext = (int *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, mpNextAlloc->header.fd, 0);
    
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

    int iter_cnt = 2;

    start_timer(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, iter_cnt);
    fprintf(stderr, "elapsed time (hw cycles): %lld\n", lap_timer(0));
    
    dma->dCacheFlushInval(needleAlloc, needle);
    dma->dCacheFlushInval(mpNextAlloc, mpNext);

    unsigned int ref_needleAlloc = dma->reference(needleAlloc);
    unsigned int ref_mpNextAlloc = dma->reference(mpNextAlloc);
    unsigned int ref_haystackAlloc = dma->reference(haystackAlloc);

    device->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
    sem_wait(&setup_sem);
    start_timer(0);
    device->search(ref_haystackAlloc, haystack_len, iter_cnt);
    sem_wait(&test_sem);
    uint64_t cycles = lap_timer(0);
    uint64_t beats = dma->show_mem_stats(ChannelType_Read);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", ((float)beats)/((float)cycles));

    close(needleAlloc->header.fd);
    close(haystackAlloc->header.fd);
    close(mpNextAlloc->header.fd);
  }
#endif


#ifdef MMAP_HW
  if(1){
    fprintf(stderr, "benchmarks\n");
    PortalAlloc *needleAlloc;
    PortalAlloc *haystackAlloc;
    PortalAlloc *mpNextAlloc;
    const char *needle_text = "I have control\n";
    unsigned int BENCHMARK_INPUT_SIZE = 16 << 18;
    unsigned int haystack_alloc_len = BENCHMARK_INPUT_SIZE;
    unsigned int needle_alloc_len = strlen(needle_text);
    unsigned int mpNext_alloc_len = needle_alloc_len*4;
    
    dma->alloc(needle_alloc_len, &needleAlloc);
    dma->alloc(haystack_alloc_len, &haystackAlloc);
    dma->alloc(mpNext_alloc_len, &mpNextAlloc);

    char *needle = (char *)mmap(0, needle_alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, needleAlloc->header.fd, 0);
    char *haystack = (char *)mmap(0, haystack_alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, haystackAlloc->header.fd, 0);
    int *mpNext = (int *)mmap(0, mpNext_alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, mpNextAlloc->header.fd, 0);

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


    int iter_cnt = 32;

    start_timer(0);
    MP(needle, haystack, mpNext, needle_len, haystack_len, iter_cnt);
    uint64_t sw_cycles = lap_timer(0);
    fprintf(stderr, "sw_cycles:%zx\n", sw_cycles);

    dma->dCacheFlushInval(needleAlloc, needle);
    dma->dCacheFlushInval(mpNextAlloc, mpNext);

    device->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
    sem_wait(&setup_sem);
    start_timer(0);
    device->search(ref_haystackAlloc, haystack_len, iter_cnt);
    sem_wait(&test_sem);
    uint64_t hw_cycles = lap_timer(0);
    uint64_t beats = dma->show_mem_stats(ChannelType_Read);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", ((float)beats)/((float)hw_cycles));

    close(needleAlloc->header.fd);
    close(haystackAlloc->header.fd);
    close(mpNextAlloc->header.fd);
  }
#endif

  fprintf(stderr, "sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
