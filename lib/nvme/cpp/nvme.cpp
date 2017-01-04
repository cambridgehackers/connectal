#include <stdio.h>
#include <queue>
#include "nvme.h"

#include <ConnectalProjectConfig.h> // PcieDataBusWidth

// queue size in create I/O completion/submission queue is specified as a 0 based value
static const int queueSizeDelta = 1;

class NvmeTrace : public NvmeTraceWrapper {
  std::multimap<int,std::string> traceValues;
public:
    void traceDmaRequest(const DmaChannel chan, const int write, const uint16_t objId, const uint32_t offset, const uint16_t burstLen, const uint8_t tag, const uint32_t timestamp) {
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
	fprintf(stderr, "%ld traceValues\n", traceValues.size());
	for (auto it=traceValues.begin(); it!=traceValues.end(); ++it) {
	    fprintf(stderr, "%08d %4d %s", it->first, it->first - prev, it->second.c_str());
	    prev = it->first;
	}
	traceValues.clear();
    }

    NvmeTrace(int id, PortalPoller *poller = 0) : NvmeTraceWrapper(id, poller) {
    }
};

class NvmeIndication : public NvmeIndicationWrapper {
    sem_t sem;
    pthread_cond_t cond;
    pthread_mutex_t mutex;
    std::queue<int> msgs;
    std::queue<int> lastmsgs;
    int waiters;
public:
    uint64_t value;
    uint32_t requests;
    uint32_t cycles;
  virtual void msgIn ( const uint32_t value ) {
  }

  virtual void transferCompleted ( const uint16_t requestId, const uint64_t status, const uint32_t cycles ) {
      fprintf(stderr, "%s:%d requestId=%08x status=%08llx cycles=%d\n", __FUNCTION__, __LINE__, requestId, (long long)status, cycles);
      value = status;
      this->requests++;
      this->cycles += cycles;
      sem_post(&sem);
    }

    virtual void msgToSoftware ( const uint32_t msg, uint8_t last ) {
	fprintf(stderr, "%s:%d msg=%x\n", __FUNCTION__, __LINE__, msg);
	pthread_mutex_lock(&mutex);
	msgs.push(msg);
	lastmsgs.push(last);
	if (waiters)
	    pthread_cond_signal(&cond);
	pthread_mutex_unlock(&mutex);
    }
    bool messageToSoftware(uint32_t *msg, bool *last, bool nonBlocking=true) {
	bool hasMsg = false;
	pthread_mutex_lock(&mutex);
	do {
	    hasMsg = !msgs.empty();
	    if (msgs.size()) {
		if (*msg)
		    *msg = msgs.front();
		if (last)
		    *last = lastmsgs.front();
		msgs.pop();
		lastmsgs.pop();
	    } else if (!nonBlocking) {
		waiters++;
		pthread_cond_wait(&cond, &mutex);
		waiters--;
	    }
	} while (!hasMsg);
      pthread_mutex_unlock(&mutex);
      return hasMsg;
    }
    void wait() {
	sem_wait(&sem);
    }
    NvmeIndication(int id, PortalPoller *poller = 0) : NvmeIndicationWrapper(id, poller), waiters(0), value(0), requests(0), cycles(0) {
	sem_init(&sem, 0, 0);
	pthread_mutex_init(&mutex, 0);
	pthread_cond_init(&cond, 0);
    }
  
};

class NvmeDriverIndication : public NvmeDriverIndicationWrapper {
    sem_t sem, wsem;
    
public:
    uint64_t value;
    uint32_t requests;
    uint32_t cycles;
    virtual void setupDone (  ) {
	fprintf(stderr, "%s:%d\n", __FUNCTION__, __LINE__);
	sem_post(&sem);
    }

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

    NvmeDriverIndication(int id, PortalPoller *poller = 0) : NvmeDriverIndicationWrapper(id, poller), value(0), requests(0), cycles(0) {
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

uint32_t Nvme::readCtl(uint32_t addr)
{
    // if (verbose) fprintf(stderr, "readCtl %x\n", addr);
    driverRequest.readCtl(addr);
    driverIndication->wait();
    return (uint32_t)driverIndication->value;
}
void Nvme::writeCtl(uint32_t addr, uint32_t data)
{
    //if (verbose) fprintf(stderr, "writeCtl %x\n", addr);
    driverRequest.writeCtl(addr, data);
    driverIndication->waitwrite();
}
uint64_t Nvme::read(uint32_t addr)
{
    driverRequest.read64(addr);
    driverIndication->wait();
    return driverIndication->value;
}
void Nvme::write(uint32_t addr, uint64_t data)
{
    driverRequest.write64(addr, data);
    driverIndication->waitwrite();
}
uint32_t Nvme::read32(uint32_t addr)
{
    driverRequest.read32(addr);
    driverIndication->wait();
    uint64_t v = driverIndication->value;
    return (uint32_t)(v >> ((addr & 4) ? 32 : 0));
    //return v;
}
void Nvme::write32(uint32_t addr, uint32_t data)
{
    uint64_t v = data;
    //fixme byte enables
    //driverRequest.write(addr & ~7, v << ((addr & 4) ? 32 : 0));
    driverRequest.write32(addr, v);
    driverIndication->waitwrite();
}
uint64_t Nvme::read64(uint32_t addr)
{
    driverRequest.read64(addr);
    driverIndication->wait();
    uint64_t v = driverIndication->value;
    return v;
}
void Nvme::write64(uint32_t addr, uint64_t data)
{
    uint64_t v = data;
    //fixme byte enables
    driverRequest.write64(addr, v);
    driverIndication->waitwrite();
}
void Nvme::write128(uint32_t addr, uint64_t udata, uint64_t ldata)
{
    driverRequest.write128(addr, udata, ldata);
    driverIndication->waitwrite();
}
uint64_t Nvme::bramRead(uint32_t addr)
{
    bram.read(addr);
    bramIndication->wait();
    return bramIndication->value;
}
void Nvme::bramWrite(uint32_t addr, uint64_t data)
{
    bram.write(addr, data);
    //bramIndication->wait();
}

Nvme::Nvme(bool verbose)
    : Nvme(BlocksPerRequest*512, verbose) {
  fprintf(stderr, "Nvme verbose=%d\n", verbose);
}


Nvme::Nvme(int transferBufferSize, bool verbose)
    : verbose(verbose)
    , requestProxy(IfcNames_NvmeRequestS2H)
    , indication(new NvmeIndication(IfcNames_NvmeIndicationH2S))
    , driverRequest(IfcNames_NvmeDriverRequestS2H)
    , driverIndication(new NvmeDriverIndication(IfcNames_NvmeDriverIndicationH2S))
    , trace(new NvmeTrace(IfcNames_NvmeTraceH2S))
    , bram(IfcNames_MemServerPortalRequestS2H)
    , bramIndication(new MemServerPortalIndication(IfcNames_MemServerPortalIndicationH2S))
    , adminRequestNumber(0)
    , adminBuffer(4096)
    , transferBuffer(transferBufferSize)
    , adminSubmissionQueue(4096)
    , adminCompletionQueue(4096)
    , ioSubmissionQueue(ioQueueSize)
    , ioCompletionQueue(ioQueueSize)
    , needleBuffer(8192)
    , mpNextBuffer(8192)
{
	
    memset(ioRequestNumber, 0, sizeof(ioRequestNumber));

    adminBufferRef = adminBuffer.reference();
    transferBufferRef = transferBuffer.reference();
    adminSubmissionQueueRef = adminSubmissionQueue.reference();
    adminCompletionQueueRef = adminCompletionQueue.reference();
    if (verbose) fprintf(stderr, "adminSubmissionQueue %d\n", adminSubmissionQueue.reference());
    if (verbose) fprintf(stderr, "adminCompletionQueue %d\n", adminCompletionQueue.reference());
    ioSubmissionQueueRef = ioSubmissionQueue.reference();
    ioCompletionQueueRef = ioCompletionQueue.reference();
    needleRef = needleBuffer.reference();
    mpNextRef = mpNextBuffer.reference();
    if (verbose) fprintf(stderr, "ioSubmissionQueue %d\n", ioSubmissionQueue.reference());
    if (verbose) fprintf(stderr, "ioCompletionQueue %d\n", ioCompletionQueue.reference());
    driverRequest.status();
    driverIndication->wait();
    driverRequest.trace(0);
}

void Nvme::setup()
{
    driverRequest.reset(16);
    sleep(1);
    driverRequest.nvmeReset(16);
    sleep(1);
    driverRequest.setup();
    driverIndication->wait();

    if (1) {
    if (verbose) fprintf(stderr, "Enabling I/O and Memory, bus master, parity and SERR\n");
    writeCtl(0x004, 0x147);
    if (verbose) fprintf(stderr, "bridge control %08x\n", readCtl(0x004));
    // required
    writeCtl(0x18, 0x00070100);
    writeCtl(0x10, 0xFFFFFFFF);
    writeCtl(0x14, 0xFFFFFFFF);
    fprintf(stderr, "Root Port BAR0: %08x\n", readCtl((0 << 20) + 0x10));
    fprintf(stderr, "Root Port BAR1: %08x\n", readCtl((0 << 20) + 0x14));
    writeCtl(0x10, 0x0);
    writeCtl(0x14, 0x0);
    if (verbose) fprintf(stderr, "Enabling card I/O and Memory, bus master, parity and SERR\n");
    writeCtl((1 << 20) + 4, 0x147);
    if (verbose) fprintf(stderr, "card bridge control %08x\n", readCtl((1 << 20) + 4));
    if (verbose)
	for (int i = 0; i < 6; i++)
	    fprintf(stderr, "Card BAR%d: %08x\n", i, readCtl((1 << 20) + 0x10 + i*4));
    if (verbose) fprintf(stderr, "probing card BAR\n");
    for (int i = 0; i < 6; i++) {
	writeCtl((1 << 20) + 0x10 + 4*i, 0xffffffff);
	if (verbose) fprintf(stderr, "Card BAR%d: %08x\n", i, readCtl((1 << 20) + 0x10 + 4*i));
    }
    writeCtl((1 << 20) + 0x10, 0x00000000); // initialize to offset 0
    writeCtl((1 << 20) + 0x14, 0x00000000);
    writeCtl((1 << 20) + 0x18, 0x02200000); // BAR2 unused
    writeCtl((1 << 20) + 0x1c, 0x00000000);
    writeCtl((1 << 20) + 0x10+5*4, 0); // sata card
    if (verbose) {
	fprintf(stderr, "reading card BARs\n");
	for (int i = 0; i < 6; i++) {
	    fprintf(stderr, "Card BAR%d: %08x\n", i, readCtl((1 << 20) + 0x10 + 4*i));
	}
    }

    fprintf(stderr, "PHY Status/Control: %08x\n", readCtl(0x144));
    fprintf(stderr, "Configuration Control (should be zero): %08x\n", readCtl(0x168));
    for (int i = 0; i < 6; i++)
	fprintf(stderr, "AXI Bar%d %08x.%08x\n", i, readCtl(0x208 + i*8), readCtl(0x208 + i*8+4));
    if (verbose) fprintf(stderr, "Enabling bridge\n");
    fprintf(stderr, "0x148: %08x\n", readCtl(0x148));
    writeCtl(0x140, 0x00000100);
    fprintf(stderr, "Bus Location Register: %08x\n", readCtl(0x140));
    writeCtl(0x148, 1);
    fprintf(stderr, "0x148: %08x\n", readCtl(0x148));

    fprintf(stderr, "before: contents of 0x30 %08lx.%08lx\n", read64(0x38), read64(0x30));
    write128(0x30, 0x11ffeeddccbbaa99l, 0x8877665544332211);
    fprintf(stderr, "after:  contents of 0x30 %08lx.%08lx\n", read64(0x38), read64(0x30));
    write64(0x30, 0x8877665544332211);
    write64(0x38, 0x11ffeeddccbbaa99l);
    fprintf(stderr, "after2: contents of 0x30 %08lx.%08lx\n", read64(0x38), read64(0x30));
    write64(0x20, 0x8877665544332211);
    write64(0x28, 0x11ffeeddccbbaa99l);
    fprintf(stderr, "after3: contents of 0x20 %08lx.%08lx\n", read64(0x28), read64(0x20));

    if (verbose) {
	fprintf(stderr, "Reading card memory space\n");
	for (int i = 0; i < 16; i++)
	    fprintf(stderr, "CARDMEM[%02x]=%08x\n", i*4, read32(0x00000000 + i*4));
	for (int i = 0; i < 16; i += 2)
	    fprintf(stderr, "CARDMEM[%02x]=%08lx\n", i*4, read64(0x00000000 + i*8));
    }
    }
    uint64_t cardcap = read64(0);
    fprintf(stderr, "cardcap=%08lx\n", cardcap);
    int mpsmax = (cardcap >> 52)&0xF;
    int mpsmin = (cardcap >> 48)&0xF;
    if (verbose) fprintf(stderr, "MPSMAX=%0x %#x bytes\n", mpsmax, 1 << (12+mpsmax));
    if (verbose) fprintf(stderr, "MPSMIN=%0x %#x bytes\n", mpsmin, 1 << (12+mpsmin));

    write32(0x1c, 0x10); // clear reset bit
    if (verbose) fprintf(stderr, "0x1c reset %08x\n", read32(0x1c));
    if (verbose) fprintf(stderr, "0x14 %08llx\n", (long long)read(0x14));
    if (verbose) fprintf(stderr, "0x18 %08llx\n", (long long)read(0x18));

    // initialize CC.IOCQES and CC.IOSQES
    write32(0x14, 0x00460000); // completion queue entry size 2^4, submission queue entry size 2^6

    if (verbose) {
      fprintf(stderr, "CMB size     %08x\n", read32(0x38));
      fprintf(stderr, "CMB location %08x\n", read32(0x3c));
    }
    uint64_t adminCompletionBaseAddress = adminCompletionQueueRef << 24;
    uint64_t adminSubmissionBaseAddress = adminSubmissionQueueRef << 24;
    if (verbose) fprintf(stderr, "Setting up Admin submission and completion queues %llx %llx\n",
			 (long long)adminCompletionBaseAddress, (long long)adminSubmissionBaseAddress);
    write64(0x28, adminSubmissionBaseAddress);
    if (verbose) fprintf(stderr, "AdminSubmissionBaseAddress %08llx\n", (long long)read(0x28));
    write64(0x30, adminCompletionBaseAddress);
    if (verbose) fprintf(stderr, "AdminCompletionBaseAddress %08llx\n", (long long)read(0x30));
    write32(0x24, 0x003f003f);

    // CC.enable
    if (verbose) fprintf(stderr, "****************************************\n");
    if (verbose) fprintf(stderr, "CSTS %08x \n", read32(0x1c));
    if (verbose) fprintf(stderr, "read64 0x18 %08lx\n", read64(0x18));
    write32(0x14, 0x00460000);
    if (verbose) fprintf(stderr, "CC.enable %08x (expected 0x00460001)\n", read32(0x14));
    write32(0x14, 0x00460001);
    if (verbose) fprintf(stderr, "read64 0x010 %08llx\n", (long long)read64(0x10));
    if (verbose) fprintf(stderr, "read32 0x014 %08llx\n", (long long)read32(0x14));
    if (verbose) fprintf(stderr, "****************************************\n");
	for (int i = 0; i < 10; i++)
	    fprintf(stderr, "CARDMEM[%02x]=%08x\n", i*4, read32(0x00000000 + i*4));

}

void Nvme::memserverWrite()
{
    Nvme *nvme = this;
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
	char *str = fgets(line, sizeof(line), stdin);
	if (str == 0)
	  fprintf(stderr, "Failed to read continuation line\n");
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

void Nvme::status() {
    driverRequest.status();
    driverIndication->wait();
}

void Nvme::transferStats()
{
    uint32_t cycles = driverIndication->cycles;
    uint32_t requests = driverIndication->requests;
    fprintf(stderr, "transfer stats: requests=%d cycles=%d average cycles/request=%5.2f\n",
	    requests, cycles, (double)cycles/(double)requests);
}

void Nvme::dumpTrace()
{
    trace->dumpTrace();
}

int Nvme::adminCommand(nvme_admin_cmd *cmd, nvme_completion *completion)
{
    nvme_admin_cmd *requests = (nvme_admin_cmd *)adminSubmissionQueue.buffer();
    int requestNumber        = adminRequestNumber % (4096 / sizeof(nvme_admin_cmd));
    nvme_admin_cmd *request  = &requests[requestNumber];
    int *responses           = (int *)adminCompletionQueue.buffer();
    int responseNumber       = adminRequestNumber % (4096 / 16);
    int *response            = &responses[responseNumber * 4];

    driverRequest.trace(1);

    if (verbose) fprintf(stderr, "%s:%d requestNumber=%d responseNumber = %d\n", __FUNCTION__, __LINE__, requestNumber, responseNumber);

    cmd->cid = adminRequestNumber++;
    *request = *cmd;
    write32(0x1000 + ((2*0 + 0) * (4 << 0)), requestNumber+1);
    fprintf(stderr, "doorbell value: %08x\n", read32(0x1000 + ((2*0 + 0) * (4 << 0))));

    adminSubmissionQueue.cacheInvalidate(4096, 1);
    adminCompletionQueue.cacheInvalidate(4096, 0);

    // update submission queue tail
    write32(0x1000 + ((2*0 + 0) * (4 << 0)), requestNumber+1);
    sleep(1);
    dumpTrace();

    if (verbose) {
	for (int i = 0; i < 4; i++)
	    fprintf(stderr, "    response[%02x]=%08x\n", i*4, response[i]);
    }
    int status = response[3];
    int more = (status >> 30) & 1;
    int sc = (status >> 17) & 0xff;
    int sct = (status >> 25) & 0x7;
    write32(0x1000 + ((2*0 + 1) * (4 << 0)), responseNumber+1);
    fprintf(stderr, "doorbell value: %08x\n", read32(0x1000 + ((2*0 + 1) * (4 << 0))));
    if (verbose) fprintf(stderr, "status=%08x more=%d sc=%x sct=%x\n", status, more, sc, sct);
    return sc;
}

int Nvme::ioCommand(nvme_io_cmd *cmd, nvme_completion *completion, int queue, int dotrace)
{
    nvme_io_cmd *requests = (nvme_io_cmd *)ioSubmissionQueue.buffer();
    int requestNumber        = ioRequestNumber[queue] % (Nvme::ioQueueSize / sizeof(nvme_io_cmd));
    nvme_io_cmd *request  = &requests[requestNumber];
    int *responses           = (int *)ioCompletionQueue.buffer();
    int responseNumber       = ioRequestNumber[queue] % (Nvme::ioQueueSize / 16);
    int *response            = &responses[responseNumber * 4];
    int responseBuffer[4];

    fprintf(stderr, "%s:%d requestNumber=%d responseNumber = %d requestOffset=%lx io request objid=%d\n",
	    __FUNCTION__, __LINE__, requestNumber, responseNumber, (long)(requestNumber*sizeof(nvme_io_cmd)), ioSubmissionQueueRef);

    cmd->cid = ioRequestNumber[queue]++;

    driverRequest.trace(dotrace);

    if (queue == 2) {
	fprintf(stderr, "%s:%d starting transfer opcode=%d\n", __FUNCTION__, __LINE__, cmd->opcode);

	int numBlocks = cmd->cdw12+1;
	requestProxy.startTransfer(/* read */ cmd->opcode, /* flags */ 0, cmd->cid, cmd->cdw10, numBlocks, /* dsm */0x71);
	//sleep(1);

	if (0) {
	    for (int i = 0; i < 16; i++) {
	      fprintf(stderr, "requestbuffer[%02x]=%016llx\n", i, (long long)bramRead(0x1000 + i*8));
	    }
	    for (int i = 0; i < 4; i++) {
	      fprintf(stderr, "responsebuffer[%02x]=%016llx\n", i, (long long)bramRead(i*8));
	    }
	}

	for (int i = 0; i < numBlocks/BlocksPerRequest; i++) {
	  fprintf(stderr, "%s:%d waiting for completion numBlocks=%d\n", __FUNCTION__, __LINE__, numBlocks);
	  indication->wait();
	}
	dumpTrace();
	int status = driverIndication->value >> 32;
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
	for (uint32_t i = 0; i < sizeof(nvme_io_cmd); i += DataBusBytes) {
	    bramWrite(bramRequestBase+i, ((uint64_t *)cmd)[i/8]);
	    uint64_t val = bramRead(bramRequestBase+i);
	    fprintf(stderr, "bramRequest[%02x]=%08x.%08x\n", bramRequestBase+i, (uint32_t)(val >> 32), (uint32_t)val);
	}
    }

    if (0 && requestNumber==7) {
	fprintf(stderr, "enabling DMA trace\n");
	driverRequest.trace(1);
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
	for (uint32_t i = 0; i < sizeof(nvme_completion); i += DataBusBytes) {
	  uint64_t val = bramRead(responseNumber*sizeof(nvme_completion) + i);
	  fprintf(stderr, "i=%02x val=%016llx\n", i, (long long)val);
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

void Nvme::identify()
{
    Nvme *nvme = this;
    fprintf(stderr, "sizeof(nvmd_id_cmd)=%ld\n", (long)sizeof(nvme_admin_cmd));
    // write an identify command
    nvme_completion completion;
    nvme_admin_cmd buffer;
    nvme_admin_cmd *cmd = &buffer;
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = nvme_identify;
    cmd->nsid = 0;
    cmd->prp1 = (nvme->transferBufferRef << 24) + 0;
    cmd->prp2 = (nvme->transferBufferRef << 24) + 4096;
    cmd->cdw10 = 1;

    nvme->adminCommand(cmd, &completion);

    {
	char *cbuffer = (char *)(nvme->transferBuffer.buffer() + 0);
	//int *buffer = (int *)(nvme->transferBuffer.buffer() + 0);
	char str[128];
	fprintf(stderr, "PCI vendorid %02x\n", *(unsigned short *)&cbuffer[0]);
	fprintf(stderr, "PCI deviceid %02x\n", *(unsigned short *)&cbuffer[2]);
	snprintf(str, 20, "%s", &cbuffer[4]);
	fprintf(stderr, "serial number '%s'\n", str);
	snprintf(str, 40, "%s", &cbuffer[24]);
	fprintf(stderr, "model number  '%s'\n", str);
	snprintf(str, 8, "%s", &cbuffer[64]);
	fprintf(stderr, "firmware rev  '%s'\n", str);
	fprintf(stderr, "host buffer preferred size %x\n", *(int *)&cbuffer[272]);
	fprintf(stderr, "host buffer min size       %x\n", *(int *)&cbuffer[276]);
	fprintf(stderr, "nvm submission queue entry size %d\n", cbuffer[512]);
	fprintf(stderr, "nvm completion queue entry size %d\n", cbuffer[513]);
	fprintf(stderr, "maximum data transfer size: %d pages\n", cbuffer[77] ? (1 << cbuffer[77]) : -1);
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

void Nvme::getFeatures(FeatureId featureId)
{
    Nvme *nvme = this;
    fprintf(stderr, "sizeof(nvmd_id_cmd)=%ld\n", (long)sizeof(nvme_admin_cmd));
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
	//int *buffer = (int *)(nvme->transferBuffer.buffer() + 0);
	//char str[128];
	fprintf(stderr, "foo %x\n", *(unsigned short *)&cbuffer[0]);
    }
}

void Nvme::allocIOQueues(int entry)
{
    Nvme *nvme = this;

    nvme_completion completion;
    nvme_admin_cmd buffer;
    nvme_admin_cmd *cmd = &buffer;

    fprintf(stderr, "%s:%d allocating completion queue with %d entries\n", __FUNCTION__, __LINE__, (Nvme::ioQueueSize / 16));
    // create I/O completion queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = nvme_create_completion_queue; //5;
    cmd->nsid = 0;
    cmd->prp1 = (nvme->ioCompletionQueueRef << 24) + 0;
    cmd->cdw10 = ((Nvme::ioQueueSize / 16 - queueSizeDelta) << 16) | 1; // size, completion queue 1
    cmd->cdw11 = 1; // physically contiguous
    nvme->adminCommand(cmd, &completion);

    fprintf(stderr, "%s:%d allocating request queue with %d entries\n", __FUNCTION__, __LINE__, (Nvme::ioQueueSize / 64));
    // create I/O submission queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = nvme_create_submission_queue; //1;
    cmd->nsid = 0;
    cmd->prp1 = (nvme->ioSubmissionQueueRef << 24) + 0;
    cmd->cdw10 = ((Nvme::ioQueueSize / 64 - queueSizeDelta) << 16) | 1; // size, submission queue 1
    cmd->cdw11 = (1 << 16) | 1; // completion queue 1, physically contiguous
    nvme->adminCommand(cmd, &completion);

    int numBramEntries = 8;
    //int responseQueueOffset = 0;
    //int submissionQueueOffset = numBramEntries * 16;
    fprintf(stderr, "%s:%d allocating completion queue with %d entries\n", __FUNCTION__, __LINE__, numBramEntries);
    // create I/O completion queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = nvme_create_completion_queue;
    cmd->nsid = 0;
    cmd->prp1 = (0x20 << 24) + 0;
    cmd->cdw10 = ((numBramEntries-queueSizeDelta)<<16) | 2; // size, completion queue 2
    cmd->cdw11 = 1; // physically contiguous
    nvme->adminCommand(cmd, &completion);

    fprintf(stderr, "%s:%d allocating request queue with %d entries\n", __FUNCTION__, __LINE__, numBramEntries);
    // create I/O submission queue
    memset(cmd, 0, sizeof(*cmd));
    cmd->opcode = nvme_create_submission_queue;
    cmd->nsid = 0;
    cmd->prp1 = (0x20 << 24) + 0x1000;
    cmd->cdw10 = ((numBramEntries-queueSizeDelta)<<16) | 2; // size, submission queue 2
    cmd->cdw11 = (2 << 16) | 1; // completion queue 2, physically contiguous
    nvme->adminCommand(cmd, &completion);

}

int Nvme::doIO(nvme_io_opcode opcode, int startBlock, int numBlocks, int queue, int dotrace)
{
    Nvme *nvme = this;
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
    cmd.opcode = opcode;
    cmd.nsid = 1;
    cmd.flags = 0x00; // PRP used for this transfer
    if (queue == 2)
      cmd.prp1 = 0x30000000ul; // send data to the FIFO
    else
      cmd.prp1 = (transferBufferId << 24);
    fprintf(stderr, "cmd.prp1=%llx\n", (long long)cmd.prp1);
    cmd.prp2 = (transferBufferId << 24) + 0;
    if (queue == 1) { 
      uint64_t *prplist = (uint64_t *)nvme->adminBuffer.buffer();
      for (int i = 0; i < numBlocks/blocksPerPage; i++) {
	if (opcode == nvme_read)
	  prplist[i] = (uint64_t)(0x30000000ul + 0x1000*i + 0x1000); // enqueue/dequeue FIFO data
	else
	  prplist[i] = (uint64_t)((transferBufferId << 24) + 0x1000*i + 0x1000); // read/write DRAM data
      }

      nvme->transferBuffer.cacheInvalidate(8*512, 1);
    } else {
      for (int i = 0; i < numBlocks/blocksPerPage; i++) {
	nvme->bramWrite(bramBuffer+i, (uint64_t)(0x30000000ul + 0x1000*i + 0x1000)); // send data to the FIFO
	fprintf(stderr, "bramRead[%02x]=%08llx\n", i, (long long)nvme->bramRead(bramBuffer+i));
      }
    }

    cmd.cdw10 = startBlock; // starting LBA.lower
    cmd.cdw11 = 0; // starting LBA.upper
    cmd.cdw12 = numBlocks-1; // read N blocks

    fprintf(stderr, "IO cmd opcode=%02x flags=%02x cid=%04x %08x\n", cmd.opcode, cmd.flags, cmd.cid, *(int *)&cmd);

    int sc = nvme->ioCommand(&cmd, &completion, queue, dotrace);
    if (sc) {
	int *buffer = (int *)nvme->transferBuffer.buffer();
	for (int i = 0; i < numBlocks*512/4; i++) {
	    if (buffer[i])
		fprintf(stderr, "data read [%02x]=%08x\n", i*4, buffer[i]);
	}
    }
    return sc;
}

void Nvme::messageFromSoftware(uint32_t msg, bool last)
{
  requestProxy.msgFromSoftware(msg, last);
}

bool Nvme::messageToSoftware(uint32_t *msgp, bool *lastp, bool nonBlocking)
{
    return indication->messageToSoftware(msgp, lastp, nonBlocking);
}
