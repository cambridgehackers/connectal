#include <stdio.h>

#include "mp.h"
#include "portal.h"
#include "dmaManager.h"
#include "NvmeIndication.h"
#include "NvmeRequest.h"
#include "NvmeTrace.h"

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
    uint8_t opcode;     // offset: 00
    uint8_t flags;
    uint16_t cid;
    uint32_t nsid;      // offset 04
    uint64_t reserved0; // offset 08
    uint64_t mptr;      // offset 16
    uint64_t prp1;      // offset 24
    uint64_t prp2;      // offset 32
    uint32_t cdw10;     // offset 40
    uint32_t cdw11;     // offset 44
    uint32_t cdw12;
    uint32_t cdw13;
    uint32_t cdw14;
    uint32_t cdw15;
};

struct nvme_completion {
    int cdw0;
    int cdw1;
    int cdw2;
    int cdw3;
};

struct sgl_data_block_descriptor {
    uint64_t address;
    uint32_t length;
    uint8_t reserved[3];
    uint8_t sglid;
};

class NvmeTrace : public NvmeTraceWrapper {
public:
    void traceDmaRequest(const DmaChannel chan, const int write, const uint16_t objId, const uint64_t offset, const uint16_t burstLen, const uint8_t tag, const uint32_t timestamp) {
	fprintf(stderr, "%08x: traceDmaRequest chan=%d write=%d objId=%d offset=%08lx burstLen=%d tag=%x\n", timestamp, chan, write, objId, (long)offset, burstLen, tag);
    }
    void traceDmaData ( const DmaChannel chan, const int write, const uint64_t data, const int last, const uint8_t tag, const uint32_t timestamp ) {
	fprintf(stderr, "%08x: traceDmaData chan=%d write=%d data=%08x.%08x last=%d tag=%x\n",
		timestamp, chan, write, (uint32_t)(data>>32), (uint32_t)(data >> 0), last, tag);
    }
    virtual void traceDmaDone ( const DmaChannel chan, const uint8_t tag, const uint32_t timestamp ) {
	fprintf(stderr, "%08x: traceDmaDone chan=%d tag=%x\n", timestamp, chan, tag);
    }
    void traceData ( const uint64_t data, const int last, const uint8_t tag ) {
	fprintf(stderr, "traceData data=%08llx last=%d tag=%x\n", (long long)data, last, tag);
    }

    NvmeTrace(int id, PortalPoller *poller = 0) : NvmeTraceWrapper(id, poller) {
    }
};

class NvmeIndication : public NvmeIndicationWrapper {
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
    virtual void setupComplete() {
	fprintf(stderr, "%s\n", __FUNCTION__);
	sem_post(&sem);
    }
    virtual void strstrLoc ( const uint32_t loc ) {
	fprintf(stderr, "strstr loc loc=%d\n", loc);
    }

    void wait() {
	sem_wait(&sem);
    }
    void waitwrite() {
	sem_wait(&wsem);
    }
    NvmeIndication(int id, PortalPoller *poller = 0) : NvmeIndicationWrapper(id, poller) {
	sem_init(&sem, 0, 0);
	sem_init(&wsem, 0, 0);
    }
  
};

class DmaBuffer {
    const int size;
    const bool cached;
    int fd;
    char *buf;
    int ref;
    static DmaManager *mgr;
    static void initDmaManager();
public:
    // Allocates a portal memory object of specified size and maps it into user process
    DmaBuffer(int size, bool cached=true);
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
    void cacheInvalidate(int size=0, int flush=0);
};

DmaManager *DmaBuffer::mgr;

void DmaBuffer::initDmaManager()
{
    if (!mgr)
	mgr = platformInit();
}


DmaBuffer::DmaBuffer(int size, bool cached)
    : size(size), cached(cached), ref(-1)
{
    fd = portalAlloc(size, cached);
    buf = (char *)portalMmap(fd, size);
    if (1) {
	cacheInvalidate(size, 0);
    }
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

void DmaBuffer::cacheInvalidate(int size, int flush)
{
#ifndef USE_ACP
    if (size == 0)
	size = this->size;
    if (cached) {
      portalCacheFlush(fd, buf, size, flush);
    }
#else
    fprintf(stderr, "cacheInvalidate skipped due to use of ACP\n");
#endif
}


class Nvme {
    NvmeRequestProxy device;
    NvmeIndication  indication;
    NvmeTrace       trace;
    int adminRequestNumber;
    int ioRequestNumber;
public:
    DmaBuffer dummy;
    DmaBuffer transferBuffer;
    DmaBuffer adminSubmissionQueue;
    DmaBuffer adminCompletionQueue;
    DmaBuffer ioSubmissionQueue;
    DmaBuffer ioCompletionQueue;
    DmaBuffer needleBuffer;
    DmaBuffer mpNextBuffer;
    int transferBufferRef;
    int adminSubmissionQueueRef;
    int adminCompletionQueueRef;
    int ioSubmissionQueueRef;
    int ioCompletionQueueRef;
    int needleRef;
    int mpNextRef;

    static const int ioQueueSize = 4096;

    Nvme()
	: device(IfcNames_NvmeRequestS2H)
	, indication(IfcNames_NvmeIndicationH2S)
	, trace(IfcNames_NvmeTraceH2S)
	, adminRequestNumber(0)
	, ioRequestNumber(0)
	, dummy(4096)
	, transferBuffer(10*4096)
	, adminSubmissionQueue(4096)
	, adminCompletionQueue(4096)
	, ioSubmissionQueue(ioQueueSize)
	, ioCompletionQueue(ioQueueSize)
	, needleBuffer(8192)
	, mpNextBuffer(8192)
  {
	
	dummy.reference();
	transferBufferRef = transferBuffer.reference();
	adminSubmissionQueueRef = adminSubmissionQueue.reference();
	adminCompletionQueueRef = adminCompletionQueue.reference();
	fprintf(stderr, "adminSubmissionQueue %d\n", adminSubmissionQueue.reference());
	fprintf(stderr, "adminCompletionQueue %d\n", adminCompletionQueue.reference());
	ioSubmissionQueueRef = ioSubmissionQueue.reference();
	ioCompletionQueueRef = ioCompletionQueue.reference();
	needleRef = needleBuffer.reference();
	mpNextRef = mpNextBuffer.reference();
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

    int setSearchString ( const uint32_t needleSglId, const uint32_t mpNextSglId, const uint32_t needleLen );
    int startSearch ( const uint32_t searchLen );

    int adminCommand(const nvme_admin_cmd *cmd, nvme_completion *completion);
    int ioCommand(const nvme_io_cmd *cmd, nvme_completion *completion);

};

uint32_t Nvme::readCtl(uint32_t addr)
{
    device.readCtl(addr);
    indication.wait();
    return (uint32_t)indication.value;
}
void Nvme::writeCtl(uint32_t addr, uint32_t data)
{
    device.writeCtl(addr, data);
    indication.waitwrite();
}
uint64_t Nvme::read(uint32_t addr)
{
    device.read(addr);
    indication.wait();
    return indication.value;
}
void Nvme::write(uint32_t addr, uint64_t data)
{
    device.write(addr, data);
    //indication.wait();
}
uint32_t Nvme::read32(uint32_t addr)
{
    device.read32(addr);
    indication.wait();
    uint64_t v = indication.value;
    return (uint32_t)(v >> ((addr & 4) ? 32 : 0));
    //return v;
}
void Nvme::write32(uint32_t addr, uint32_t data)
{
    uint64_t v = data;
    //fixme byte enables
    //device.write(addr & ~7, v << ((addr & 4) ? 32 : 0));
    device.write32(addr, v);
    //indication.wait();
}

int Nvme::setSearchString ( const uint32_t needleSglId, const uint32_t mpNextSglId, const uint32_t needleLen )
{
    device.setSearchString(needleSglId, mpNextSglId, needleLen);
    // completion method is missing
    //indication.wait();
    sleep(1);
}
int Nvme::startSearch ( const uint32_t searchLen )
{
    device.startSearch(searchLen);
}

void memserverWrite(Nvme *nvme)
{
    // identify portals
    int numTiles = nvme->read32(0x02200000 + 0x08);
    int numPortals = nvme->read32(0x02200000 + 0x14);
    fprintf(stderr, "numTiles=%x numPortals=%x\n", numTiles, numPortals);
    for (int p = 0; p < numPortals; p++) {
	fprintf(stderr, "Platform Portal[%d].id=%x\n", p, nvme->read32(0x02200000 + p*0x1000 + 0x10));
    }

    numTiles = nvme->read32(0x02200000 + 0x40000 + 0x08);
    numPortals = nvme->read32(0x02200000 + 0x40000 + 0x14);
    fprintf(stderr, "numTiles=%x numPortals=%x\n", numTiles, numPortals);
    for (int p = 0; p < numPortals; p++) {
	fprintf(stderr, "Portal[%d].id=%x\n", p, nvme->read32(0x02200000 + 0x40000 + p*0x1000 + 0x10));
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
    nvme->write32(0x02200000 + 0x41000 + 0x20, (pointer>>24));
    nvme->write32(0x02200000 + 0x41000 + 0x20, (numWords>>24)|(((unsigned long)pointer)<<8));
    nvme->write32(0x02200000 + 0x41000 + 0x20, (numReqs>>24)|(((unsigned long)numWords)<<8));
    nvme->write32(0x02200000 + 0x41000 + 0x20, (burstLen>>24)|(((unsigned long)numReqs)<<8));
    nvme->write32(0x02200000 + 0x41000 + 0x20, byteEnable|(((unsigned long)burstLen)<<8));
}

int Nvme::adminCommand(const nvme_admin_cmd *cmd, nvme_completion *completion)
{
    nvme_admin_cmd *requests = (nvme_admin_cmd *)adminSubmissionQueue.buffer();
    int requestNumber        = adminRequestNumber % (4096 / sizeof(nvme_admin_cmd));
    nvme_admin_cmd *request  = &requests[requestNumber];
    int *responses           = (int *)adminCompletionQueue.buffer();
    int responseNumber       = adminRequestNumber % (4096 / 16);
    int *response            = &responses[responseNumber * 4];

    fprintf(stderr, "%s:%d requestNumber=%d responseNumber = %d\n", __FUNCTION__, __LINE__, requestNumber, responseNumber);

    *request = *cmd;
    request->cid = adminRequestNumber++;

    adminSubmissionQueue.cacheInvalidate(4096, 1);
    adminCompletionQueue.cacheInvalidate(4096, 0);

    // update submission queue tail
    write32(0x1000, requestNumber+1);
    sleep(1);

    for (int i = 0; i < 4; i++) {
	fprintf(stderr, "    response[%02x]=%08x\n", i*4, response[i]);
    }
    int status = response[3];
    int more = (status >> 30) & 1;
    int sc = (status >> 17) & 0xff;
    int sct = (status >> 25) & 0x7;
    fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    return sc;
}

int Nvme::ioCommand(const nvme_io_cmd *cmd, nvme_completion *completion)
{
    nvme_io_cmd *requests = (nvme_io_cmd *)ioSubmissionQueue.buffer();
    int requestNumber        = ioRequestNumber % (Nvme::ioQueueSize / sizeof(nvme_io_cmd));
    nvme_io_cmd *request  = &requests[requestNumber];
    int *responses           = (int *)ioCompletionQueue.buffer();
    int responseNumber       = ioRequestNumber % (Nvme::ioQueueSize / 16);
    int *response            = &responses[responseNumber * 4];

    fprintf(stderr, "%s:%d requestNumber=%d responseNumber = %d requestOffset=%x io request objid=%d\n",
	    __FUNCTION__, __LINE__, requestNumber, responseNumber, requestNumber*sizeof(nvme_io_cmd), ioSubmissionQueueRef);

    ioSubmissionQueue.cacheInvalidate(Nvme::ioQueueSize, 0);

    *request = *cmd;
    request->cid = ioRequestNumber++;

    ioSubmissionQueue.cacheInvalidate(Nvme::ioQueueSize, 1);
    ioCompletionQueue.cacheInvalidate(Nvme::ioQueueSize, 0);

    // update submission queue tail
    write32(0x1000+(2*1*(4<<0)), requestNumber+1);

    sleep(1);

    for (int i = 0; i < 4; i++) {
	fprintf(stderr, "    response[%02x]=%08x\n", i*4, response[i]);
    }
    int status = response[3];
    int more = (status >> 30) & 1;
    int sc = (status >> 17) & 0xff;
    int sct = (status >> 25) & 0x7;
    fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    return sc;
}

void identify(Nvme *nvme)
{
    fprintf(stderr, "sizeof(nvmd_id_cmd)=%d\n", sizeof(nvme_admin_cmd));
    // write an identify command
    nvme_completion completion;
    nvme_admin_cmd buffer;
    nvme_admin_cmd *cmd = &buffer;
    memset(cmd, 0, 64);
    cmd->opcode = 6; //nvme_identify;
    cmd->cid = 22;
    cmd->nsid = 0;
    cmd->prp1 = (nvme->transferBufferRef << 24) + 0;
    cmd->prp2 = (nvme->transferBufferRef << 24) + 4096;
    cmd->cdw10 = 1;

    nvme->adminCommand(cmd, &completion);

    {
	char *cbuffer = (char *)(nvme->transferBuffer.buffer() + 0);
	int *buffer = (int *)(nvme->transferBuffer.buffer() + 0);
	char str[128];
	fprintf(stderr, "PCI vendorid %02x\n", *(unsigned short *)&cbuffer[0]);
	fprintf(stderr, "PCI deviceid %02x\n", *(unsigned short *)&cbuffer[2]);
	snprintf(str, 20, "%s", &cbuffer[4]);
	fprintf(stderr, "serial number '%s'\n", str);
	snprintf(str, 40, "%s", &cbuffer[24]);
	fprintf(stderr, "model number  '%s'\n", str);
	fprintf(stderr, "host buffer preferred size %x\n", *(int *)&cbuffer[272]);
	fprintf(stderr, "host buffer min size       %x\n", *(int *)&cbuffer[276]);
	fprintf(stderr, "nvm submission queue entry size %d\n", cbuffer[512]);
	fprintf(stderr, "nvm completion queue entry size %d\n", cbuffer[513]);
	fprintf(stderr, "maximum data transfer size: %d blocks\n", cbuffer[77] ? 2^cbuffer[77] : -1);
	fprintf(stderr, "controller id: %d\n", *(unsigned short *)&cbuffer[78]);
	fprintf(stderr, "OACS: %x\n", *(unsigned short *)&cbuffer[256]);
	fprintf(stderr, "log page attributes: %x\n", cbuffer[261]);
	fprintf(stderr, "error log page entries %d\n", cbuffer[262]);
	fprintf(stderr, "host memory buffer preferred size: %x\n", *(unsigned int *)&cbuffer[272]);
	fprintf(stderr, "host memory buffer minimum size: %x\n", *(unsigned int *)&cbuffer[272]);
	fprintf(stderr, "nvm capacity: %08llx %08llx\n", *(long long *)&cbuffer[288], *(long long *)&cbuffer[280]);
	fprintf(stderr, "unallocated capacity: %08llx %08llx\n", *(long long *)&cbuffer[304], *(long long *)&cbuffer[296]);
	fprintf(stderr, "number of namespaces: %x\n", *(unsigned int *)&cbuffer[516]);
	fprintf(stderr, "ONCS: %x\n", *(unsigned short *)&cbuffer[520]);
	fprintf(stderr, "supports SGL: %x\n", *(int *)&cbuffer[536]);
    }
}

void allocIOQueues(Nvme *nvme, int entry=0)
{
    nvme_completion completion;
    nvme_admin_cmd buffer;
    nvme_admin_cmd *cmd = &buffer;

    // create I/O completion queue
    memset(cmd, 0, 64);
    cmd->opcode = 5; //create I/O completion queue
    cmd->cid = 17;
    cmd->nsid = 0;
    cmd->prp1 = (nvme->ioCompletionQueueRef << 24) + 0;
    cmd->cdw10 = ((Nvme::ioQueueSize / 16 - 1) << 16) | 1; // size, completion queue 1
    cmd->cdw11 = 1; // physically contiguous
    nvme->adminCommand(cmd, &completion);

    // create I/O submission queue
    memset(cmd, 0, 64);
    cmd->opcode = 1; //create I/O submission queue
    cmd->cid = 18;
    cmd->nsid = 0;
    cmd->prp1 = (nvme->ioSubmissionQueueRef << 24) + 0;
    cmd->cdw10 = ((Nvme::ioQueueSize / 64 - 1) << 16) + 1; // submission queue 1
    cmd->cdw11 = (1 << 16) | 1; // completion queue 1, physically contiguous
    nvme->adminCommand(cmd, &completion);
}

void doIO(Nvme *nvme, int startBlock, int numBlocks)
{
    int blocksPerPage = 4096 / 512;
    // clear transfer buffer
    {
	int *buffer = (int *)nvme->ioCompletionQueue.buffer();
	memset(buffer, 0, numBlocks*512);
    }

    // let's do a read
    nvme_io_cmd cmd;
    nvme_completion completion;
    memset(&cmd, 0, 64);
    cmd.opcode = 2; // read
    cmd.nsid = 1;
    if (0) {
	cmd.prp1 = (nvme->transferBufferRef << 24) + 0;
    } else {
	cmd.flags = 0x40; // SGL used for this transfer
	cmd.prp1 = 0x30000000ul; // send data to the FIFO
	cmd.prp2 = (nvme->transferBufferRef << 24) + 0;
	uint64_t *prplist = (uint64_t *)nvme->transferBuffer.buffer();
	for (int i = 0; i < numBlocks/blocksPerPage; i++) {
	    prplist[i] = (uint64_t)(0x30000000ul + 0x1000*i + 0x1000); // send data to the FIFO
	}
    }
    cmd.cdw10 = 10; // starting LBA.lower
    cmd.cdw11 = 0; // starting LBA.upper
    cmd.cdw12 = numBlocks-1; // read N blocks

    nvme->transferBuffer.cacheInvalidate(8*512, 1);

    fprintf(stderr, "IO cmd opcode=%02x flags=%02x cid=%04x %08x\n", cmd.opcode, cmd.flags, cmd.cid, *(int *)&cmd);
    fprintf(stderr, "enqueueing IO read request offsetof(prp1)=%d offsetof(prp2)=%d offsetof(cdw10)=%d sizeof(req)=%d\n",
	    offsetof(nvme_io_cmd,prp1), offsetof(nvme_io_cmd,prp2), offsetof(nvme_io_cmd,cdw10), sizeof(nvme_io_cmd));

    int sc = nvme->ioCommand(&cmd, &completion);
    if (sc) {
	int *buffer = (int *)nvme->transferBuffer.buffer();
	for (int i = 0; i < numBlocks*512/4; i++) {
	    if (buffer[i])
		fprintf(stderr, "data read [%02x]=%08x\n", i*4, buffer[i]);
	}
    }
}

int main(int argc, const char **argv)
{
    Nvme nvme;

    sleep(1);
    fprintf(stderr, "Enabling I/O and Memory, bus master, parity and SERR\n");
    nvme.writeCtl(0x004, 0x147);
    nvme.readCtl(0x004);
    nvme.readCtl(0x130);
    nvme.readCtl(0x134);
    nvme.readCtl(0x18);
    // required
    nvme.writeCtl(0x18, 0x00070100);
    nvme.readCtl(0x18);
    nvme.writeCtl(0x10, 0xFFFFFFFF);
    nvme.writeCtl(0x14, 0xFFFFFFFF);
    fprintf(stderr, "Root Port BAR0: %08x\n", nvme.readCtl((0 << 20) + 0x10));
    fprintf(stderr, "Root Port BAR1: %08x\n", nvme.readCtl((0 << 20) + 0x14));
    nvme.writeCtl(0x10, 0x0);
    nvme.writeCtl(0x14, 0x0);
    fprintf(stderr, "Enabling card I/O and Memory, bus master, parity and SERR\n");
    nvme.writeCtl((1 << 20) + 4, 0x147);
    fprintf(stderr, "reading config regs\n");
    nvme.readCtl((1 << 20) + 0);
    nvme.readCtl((1 << 20) + 4);
    nvme.readCtl((1 << 20) + 8);
    fprintf(stderr, "Card BAR0: %08x\n", nvme.readCtl((1 << 20) + 0x10));
    fprintf(stderr, "reading AXI BAR\n");
    nvme.readCtl(0x208);
    nvme.readCtl(0x20C);
    nvme.readCtl(0x210);
    fprintf(stderr, "writing card BAR0\n");
    for (int i = 0; i < 6; i++) {
	nvme.writeCtl((1 << 20) + 0x10 + 4*i, 0xffffffff);
	nvme.readCtl((1 << 20) + 0x10 + 4*i);
    }
    nvme.writeCtl((1 << 20) + 0x10, 0);
    nvme.writeCtl((1 << 20) + 0x14, 0x0000);
    nvme.writeCtl((1 << 20) + 0x18, 0x02200000); // BAR1
    nvme.writeCtl((1 << 20) + 0x1c, 0x00000000);
    nvme.writeCtl((1 << 20) + 0x10+5*4, 0); // sata card
    fprintf(stderr, "reading card BARs\n");
    for (int i = 0; i < 6; i++) {
	fprintf(stderr, "BAR%d: %08x\n", i, nvme.readCtl((1 << 20) + 0x10 + 4*i));
    }

    nvme.readCtl((1 << 20) + 0x10);
    nvme.readCtl((1 << 20) + 0x14);
    fprintf(stderr, "Enabling bridge\n");
    nvme.readCtl(0x148);
    nvme.writeCtl(0x148, 1);
    nvme.readCtl(0x148);
    nvme.readCtl(0x140);
    nvme.writeCtl(0x140, 0x00010000);
    nvme.readCtl(0x140);

    if (1) {
	fprintf(stderr, "Reading card memory space BAR0\n");
	for (int i = 0; i < 8; i++)
	    fprintf(stderr, "BAR0[%02x]=%08x\n", i*4, nvme.read32(0 + i*4));
    }
    if (0) {
	fprintf(stderr, "Reading card memory space BAR2\n");
	for (int i = 0; i < 8; i++)
	    fprintf(stderr, "BAR1[%02x]=%08x\n", i*4, nvme.read32(0x02200000 + i*4));
    }

    fprintf(stderr, "CTS %08x\n", nvme.read32( 0x1c));
    nvme.write32(0x1c, 0x10); // clear reset bit
    fprintf(stderr, "CTS %08x\n", nvme.read32( 0x1c));

    // disable
    nvme.write32(0x14, 0);
    // reset
    nvme.write32(0x20, 0x4e564d65);
    sleep(1);
    fprintf(stderr, "Reset reg %08x\n", nvme.read32(0x20));
    fprintf(stderr, "CTS %08x\n", nvme.read32( 0x1c));

    fprintf(stderr, "CMB size     %08x\n", nvme.read32(0x38));
    fprintf(stderr, "CMB location %08x\n", nvme.read32(0x3c));
    uint64_t adminCompletionBaseAddress = nvme.adminCompletionQueueRef << 24;
    uint64_t adminSubmissionBaseAddress = nvme.adminSubmissionQueueRef << 24;
    fprintf(stderr, "Setting up Admin submission and completion queues %llx %llx\n",
	    (long long)adminCompletionBaseAddress, (long long)adminSubmissionBaseAddress);
    nvme.write(0x28, adminSubmissionBaseAddress);
    fprintf(stderr, "AdminSubmissionBaseAddress %08llx\n", (long long)nvme.read(0x28));
    nvme.write(0x30, adminCompletionBaseAddress);
    fprintf(stderr, "AdminCompletionBaseAddress %08llx\n", (long long)nvme.read(0x30));
    nvme.write32(0x24, 0x003f003f);
    fprintf(stderr, "register 0x20 %x\n", nvme.read32(0x20));

    fprintf(stderr, "CTS %08x\n", nvme.read32( 0x1c));
    // CC.enable
    nvme.write32(0x14, 1);
    fprintf(stderr, "CTS %08x\n", nvme.read32( 0x1c));

    const char *needle = "property";
    int needle_len = strlen(needle);
    int border[needle_len+1];

    compute_borders(nvme.needleBuffer.buffer(), border, needle_len);
    compute_MP_next(nvme.needleBuffer.buffer(), (int *)nvme.mpNextBuffer.buffer(), needle_len);
    nvme.needleBuffer.cacheInvalidate(0, 1); // flush the whole thing
    nvme.mpNextBuffer.cacheInvalidate(0, 1); // flush the whole thing

    //FIXME: read the text from NVME storage
    //MP(needle, haystack, mpNext, needle_len, haystack_len, &sw_match_cnt);

    // the MPEngine will read in the needle and mpNext
    nvme.setSearchString(nvme.needleRef, nvme.mpNextRef, needle_len);

    identify(&nvme);
    allocIOQueues(&nvme, 0);
    nvme.startSearch(8177*512);

    fprintf(stderr, "CTS %08x\n", nvme.read32( 0x1c));
    int startBlock = 34816;
    int numBlocks = 8; //8177;
    for (int block = 0; block < 8177; block += numBlocks) {
      doIO(&nvme, startBlock, numBlocks);
      startBlock += numBlocks;
    }

    return 0;
}

