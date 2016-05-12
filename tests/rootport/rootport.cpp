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

    if (0) {
      // pause for vivado to connect
      fprintf(stderr, "type enter to continue:");
      char line[100];
      fgets(line, sizeof(line), stdin);
    }

    sleep(1);
    rootPort.readCtl(0x130);
    rootPort.readCtl(0x134);
    rootPort.readCtl(0x18);
    rootPort.writeCtl(0x18, 0x00070100);
    rootPort.readCtl(0x18);
    rootPort.readCtl(0x148);
    rootPort.writeCtl(0x148, 1);
    rootPort.readCtl(148);
    fprintf(stderr, "reading 0x1020\n");
    rootPort.read(0x1020);
    fprintf(stderr, "reading 0x40000000\n");
    rootPort.read(1 << 20);
    rootPort.readCtl(0);
    rootPort.readCtl(0);
    for (int i = 0; i < 10; i++)
      sleep(1);
    return 0;

    rootPort.writeCtl(0x148, 0);
    rootPort.readCtl(148);
    rootPort.writeCtl(0x0010, 0xfffff000);
    rootPort.readCtl(0x0010);
    rootPort.writeCtl(0x1010, 0xfffff000);
    rootPort.readCtl(0x1010);


    rootPort.readCtl(0x0000 + (0 << 20) + 0);


    fprintf(stderr, "reading at offset 0x0000\n");
    for (int i = 0; i < 32; i++) {
	rootPort.readCtl(0x0000 + (0 << 20) + 4*i);
    }
    fprintf(stderr, "reading at offset 0x1000\n");
    for (int i = 0; i < 32; i++) {
	rootPort.readCtl(0x1000 + (0 << 20) + 4*i);
    }
    return 0;
}

