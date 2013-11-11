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
    fprintf(stderr, "storeAddress addr=%08llx\n", addr);
    if (storeCount < 16) {
      device->store(srcAlloc.entries[0].dma_address+storeCount*8, 0xd00df00ddeadbeefULL);
      storeCount++;
    } else {
      device->load(srcAlloc.entries[0].dma_address, 3);
    }
  }
  virtual void loadAddress ( unsigned long long addr ) {
    fprintf(stderr, "loadAddress addr=%08llx\n", addr);
  }
  virtual void loadValue ( std::bitset<128> &value, unsigned long cycles ) {
    fprintf(stderr, "loadValue value=%08lx%08lx cycles=%ld\n", (value >> 64).to_ulong(), value.to_ulong(), cycles);
    fprintf(stderr, "srcBuffer[0] = %08lx\n", *(long *)srcBuffer);
    //device->load(srcAlloc.entries[0].dma_address, 7);
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


  for (int i = 0; i < 1; i++) {
    int rc = device->alloc(alloc_sz, &srcAlloc);
    fprintf(stderr, "alloc rc=%d fd=%d dma_address=%08lx\n", rc, srcAlloc.header.fd, srcAlloc.entries[0].dma_address);

    srcBuffer = (unsigned int *)device->mmap(&srcAlloc);


    fprintf(stderr, "srcBuffer=%p\n", srcBuffer);
    memset(srcBuffer, 0xba, alloc_sz);
    fprintf(stderr, "srcBuffer[0]=%x\n", srcBuffer[0]);

    for (int cl = 0; cl < alloc_sz/4; cl++) {
      asm volatile ("clflush %0" : "+m" (*(long *)(srcBuffer+cl)));
    }
    //rc = device->dCacheFlushInval(&srcAlloc, srcBuffer);
    fprintf(stderr, "cache flushed rc=%d\n", rc);
  }

  device->store(srcAlloc.entries[0].dma_address, 0xd00df00ddeadbeefULL);
  if (0) {
    tPortalInfo portal_info;
    int res = ioctl(device->fd, BNOC_IDENTIFY_PORTAL, &portal_info);
    fprintf(stderr, "scratchpad=%08x\n", portal_info.scratchpad);
    srcAlloc.entries[0].dma_address = portal_info.scratchpad;
  } else {
    int rc = ioctl(device->fd, BNOC_DMA_MAP, srcAlloc.header.fd);
    fprintf(stderr, "BNOC_DMA_MAP rc=%d errno=%d\n", rc, errno);
  }
  //device->load(srcAlloc.entries[0].dma_address, 3);
  portalExec(0);

}
