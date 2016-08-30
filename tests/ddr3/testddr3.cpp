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
#include "dmaManager.h"
#include "Ddr3TestIndication.h"
#include "Ddr3TestRequest.h"

sem_t test_sem;
unsigned int alloc_sz = 1<<10;

class Ddr3TestIndication : public Ddr3TestIndicationWrapper
{
public:
  Ddr3TestIndication(unsigned int id) : Ddr3TestIndicationWrapper(id){}
  virtual void writeDone(uint32_t v) {
    fprintf(stderr, "writeDone %d\n", v);
    sem_post(&test_sem);
  }
  virtual void readDone(uint32_t v) {
    fprintf(stderr, "readDone %d\n", v);
    sem_post(&test_sem);
  }
};

int main(int argc, const char **argv)
{
  DmaManager *dma = platformInit();
  Ddr3TestRequestProxy *testRequest = new Ddr3TestRequestProxy(IfcNames_Ddr3TestRequestS2H);
  Ddr3TestIndication testIndication(IfcNames_Ddr3TestIndicationH2S);

  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }
  int srcAlloc = portalAlloc(alloc_sz, 0);
  int dstAlloc = portalAlloc(alloc_sz, 0);
  unsigned int *srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  for (int i = 0; i < 1024/4; i++) {
      srcBuffer[i] = i;
      fprintf(stderr, "src dram[%04x]=%08x\n", i*4, srcBuffer[i]);
  }
  int ref_srcAlloc = dma->reference(srcAlloc);
  int ref_dstAlloc = dma->reference(dstAlloc);

  if (1) {
    testRequest->startWriteDram(ref_srcAlloc, 256);
      fprintf(stderr, "Started writing dram\n");
      //for (int i = 0; i < 1024; i += 128) // one write done indication per 128 bytes
      for (int i = 0; i < 2; i++)
	  sem_wait(&test_sem);
      testRequest->startReadDram(ref_dstAlloc, 256);
      for (int i = 0; i < 2; i++)
	sem_wait(&test_sem);
  }
  for (int i = 0; i < 1024/4; i++) {
      fprintf(stderr, "dst dram[%04x]=%08x\n", i*4, dstBuffer[i]);
  }
  return 0;
}
