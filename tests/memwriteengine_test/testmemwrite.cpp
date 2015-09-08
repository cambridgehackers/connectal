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

#define NUMBER_OF_WORDS   0x1240

static sem_t done_sem;
class MemwriteIndication : public MemwriteIndicationWrapper
{
public:
  MemwriteIndication(int id) : MemwriteIndicationWrapper(id){}

  virtual void writeDone ( uint32_t srcGen ){
    fprintf(stderr, "Memwrite::writeDone (%08x)\n", srcGen);
    sem_post(&done_sem);
  }
  virtual void req ( uint32_t addr ){
    fprintf(stderr, "req.addr=%08x\n", addr);
  }
  virtual void done ( uint32_t tag ){
    fprintf(stderr, "done.tag=%x\n", tag);
  }
  virtual void mismatch ( const uint32_t addr, const uint64_t data ){
    fprintf(stderr, "mismatch: addr=%08x data = %08lx %08lx\n",
	    addr, (long)((data >> 32) & 0xFFFFFFFF), (long)(data & 0xFFFFFFFF));
  }
};

int main(int argc, const char **argv)
{
  size_t alloc_sz = NUMBER_OF_WORDS;
  MemwriteRequestProxy *device = new MemwriteRequestProxy(IfcNames_MemwriteRequestS2H);
  MemwriteIndication deviceIndication(IfcNames_MemwriteIndicationH2S);
#if (NumberOfMasters != 0)
  DmaManager *dma = platformInit();
#endif

  sem_init(&done_sem, 1, 0);
#if (NumberOfMasters != 0)
  int dstAlloc = portalAlloc(alloc_sz, 0);
  unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);

  for (unsigned int i = 0; i < alloc_sz/sizeof(uint32_t); i++)
    dstBuffer[i] = 0xDEADBEEF;

  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);

  fprintf(stderr, "parent::starting write\n");
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);
#else
  unsigned int ref_dstAlloc = 1;
#endif
  device->startWrite(ref_dstAlloc, alloc_sz, 2 * sizeof(uint32_t));

  sem_wait(&done_sem);
  fprintf(stderr, "%s: done\n", __FUNCTION__);
  sleep(2);
  return 0;
}
