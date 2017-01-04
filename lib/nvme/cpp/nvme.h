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

enum FeatureId {
    FID_NumberOfQueues = 7
};

class NvmeTrace;
class NvmeIndication;
class NvmeDriverIndication;
class MemServerPortalIndication;

class Nvme {
    bool verbose;
    NvmeRequestProxy requestProxy;
    NvmeIndication  *indication;
    NvmeDriverRequestProxy driverRequest;
    NvmeDriverIndication  *driverIndication;
    NvmeTrace       *trace;
    MemServerPortalRequestProxy bram;
    MemServerPortalIndication   *bramIndication;
    int adminRequestNumber;
    int ioRequestNumber[3]; // per queue, io queue 0 unused
public:
    DmaBuffer adminBuffer;
    DmaBuffer transferBuffer;
    DmaBuffer adminSubmissionQueue;
    DmaBuffer adminCompletionQueue;
    DmaBuffer ioSubmissionQueue;
    DmaBuffer ioCompletionQueue;
    DmaBuffer needleBuffer;
    DmaBuffer mpNextBuffer;
    int adminBufferRef;
    int transferBufferRef;
    int adminSubmissionQueueRef;
    int adminCompletionQueueRef;
    int ioSubmissionQueueRef;
    int ioCompletionQueueRef;
    int needleRef;
    int mpNextRef;

    static const int ioQueueSize = 4096;

    Nvme(int transferBuffeSize = BlocksPerRequest*512, bool verbose=false);
    Nvme(bool verbose);
    void setup();

    int adminCommand(nvme_admin_cmd *cmd, nvme_completion *completion);
    int ioCommand(nvme_io_cmd *cmd, nvme_completion *completion, int queue=1, int dotrace=0);
    void status();
    void transferStats();
    void dumpTrace();

    void identify();
    void getFeatures(FeatureId featureId=FID_NumberOfQueues);
    void allocIOQueues(int entry=0);

    int doIO(nvme_io_opcode opcode, int startBlock, int numBlocks, int queue=1, int dotrace=0);

    void messageFromSoftware(uint32_t msg, bool last=false);
    bool messageToSoftware(uint32_t *msg, bool *last, bool nonBlocking=false);

    // private:
    uint32_t readCtl(uint32_t addr);
    void writeCtl(uint32_t addr, uint32_t data);
    uint64_t read(uint32_t addr);
    void write(uint32_t addr, uint64_t data);
    uint32_t read32(uint32_t addr);
    void write32(uint32_t addr, uint32_t data);
    uint64_t read64(uint32_t addr);
    void write64(uint32_t addr, uint64_t data);
    void write128(uint32_t addr, uint64_t udata, uint64_t ldata);
    uint64_t bramRead(uint32_t addr);
    void bramWrite(uint32_t addr, uint64_t data);

    void memserverWrite();
};

