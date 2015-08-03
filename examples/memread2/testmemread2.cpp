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
#include "Memread2Indication.h"
#include "Memread2Request.h"

int srcAlloc, srcAlloc2;
unsigned int *srcBuffer = 0;
unsigned int *srcBuffer2 = 0;
int numWords = 16 << 8;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (size_t i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class Memread2Indication : public Memread2IndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readReq(uint32_t v){
    //fprintf(stderr, "Memread2::readReq %lx\n", v);
  }
  virtual void readDone(uint32_t v){
    fprintf(stderr, "Memread2::readDone mismatch=%x\n", v);
    mismatchCount = v;
    //    if (mismatchesReceived == mismatchCount)
    // exit(v ? 1 : 0);
  }
  virtual void started(uint32_t words){
    fprintf(stderr, "Memread2::started: words=%x\n", words);
  }
  virtual void rData ( uint64_t v ){
    fprintf(stderr, "rData (%08x): ", rDataCnt++);
    dump("", (char*)&v, sizeof(v));
  }
  virtual void reportStateDbg(uint32_t x, uint32_t y){
    fprintf(stderr, "Memread2::reportStateDbg: x=%08x y=%08x\n", x, y);
  }  
  virtual void mismatch(uint32_t offset, uint64_t ev, uint64_t v) {
    fprintf(stderr, "Mismatch at %x %llx != %llx\n", offset, (long long)ev, (long long)v);

    mismatchesReceived++;
    if (mismatchesReceived == mismatchCount)
      exit(1);
  }
  Memread2Indication(int id) : Memread2IndicationWrapper(id), mismatchCount(0), mismatchesReceived(0){}
private:
  int mismatchCount;
  int mismatchesReceived;
};

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;
  int limit = 20;

  Memread2RequestProxy *device = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new Memread2RequestProxy(IfcNames_Memread2RequestS2H);
  DmaManager *dma = platformInit();
  Memread2Indication deviceIndication(IfcNames_Memread2IndicationH2S);

  fprintf(stderr, "Main::allocating memory...\n");
  srcAlloc = portalAlloc(alloc_sz, 0);
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  srcAlloc2 = portalAlloc(alloc_sz, 0);
  srcBuffer2 = (unsigned int *)portalMmap(srcAlloc2, alloc_sz);

  for (int i = 0; i < numWords; i++){
    int v = srcGen++;
    srcBuffer[i] = v;
    srcBuffer2[i] = v*3;
  }
    
  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);
  fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);
  unsigned int ref_srcAlloc2 = dma->reference(srcAlloc2);
  fprintf(stderr, "ref_srcAlloc2=%d\n", ref_srcAlloc2);

  fprintf(stderr, "Main::starting read %08x\n", numWords);
  device->startRead(ref_srcAlloc, ref_srcAlloc2, 32, 16);
  fprintf(stderr, "Main::sleeping\n");
  while(limit-- > 0){
    sleep(3);
    device->getStateDbg();
    //uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    uint64_t beats = 0;
    fprintf(stderr, "   beats: %"PRIx64"\n", beats);
    //hostMemServerRequest->stateDbg(ChannelType_Read);
    platformStatistics();
  }
  return 0;
}
