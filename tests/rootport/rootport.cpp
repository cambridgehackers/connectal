#include <stdio.h>

#include "portal.h"
#include "dmaManager.h"
#include "RootPortIndication.h"
#include "RootPortRequest.h"
#include "RootPortTrace.h"

enum nvme_admin_opcode {
    nvme_identify = 0xe2 // 6?
};

struct nvme_admin_cmd {
    uint8_t opcode;
    uint8_t flags;
    uint16_t cid;
    uint32_t nsid;
    uint32_t reserved0;
    uint32_t reserved1;
    uint64_t mptr;
    uint64_t prp1;
    uint64_t prp2;
    uint32_t cdw10;
    uint32_t cdw11;
    uint32_t cdw12;
    uint32_t cdw13;
    uint32_t cdw14;
    uint32_t cdw15;
};

struct nvme_io_cmd {
    uint8_t opcode;
    uint8_t flags;
    uint16_t cid;
    uint32_t nsid;
    uint32_t reserved0;
    uint32_t reserved1;
    uint64_t mptr;
    uint64_t prp1;
    uint64_t prp2;
    uint32_t cdw10;
    uint32_t cdw11;
    uint32_t cdw12;
    uint32_t cdw13;
    uint32_t cdw14;
    uint32_t cdw15;
};

class RootPortTrace : public RootPortTraceWrapper {
public:
    void traceDmaRequest(const DmaChannel chan, const int write, const uint16_t objId, const uint64_t offset, const uint16_t burstLen, const uint8_t tag, const uint32_t timestamp) {
	fprintf(stderr, "%08x: traceDmaRequest chan=%d write=%d objId=%d offset=%08lx burstLen=%d tag=%x\n", timestamp, chan, write, objId, (long)offset, burstLen, tag);
    }
    void traceDmaData ( const DmaChannel chan, const int write, const uint64_t data, const int last, const uint8_t tag, const uint32_t timestamp ) {
	fprintf(stderr, "%08x: traceDmaData chan=%d write=%d data=%08llx last=%d tag=%x\n", timestamp, chan, write, (long long)data, last, tag);
    }

    RootPortTrace(int id, PortalPoller *poller = 0) : RootPortTraceWrapper(id, poller) {
    }
};

class RootPortIndication : public RootPortIndicationWrapper {
    sem_t sem, wsem;
    
public:
    uint64_t value;
    virtual void readDone ( const uint64_t data ) {
	//fprintf(stderr, "%s:%d data=%08llx\n", __FUNCTION__, __LINE__, (long long)data);
	value = data;
	sem_post(&sem);
    }
    virtual void writeDone (  ) {
	//fprintf(stderr, "%s:%d\n", __FUNCTION__, __LINE__);
	sem_post(&wsem);
    }
    virtual void status ( const uint8_t mmcm_lock ) {
	fprintf(stderr, "%s:%d mmcm_lock=%d\n", __FUNCTION__, __LINE__, mmcm_lock);
	sem_post(&sem);
    }	

    void wait() {
	sem_wait(&sem);
    }
    void waitwrite() {
	sem_wait(&wsem);
    }
    RootPortIndication(int id, PortalPoller *poller = 0) : RootPortIndicationWrapper(id, poller) {
	sem_init(&sem, 0, 0);
	sem_init(&wsem, 0, 0);
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
    // invalidate and optionally flush from the dcache
    void cacheFlush(int size=0, int flush=0);
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

void DmaBuffer::cacheFlush(int size, int flush)
{
    if (size == 0)
	size = this->size;
    portalCacheFlush(fd, buf, size, flush);
}


class RootPort {
    RootPortRequestProxy device;
    RootPortIndication  indication;
    RootPortTrace       trace;
public:
    DmaBuffer dummy;
    DmaBuffer transferBuffer;
    DmaBuffer adminSubmissionQueue;
    DmaBuffer adminCompletionQueue;
    DmaBuffer ioSubmissionQueue;
    DmaBuffer ioCompletionQueue;
    int transferBufferRef;
    int adminSubmissionQueueRef;
    int adminCompletionQueueRef;
    int ioSubmissionQueueRef;
    int ioCompletionQueueRef;

    RootPort()
	: device(IfcNames_RootPortRequestS2H)
	, indication(IfcNames_RootPortIndicationH2S)
	, trace(IfcNames_RootPortTraceH2S)
	, dummy(4096)
	, transferBuffer(10*4096)
	, adminSubmissionQueue(64*64)
	, adminCompletionQueue(4096)
	, ioSubmissionQueue(8192)
	, ioCompletionQueue(8192) {
	
	dummy.reference();
	transferBufferRef = transferBuffer.reference();
	adminSubmissionQueueRef = adminSubmissionQueue.reference();
	adminCompletionQueueRef = adminCompletionQueue.reference();
	fprintf(stderr, "adminSubmissionQueue %d\n", adminSubmissionQueue.reference());
	fprintf(stderr, "adminCompletionQueue %d\n", adminCompletionQueue.reference());
	ioSubmissionQueueRef = ioSubmissionQueue.reference();
	ioCompletionQueueRef = ioCompletionQueue.reference();
	fprintf(stderr, "ioSubmissionQueue %d\n", ioSubmissionQueue.reference());
	fprintf(stderr, "ioCompletionQueue %d\n", ioCompletionQueue.reference());
	device.status();
	indication.wait();
    }
    uint32_t readCtl(uint32_t addr);
    void writeCtl(uint32_t addr, uint32_t data);
    uint64_t read(uint32_t addr);
    void write(uint32_t addr, uint64_t data);
    uint32_t read32(uint32_t addr);
    void write32(uint32_t addr, uint32_t data);
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
    indication.waitwrite();
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
    //indication.wait();
}
uint32_t RootPort::read32(uint32_t addr)
{
    device.read32(addr);
    indication.wait();
    uint64_t v = indication.value;
    return (uint32_t)(v >> ((addr & 4) ? 32 : 0));
    //return v;
}
void RootPort::write32(uint32_t addr, uint32_t data)
{
    uint64_t v = data;
    //fixme byte enables
    //device.write(addr & ~7, v << ((addr & 4) ? 32 : 0));
    device.write32(addr, v);
    //indication.wait();
}

void memserverWrite(RootPort *rootPort)
{
    // identify portals
    int numTiles = rootPort->read32(0x02200000 + 0x08);
    int numPortals = rootPort->read32(0x02200000 + 0x14);
    fprintf(stderr, "numTiles=%x numPortals=%x\n", numTiles, numPortals);
    for (int p = 0; p < numPortals; p++) {
	fprintf(stderr, "Platform Portal[%d].id=%x\n", p, rootPort->read32(0x02200000 + p*0x1000 + 0x10));
    }

    numTiles = rootPort->read32(0x02200000 + 0x40000 + 0x08);
    numPortals = rootPort->read32(0x02200000 + 0x40000 + 0x14);
    fprintf(stderr, "numTiles=%x numPortals=%x\n", numTiles, numPortals);
    for (int p = 0; p < numPortals; p++) {
	fprintf(stderr, "Portal[%d].id=%x\n", p, rootPort->read32(0x02200000 + 0x40000 + p*0x1000 + 0x10));
    }

    if (1) {
	// pause for vivado to connect
	fprintf(stderr, "type enter to continue:\n");
	char line[100];
	fgets(line, sizeof(line), stdin);
    }

    // start write test
    int pointer = 1;
    int numWords = 0x1000;
    int burstLen = 64;
    int numReqs = numWords / burstLen;
    int byteEnable = 0xff;
    rootPort->write32(0x02200000 + 0x41000 + 0x20, (pointer>>24));
    rootPort->write32(0x02200000 + 0x41000 + 0x20, (numWords>>24)|(((unsigned long)pointer)<<8));
    rootPort->write32(0x02200000 + 0x41000 + 0x20, (numReqs>>24)|(((unsigned long)numWords)<<8));
    rootPort->write32(0x02200000 + 0x41000 + 0x20, (burstLen>>24)|(((unsigned long)numReqs)<<8));
    rootPort->write32(0x02200000 + 0x41000 + 0x20, byteEnable|(((unsigned long)burstLen)<<8));
}

void identify(RootPort *rootPort)
{
    memset(rootPort->adminCompletionQueue.buffer(), 0xbf, 4096);

    fprintf(stderr, "sizeof(nvmd_id_cmd)=%d\n", sizeof(nvme_admin_cmd));
    // write an identify command
    nvme_admin_cmd *cmd = (nvme_admin_cmd *)rootPort->adminSubmissionQueue.buffer();
    memset(cmd, 0, 64);
    cmd->opcode = 6; //nvme_identify;
    cmd->cid = 22;
    cmd->nsid = 0;
    cmd->prp1 = (rootPort->transferBufferRef << 24) + 0;
    cmd->prp2 = (rootPort->transferBufferRef << 24) + 4096;
    cmd->cdw10 = 1;

    //rootPort->adminSubmissionQueue.cacheFlush(4096, 1);
    //rootPort->adminCompletionQueue.cacheFlush(4096, 0);

    // update submission queue tail
    rootPort->write32(0x1000, 1);
    //rootPort->write32(0x1000, 64);
    fprintf(stderr, "CTS %08x\n", rootPort->read32( 0x1c));
    fprintf(stderr, "CMDSTATUS: %08x\n", rootPort->readCtl((1 << 20) + 0x4));
    sleep(1);
    fprintf(stderr, "CTS %08x\n", rootPort->read32( 0x1c));
    fprintf(stderr, "CMDSTATUS: %08x\n", rootPort->readCtl((1 << 20) + 0x4));
    {
	int *buffer = (int *)rootPort->adminCompletionQueue.buffer();
	for (int i = 0; i < 16; i++) {
	    fprintf(stderr, "response[%02x]=%08x\n", i*4, buffer[i]);
	}
	int status = buffer[3];
	int more = (status >> 30) & 1;
	int sc = (status >> 17) & 0xff;
	int sct = (status >> 25) & 0x7;
	fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    }
    {
	char *cbuffer = (char *)(rootPort->transferBuffer.buffer() + 0);
	int *buffer = (int *)(rootPort->transferBuffer.buffer() + 0);
	for (int i = 0; i < 16; i++) {
	    fprintf(stderr, "identity[%02x]=%08x\n", i*4, buffer[i]);
	}
	fprintf(stderr, "error log page entries %d\n", cbuffer[262]);
	fprintf(stderr, "host buffer preferred size %x\n", *(int *)&cbuffer[272]);
	fprintf(stderr, "host buffer min size       %x\n", *(int *)&cbuffer[276]);
	fprintf(stderr, "nvm submission queue entry size %d\n", cbuffer[512]);
	fprintf(stderr, "nvm completion queue entry size %d\n", cbuffer[513]);
	fprintf(stderr, "nvm capacity: %08llx %08llx\n", *(long long *)&cbuffer[288], *(long long *)&cbuffer[280]);

    }
}

void allocIOQueues(RootPort *rootPort, int entry=0)
{
    nvme_admin_cmd *cmd = 0;

    // create I/O completion queue
    cmd = (nvme_admin_cmd *)(rootPort->adminSubmissionQueue.buffer() + (entry+0)*64);
    memset(cmd, 0, 64);
    cmd->opcode = 5; //create I/O completion queue
    cmd->cid = 18;
    cmd->nsid = 0;
    cmd->prp1 = (rootPort->ioCompletionQueueRef << 24) + 0;
    cmd->cdw10 = ((8192 / 16 - 1) << 16) | 1; // size, completion queue 1
    cmd->cdw11 = 1; // physically contiguous

    // create I/O submission queue
    cmd = (nvme_admin_cmd *)(rootPort->adminSubmissionQueue.buffer() + (entry+1)*64);
    memset(cmd, 0, 64);
    cmd->opcode = 1; //create I/O submission queue
    cmd->cid = 17;
    cmd->nsid = 0;
    cmd->prp1 = (rootPort->ioSubmissionQueueRef << 24) + 0;
    cmd->cdw10 = ((8192 / 64 - 1) << 16) + 1; // submission queue 1
    cmd->cdw11 = (1 << 16) | 1; // completion queue 1, physically contiguous


    fprintf(stderr, "allocating IO submission queue\n");
    // update submission queue tail
    rootPort->write32(0x1000, entry+2);

    sleep(1);
    {
	int *buffer = (int *)(rootPort->adminCompletionQueue.buffer() + (entry+0)*16);
	for (int i = 0; i < 16; i++) {
	    fprintf(stderr, "response[%02x]=%08x\n", i*4, buffer[i]);
	}
	int status = buffer[3];
	int more = (status >> 30) & 1;
	int sc = (status >> 17) & 0xff;
	int sct = (status >> 25) & 0x7;
	fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    }
    {
	int *buffer = (int *)(rootPort->adminCompletionQueue.buffer() + (entry+1)*16);
	for (int i = 0; i < 16; i++) {
	    fprintf(stderr, "response[%02x]=%08x\n", i*4, buffer[i]);
	}
	int status = buffer[3];
	int more = (status >> 30) & 1;
	int sc = (status >> 17) & 0xff;
	int sct = (status >> 25) & 0x7;
	fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    }
    
    {
	// let's do a read
	nvme_io_cmd *cmd = (nvme_io_cmd *)(rootPort->ioSubmissionQueue.buffer() + (entry+0)*64);
	memset(cmd, 0, 64);
	cmd->opcode = 2; // read
	cmd->cid = 42;
	cmd->nsid = 1;
	cmd->prp1 = (rootPort->transferBufferRef << 24) + 0;
	cmd->cdw10 = 0; // starting LBA.lower
	cmd->cdw11 = 0; // starting LBA.upper
	cmd->cdw12 = 7; // read 8 blocks

	fprintf(stderr, "enqueueing IO read request\n");
	// update submission queue tail
	rootPort->write32(0x1000+(2*1*(4 << 0)), 1);
	sleep(1);
	{
	    int *buffer = (int *)(rootPort->ioCompletionQueue.buffer() + (entry+0)*16);
	    for (int i = 0; i < 16; i++) {
		fprintf(stderr, "response[%02x]=%08x\n", i*4, buffer[i]);
	    }
	    int status = buffer[3];
	    int more = (status >> 30) & 1;
	    int sc = (status >> 17) & 0xff;
	    int sct = (status >> 25) & 0x7;
	    fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
	}
	{
	    int *buffer = (int *)(rootPort->transferBuffer.buffer() + (entry+0)*16);
	    for (int i = 0; i < 8*512/4; i++) {
		fprintf(stderr, "data read [%02x]=%08x\n", i*4, buffer[i]);
	    }
	}
    }

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
    rootPort.writeCtl(0x10, 0xFFFFFFFF);
    rootPort.writeCtl(0x14, 0xFFFFFFFF);
    fprintf(stderr, "Root Port BAR0: %08x\n", rootPort.readCtl((0 << 20) + 0x10));
    fprintf(stderr, "Root Port BAR1: %08x\n", rootPort.readCtl((0 << 20) + 0x14));
    rootPort.writeCtl(0x10, 0x0);
    rootPort.writeCtl(0x14, 0x0);
    fprintf(stderr, "Enabling card I/O and Memory, bus master, parity and SERR\n");
    rootPort.writeCtl((1 << 20) + 4, 0x147);
    fprintf(stderr, "reading config regs\n");
    rootPort.readCtl((1 << 20) + 0);
    rootPort.readCtl((1 << 20) + 4);
    rootPort.readCtl((1 << 20) + 8);
    fprintf(stderr, "Card BAR0: %08x\n", rootPort.readCtl((1 << 20) + 0x10));
    fprintf(stderr, "reading AXI BAR\n");
    rootPort.readCtl(0x208);
    rootPort.readCtl(0x20C);
    rootPort.readCtl(0x210);
    fprintf(stderr, "writing card BAR0\n");
    for (int i = 0; i < 6; i++) {
	rootPort.writeCtl((1 << 20) + 0x10 + 4*i, 0xffffffff);
	rootPort.readCtl((1 << 20) + 0x10 + 4*i);
    }
    rootPort.writeCtl((1 << 20) + 0x10, 0);
    rootPort.writeCtl((1 << 20) + 0x14, 0x0000);
    rootPort.writeCtl((1 << 20) + 0x18, 0x02200000); // BAR1
    rootPort.writeCtl((1 << 20) + 0x1c, 0x00000000);
    rootPort.writeCtl((1 << 20) + 0x10+5*4, 0); // sata card
    fprintf(stderr, "reading card BARs\n");
    for (int i = 0; i < 6; i++) {
	fprintf(stderr, "BAR%d: %08x\n", i, rootPort.readCtl((1 << 20) + 0x10 + 4*i));
    }

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
	fprintf(stderr, "Reading card memory space BAR0\n");
	for (int i = 0; i < 8; i++)
	    fprintf(stderr, "BAR0[%02x]=%08x\n", i*4, rootPort.read32(0 + i*4));
    }
    if (0) {
	fprintf(stderr, "Reading card memory space BAR2\n");
	for (int i = 0; i < 8; i++)
	    fprintf(stderr, "BAR1[%02x]=%08x\n", i*4, rootPort.read32(0x02200000 + i*4));
    }

    fprintf(stderr, "CTS %08x\n", rootPort.read32( 0x1c));
    rootPort.write32(0x1c, 0x10); // clear reset bit
    fprintf(stderr, "CTS %08x\n", rootPort.read32( 0x1c));

    // disable
    rootPort.write32(0x14, 0);
    // reset
    rootPort.write32(0x20, 0x4e564d65);
    sleep(1);
    fprintf(stderr, "Reset reg %08x\n", rootPort.read32(0x20));
    fprintf(stderr, "CTS %08x\n", rootPort.read32( 0x1c));

    fprintf(stderr, "CMB size     %08x\n", rootPort.read32(0x38));
    fprintf(stderr, "CMB location %08x\n", rootPort.read32(0x3c));
    uint64_t adminCompletionBaseAddress = rootPort.adminCompletionQueueRef << 24;
    uint64_t adminSubmissionBaseAddress = rootPort.adminSubmissionQueueRef << 24;
    fprintf(stderr, "Setting up Admin submission and completion queues %llx %llx\n",
	    (long long)adminCompletionBaseAddress, (long long)adminSubmissionBaseAddress);
    rootPort.write(0x28, adminSubmissionBaseAddress);
    fprintf(stderr, "AdminSubmissionBaseAddress %08llx\n", (long long)rootPort.read(0x28));
    rootPort.write(0x30, adminCompletionBaseAddress);
    fprintf(stderr, "AdminCompletionBaseAddress %08llx\n", (long long)rootPort.read(0x30));
    rootPort.write32(0x24, 0x003f003f);
    fprintf(stderr, "register 0x20 %x\n", rootPort.read32(0x20));

    fprintf(stderr, "CTS %08x\n", rootPort.read32( 0x1c));
    // CC.enable
    rootPort.write32(0x14, 1);
    fprintf(stderr, "CTS %08x\n", rootPort.read32( 0x1c));

    //identify(&rootPort);
    allocIOQueues(&rootPort, 0);

    fprintf(stderr, "CTS %08x\n", rootPort.read32( 0x1c));

    return 0;
}

