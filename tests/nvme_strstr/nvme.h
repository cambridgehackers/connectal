#pragma once

#include <map>
#include <string>

#include "DmaBuffer.h"
#include "portal.h"
#include "dmaManager.h"
#include "NvmeDriverIndication.h"
#include "NvmeDriverRequest.h"
#include "NvmeIndication.h"
#include "NvmeRequest.h"
#include "NvmeTrace.h"
#include "MemServerPortalRequest.h"
#include "MemServerPortalIndication.h"
#include "StringSearchRequest.h"
#include "StringSearchResponse.h"
//#include "ConnectalProjectConfig.h"

const int DataBusWidth = 64;
const int DataBusBytes = DataBusWidth/8;

enum nvme_admin_opcode {
    nvme_create_submission_queue = 1,
    nvme_create_completion_queue = 5,
    nvme_identify     = 6,
    nvme_get_features = 10,
};

enum nvme_io_opcode {
    nvme_flush = 0,
    nvme_write = 1,
    nvme_read = 2,
    nvme_write_uncorrectable = 4,
    nvme_compare = 5,
    nvme_write_zeroes = 8,
    nvme_manage_dataset = 9,
    nvme_register_reservation = 13,
    nvme_report_reservation = 14,
    nvme_acquire_reservation = 17,
    nvme_release_reservation = 21
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


class NvmeTrace;

class NvmeIndication : public NvmeIndicationWrapper {
    sem_t sem;
    
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

    void wait() {
	sem_wait(&sem);
    }
    NvmeIndication(int id, PortalPoller *poller = 0) : NvmeIndicationWrapper(id, poller), value(0), requests(0), cycles(0) {
	sem_init(&sem, 0, 0);
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

class Nvme {
    NvmeRequestProxy requestProxy;
    NvmeIndication  indication;
    NvmeDriverRequestProxy driverRequest;
    NvmeDriverIndication  driverIndication;
    NvmeTrace       *trace;
    MemServerPortalRequestProxy bram;
    MemServerPortalIndication   bramIndication;
    int adminRequestNumber;
    int ioRequestNumber[3]; // per queue, io queue 0 unused
    int verbose;
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

    Nvme();
    void setup();
    uint32_t readCtl(uint32_t addr);
    void writeCtl(uint32_t addr, uint32_t data);
    uint64_t read(uint32_t addr);
    void write(uint32_t addr, uint64_t data);
    uint32_t read32(uint32_t addr);
    void write32(uint32_t addr, uint32_t data);
    uint64_t bramRead(uint32_t addr);
    void bramWrite(uint32_t addr, uint64_t data);

    int adminCommand(nvme_admin_cmd *cmd, nvme_completion *completion);
    int ioCommand(nvme_io_cmd *cmd, nvme_completion *completion, int queue=1, int dotrace=0);
    void status();
    void transferStats();
    void dumpTrace();
};

enum FeatureId {
    FID_NumberOfQueues = 7
};

void identify(Nvme *nvme);
void getFeatures(Nvme *nvme, FeatureId featureId=FID_NumberOfQueues);
void allocIOQueues(Nvme *nvme, int entry=0);
int doIO(Nvme *nvme, nvme_io_opcode opcode, int startBlock, int numBlocks, int queue=1, int dotrace=0);

