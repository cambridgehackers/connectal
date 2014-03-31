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
#include <semaphore.h>
#include <ctime>
#include <monkit.h>
#include <mp.h>
#include "StdDmaIndication.h"
#include <sys/types.h>
#include <sys/stat.h>

#include "MaxcommonsubseqIndicationWrapper.h"
#include "MaxcommonsubseqRequestProxy.h"
#include "GeneratedTypes.h"
#include "DmaConfigProxy.h"


sem_t test_sem;
sem_t setup_sem;
int sw_match_cnt = 0;
int hw_match_cnt = 0;

class MaxcommonsubseqIndication : public MaxcommonsubseqIndicationWrapper
{
public:
  MaxcommonsubseqIndication(unsigned int id) : MaxcommonsubseqIndicationWrapper(id){};

  virtual void setupAComplete() {
    fprintf(stderr, "setupAComplete\n");
    sem_post(&setup_sem);
  }
  virtual void setupBComplete() {
    fprintf(stderr, "setupBComplete\n");
    sem_post(&setup_sem);
  }
  virtual void fetchComplete() {
    fprintf(stderr, "fetchComplete\n");
    sem_post(&setup_sem);
  }

  virtual void searchResult (int v){
    fprintf(stderr, "searchResult = %d\n", v);
    sem_post(&test_sem);
  }
};


int main(int argc, const char **argv)
{
  MaxcommonsubseqRequestProxy *device = 0;
  DmaConfigProxy *dma = 0;
  
  MaxcommonsubseqIndication *deviceIndication = 0;
  DmaIndication *dmaIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new MaxcommonsubseqRequestProxy(IfcNames_MaxcommonsubseqRequest);
  dma = new DmaConfigProxy(IfcNames_DmaConfig);

  deviceIndication = new MaxcommonsubseqIndication(IfcNames_MaxcommonsubseqIndication);
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

    fprintf(stderr, "simple tests\n");
    PortalAlloc *strAAlloc;
    PortalAlloc *strBAlloc;
    PortalAlloc *fetchAlloc;
    unsigned int alloc_len = 128;
    unsigned int fetch_len = alloc_len * alloc_len;
    int rcA, rcB, rcFetch;
    struct stat statAbuf, statBbuf, statFetchbuf;
    
    dma->alloc(fetch_len*sizeof(uint16_t), &fetchAlloc);
    rcFetch = fstat(fetchAlloc->header.fd, &statFetchbuf);
    if (rcA < 0) perror("fstatFetch");
    int *fetch = (int *)mmap(0, fetch_len * sizeof(uint16_t), PROT_READ|PROT_WRITE, MAP_SHARED, fetchAlloc->header.fd, 0);
    if (fetch == MAP_FAILED) perror("fetch mmap failed");
    assert(fetch != MAP_FAILED);

    dma->alloc(alloc_len, &strAAlloc);
    rcA = fstat(strAAlloc->header.fd, &statAbuf);
    if (rcA < 0) perror("fstatA");
    char *strA = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE, MAP_SHARED, strAAlloc->header.fd, 0);
    if (strA == MAP_FAILED) perror("strA mmap failed");
    assert(strA != MAP_FAILED);

    dma->alloc(alloc_len, &strBAlloc);
    rcB = fstat(strBAlloc->header.fd, &statBbuf);
    if (rcA < 0) perror("fstatB");
    char *strB = (char *)mmap(0, alloc_len, PROT_READ|PROT_WRITE, MAP_SHARED, strBAlloc->header.fd, 0);
    if (strB == MAP_FAILED) perror("strB mmap failed");
    assert(strB != MAP_FAILED);

    const char *strA_text = "   a     b      c    ";
    const char *strB_text = "..a........b.c....";
    
    assert(strlen(strA_text) < alloc_len);
    assert(strlen(strB_text) < alloc_len);

    strncpy(strA, strA_text, alloc_len);
    strncpy(strB, strB_text, alloc_len);

    int strA_len = strlen(strA);
    int strB_len = strlen(strB);
    uint16_t swFetch[fetch_len];

    init_timer();
    start_timer(0);


    fprintf(stderr, "elapsed time (hw cycles): %zd\n", lap_timer(0));
    
    dma->dCacheFlushInval(strAAlloc, strA);
    dma->dCacheFlushInval(strBAlloc, strB);
    dma->dCacheFlushInval(fetchAlloc, fetch);

    unsigned int ref_strAAlloc = dma->reference(strAAlloc);
    unsigned int ref_strBAlloc = dma->reference(strBAlloc);
    unsigned int ref_fetchAlloc = dma->reference(fetchAlloc);

    device->setupA(ref_strAAlloc, strA_len);
    sem_wait(&setup_sem);

    device->setupB(ref_strBAlloc, strB_len);
    sem_wait(&setup_sem);

    fprintf(stderr, "starting algorithm A\n");

    init_timer();
    start_timer(0);

    device->start(0);
    sem_wait(&test_sem);
    uint64_t cycles = lap_timer(0);
    uint64_t beats = dma->show_mem_stats(ChannelType_Read);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);
    device->fetch(ref_fetchAlloc, 0, 0, fetch_len / 2);
    sem_wait(&setup_sem);
    printf("fetch 1 finished \n");
    device->fetch(ref_fetchAlloc, fetch_len, fetch_len / 2, fetch_len / 2);
    sem_wait(&setup_sem);
    printf("fetch 2 finished \n");

    memcpy(swFetch, fetch, fetch_len * sizeof(uint16_t));
    printf("        ");
    for (int j = 0; j <= strB_len; j += 1) {
      printf("%4d", j);
    }
    printf("\n");
    printf("        ");
    for (int j = 0; j <= strB_len; j += 1) {
      printf("%4c", strB[j-1]);
    }
    printf("\n");
    for (int i = 0; i <= strA_len; i += 1) {
      printf("%4c%4d", strA[i-1], i);
      for (int j = 0; j <= strB_len; j += 1) {
	printf("%4d", swFetch[(i << 7) + j] & 0xff);
      }
    printf("\n");
    }

    fprintf(stderr, "starting algorithm B\n");

    device->start(1);
    sem_wait(&test_sem);
    cycles = lap_timer(0);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);
    device->fetch(ref_fetchAlloc, 0, 0, fetch_len / 2);
    sem_wait(&setup_sem);

    memcpy(swFetch, fetch, fetch_len * sizeof(uint16_t));

    for (int j = 0; j <= strB_len; j += 1) {
      printf("%4d", j);
    }
    printf("\n");
    printf("        ");
    for (int j = 0; j <= strB_len; j += 1) {
      printf("%4c", strB[j-1]);
    }
    printf("\n");
    for (int i = 0; i < 1; i += 1) {
      printf("%4c%4d", strA[i-1], i);
      for (int j = 0; j <= strB_len; j += 1) {
	printf("%4d", swFetch[(i << 7) + j] & 0xff);
      }
    printf("\n");
    }

    close(strAAlloc->header.fd);
    close(strBAlloc->header.fd);
    close(fetchAlloc->header.fd);
  }


