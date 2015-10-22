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
#include "ReadTestRequest.h"
#include "ReadTestIndication.h"

#ifdef SIMULATION
static size_t test_sz = 0x124000; // make sure to allocate at least one entry of each size
#else
static size_t test_sz = 0x1240000; // make sure to allocate at least one entry of each size
#endif
sem_t test_sem;
static int burstLen = 16 * 4;

class ReadTestIndication : public ReadTestIndicationWrapper
{
public:
  void readDone(uint32_t v){
    printf( "ReadTest::readDone(mismatch = %x)\n", v);
    sem_post(&test_sem);
  }
  ReadTestIndication(int id) : ReadTestIndicationWrapper(id){}
};

int main(int argc, const char **argv)
{
  ReadTestRequestProxy *device = new ReadTestRequestProxy(IfcNames_ReadTestRequestS2H);
  ReadTestIndication deviceIndication(IfcNames_ReadTestIndicationH2S);
  DmaManager *dma = platformInit();

  int srcAlloc;
  srcAlloc = portalAlloc(test_sz, 0);
  unsigned int *srcBuffer = (unsigned int *)portalMmap(srcAlloc, test_sz);

  for (unsigned int i = 0; i < test_sz/sizeof(unsigned int); i++)
    srcBuffer[i] = i;
  portalCacheFlush(srcAlloc, srcBuffer, test_sz, 1);
  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  printf( "Main::starting read %lx\n", test_sz);
  device->startRead(ref_srcAlloc, test_sz, burstLen, 1);
  sem_wait(&test_sem);
  return 0;
}
