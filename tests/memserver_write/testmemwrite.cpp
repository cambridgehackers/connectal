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
#include <sys/mman.h>
#include <errno.h>
#include "dmaManager.h"
#include "MemwriteIndication.h"
#include "MemwriteRequest.h"

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
class MemwriteIndication : public MemwriteIndicationWrapper
{
public:
  MemwriteIndication(int id) : MemwriteIndicationWrapper(id){}

  virtual void writeDone ( uint32_t srcGen ){
    fprintf(stderr, "Memwrite::writeDone (%08x)\n", srcGen);
    sem_post(&done_sem);
  }
  virtual void writeProgress ( uint32_t numtodo ){
    fprintf(stderr, "Memwrite::writeProgress (%08x)\n", numtodo);
  }
};

MemwriteIndication *deviceIndication;
int main(int argc, const char **argv)
{
    size_t alloc_sz = 4096; //1024*1024;
  MemwriteRequestProxy *device = new MemwriteRequestProxy(IfcNames_MemwriteRequestS2H);
  deviceIndication = new MemwriteIndication(IfcNames_MemwriteIndicationH2S);
  DmaManager *dma = platformInit();

  device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */
  //dmap->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  sem_init(&done_sem, 1, 0);

  int iters = 64;

  int mismatchCount = 0;

  for (int iter = 0; iter < iters; iter++) {
      int dstAlloc = portalAlloc(alloc_sz, 1);
      unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);

      for (uint32_t i = 0; i < alloc_sz/sizeof(uint32_t); i++)
	  dstBuffer[i] = 0xDEADBEEF;

#ifndef USE_ACP
      fprintf(stderr, "flushing cache\n");
      portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
#endif

      fprintf(stderr, "parent::starting write\n");
      mismatchCount = 0;
      unsigned int ref_dstAlloc = dma->reference(dstAlloc);
      fprintf(stderr, "dma->reference %d\n", ref_dstAlloc);
      int burstLenBytes = 16*sizeof(uint32_t);
      device->startWrite(ref_dstAlloc, alloc_sz, alloc_sz / burstLenBytes, burstLenBytes);

      sem_wait(&done_sem);
      memdump((unsigned char *)dstBuffer, 32, "MEM");
      for (uint32_t i = 0; i < alloc_sz/sizeof(uint32_t); i++) {
	  if (dstBuffer[i] != i)
	      mismatchCount++;
      }
      fprintf(stderr, "%s: done mismatchCount=%d\n", __FUNCTION__, mismatchCount);
      platformStatistics();

      fprintf(stderr, "%s: calling munmap\n", __FUNCTION__);
      int unmapped = munmap(dstBuffer, alloc_sz);
      if (unmapped != 0)
	  fprintf(stderr, "Failed to unmap dstBuffer errno=%d:%s\n", errno, strerror(errno));
      
      fprintf(stderr, "%s: close\n", __FUNCTION__);
      close(dstAlloc);

      fprintf(stderr, "%s: calling dereference\n", __FUNCTION__);
      dma->dereference(ref_dstAlloc);
      fprintf(stderr, "%s: after dereference\n", __FUNCTION__);
  }

  return (mismatchCount == 0) ? 0 : 1;
}
