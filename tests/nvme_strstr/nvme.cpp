#include <stdio.h>
#include "nvme.h"

// queue size in create I/O completion/submission queue is specified as a 0 based value
static const int queueSizeDelta = 1;

uint32_t Nvme::readCtl(uint32_t addr)
{
    driverRequest.readCtl(addr);
    driverIndication.wait();
    return (uint32_t)driverIndication.value;
}
void Nvme::writeCtl(uint32_t addr, uint32_t data)
{
    driverRequest.writeCtl(addr, data);
    driverIndication.waitwrite();
}
uint64_t Nvme::read(uint32_t addr)
{
    driverRequest.read(addr);
    driverIndication.wait();
    return driverIndication.value;
}
void Nvme::write(uint32_t addr, uint64_t data)
{
    driverRequest.write(addr, data);
    //driverIndication.wait();
}
uint32_t Nvme::read32(uint32_t addr)
{
    driverRequest.read32(addr);
    driverIndication.wait();
    uint64_t v = driverIndication.value;
    return (uint32_t)(v >> ((addr & 4) ? 32 : 0));
    //return v;
}
void Nvme::write32(uint32_t addr, uint32_t data)
{
    uint64_t v = data;
    //fixme byte enables
    //driverRequest.write(addr & ~7, v << ((addr & 4) ? 32 : 0));
    driverRequest.write32(addr, v);
    //driverIndication.wait();
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

void Nvme::setup()
{
    driverRequest.setup();
    driverIndication.wait();

    if (0) {
    if (verbose) fprintf(stderr, "Enabling I/O and Memory, bus master, parity and SERR\n");
    writeCtl(0x004, 0x147);
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
    if (verbose)
	for (int i = 0; i < 6; i++)
	    fprintf(stderr, "Card BAR%d: %08x\n", i, readCtl((1 << 20) + 0x10 + i*4));
    fprintf(stderr, "probing card BAR\n");
    for (int i = 0; i < 6; i++) {
	writeCtl((1 << 20) + 0x10 + 4*i, 0xffffffff);
	fprintf(stderr, "Card BAR%d: %08x\n", i, readCtl((1 << 20) + 0x10 + 4*i));
    }
    writeCtl((1 << 20) + 0x10, 0x00000000); // initialize to offset 0
    writeCtl((1 << 20) + 0x14, 0x00000000);
    writeCtl((1 << 20) + 0x18, 0x02200000); // BAR2 unused
    writeCtl((1 << 20) + 0x1c, 0x00000000);
    writeCtl((1 << 20) + 0x10+5*4, 0); // sata card
    fprintf(stderr, "reading card BARs\n");
    for (int i = 0; i < 6; i++) {
	fprintf(stderr, "Card BAR%d: %08x\n", i, readCtl((1 << 20) + 0x10 + 4*i));
    }

    if (verbose) fprintf(stderr, "Enabling bridge\n");
    writeCtl(0x148, 1);
    writeCtl(0x140, 0x00010000);

    if (verbose) {
	fprintf(stderr, "Reading card memory space\n");
	for (int i = 0; i < 10; i++)
	    fprintf(stderr, "CARDMEM[%02x]=%08x\n", i*4, read32(0x00000000 + i*4));
    }
    }
    uint64_t cardcap = read(0);
    int mpsmax = (cardcap >> 52)&0xF;
    int mpsmin = (cardcap >> 48)&0xF;
    fprintf(stderr, "MPSMAX=%0x %#x bytes\n", mpsmax, 1 << (12+mpsmax));
    fprintf(stderr, "MPSMIN=%0x %#x bytes\n", mpsmin, 1 << (12+mpsmin));
    write32(0x1c, 0x10); // clear reset bit

    // initialize CC.IOCQES and CC.IOSQES
    write32(0x14, 0x00460000); // completion queue entry size 2^4, submission queue entry size 2^6

    if (verbose) {
      fprintf(stderr, "CMB size     %08x\n", read32(0x38));
      fprintf(stderr, "CMB location %08x\n", read32(0x3c));
    }
    uint64_t adminCompletionBaseAddress = adminCompletionQueueRef << 24;
    uint64_t adminSubmissionBaseAddress = adminSubmissionQueueRef << 24;
    fprintf(stderr, "Setting up Admin submission and completion queues %llx %llx\n",
	    (long long)adminCompletionBaseAddress, (long long)adminSubmissionBaseAddress);
    write(0x28, adminSubmissionBaseAddress);
    fprintf(stderr, "AdminSubmissionBaseAddress %08llx\n", (long long)read(0x28));
    write(0x30, adminCompletionBaseAddress);
    fprintf(stderr, "AdminCompletionBaseAddress %08llx\n", (long long)read(0x30));
    write32(0x24, 0x003f003f);

    // CC.enable
    write32(0x14, 0x00460001);
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
	  indication.wait();
	}
	dumpTrace();
	int status = driverIndication.value >> 32;
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

void identify(Nvme *nvme)
{
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

void getFeatures(Nvme *nvme, FeatureId featureId)
{
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

void allocIOQueues(Nvme *nvme, int entry)
{
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

int doIO(Nvme *nvme, nvme_io_opcode opcode, int startBlock, int numBlocks, int queue, int dotrace)
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
    cmd.opcode = opcode;
    cmd.nsid = 1;
    cmd.flags = 0x00; // PRP used for this transfer
    if (opcode == nvme_read)
      cmd.prp1 = 0x30000000ul; // send data to the FIFO
    else
      cmd.prp1 = (transferBufferId << 24);
    fprintf(stderr, "cmd.prp1=%llx\n", cmd.prp1);
    cmd.prp2 = (transferBufferId << 24) + 0;
    if (queue == 1) { 
      uint64_t *prplist = (uint64_t *)nvme->transferBuffer.buffer();
      for (int i = 0; i < numBlocks/blocksPerPage; i++) {
	if (opcode == nvme_read)
	  prplist[i] = (uint64_t)(0x30000000ul + 0x1000*i + 0x1000); // send data to the FIFO
	else
	  prplist[i] = (uint64_t)((transferBufferId << 24) + 0x1000*i + 0x1000); // read data from DRAM
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

