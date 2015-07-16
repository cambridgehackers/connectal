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
};

int main(int argc, const char **argv)
{
  size_t alloc_sz = 0x1240;
  MemwriteRequestProxy *device = new MemwriteRequestProxy(IfcNames_MemwriteRequestS2H);
  MemwriteIndication deviceIndication(IfcNames_MemwriteIndicationH2S);
  DmaManager *dma = platformInit();

  sem_init(&done_sem, 1, 0);
  int dstAlloc = portalAlloc(alloc_sz, 0);
  unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);

  for (unsigned int i = 0; i < alloc_sz/sizeof(uint32_t); i++)
    dstBuffer[i] = 0xDEADBEEF;

  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);

  fprintf(stderr, "parent::starting write\n");
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
  device->startWrite(ref_dstAlloc, alloc_sz, 2 * sizeof(uint32_t));

  sem_wait(&done_sem);
  memdump((unsigned char *)dstBuffer, 32, "MEM");
  fprintf(stderr, "%s: done\n", __FUNCTION__);
}
