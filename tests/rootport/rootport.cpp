#include <stdio.h>

#include "portal.h"
#include "RootPortIndication.h"
#include "RootPortRequest.h"

class RootPortIndication : public RootPortIndicationWrapper {
  sem_t sem;
public:
    virtual void readDone ( const uint64_t data ) {
	fprintf(stderr, "%s:%d data=%08llx\n", __FUNCTION__, __LINE__, (long long)data);
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

class RootPort {
    RootPortRequestProxy device;
    RootPortIndication  indication;
public:
    RootPort()
	: device(IfcNames_RootPortRequestS2H)
	, indication(IfcNames_RootPortIndicationH2S) {
	sleep(1);
	device.status();
	indication.wait();
    }
    void readCtl(uint32_t addr);
    void writeCtl(uint32_t addr, uint32_t data);
    void read(uint32_t addr);
    void write(uint32_t addr, uint64_t data);
};

void RootPort::readCtl(uint32_t addr)
{
    device.readCtl(addr);
    indication.wait();
}
void RootPort::writeCtl(uint32_t addr, uint32_t data)
{
    device.writeCtl(addr, data);
    indication.wait();
}
void RootPort::read(uint32_t addr)
{
    device.read(addr);
    indication.wait();
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
    rootPort.writeCtl((1 << 20) + 0x10, 0x220000);
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
    if (1) {
      // pause for vivado to connect
      fprintf(stderr, "type enter to continue:");
      char line[100];
      fgets(line, sizeof(line), stdin);
    }

    fprintf(stderr, "Reading card memory space\n");
    for (int i = 0; i < 16; i++)
      rootPort.read(0x220000 + i*4);
    for (int i = 0; i < 10; i++)
      sleep(1);
    return 0;
}

