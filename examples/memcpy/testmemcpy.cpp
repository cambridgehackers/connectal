
#include "Memcpy.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

Memcpy *device = 0;
PortalAlloc srcAlloc;
PortalAlloc dstAlloc;
int srcFd = -1;
int dstFd = -1;
char *srcBuffer = 0;
char *dstBuffer = 0;
int phase = 0;
int numWords = 32;


void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s: ", prefix);
    for (int i = 0; i < (len > 16 ? 16 : len); i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class TestMemcpyIndications : public MemcpyIndications
{
  virtual void started() {
    fprintf(stderr, "started\n");
  }
  virtual void started1(unsigned long src, unsigned long srcLimit, unsigned long dst, unsigned long dstLimit){
    fprintf(stderr, "started1:  srcPhys=%lx\n", src);
    fprintf(stderr, "started1: srcLimit=%lx\n", srcLimit);
    fprintf(stderr, "started1:  dstPhys=%lx\n", dst);
    fprintf(stderr, "started1: dstLimit=%lx\n", dstLimit);
  }
  virtual void traceData(long long unsigned int){}
  virtual void sampleCount(long unsigned int){}
  virtual void srcPhys(unsigned long src) {
    fprintf(stderr, "srcPhys: %lx\n", src);
  }
  virtual void srcLimit(unsigned long limit) {
    fprintf(stderr, "srcLimit: %lx\n", limit);
  }
  virtual void dstPhys(unsigned long dst) {
    fprintf(stderr, "dstPhys: %lx\n", dst);
  }
  virtual void dstLimit(unsigned long limit) {
    fprintf(stderr, "dstLimit: %lx\n", limit);
  }
  virtual void src(unsigned long src) {
    fprintf(stderr, "src: %lx\n", src);
  }
  virtual void dst(unsigned long dst) {
    fprintf(stderr, "dst: %lx\n", dst);
  }
  virtual void rData(unsigned long long v) {
    dump("rData: ", (char*)&v, sizeof(v));
  }
  virtual void readWordResult ( unsigned long addr, unsigned long long v ){
    dump("readWordResult: ", (char*)&v, sizeof(v));
    exit(0);
  }
  virtual void done(unsigned long v) {
    fprintf(stderr, "phase %d memcpy done: %lx\n", phase, v);
    switch (phase++) {
    // case 0: {
    //   device->readWord(srcAlloc.entries[0].dma_address);
    //   device->memcpy(srcAlloc.entries[0].dma_address,
    // 		     dstAlloc.entries[0].dma_address,
    // 		     numWords);
    // } break;
    default: {
      size_t size=4096;
      device->readWord(dstAlloc.entries[0].dma_address);
      fprintf(stderr, "memcmp src=%lx dst=%lx success=%s\n",
	      srcBuffer, dstBuffer, memcmp(srcBuffer, dstBuffer, size) == 0 ? "yes" : "no");
      dump("src", srcBuffer, size);
      dump("dst", dstBuffer, size);
    }
    }
  }
};

int main(int argc, const char **argv)
{
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  device = Memcpy::createMemcpy("fpga0", new TestMemcpyIndications);
  size_t size = 4096;

  PortalInterface::alloc(size, &srcFd, &srcAlloc);
  PortalInterface::alloc(size, &dstFd, &dstAlloc);

  srcBuffer = (char *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcFd, 0);
  dstBuffer = (char *)mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, dstFd, 0);

  for (int i = 0; i < size; i++){
    srcBuffer[i] = i;
    dstBuffer[i] = 5;
  }
  
  device->readWord(srcAlloc.entries[0].dma_address);

  //device->reset(8);
  // fprintf(stderr, "starting mempcy src:%x dst:%x numWords:%x\n",
  // 	  srcAlloc.entries[0].dma_address,
  // 	  dstAlloc.entries[0].dma_address,
  // 	  numWords); // num words
  // device->memcpy(dstAlloc.entries[0].dma_address,
  // 		 srcAlloc.entries[0].dma_address,
  // 		 numWords);
  PortalInterface::exec();
}
