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
#include "mp.h"

class StringSearchResponse : public StringSearchResponseWrapper {
public:
    virtual void strstrLoc ( const uint32_t pos ) {
	if (pos != (uint32_t)-1)
	    fprintf(stderr, "string search at character pos=%d\n", pos);
    }
    StringSearchResponse(int id, PortalPoller *poller = 0) : StringSearchResponseWrapper(id, poller) {
    }
};

int main(int argc, char * const *argv)
{
    Nvme nvme;
    StringSearchRequestProxy search(IfcNames_StringSearchRequestS2H);
    StringSearchResponse     searchResponse(IfcNames_StringSearchResponseH2S);

    int opt;
    const char *filename = NULL;
    const char *needle = "needle";
    int source_fd = -1;

    int doidentify;
    int dosearch = 0;
    int dotrace = 0;
    int dowrite = 0;
    while ((opt = getopt(argc, argv, "iw:s:t")) != -1) {
	switch (opt) {
	case 'i':
	    doidentify = 1;
	    break;
	case 's':
	    needle = optarg;
	    dosearch = 1;
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

    nvme.setup();

    if (dosearch) {
	int needle_len = strlen(needle);
	int border[needle_len+1];

	compute_borders(nvme.needleBuffer.buffer(), border, needle_len);
	compute_MP_next(nvme.needleBuffer.buffer(), (struct MP *)nvme.mpNextBuffer.buffer(), needle_len);
	nvme.needleBuffer.cacheInvalidate(0, 1); // flush the whole thing
	nvme.mpNextBuffer.cacheInvalidate(0, 1); // flush the whole thing

	//FIXME: read the text from NVME storage
	//MP(needle, haystack, mpNext, needle_len, haystack_len, &sw_match_cnt);

	// the MPEngine will read in the needle and mpNext
	search.setSearchString(nvme.needleRef, nvme.mpNextRef, needle_len);
    }

    if (doidentify)
	nvme.identify();
    nvme.getFeatures();
    nvme.allocIOQueues(0);

    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));
    int startBlock = 100000; // base and extent of test file in SSD
    int blocksPerRequest = 8; //12*BlocksPerRequest;
    int numBlocks = 1*blocksPerRequest; // 55; //8177;
    if (dosearch) {
	search.startSearch(numBlocks*512);
    } else {
      // if search is not running, then data read below will be discarded
    }
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
