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
#include <ctime>
#include <monkit.h>
#include <mp.h>
#include "dmaManager.h"
#include <sys/types.h>
#include <sys/stat.h>
#include "SmithwatermanIndication.h"
#include "SmithwatermanRequest.h"

sem_t test_sem;
int result_length;

class SmithwatermanIndication : public SmithwatermanIndicationWrapper
{
public:
  SmithwatermanIndication(unsigned int id) : SmithwatermanIndicationWrapper(id){};

  virtual void setupAComplete() {
    fprintf(stderr, "setupAComplete\n");
    sem_post(&test_sem);
  }
  virtual void setupBComplete() {
    fprintf(stderr, "setupBComplete\n");
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
  SmithwatermanRequestProxy *device = 0;
  SmithwatermanIndication *deviceIndication = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = new SmithwatermanRequestProxy(IfcNames_SmithwatermanRequest);
  deviceIndication = new SmithwatermanIndication(IfcNames_SmithwatermanIndication);
    DmaManager *dma = platformInit();

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }

    fprintf(stderr, "simple tests\n");
    int strAAlloc;
    int strBAlloc;
    unsigned int alloc_len = 128;
    int rcA, rcB;
    struct stat statAbuf, statBbuf;
    
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

    const char *strA_text = "agtac";
    const char *strB_text = "aag";
    
    assert(strlen(strA_text) < alloc_len);
    assert(strlen(strB_text) < alloc_len);

    strncpy(strA, strA_text, alloc_len);
    strncpy(strB, strB_text, alloc_len);

    int strA_len = strlen(strA);
    int strB_len = strlen(strB);

    portalTimerInit();
    portalTimerStart(0);


    fprintf(stderr, "elapsed time (hw cycles): %lld\n", (long long)portalTimerLap(0));
    
    portalCacheFlush(strAAlloc, strA, alloc_len, 1);
    portalCacheFlush(strBAlloc, strB, alloc_len, 1);

    unsigned int ref_strAAlloc = dma->reference(strAAlloc);
    unsigned int ref_strBAlloc = dma->reference(strBAlloc);

    device->setupA(ref_strAAlloc, 0, strA_len);
    sem_wait(&test_sem);

    device->setupB(ref_strBAlloc, 0, strB_len);
    sem_wait(&test_sem);

    uint64_t cycles;
    uint64_t beats;


    fprintf(stderr, "starting algorithm C\n");
    portalTimerInit();
    portalTimerStart(0);

    device->start(3);
    sem_wait(&test_sem);
    cycles = portalTimerLap(0);
    fprintf(stderr, "hw cycles: %f\n", (float)cycles);

    sem_wait(&test_sem);

    printf("Algorithm C results\n");
    printf("\n");



    close(strAAlloc);
    close(strBAlloc);
}
