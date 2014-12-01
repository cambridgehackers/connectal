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
#include "ReadBW.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
//#include <pthread.h>
#include <errno.h>
#include "../../drivers/pcie/bluenoc.h"

CoreRequest *device = 0;
int srcAlloc;
unsigned int *srcBuffer = 0;
size_t alloc_sz = 8192;

int storeCount = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len) ; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}


class TestCoreIndication : public CoreIndication
{
  virtual void storeAddress ( uint64_t addr ) {
    fprintf(stderr, "storeAddress addr=%08llx *(long*)srcBuffer=%lx\n", addr, *(long*)srcBuffer);
    if (storeCount < 16) {
      std::bitset<128>     value128(0xD00DF00DDEADBEEFul);
      value128 |= (std::bitset<128>(0xAAAABBBBCCCCDDDDul) << 64);
      device->store(srcAlloc.entries[0].dma_address+storeCount*8, value128);
      storeCount++;
    } else {
      device->loadMultiple(srcAlloc.entries[0].dma_address, 7, 32);
    }
  }
  virtual void loadAddress ( uint64_t addr ) {
    fprintf(stderr, "loadAddress addr=%08llx\n", addr);
  }
  virtual void loadValue ( std::bitset<128> &value, uint32_t cycles ) {
    if (!srcBuffer) {
      srcBuffer = (unsigned int *)mmap(NULL, 1<<16, PROT_READ|PROT_WRITE, MAP_SHARED, device->fd, 1<<16);
    }
    fprintf(stderr, "loadValue value=%08lx%08lx cycles=%ld\n",
	    ((value >> 64) & std::bitset<128>(0xFFFFFFFFFFFFFFFFul)).to_ulong(),
	    (value & std::bitset<128>(0xFFFFFFFFFFFFFFFFul)).to_ulong(),
	    cycles);
    fprintf(stderr, "srcBuffer[0] = %08lx\n", *(long *)srcBuffer);
  }
  virtual void loadMultipleLatency ( uint32_t busWidth, uint32_t beatsPerRead, uint32_t numReads,
				     uint32_t startTime, uint32_t endTime )
  {
    uint32_t numBytes = beatsPerRead * numReads * busWidth / 8;
    uint32_t numCycles = endTime - startTime;
    double numMicroSeconds = numCycles / 125.0;
    double megabytesPerSecond = numBytes / numMicroSeconds;

    fprintf(stderr, "loadMultiple  %ld bytes latency=%ld cycles %f us %f MB/s\n",
	    numBytes, numCycles, numMicroSeconds, megabytesPerSecond);
  }

};

class TestCoreRequest : public CoreRequest
{
public:

  virtual void sglist(uint32_t off, uint64_t addr, uint32_t len) {
  }

  virtual void paref(uint32_t off, uint32_t ref, uint32_t foo) {
  }

  static TestCoreRequest *createTestCoreRequest(CoreIndication *indication) {
    const char *instanceName = "fpga0"; 
    TestCoreRequest *instance = new TestCoreRequest(instanceName, indication);
    return instance;
  }

protected:
  TestCoreRequest(const char *instanceName, CoreIndication *indication)
    : CoreRequest(instanceName, indication)
  {
  }

  ~TestCoreRequest() {}
};

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = TestCoreRequest::createTestCoreRequest(new TestCoreIndication);

  fprintf(stderr, "allocating memory...\n");

  memset(&srcAlloc, 0, sizeof(srcAlloc));


  // use PortalAlloc
  if (1) {
    int rc = 0;
    srcAlloc = device->alloc(alloc_sz);
    fprintf(stderr, "alloc rc=%d fd=%d\n", rc, srcAlloc);

    srcBuffer = (unsigned int *)device->mmap(&srcAlloc);

    fprintf(stderr, "srcBuffer=%p\n", srcBuffer);
    memset(srcBuffer, 0xba, alloc_sz);
    fprintf(stderr, "srcBuffer[0]=%x\n", srcBuffer[0]);

    // flush cache not needed on x86
#ifdef __arm__
    rc = device->dCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
    fprintf(stderr, "cache flushed rc=%d\n", rc);
#endif
    // map the Dma buf into PCIe. Seems not to be needed.
    //rc = ioctl(device->fd, BNOC_DMA_BUF_MAP, srcAlloc.header.fd);
    //fprintf(stderr, "BNOC_DMA_BUF_MAP rc=%d errno=%d\n", rc, errno);

  } else {
    // use bluenoc driver to allocate memory coherent with PCIe
    tDmaMap dmaMap;
    srcBuffer = (unsigned int *)mmap(NULL, 1<<16, PROT_READ|PROT_WRITE, MAP_SHARED, device->fd, 1<<16);
    int rc = ioctl(device->fd, BNOC_DMA_MAP, &dmaMap);
    fprintf(stderr, "BNOC_PCI_ALLOC rc=%d errno=%d\n", rc, errno);
    fprintf(stderr, "srcBuffer=%p virt=%p dma_handle=%lx\n", srcBuffer, dmaMap.virt, dmaMap.dma_handle);

    srcAlloc.entries[0].dma_address = dmaMap.dma_handle;
    memset(srcBuffer, 0xda, 8192);
  }

  std::bitset<128>     value128(0xD00DF00DDEADBEEFul);
  value128 |= (std::bitset<128>(0xAAAABBBBCCCCDDDDul) << 64);
  device->store(srcAlloc.entries[0].dma_address, value128);
  //device->loadMultiple(srcAlloc.entries[0].dma_address, 3, 1);
  portalExec(0);

}
