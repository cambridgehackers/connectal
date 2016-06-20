#include <stdio.h>
//#include "jsoncpp/json/json.h"
#include <map>
#include <string>

#include "DmaBuffer.h"
#include "mp.h"
#include "portal.h"
#include "dmaManager.h"
#include "NvmeIndication.h"
#include "NvmeRequest.h"
#include "NvmeTrace.h"
#include "MemServerPortalRequest.h"
#include "MemServerPortalIndication.h"
//#include "ConnectalProjectConfig.h"

const int DataBusWidth = 64;
const int DataBusBytes = DataBusWidth/8;

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
  std::multimap<int,std::string> traceValues;
public:
    void traceDmaRequest(const DmaChannel chan, const int write, const uint16_t objId, const uint64_t offset, const uint16_t burstLen, const uint8_t tag, const uint32_t timestamp) {
	char msg[128];
	snprintf(msg, sizeof(msg), "%08x: traceDmaRequest chan=%d write=%d objId=%d offset=%08lx burstLen=%d tag=%x\n", timestamp, chan, write, objId, (long)offset, burstLen, tag);
	traceValues.insert(std::pair<int, std::string>(timestamp, std::string(msg)));
    }
    void traceDmaData ( const DmaChannel chan, const int write, const bsvvector_Luint32_t_L4 data, const int last, const uint8_t tag, const uint32_t timestamp ) {
	char msg[128];
	char datastr[128];
	int offset = 0;
	for (int i = 0; i < PcieDataBusWidth/32; i++)
	    offset += snprintf(datastr+offset, sizeof(datastr)-offset-1, " %08x", data[i]);

	snprintf(msg, sizeof(msg), "%08x: traceDmaData chan=%d write=%d data=%s last=%d tag=%x\n",
		timestamp, chan, write, datastr, last, tag);
	traceValues.insert(std::pair<int, std::string>(timestamp, std::string(msg)));
    }
    virtual void traceDmaDone ( const DmaChannel chan, const uint8_t tag, const uint32_t timestamp ) {
	char msg[128];
	snprintf(msg, sizeof(msg), "%08x: traceDmaDone chan=%d tag=%x\n", timestamp, chan, tag);
	traceValues.insert(std::pair<int, std::string>(timestamp, std::string(msg)));
    }
    void traceData ( const bsvvector_Luint32_t_L4 data, const int last, const uint8_t tag, const uint32_t timestamp ) {
	char datastr[128];
	int offset = 0;
	for (int i = 0; i < PcieDataBusWidth/32; i++)
	    offset += snprintf(datastr+offset, sizeof(datastr)-offset-1, " %08x", data[i]);
	char msg[128];
	snprintf(msg, sizeof(msg), "traceData data=%s last=%d tag=%x\n", datastr, last, tag);
	traceValues.insert(std::pair<int,std::string>(timestamp, std::string(msg)));
    }

    void dumpTrace() {
	int prev = 0;
	for (auto it=traceValues.begin(); it!=traceValues.end(); ++it) {
	    fprintf(stderr, "%08d %4d %s", it->first, it->first - prev, it->second.c_str());
	    prev = it->first;
	}
    }

    NvmeTrace(int id, PortalPoller *poller = 0) : NvmeTraceWrapper(id, poller) {
    }
};

class NvmeIndication : public NvmeIndicationWrapper {
    sem_t sem, wsem;
    
public:
    uint64_t value;
    uint32_t requests;
    uint32_t cycles;
    virtual void readDone ( const uint64_t data ) {
	//fprintf(stderr, "%s:%d data=%08llx\n", __FUNCTION__, __LINE__, (long long)data);
	value = data;
	sem_post(&sem);
    }
    virtual void writeDone (  ) {
	//fprintf(stderr, "%s:%d\n", __FUNCTION__, __LINE__);
	sem_post(&wsem);
    }
    virtual void status ( const uint8_t mmcm_lock, const uint32_t counter ) {
	fprintf(stderr, "%s:%d mmcm_lock=%d counter=%d\n", __FUNCTION__, __LINE__, mmcm_lock, counter);
	sem_post(&sem);
    }	
    virtual void setupComplete() {
	fprintf(stderr, "%s\n", __FUNCTION__);
	sem_post(&sem);
    }
    virtual void strstrLoc ( const uint32_t loc ) {
	fprintf(stderr, "strstr loc loc=%d\n", loc);
    }

  virtual void transferCompleted ( const uint16_t requestId, const uint64_t status, const uint32_t cycles ) {
      fprintf(stderr, "%s:%d requestId=%08x status=%08llx cycles=%d\n", __FUNCTION__, __LINE__, requestId, (long long)status, cycles);
      value = status;
      this->requests++;
      this->cycles += cycles;
      sem_post(&sem);
    }

    void wait() {
	sem_wait(&sem);
    }
    void waitwrite() {
	sem_wait(&wsem);
    }

    NvmeIndication(int id, PortalPoller *poller = 0) : NvmeIndicationWrapper(id, poller), value(0), requests(0), cycles(0) {
	sem_init(&sem, 0, 0);
	sem_init(&wsem, 0, 0);
    }
  
};

class MemServerPortalIndication : public MemServerPortalIndicationWrapper {
    sem_t sem;
    sem_t wsem;
public:
    uint64_t value;
    MemServerPortalIndication(int id, PortalPoller *poller = 0)
	: MemServerPortalIndicationWrapper(id, poller) {
	sem_init(&sem, 0, 0);
	sem_init(&wsem, 0, 0);
    }
    virtual void readDone ( const uint64_t data ) {
	value = data;
	sem_post(&sem);
    }
    virtual void writeDone (  ) {
	sem_post(&wsem);
    }
    void wait() {
	sem_wait(&sem);
    }
    void waitw() {
	sem_wait(&sem);
    }
};

class Nvme {
    NvmeRequestProxy device;
    NvmeIndication  indication;
    NvmeTrace       trace;
    MemServerPortalRequestProxy bram;
    MemServerPortalIndication   bramIndication;
    int adminRequestNumber;
    int ioRequestNumber[3]; // per queue, io queue 0 unused
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
	, bram(IfcNames_MemServerPortalRequestS2H)
	, bramIndication(IfcNames_MemServerPortalIndicationH2S)
	, adminRequestNumber(0)
	, dummy(4096)
	, transferBuffer(10*4096)
	, adminSubmissionQueue(4096)
	, adminCompletionQueue(4096)
	, ioSubmissionQueue(ioQueueSize)
	, ioCompletionQueue(ioQueueSize)
	, needleBuffer(8192)
	, mpNextBuffer(8192)
  {
	
        memset(ioRequestNumber, 0, sizeof(ioRequestNumber));

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
	device.trace(0);
    }
    uint32_t readCtl(uint32_t addr);
    void writeCtl(uint32_t addr, uint32_t data);
    uint64_t read(uint32_t addr);
    void write(uint32_t addr, uint64_t data);
    uint32_t read32(uint32_t addr);
    void write32(uint32_t addr, uint32_t data);
    uint64_t bramRead(uint32_t addr);
    void bramWrite(uint32_t addr, uint64_t data);

    int setSearchString ( const uint32_t needleSglId, const uint32_t mpNextSglId, const uint32_t needleLen );
    int startSearch ( const uint32_t searchLen );

    int adminCommand(nvme_admin_cmd *cmd, nvme_completion *completion);
    int ioCommand(nvme_io_cmd *cmd, nvme_completion *completion, int queue=1);
    void status() {
	device.status();
	indication.wait();
    }
    void transferStats() {
	uint32_t cycles = indication.cycles;
	uint32_t requests = indication.requests;
	fprintf(stderr, "transfer stats: requests=%d cycles=%d average cycles/request=%5.2f\n",
		requests, cycles, (double)cycles/(double)requests);
    }
    void dumpTrace() {
	trace.dumpTrace();
    }
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
uint64_t Nvme::bramRead(uint32_t addr)
{
    bram.read(addr);
    bramIndication.wait();
    return bramIndication.value;
}
void Nvme::bramWrite(uint32_t addr, uint64_t data)
{
    bram.write(addr, data);
    //bramIndication.wait();
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

int Nvme::adminCommand(nvme_admin_cmd *cmd, nvme_completion *completion)
{
    nvme_admin_cmd *requests = (nvme_admin_cmd *)adminSubmissionQueue.buffer();
    int requestNumber        = adminRequestNumber % (4096 / sizeof(nvme_admin_cmd));
    nvme_admin_cmd *request  = &requests[requestNumber];
    int *responses           = (int *)adminCompletionQueue.buffer();
    int responseNumber       = adminRequestNumber % (4096 / 16);
    int *response            = &responses[responseNumber * 4];

    fprintf(stderr, "%s:%d requestNumber=%d responseNumber = %d\n", __FUNCTION__, __LINE__, requestNumber, responseNumber);

    cmd->cid = adminRequestNumber++;
    *request = *cmd;

    adminSubmissionQueue.cacheInvalidate(4096, 1);
    adminCompletionQueue.cacheInvalidate(4096, 0);

    // update submission queue tail
    write32(0x1000 + ((2*0 + 0) * (4 << 0)), requestNumber+1);
    sleep(1);

    for (int i = 0; i < 4; i++) {
	fprintf(stderr, "    response[%02x]=%08x\n", i*4, response[i]);
    }
    int status = response[3];
    int more = (status >> 30) & 1;
    int sc = (status >> 17) & 0xff;
    int sct = (status >> 25) & 0x7;
    write32(0x1000 + ((2*0 + 1) * (4 << 0)), responseNumber+1);
    fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    return sc;
}

int Nvme::ioCommand(nvme_io_cmd *cmd, nvme_completion *completion, int queue)
{
    nvme_io_cmd *requests = (nvme_io_cmd *)ioSubmissionQueue.buffer();
    int requestNumber        = ioRequestNumber[queue] % (Nvme::ioQueueSize / sizeof(nvme_io_cmd));
    nvme_io_cmd *request  = &requests[requestNumber];
    int *responses           = (int *)ioCompletionQueue.buffer();
    int responseNumber       = ioRequestNumber[queue] % (Nvme::ioQueueSize / 16);
    int *response            = &responses[responseNumber * 4];
    int responseBuffer[4];

    fprintf(stderr, "%s:%d requestNumber=%d responseNumber = %d requestOffset=%x io request objid=%d\n",
	    __FUNCTION__, __LINE__, requestNumber, responseNumber, requestNumber*sizeof(nvme_io_cmd), ioSubmissionQueueRef);

    cmd->cid = ioRequestNumber[queue]++;

    if (queue == 2) {
	fprintf(stderr, "%s:%d starting transfer\n", __FUNCTION__, __LINE__);
	device.trace(1);

	device.startTransfer(/* read */ 2, /* flags */ 0, cmd->cid, cmd->cdw10, cmd->cdw12+1, /* dsm */0x71);
	//sleep(1);

	for (int i = 0; i < 16; i++) {
	    fprintf(stderr, "requestbuffer[%02x]=%016llx\n", i, bramRead(0x1000 + i*8));
	}
	for (int i = 0; i < 4; i++) {
	    fprintf(stderr, "responsebuffer[%02x]=%016llx\n", i, bramRead(i*8));
	}

	fprintf(stderr, "%s:%d waiting for completion\n", __FUNCTION__, __LINE__);
	indication.wait();
	int status = indication.value >> 32;
	int more = (status >> 30) & 1;
	int sc = (status >> 17) & 0xff;
	int sct = (status >> 25) & 0x7;
	fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
	return sc;
    }

    if (queue == 1) {
	ioSubmissionQueue.cacheInvalidate(Nvme::ioQueueSize, 0);

	*request = *cmd;

	ioSubmissionQueue.cacheInvalidate(Nvme::ioQueueSize, 1);
	ioCompletionQueue.cacheInvalidate(Nvme::ioQueueSize, 0);
    } else {
	requestNumber = cmd->cid % 8;
	uint32_t bramRequestBase = 0x1000 + requestNumber*sizeof(nvme_io_cmd);
	for (int i = 0; i < sizeof(nvme_io_cmd); i += DataBusBytes) {
	    bramWrite(bramRequestBase+i, ((uint64_t *)cmd)[i/8]);
	    uint64_t val = bramRead(bramRequestBase+i);
	    fprintf(stderr, "bramRequest[%02x]=%08x.%08x\n", bramRequestBase+i, (uint32_t)(val >> 32), (uint32_t)val);
	}
    }

    if (0 && requestNumber==7) {
	fprintf(stderr, "enabling DMA trace\n");
	device.trace(1);
	sleep(1);
    }

    // update submission queue tail
    write32(0x1000+(2*queue*(4<<0)), requestNumber+1);

    sleep(1);

    if (queue != 1) {
	// read response from BRAM
	response = responseBuffer;
	responseNumber = cmd->cid % 8;
	fprintf(stderr, "cmd->cid=%x\n", cmd->cid);
	for (int i = 0; i < sizeof(nvme_completion); i += DataBusBytes) {
	  uint64_t val = bramRead(responseNumber*sizeof(nvme_completion) + i);
	  fprintf(stderr, "i=%02x val=%016llx\n", i, val);
	  ((uint64_t *)responseBuffer)[i/DataBusBytes] = val;
	}
    }

    for (int i = 0; i < 4; i++) {
	fprintf(stderr, "    response[%02x]=%08x\n", i*4, response[i]);
    }
    int status = response[3];
    int more = (status >> 30) & 1;
    int sc = (status >> 17) & 0xff;
    int sct = (status >> 25) & 0x7;
    // clear status field so we can detect when NVME updates it
    if (queue == 1) {
	response[3] = 0;
    } else {
      // clear status field
	bramWrite(responseNumber*sizeof(nvme_completion) + 1, 0);
    }
    // notify NVME that we processed this response
    write32(0x1000 + ((2*queue + 1) * (4 << 0)), responseNumber+1);
    fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    return status ? sc : -1;
}

void identify(Nvme *nvme)
{
    fprintf(stderr, "sizeof(nvmd_id_cmd)=%d\n", sizeof(nvme_admin_cmd));
    // write an identify command
    nvme_completion completion;
    nvme_admin_cmd buffer;
    nvme_admin_cmd *cmd = &buffer;
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = 6; //nvme_identify;
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

enum FeatureId {
    FID_NumberOfQueues = 7
};

void getFeatures(Nvme *nvme, FeatureId featureId=FID_NumberOfQueues)
{
    fprintf(stderr, "sizeof(nvmd_id_cmd)=%d\n", sizeof(nvme_admin_cmd));
    nvme_completion completion;
    nvme_admin_cmd buffer;
    nvme_admin_cmd *cmd = &buffer;
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = 0xa;
    cmd->nsid = 0;
    //cmd->prp1 = (nvme->transferBufferRef << 24) + 0;
    //cmd->prp2 = (nvme->transferBufferRef << 24) + 4096;
    cmd->cdw10 = featureId;

    nvme->adminCommand(cmd, &completion);

    {
	char *cbuffer = (char *)(nvme->transferBuffer.buffer() + 0);
	int *buffer = (int *)(nvme->transferBuffer.buffer() + 0);
	char str[128];
	fprintf(stderr, "foo %x\n", *(unsigned short *)&cbuffer[0]);
    }
}

void allocIOQueues(Nvme *nvme, int entry=0)
{
    nvme_completion completion;
    nvme_admin_cmd buffer;
    nvme_admin_cmd *cmd = &buffer;

    fprintf(stderr, "%s:%d allocating completion queue with %d entries\n", __FUNCTION__, __LINE__, (Nvme::ioQueueSize / 16));
    // create I/O completion queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = 5; //create I/O completion queue
    cmd->nsid = 0;
    cmd->prp1 = (nvme->ioCompletionQueueRef << 24) + 0;
    cmd->cdw10 = ((Nvme::ioQueueSize / 16) << 16) | 1; // size, completion queue 1
    cmd->cdw11 = 1; // physically contiguous
    nvme->adminCommand(cmd, &completion);

    fprintf(stderr, "%s:%d allocating request queue with %d entries\n", __FUNCTION__, __LINE__, (Nvme::ioQueueSize / 64));
    // create I/O submission queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = 1; //create I/O submission queue
    cmd->nsid = 0;
    cmd->prp1 = (nvme->ioSubmissionQueueRef << 24) + 0;
    cmd->cdw10 = ((Nvme::ioQueueSize / 64) << 16) | 1; // size, submission queue 1
    cmd->cdw11 = (1 << 16) | 1; // completion queue 1, physically contiguous
    nvme->adminCommand(cmd, &completion);

    int numBramEntries = 8;
    int responseQueueOffset = 0;
    int submissionQueueOffset = numBramEntries * 16;
    fprintf(stderr, "%s:%d allocating completion queue with %d entries\n", __FUNCTION__, __LINE__, numBramEntries);
    // create I/O completion queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = 5; //create I/O completion queue
    cmd->nsid = 0;
    cmd->prp1 = (0x20 << 24) + 0;
    cmd->cdw10 = (numBramEntries<<16) | 2; // size, completion queue 2
    cmd->cdw11 = 1; // physically contiguous
    nvme->adminCommand(cmd, &completion);

    fprintf(stderr, "%s:%d allocating request queue with %d entries\n", __FUNCTION__, __LINE__, numBramEntries);
    // create I/O submission queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = 1; //create I/O submission queue
    cmd->nsid = 0;
    cmd->prp1 = (0x20 << 24) + 0x1000;
    cmd->cdw10 = (numBramEntries<<16) | 2; // size, submission queue 2
    cmd->cdw11 = (2 << 16) | 1; // completion queue 2, physically contiguous
    nvme->adminCommand(cmd, &completion);

}

int doIO(Nvme *nvme, int startBlock, int numBlocks, int queue=1)
{
    int blocksPerPage = 4096 / 512;
    int transferBufferId = (queue == 1) ? nvme->transferBufferRef : 2;
    uint32_t bramBuffer = (2 << 24) + 0x2000;
    // clear transfer buffer
    {
	int *buffer = (int *)nvme->ioCompletionQueue.buffer();
	memset(buffer, 0, numBlocks*512);
    }

    // let's do a read
    nvme_io_cmd cmd;
    nvme_completion completion;
    memset(&cmd, 0, sizeof(cmd));
    cmd.opcode = 2; // read
    cmd.nsid = 1;
    cmd.flags = 0x00; // PRP used for this transfer
    cmd.prp1 = 0x30000000ul; // send data to the FIFO
    cmd.prp2 = (transferBufferId << 24) + 0;
    if (queue == 1) { 
      uint64_t *prplist = (uint64_t *)nvme->transferBuffer.buffer();
      for (int i = 0; i < numBlocks/blocksPerPage; i++) {
	prplist[i] = (uint64_t)(0x30000000ul + 0x1000*i + 0x1000); // send data to the FIFO
      }

      nvme->transferBuffer.cacheInvalidate(8*512, 1);
    } else {
      for (int i = 0; i < numBlocks/blocksPerPage; i++) {
	nvme->bramWrite(bramBuffer+i, (uint64_t)(0x30000000ul + 0x1000*i + 0x1000)); // send data to the FIFO
	fprintf(stderr, "bramRead[%02x]=%08llx\n", i, nvme->bramRead(bramBuffer+i));
      }
    }

    cmd.cdw10 = startBlock; // starting LBA.lower
    cmd.cdw11 = 0; // starting LBA.upper
    cmd.cdw12 = numBlocks-1; // read N blocks

    fprintf(stderr, "IO cmd opcode=%02x flags=%02x cid=%04x %08x\n", cmd.opcode, cmd.flags, cmd.cid, *(int *)&cmd);
    fprintf(stderr, "enqueueing IO read request offsetof(prp1)=%d offsetof(prp2)=%d offsetof(cdw10)=%d sizeof(req)=%d\n",
	    offsetof(nvme_io_cmd,prp1), offsetof(nvme_io_cmd,prp2), offsetof(nvme_io_cmd,cdw10), sizeof(nvme_io_cmd));

    int sc = nvme->ioCommand(&cmd, &completion, queue);
    if (sc) {
	int *buffer = (int *)nvme->transferBuffer.buffer();
	for (int i = 0; i < numBlocks*512/4; i++) {
	    if (buffer[i])
		fprintf(stderr, "data read [%02x]=%08x\n", i*4, buffer[i]);
	}
    }
    return sc;
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
    for (int i = 0; i < 6; i++)
      fprintf(stderr, "Card BAR%d: %08x\n", i, nvme.readCtl((1 << 20) + 0x10 + i*4));
    fprintf(stderr, "reading AXI BAR\n");
    nvme.readCtl(0x208);
    nvme.readCtl(0x20C);
    nvme.readCtl(0x210);
    fprintf(stderr, "writing card BAR\n");
    for (int i = 0; i < 6; i++) {
	nvme.writeCtl((1 << 20) + 0x10 + 4*i, 0xffffffff);
	fprintf(stderr, "Card BAR%d: %08x\n", i, nvme.readCtl((1 << 20) + 0x10 + 4*i));
    }
    nvme.writeCtl((1 << 20) + 0x10, 0x00000000); // initialize to offset 0
    nvme.writeCtl((1 << 20) + 0x14, 0x00000000);
    nvme.writeCtl((1 << 20) + 0x18, 0x02200000); // BAR2 unused
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
	fprintf(stderr, "Reading card memory space\n");
	for (int i = 0; i < 10; i++)
	    fprintf(stderr, "CARDMEM[%02x]=%08x\n", i*4, nvme.read32(0x00000000 + i*4));
    }

    fprintf(stderr, "CSTS %08x checking reset bit\n", nvme.read32( 0x1c));
    nvme.write32(0x1c, 0x10); // clear reset bit
    fprintf(stderr, "CSTS %08x cleared reset bit\n", nvme.read32( 0x1c));

    // initialize CC.IOCQES and CC.IOSQES
    nvme.write32(0x14, 0x00460000); // completion queue entry size 2^4, submission queue entry size 2^6
    // reset
    //nvme.write32(0x20, 0x4e564d65);
    //sleep(1);
    fprintf(stderr, "Reset reg %08x\n", nvme.read32(0x20));
    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));

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

    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));
    // CC.enable
    nvme.write32(0x14, 0x00460001);
    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));

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
    getFeatures(&nvme);
    allocIOQueues(&nvme, 0);

    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));
    int startBlock = 34816; // base and extent of test file in SSD
    int blocksPerRequest = 32;
    int numBlocks = 1*blocksPerRequest; // 55; //8177;
    if (0)
	nvme.startSearch(numBlocks*512);
    for (int block = 0; block < numBlocks; block += blocksPerRequest) {
      int sc = doIO(&nvme, startBlock, blocksPerRequest, 2);
      nvme.status();
      if (sc != 0)
	break;
      startBlock += blocksPerRequest;
    }

    nvme.dumpTrace();
    nvme.transferStats();
    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));

    return 0;
}

