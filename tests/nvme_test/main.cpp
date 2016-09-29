#include <stdio.h>
//#include "jsoncpp/json/json.h"
#include <map>
#include <errno.h>
#include <fcntl.h>
#include <string>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "ConnectalProjectConfig.h"

#include "nvme.h"

int main(int argc, char * const *argv)
{
    int opt;
    const char *filename = NULL;
    int source_fd = -1;

    int doidentify;
    int dotrace = 0;
    int dowrite = 0;
    bool verbose = false;
    while ((opt = getopt(argc, argv, "iw:tv")) != -1) {
	switch (opt) {
	case 'i':
	    doidentify = 1;
	    break;
	case 't':
	    dotrace = 1;
	    break;
	case 'v':
	    verbose = true;
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

    Nvme nvme(verbose);

    sleep(1);

    nvme.setup();

    if (doidentify)
	nvme.identify();
    nvme.getFeatures();
    nvme.allocIOQueues(0);

    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));
    int startBlock = 100000; // base and extent of test file in SSD
    int blocksPerRequest = 8; //12*BlocksPerRequest;
    int numBlocks = 1*blocksPerRequest; // 55; //8177;
    if (dowrite) {
	struct stat statbuf;
	int rc = stat(filename, &statbuf);
	if (rc < 0) {
	    fprintf(stderr, "%s:%d File %s does not exist %d:%s\n", __FILE__, __LINE__, filename, errno, strerror(errno));
	    return rc;
	}
	numBlocks = statbuf.st_blocks;
	numBlocks -= (numBlocks % blocksPerRequest);
	fprintf(stderr, "Writing %d blocks from file %s to flash at block %d\n", numBlocks, filename, startBlock);
	source_fd = open(filename, O_RDONLY);
    }

    for (int block = 0; block < numBlocks; block += blocksPerRequest) {
	nvme_io_opcode opcode = (dowrite) ? nvme_write : nvme_read;
	fprintf(stderr, "starting transfer dowrite=%d opcode=%d\n", dowrite, opcode);
	if (opcode == nvme_write) {
	    if (filename) {
		size_t bytesToRead = 512*blocksPerRequest;
		char *buffer = (char *)nvme.transferBuffer.buffer();
		do {
		    size_t bytesRead = read(source_fd, buffer, bytesToRead);
		    if (bytesRead <= 0) {
			fprintf(stderr, "%s:%d Requested %ld bytes, received %ld bytes errno=%d:%s\n",
				__FUNCTION__, __LINE__, bytesToRead, bytesRead, errno, strerror(errno));
			break;
		    }
		    bytesToRead -= bytesRead;
		    buffer += bytesRead;
		} while (bytesToRead);
	    } else {
		    int *buffer = (int *)nvme.transferBuffer.buffer();
		for (int i = 0; i < numBlocks*512/4; i ++)
		    buffer[i] = i;
	    }
	}
	int sc = nvme.doIO(opcode, startBlock, blocksPerRequest, (opcode == nvme_read ? 2 : 1), dotrace);
	nvme.status();
	if (sc != 0)
	    break;
	startBlock += blocksPerRequest;
    }

    nvme.dumpTrace();
    //nvme.transferStats();
    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));

    return 0;
}
