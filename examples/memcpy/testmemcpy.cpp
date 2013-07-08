
#include "Memcpy.h"
#include <stdio.h>
#include <sys/mman.h>

Memcpy *device = 0;
PortalAlloc srcAlloc;
PortalAlloc dstAlloc;
int srcFd = -1;
int dstFd = -1;
char *srcBuffer = 0;
char *dstBuffer = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s: ", prefix);
    for (int i = 0; i < 16; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

class TestMemcpyIndications : public MemcpyIndications
{
    virtual void started(unsigned long src) {
	device->getSrcPhys();
	device->getSrcLimit();
	device->getDstPhys();
	device->getDstLimit();
    }
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
	fprintf(stderr, "memcpy read: %lx\n", src);
    }
    virtual void rData(unsigned long v) {
	fprintf(stderr, "memcpy read data: %lx\n", v);
    }
    virtual void wData(unsigned long v) {
	fprintf(stderr, "memcpy write data: %lx\n", v);
    }
    virtual void done(unsigned long v) {
        fprintf(stderr, "memcpy done: %lx\n", v);
	size_t size=4096;
	dstBuffer = (char *)mmap(0, size, PROT_READ|PROT_WRITE, MAP_SHARED, dstFd, 0);
	fprintf(stderr, "memcmp %lx %lx => %d\n",
		srcBuffer, dstBuffer, memcmp(srcBuffer, dstBuffer, size));
	dump("src", srcBuffer, size);
	dump("dst", dstBuffer, size);
	exit(0);
    }
};

int main(int argc, const char **argv)
{
    device = Memcpy::createMemcpy("fpga0", new TestMemcpyIndications);
    size_t size = 4096;
    PortalInterface::alloc(size, &srcFd, &srcAlloc);
    srcBuffer = (char *)mmap(0, size, PROT_READ|PROT_WRITE, MAP_SHARED, srcFd, 0);
    memset((long *)srcBuffer, 0xdeadd00d, size/4);
    for (int i = 0; i < size; i++)
	srcBuffer[i] = i;
    PortalInterface::alloc(size, &dstFd, &dstAlloc);

    //device->reset(8);

    int numWords = 32;
    fprintf(stderr, "starting mempcy %x %x %x\n",
	    dstAlloc.entries[0].dma_address,
	    srcAlloc.entries[0].dma_address,
	    numWords); // num words
    device->memcpy(dstAlloc.entries[0].dma_address,
		   srcAlloc.entries[0].dma_address,
		   numWords);
    PortalInterface::exec();
}
