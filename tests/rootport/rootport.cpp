#include <stdio.h>

#include "portal.h"
#include "dmaManager.h"
#include "RootPortIndication.h"
#include "RootPortRequest.h"

class RootPortIndication : public RootPortIndicationWrapper {
  sem_t sem;
public:
    uint64_t value;
    virtual void readDone ( const uint64_t data ) {
	fprintf(stderr, "%s:%d data=%08llx\n", __FUNCTION__, __LINE__, (long long)data);
	value = data;
	sem_post(&sem);
    }
    virtual void writeDone (  ) {
	fprintf(stderr, "%s:%d\n", __FUNCTION__, __LINE__);
	sem_post(&sem);
    }
    virtual void status ( const uint8_t mmcm_lock ) {
	fprintf(stderr, "%s:%d mmcm_lock=%d\n", __FUNCTION__, __LINE__, mmcm_lock);
	sem_post(&sem);
    }	

    void wait() {
	sem_wait(&sem);
    }
    RootPortIndication(int id, PortalPoller *poller = 0) : RootPortIndicationWrapper(id, poller) {
	sem_init(&sem, 0, 0);
    }
  
};

class DmaBuffer {
    const int size;
    int fd;
    char *buf;
    int ref;
    static DmaManager *mgr;
    static void initDmaManager();
public:
    // Allocates a portal memory object of specified size and maps it into user process
    DmaBuffer(int size);
    // Dereferences and deallocates the portal memory object
    // if destructor is not called, the object is automatically
    // unreferenced and freed when the process exits
    ~DmaBuffer();
    // returns the address of the mapped buffer
    char *buffer() {
	return buf;
    }
    // returns the reference to the object
    //
    // Sends the address translation table to hardware MMU if necessary.
    uint32_t reference();
    // Removes the address translation table from the hardware MMU
    void dereference();
};

DmaManager *DmaBuffer::mgr;

void DmaBuffer::initDmaManager()
{
    if (!mgr)
	mgr = platformInit();
}


DmaBuffer::DmaBuffer(int size)
  : size(size), ref(-1)
{
    fd = portalAlloc(size, 1);
    buf = (char *)portalMmap(fd, size);
}

DmaBuffer::~DmaBuffer()
{
    dereference();
    portalMunmap(buf, size);
    close(fd);
}

uint32_t DmaBuffer::reference()
{
    initDmaManager();
    if (ref == -1)
	ref = mgr->reference(fd);
    return ref;
}

void DmaBuffer::dereference()
{
    if (ref != -1 && mgr)
	mgr->dereference(ref);
    ref = -1;
}

class RootPort {
    RootPortRequestProxy device;
    RootPortIndication  indication;
    DmaBuffer dmaBuffer;
public:
    RootPort()
	: device(IfcNames_RootPortRequestS2H)
	, indication(IfcNames_RootPortIndicationH2S)
	, dmaBuffer(1024*1024) {
	device.status();
	indication.wait();
    }
    uint32_t readCtl(uint32_t addr);
    void writeCtl(uint32_t addr, uint32_t data);
    uint64_t read(uint32_t addr);
    void write(uint32_t addr, uint64_t data);
};

uint32_t RootPort::readCtl(uint32_t addr)
{
    device.readCtl(addr);
    indication.wait();
    return (uint32_t)indication.value;
}
void RootPort::writeCtl(uint32_t addr, uint32_t data)
{
    device.writeCtl(addr, data);
    indication.wait();
}
uint64_t RootPort::read(uint32_t addr)
{
    device.read(addr);
    indication.wait();
    return indication.value;
}
void RootPort::write(uint32_t addr, uint64_t data)
{
    device.write(addr, data);
    indication.wait();
}

int main(int argc, const char **argv)
{
    RootPort rootPort;

    sleep(1);
    fprintf(stderr, "Enabling I/O and Memory, bus master, parity and SERR\n");
    rootPort.writeCtl(0x004, 0x147);
    rootPort.readCtl(0x004);
    rootPort.readCtl(0x130);
    rootPort.readCtl(0x134);
    rootPort.readCtl(0x18);
    // required
    rootPort.writeCtl(0x18, 0x00070100);
    rootPort.readCtl(0x18);
    fprintf(stderr, "Enabling card I/O and Memory, bus master, parity and SERR\n");
    rootPort.writeCtl((1 << 20) + 4, 0x147);
    fprintf(stderr, "reading config regs\n");
    rootPort.readCtl((1 << 20) + 0);
    rootPort.readCtl((1 << 20) + 4);
    rootPort.readCtl((1 << 20) + 8);
    rootPort.readCtl((1 << 20) + 0x10);
    fprintf(stderr, "reading AXI BAR\n");
    rootPort.readCtl(0x208);
    rootPort.readCtl(0x20C);
    rootPort.readCtl(0x210);
    fprintf(stderr, "writing card BAR0\n");
    for (int i = 0; i < 6; i++) {
	rootPort.writeCtl((1 << 20) + 0x10 + 4*i, 0xffffffff);
	rootPort.readCtl((1 << 20) + 0x10 + 4*i);
    }
    rootPort.writeCtl((1 << 20) + 0x10, 0x2200000);
    rootPort.writeCtl((1 << 20) + 0x10+5*4, 0x2200000); // sata card
    rootPort.writeCtl((1 << 20) + 0x14, 0x0000);
    rootPort.readCtl((1 << 20) + 0x10);
    rootPort.readCtl((1 << 20) + 0x14);
    fprintf(stderr, "Enabling bridge\n");
    rootPort.readCtl(0x148);
    rootPort.writeCtl(0x148, 1);
    rootPort.readCtl(0x148);
    rootPort.readCtl(0x140);
    rootPort.writeCtl(0x140, 0x00010000);
    rootPort.readCtl(0x140);
    if (0) {
      // pause for vivado to connect
      fprintf(stderr, "type enter to continue:");
      char line[100];
      fgets(line, sizeof(line), stdin);
    }

    fprintf(stderr, "Reading card memory space\n");
    for (int i = 0; i < 16; i++)
      rootPort.read(0x2200000 + i*8);
    for (int i = 0; i < 10; i++)
      sleep(1);
    return 0;
}

