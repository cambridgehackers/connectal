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
#include "dmaManager.h"
#include "MemcopyIndication.h"
#include "MemcopyRequest.h"

static void memdump(unsigned char *p, int len, const char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                printf("\n");
            printf("%s: ",title);
        }
        printf("%02x ", *p++);
        i++;
        len--;
    }
    printf("\n");
}

static sem_t done_sem;
class MemcopyIndication : public MemcopyIndicationWrapper
{
public:
  MemcopyIndication(int id) : MemcopyIndicationWrapper(id){}

  virtual void copyDone ( uint32_t srcGen ){
    fprintf(stderr, "Memcopy::writeDone (%08x)\n", srcGen);
    sem_post(&done_sem);
  }
  virtual void copyProgress ( uint32_t numtodo ){
    fprintf(stderr, "Memcopy::writeProgress (%08x)\n", numtodo);
  }
};

int main(int argc, const char **argv)
{
#ifdef SIMULATION
  size_t alloc_sz = 4*1024;
#else
  size_t alloc_sz = 10*1024*1024;
#endif
  MemcopyRequestProxy *device = new MemcopyRequestProxy(IfcNames_MemcopyRequestS2H);
  MemcopyIndication deviceIndication(IfcNames_MemcopyIndicationH2S);
  DmaManager *dma = platformInit();
  sem_init(&done_sem, 1, 0);

  int srcAlloc = portalAlloc(alloc_sz, 0);
  unsigned int *srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  int dstAlloc = portalAlloc(alloc_sz, 0);
  unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);

  for (size_t i = 0; i < alloc_sz/sizeof(uint32_t); i++) {
    srcBuffer[i] = 7*i-3;
    dstBuffer[i] = 0xDEADBEEF;
  }

#ifndef USE_ACP
  fprintf(stderr, "flushing cache\n");
  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
#endif

  fprintf(stderr, "parent::starting write\n");
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  int burstLenBytes = 32*sizeof(uint32_t);

  portalTimerStart(0);
  device->startCopy(ref_srcAlloc, ref_dstAlloc, alloc_sz, alloc_sz / burstLenBytes, burstLenBytes);
  sem_wait(&done_sem);
  platformStatistics();

  memdump((unsigned char *)dstBuffer, 32, "MEM");
  int mismatchCount = 0;
  for (size_t i = 0; i < alloc_sz/sizeof(uint32_t); i++) {
    if (dstBuffer[i] != srcBuffer[i])
      mismatchCount++;
  }
  fprintf(stderr, "%s: done mismatchCount=%d\n", __FUNCTION__, mismatchCount);
  return (mismatchCount == 0) ? 0 : 1;
}
