#include "ReadBW.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>
#include <errno.h>
#include "../../drivers/pcie/bluenoc.h"

CoreRequest *device = 0;
PortalAlloc srcAlloc;
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
  virtual void storeAddress ( unsigned long long addr ) {
    fprintf(stderr, "storeAddress addr=%08llx *(long*)srcBuffer=%lx\n", addr, *(long*)srcBuffer);
    if (storeCount < 16) {
      std::bitset<128>     value128(0xD00DF00DDEADBEEFul);
      value128 |= (std::bitset<128>(0xAAAABBBBCCCCDDDDul) << 64);
      device->store(srcAlloc.entries[0].dma_address+storeCount*8, value128);
      storeCount++;
    } else {
      device->loadMultiple(srcAlloc.entries[0].dma_address, 63, 16);
    }
  }
  virtual void loadAddress ( unsigned long long addr ) {
    fprintf(stderr, "loadAddress addr=%08llx\n", addr);
  }
  virtual void loadValue ( std::bitset<128> &value, unsigned long cycles ) {
    if (!srcBuffer) {
      srcBuffer = (unsigned int *)mmap(NULL, 1<<16, PROT_READ|PROT_WRITE, MAP_SHARED, device->fd, 1<<16);
    }
    fprintf(stderr, "loadValue value=%08lx%08lx cycles=%ld\n",
	    ((value >> 64) & std::bitset<128>(0xFFFFFFFFFFFFFFFFul)).to_ulong(),
	    (value & std::bitset<128>(0xFFFFFFFFFFFFFFFFul)).to_ulong(),
	    cycles);
    fprintf(stderr, "srcBuffer[0] = %08lx\n", *(long *)srcBuffer);
    //device->load(srcAlloc.entries[0].dma_address, 3);
  }
  virtual void loadMultipleLatency ( unsigned long busWidth, unsigned long beatsPerRead, unsigned long numReads,
				     unsigned long startTime, unsigned long endTime )
  {
    unsigned long numBytes = beatsPerRead * numReads * busWidth / 8;
    unsigned long numCycles = endTime - startTime;
    double numMicroSeconds = numCycles / 125.0;
    double megabytesPerSecond = numBytes / numMicroSeconds;

    fprintf(stderr, "loadMultiple  %ld bytes latency=%ld cycles %f us %f MB/s\n",
	    numBytes, numCycles, numMicroSeconds, megabytesPerSecond);
  }

};

class TestCoreRequest : public CoreRequest
{
public:

  virtual void sglist(unsigned long off, unsigned long long addr, unsigned long len) {
  }

  virtual void paref(unsigned long off, unsigned long ref) {
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


  if (1) {
    int rc = device->alloc(alloc_sz, &srcAlloc);
    fprintf(stderr, "alloc rc=%d fd=%d dma_address=%08lx\n", rc, srcAlloc.header.fd, srcAlloc.entries[0].dma_address);

    srcBuffer = (unsigned int *)device->mmap(&srcAlloc);


    fprintf(stderr, "srcBuffer=%p\n", srcBuffer);
    memset(srcBuffer, 0xba, alloc_sz);
    fprintf(stderr, "srcBuffer[0]=%x\n", srcBuffer[0]);

    for (int cl = 0; cl < alloc_sz/4; cl++) {
      unsigned int *line = srcBuffer+cl;
      asm volatile ("clflush %0" : "+m" (line));
    }
    //rc = device->dCacheFlushInval(&srcAlloc, srcBuffer);
    fprintf(stderr, "cache flushed rc=%d\n", rc);
  } 
  if (1) {
    tPciAlloc pciAlloc;
    srcBuffer = (unsigned int *)mmap(NULL, 1<<16, PROT_READ|PROT_WRITE, MAP_SHARED, device->fd, 1<<16);
    int rc = ioctl(device->fd, BNOC_PCI_ALLOC, &pciAlloc);
    fprintf(stderr, "BNOC_PCI_ALLOC rc=%d errno=%d\n", rc, errno);
    fprintf(stderr, "srcBuffer=%p virt=%p dma_handle=%lx\n", srcBuffer, pciAlloc.virt, pciAlloc.dma_handle);

    srcAlloc.entries[0].dma_address = pciAlloc.dma_handle;
    memset(srcBuffer, 0xda, 8192);
    asm volatile ("clflush %0" : "+m" (srcBuffer[0]));
    //munmap(srcBuffer, 1<<16);
    //srcBuffer = 0;
  }

  if (0) {
    tPortalInfo portal_info;
    int res = ioctl(device->fd, BNOC_IDENTIFY_PORTAL, &portal_info);
    fprintf(stderr, "scratchpad=%08x\n", portal_info.scratchpad);
    srcAlloc.entries[0].dma_address = portal_info.scratchpad;
  }
  if (0) {
    int rc = ioctl(device->fd, BNOC_DMA_MAP, srcAlloc.header.fd);
    fprintf(stderr, "BNOC_DMA_MAP rc=%d errno=%d\n", rc, errno);
  }
  std::bitset<128>     value128(0xD00DF00DDEADBEEFul);
  value128 |= (std::bitset<128>(0xAAAABBBBCCCCDDDDul) << 64);
  device->store(srcAlloc.entries[0].dma_address, value128);
  //device->loadMultiple(srcAlloc.entries[0].dma_address, 3, 1);
  portalExec(0);

}
