#include "LoadStore.h"
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
  virtual void loadValue ( unsigned long long value ) {
    fprintf(stderr, "loadValue value=%lx, loading %lx\n", value, srcAlloc.entries[0].dma_address);
    device->load(srcAlloc.entries[0].dma_address, 1);
  }
};

class TestCoreRequest : public CoreRequest
{
public:

  virtual void sglist(unsigned long off, unsigned long long addr, unsigned long len) {
  }

  static TestCoreRequest *createTestCoreRequest(CoreIndication *indication) {
#ifdef ZYNQ
    const char *instanceName = "fpga0"; 
#else
    const char *instanceName = "bluenoc_1"; 
#endif
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

  int rc = device->alloc(alloc_sz, &srcAlloc);
  fprintf(stderr, "alloc rc=%d fd=%d dma_address=%08lx\n", rc, srcAlloc.fd, srcAlloc.entries[0].dma_address);

  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc.fd, 0);
  fprintf(stderr, "srcBuffer=%p\n", srcBuffer);
  *srcBuffer = 0x69abba72;
  rc = device->dCacheFlushInval(&srcAlloc);

  fprintf(stderr, "cache flushed rc=%d\n", rc);

  device->load(srcAlloc.entries[0].dma_address, 4);
  portalExec(0);
}
