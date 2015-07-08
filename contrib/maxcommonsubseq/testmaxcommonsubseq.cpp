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
#include <assert.h>
#include <semaphore.h>
#include <ctype.h>
#include <ctime>
#include <monkit.h>
#include <mp.h>
#include "dmaManager.h"
#include <sys/types.h>
#include <sys/stat.h>

#include "MaxcommonsubseqIndication.h"
#include "MaxcommonsubseqRequest.h"

sem_t test_sem;
int result_length;

class MaxcommonsubseqIndication : public MaxcommonsubseqIndicationWrapper
{
public:
  MaxcommonsubseqIndication(unsigned int id) : MaxcommonsubseqIndicationWrapper(id){};

  virtual void setupAComplete() {
    fprintf(stderr, "setupAComplete\n");
    sem_post(&test_sem);
  }
  virtual void setupBComplete() {
    fprintf(stderr, "setupBComplete\n");
    sem_post(&test_sem);
  }
  virtual void fetchComplete() {
    fprintf(stderr, "fetchComplete\n");
    sem_post(&test_sem);
  }
  virtual void searchResult (uint32_t v){
    result_length = v;
    fprintf(stderr, "searchResult = %d\n", v);
    sem_post(&test_sem);
  }
};


int main(int argc, const char **argv)
{
  MaxcommonsubseqRequestProxy *device = 0;
  MaxcommonsubseqIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new MaxcommonsubseqRequestProxy(IfcNames_MaxcommonsubseqRequest);
    DmaManager *dma = platformInit();
  deviceIndication = new MaxcommonsubseqIndication(IfcNames_MaxcommonsubseqIndication);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

    fprintf(stderr, "simple tests\n");
    int strAAlloc;
    int strBAlloc;
    int fetchAlloc;
    unsigned int alloc_len = 128;
    unsigned int fetch_len = alloc_len * alloc_len;
    int rcA, rcB, rcFetch;
    struct stat statAbuf, statBbuf, statFetchbuf;
    
    fetchAlloc = portalAlloc(fetch_len*sizeof(uint16_t), 0);
    rcFetch = fstat(fetchAlloc, &statFetchbuf);
    if (rcA < 0) perror("fstatFetch");
    int *fetch = (int *)portalMmap(fetchAlloc, fetch_len * sizeof(uint16_t));
    if (fetch == MAP_FAILED) perror("fetch mmap failed");
    assert(fetch != MAP_FAILED);

    strAAlloc = portalAlloc(alloc_len, 0);
    rcA = fstat(strAAlloc, &statAbuf);
    if (rcA < 0) perror("fstatA");
    char *strA = (char *)portalMmap(strAAlloc, alloc_len);
    if (strA == MAP_FAILED) perror("strA mmap failed");
    assert(strA != MAP_FAILED);

    strBAlloc = portalAlloc(alloc_len, 0);
    rcB = fstat(strBAlloc, &statBbuf);
    if (rcA < 0) perror("fstatB");
    char *strB = (char *)portalMmap(strBAlloc, alloc_len);
    if (strB == MAP_FAILED) perror("strB mmap failed");
    assert(strB != MAP_FAILED);

/*
    const char *strA_text = "___a_____b______c____";
    const char *strB_text = "..a........b.c....";
*/
    const char *strA_text = "012a45678b012345c7890";
    const char *strB_text = "ABaDEFGHIJKbMcOPQR";
    
    assert(strlen(strA_text) < alloc_len);
    assert(strlen(strB_text) < alloc_len);

    strncpy(strA, strA_text, alloc_len);
    strncpy(strB, strB_text, alloc_len);

    int strA_len = strlen(strA);
    int strB_len = strlen(strB);
    uint16_t swFetch[fetch_len];

    portalTimerInit();
    portalTimerStart(0);


    fprintf(stderr, "elapsed time (hw cycles): %lld\n", (long long)portalTimerLap(0));
    
    portalCacheFlush(strAAlloc, strA, alloc_len, 1);
    portalCacheFlush(strBAlloc, strB, alloc_len, 1);
    portalCacheFlush(fetchAlloc, fetch, fetch_len*sizeof(uint16_t), 1);

    unsigned int ref_strAAlloc = dma->reference(strAAlloc);
    unsigned int ref_strBAlloc = dma->reference(strBAlloc);
    unsigned int ref_fetchAlloc = dma->reference(fetchAlloc);

    device->setupA(ref_strAAlloc, 0, strA_len);
    sem_wait(&test_sem);

    device->setupB(ref_strBAlloc, 0, strB_len);
    sem_wait(&test_sem);

    uint64_t cycles;
    uint64_t beats;

    fprintf(stderr, "starting algorithm A\n");

    portalTimerInit();
    portalTimerStart(0);

    device->start(0);
    sem_wait(&test_sem);
    cycles = portalTimerLap(0);
    beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);
    device->fetch(ref_fetchAlloc, 0, 0, fetch_len / 2);
    sem_wait(&test_sem);
    printf("fetch 1 finished \n");
    device->fetch(ref_fetchAlloc, fetch_len, fetch_len / 2, fetch_len / 2);
    sem_wait(&test_sem);
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


    fprintf(stderr, "starting algorithm B, forward\n");
    portalTimerInit();
    portalTimerStart(0);

    device->start(1);
    sem_wait(&test_sem);
    cycles = portalTimerLap(0);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);
    device->fetch(ref_fetchAlloc, 0, 0, fetch_len / 2);
    sem_wait(&test_sem);

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
    for (int i = 0; i < 1; i += 1) {
      printf("%4c%4d", strA[i-1], i);
      for (int j = 0; j <= strB_len; j += 1) {
	printf("%4d", swFetch[(i << 7) + j] & 0xff);
      }
    printf("\n");
    }

    /* reverse argument strings */
    for (int i = 0; i < strA_len; i += 1) {
      strA[i] = strA_text[strA_len - i - 1];
    }
    for (int i = 0; i < strB_len; i += 1) {
      strB[i] = strB_text[strB_len - i - 1];
    }
    device->setupA(ref_strAAlloc, 0, strA_len);
    sem_wait(&test_sem);

    device->setupB(ref_strBAlloc, 0, strB_len);
    sem_wait(&test_sem);

    fprintf(stderr, "starting algorithm B, backward\n");



    portalTimerInit();
    portalTimerStart(0);

    device->start(2);
    sem_wait(&test_sem);
    cycles = portalTimerLap(0);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);
    device->fetch(ref_fetchAlloc, 0, 0, fetch_len / 2);
    sem_wait(&test_sem);

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
    for (int i = 0; i < 1; i += 1) {
      printf("%4c%4d", strA[i-1], i);
      for (int j = 0; j <= strB_len; j += 1) {
	printf("%4d", swFetch[(i << 7) + j] & 0xff);
      }
    printf("\n");
    }

    /* forward argument strings */
    for (int i = 0; i < strA_len; i += 1) {
      strA[i] = strA_text[i];
    }
    for (int i = 0; i < strB_len; i += 1) {
      strB[i] = strB_text[i];
    }
    device->setupA(ref_strAAlloc, 0, strA_len);
    sem_wait(&test_sem);

    device->setupB(ref_strBAlloc, 0, strB_len);
    sem_wait(&test_sem);


    fprintf(stderr, "starting algorithm C\n");
    portalTimerInit();
    portalTimerStart(0);

    device->start(3);
    sem_wait(&test_sem);
    cycles = portalTimerLap(0);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);
    device->fetch(ref_fetchAlloc, 0, 0, fetch_len / 2);
    sem_wait(&test_sem);

    memcpy(swFetch, fetch, fetch_len * sizeof(uint16_t));

    if (result_length > strB_len) result_length = strB_len;
    
    printf("Algorithm C results\n");
    for (int j = 0; j < result_length; j += 1) {
      char c =  swFetch[j] & 0xff;
      printf(" %02x (%c)", 0xff & c, (isalnum(c) ? c: '_'));
    }
    printf("\n");



    close(strAAlloc);
    close(strBAlloc);
    close(fetchAlloc);
  }


