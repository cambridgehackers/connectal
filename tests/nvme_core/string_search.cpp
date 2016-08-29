#include <stdio.h>
//#include "jsoncpp/json/json.h"
#include <map>
#include <errno.h>
#include <fcntl.h>
#include <string>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <ConnectalProjectConfig.h> // BlocksPerRequest

#include "nvme.h"
#include "mp.h"

enum MsgFromSoftwareTag {
   REQ_Loopback,
   REQ_Needle,
   REQ_MpNext,
   REQ_Clear,
   REQ_Opcode,
   REQ_StartBlock,
   REQ_NumBlocks,
   REQ_Start
};

struct MsgFromSoftware {
  int data : 24;
  MsgFromSoftwareTag tag : 8;
};

enum MsgToSoftwareTag {
   RESP_Loopback=1,
   RESP_LocDone=2,
   RESP_TransferDone=3
};

struct MsgToSoftware {
  int data : 24;
  MsgToSoftwareTag tag : 8;
};

union Msg {
  MsgToSoftware to;
  MsgFromSoftware from;
  int bits;
};

static Nvme *nvme;

void sendMessage(MsgFromSoftwareTag tag, int data, bool last=false)
{
    Msg msg;
    msg.from.tag = tag;
    msg.from.data = data;
    fprintf(stderr, "%s:%d tag=%x data=%06x last=%d msg=%08x\n", __FUNCTION__, __LINE__, tag, data, last, msg.bits);
    nvme->messageFromSoftware(msg.bits, last);
}

int main(int argc, char * const *argv)
{
    nvme = new Nvme();

    int opt;
    const char *filename = 0;
    int source_fd = -1;

    const char *needle = "needle";

    int dotrace = 0;
    int dowrite = 0;
    while ((opt = getopt(argc, argv, "n:w:t")) != -1) {
	switch (opt) {
	case 'n':
	    needle = optarg;
	    break;
	case 't':
	    dotrace = 1;
	    break;
	case 'w':
	    filename = optarg;
	    dowrite = 1;
	    break;
	}
    }

    if (dowrite) {
	struct stat statbuf;
	int rc = stat(filename, &statbuf);
	if (rc < 0) {
	    fprintf(stderr, "%s:%d File %s does not exist %d:%s\n", __FILE__, __LINE__, filename, errno, strerror(errno));
	    return rc;
	}
    }

    sleep(1);
    nvme->setup();
    sleep(1);
    nvme->allocIOQueues(0);

    int needle_len = strlen(needle);
    int border[needle_len+1];

    compute_borders(nvme->needleBuffer.buffer(), border, needle_len);
    compute_MP_next(nvme->needleBuffer.buffer(), (struct MP *)nvme->mpNextBuffer.buffer(), needle_len);
    nvme->needleBuffer.cacheInvalidate(0, 1); // flush the whole thing
    nvme->mpNextBuffer.cacheInvalidate(0, 1); // flush the whole thing

    fprintf(stderr, "CSTS %08x\n", nvme->read32( 0x1c));
    int startBlock = 100000; // base and extent of test file in SSD
    int blocksPerRequest = BlocksPerRequest; //12*BlocksPerRequest;
    int numBlocks = 1*blocksPerRequest; // 55; //8177;

    sendMessage(REQ_Loopback, 22);

    // send needle and mpNext
    for (int i = 0; i < needle_len; i++) {
	struct MP *mpNext = (struct MP *)nvme->mpNextBuffer.buffer();
	bool last = ((i + 1) == needle_len);
	fprintf(stderr, "needle[%d]=%02x mpNext[%d]=%2x.%02x\n", i, needle[i], i, mpNext[i].index, mpNext[i].x);
	sendMessage(REQ_Needle, needle[i], last);
	sendMessage(REQ_MpNext, *(int *)&mpNext[i], last);
    }

    // send search command
    sendMessage(REQ_Opcode, nvme_read);
    sendMessage(REQ_StartBlock, startBlock);
    sendMessage(REQ_NumBlocks, numBlocks);
    sendMessage(REQ_Start, needle_len);

    sleep(10);

    nvme->dumpTrace();

    return 0;
}
