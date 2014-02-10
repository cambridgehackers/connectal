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
#include "StdDmaDbgIndication.h"

#include "StrstrIndicationWrapper.h"
#include "StrstrRequestProxy.h"
#include "GeneratedTypes.h"
#include "DmaConfigProxy.h"
#include "DmaDbgConfigProxy.h"


sem_t test_sem;
unsigned int sw_match_cnt = 0;
unsigned int hw_match_cnt = 0;
extern Directory *pdir;
static unsigned long long c_start;


static void start_timer() 
{
  c_start = pdir->cycle_count();
}

static void stop_timer()
{
  fprintf(stderr, "search time (hw cycles): %lld\n", pdir->cycle_count() - c_start);
}

class StrstrIndication : public StrstrIndicationWrapper
{
public:
  StrstrIndication(unsigned int id) : StrstrIndicationWrapper(id){};

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

void MP(const char *x, const char *t, int *MP_next, int m, int n)
{
  int i = 1;
  int j = 1;
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
  fprintf(stderr, "MP exiting\n");
}

int main(int argc, const char **argv)
{
  StrstrRequestProxy *device = 0;
  DmaConfigProxy *dma = 0;
  DmaDbgConfigProxy *dmaDbg = 0;
  
  StrstrIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;
  DmaDbgIndication *dmaDbgIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new StrstrRequestProxy(IfcNames_StrstrRequest);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);
  dmaDbg = new DmaDbgConfigProxy(IfcNames_DmaDbgConfig);

  deviceIndication = new StrstrIndication(IfcNames_StrstrIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);
  dmaDbgIndication = new DmaDbgIndication(IfcNames_DmaDbgIndication);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  if(1){
    fprintf(stderr, "simple tests\n");
    PortalAlloc *needleAlloc;
    PortalAlloc *haystackAlloc;
    PortalAlloc *mpNextAlloc;
    unsigned int alloc_len = 16 << 2;
    
    dma->alloc(alloc_len, &needleAlloc);
    dma->alloc(alloc_len, &haystackAlloc);
    dma->alloc(alloc_len, &mpNextAlloc);

    char *needle = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, needleAlloc->header.fd, 0);
    char *haystack = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, haystackAlloc->header.fd, 0);
    int *mpNext = (int *)mmap(0, alloc_len, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, mpNextAlloc->header.fd, 0);
    
    unsigned int ref_needleAlloc = dma->reference(needleAlloc);
    unsigned int ref_haystackAlloc = dma->reference(haystackAlloc);
    unsigned int ref_mpNextAlloc = dma->reference(mpNextAlloc);

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

    start_timer();
    MP(needle, haystack, mpNext, needle_len, haystack_len);
    stop_timer();
    
    dma->dCacheFlushInval(needleAlloc, needle);
    dma->dCacheFlushInval(mpNextAlloc, mpNext);

    dmaDbg->getMemoryTraffic(ChannelType_Read);
    start_timer();
    device->search(ref_needleAlloc, ref_haystackAlloc, ref_mpNextAlloc, needle_len, haystack_len);
    sem_wait(&test_sem);
    dmaDbg->getMemoryTraffic(ChannelType_Read);
    stop_timer();

    close(needleAlloc->header.fd);
    close(haystackAlloc->header.fd);
    close(mpNextAlloc->header.fd);
  }


#ifdef MMAP_HW
  if(1){
    fprintf(stderr, "benchmarks\n");
    PortalAlloc *needleAlloc;
    PortalAlloc *haystackAlloc;
    PortalAlloc *mpNextAlloc;
    const char *needle_text = "I have control\n";
    unsigned int BENCHMARK_INPUT_SIZE = 1024 << 12;
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


    dma->dCacheFlushInval(needleAlloc, needle);
    dma->dCacheFlushInval(mpNextAlloc, mpNext);

    start_timer();    
    MP(needle, haystack, mpNext, needle_len, haystack_len);
    stop_timer();

    start_timer();
    device->search(ref_needleAlloc, ref_haystackAlloc, ref_mpNextAlloc, needle_len, haystack_len);
    sem_wait(&test_sem);
    stop_timer();

    close(needleAlloc->header.fd);
    close(haystackAlloc->header.fd);
    close(mpNextAlloc->header.fd);
  }
#endif

  fprintf(stderr, "sw_match_cnt=%d, hw_match_cnt=%d\n", sw_match_cnt, hw_match_cnt);
  return (sw_match_cnt != hw_match_cnt);
}
