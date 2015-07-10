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
#include <string.h>
#include <ctime>
#include <monkit.h>
#include "dmaManager.h"

#include "SpliceIndication.h"
#include "SpliceRequest.h"

sem_t test_sem;
sem_t setup_sem;
int sw_match_cnt = 0;
int hw_match_cnt = 0;
unsigned result_len = 0;

class SpliceIndication : public SpliceIndicationWrapper
{
public:
  SpliceIndication(unsigned int id) : SpliceIndicationWrapper(id){};

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
    result_len = v;
    sem_post(&test_sem);
  }
};


int main(int argc, const char **argv)
{
  SpliceRequestProxy *device = 0;
  SpliceIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new SpliceRequestProxy(IfcNames_SpliceRequest);
  deviceIndication = new SpliceIndication(IfcNames_SpliceIndication);
    DmaManager *dma = platformInit();

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

  if(sem_init(&setup_sem, 1, 0)){
    fprintf(stderr, "failed to init setup_sem\n");
    return -1;
  }

    fprintf(stderr, "simple tests\n");
    int strAAlloc;
    int strBAlloc;
    int fetchAlloc;
    unsigned int alloc_len = 128;
    unsigned int fetch_len = alloc_len * alloc_len;
    
    strAAlloc = portalAlloc(alloc_len, 0);
    strBAlloc = portalAlloc(alloc_len, 0);
    fetchAlloc = portalAlloc(fetch_len, 0);

    char *strA = (char *)portalMmap(strAAlloc, alloc_len);
    char *strB = (char *)portalMmap(strBAlloc, alloc_len);
    int *fetch = (int *)portalMmap(fetchAlloc, fetch_len);
    
    const char *strA_text = "   a     b      c    ";
    const char *strB_text = "..a........b......";
    
    assert(strlen(strA_text) < alloc_len);
    assert(strlen(strB_text) < alloc_len);

    strncpy(strA, strA_text, alloc_len);
    strncpy(strB, strB_text, alloc_len);

    int strA_len = strlen(strA);
    int strB_len = strlen(strB);
    uint16_t swFetch[fetch_len];

    for (int i = 0; i < alloc_len; i += 1) {
      strA[i] = i;
      strB[i] = 255 - i;
    }


    portalTimerStart(0);


    fprintf(stderr, "elapsed time (hw cycles): %lld\n", (long long)portalTimerLap(0));
    
    portalCacheFlush(strAAlloc, strA, alloc_len, 1);
    portalCacheFlush(strBAlloc, strB, alloc_len, 1);
    portalCacheFlush(fetchAlloc, fetch, fetch_len, 1);

    unsigned int ref_strAAlloc = dma->reference(strAAlloc);
    unsigned int ref_strBAlloc = dma->reference(strBAlloc);
    unsigned int ref_fetchAlloc = dma->reference(fetchAlloc);

    device->setupA(ref_strAAlloc, strA_len);
    sem_wait(&setup_sem);

    device->setupB(ref_strBAlloc, strB_len);
    sem_wait(&setup_sem);
    portalTimerStart(0);

    device->start();
    sem_wait(&test_sem);
    uint64_t cycles = portalTimerLap(0);
    uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);
    assert(result_len < alloc_len * alloc_len);
    //    device->fetch(ref_fetchAlloc, (result_len+7)& ~7);
    device->fetch(ref_fetchAlloc, 32);
    printf("fetch called %d\n", result_len);
    sem_wait(&setup_sem);
    printf("fetch finished \n");

    memcpy(swFetch, fetch, result_len * sizeof(uint16_t));
    for (int i = 0; i < result_len; i += 1) {
      if ((swFetch[i] & 0xffff) != ((strA[i] << 8) & 0xff00 | (strB[i] & 0xff)))
	printf("mismatch i %d A %02x B %02x R %04x\n", 
	       i, strA[i], strB[i], swFetch[i]);
    }


    close(strAAlloc);
    close(strBAlloc);
    close(fetchAlloc);
  }

