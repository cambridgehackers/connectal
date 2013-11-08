#include "ReadBW.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>

CoreRequest *device = 0;
PortalAlloc srcAlloc;
unsigned int *srcBuffer = 0;
size_t alloc_sz = 8192;

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
    device->load(srcAlloc.entries[0].dma_address+16, 1);
  }
  virtual void loadAddress ( unsigned long long addr ) {
    fprintf(stderr, "loadAddress addr=%08llx\n", addr);
  }
  virtual void loadValue ( std::bitset<128> &value, unsigned long cycles ) {
    fprintf(stderr, "loadValue value=%08lx%08lx cycles=%ld\n", (value >> 64).to_ulong(), value.to_ulong(), cycles);
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
    *srcBuffer = 0x69abba72;

    asm volatile ("clflush %0" :: "m" (srcBuffer));
    //rc = device->dCacheFlushInval(&srcAlloc, srcBuffer);
    fprintf(stderr, "cache flushed rc=%d\n", rc);
  }

  //device->store(srcAlloc.entries[0].dma_address+16, 0xd00df00ddeadbeefULL);
  device->load(srcAlloc.entries[0].dma_address, 15);
  portalExec(0);
}
