#include <stdio.h>
//#include "jsoncpp/json/json.h"
#include <map>
#include <string>

#include "nvme.h"
#include "mp.h"

class StringSearchResponse : public StringSearchResponseWrapper {
public:
    virtual void strstrLoc ( const uint32_t loc ) {
	fprintf(stderr, "strstr loc loc=%d\n", loc);
    }
    StringSearchResponse(int id, PortalPoller *poller = 0) : StringSearchResponseWrapper(id, poller) {
    }
};

int main(int argc, const char **argv)
{
    Nvme nvme;
    StringSearchRequestProxy search(IfcNames_StringSearchRequestS2H);
    StringSearchResponse     searchResponse(IfcNames_StringSearchResponseH2S);

    sleep(1);

    nvme.setup();

    const char *needle = "property";
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

    identify(&nvme);
    getFeatures(&nvme);
    allocIOQueues(&nvme, 0);

    fprintf(stderr, "CSTS %08x\n", nvme.read32( 0x1c));
    int startBlock = 34816; // base and extent of test file in SSD
    int blocksPerRequest = 8; //12*BlocksPerRequest;
    int numBlocks = 1*blocksPerRequest; // 55; //8177;
    if (0)
	search.startSearch(numBlocks*512);
    for (int block = 0; block < numBlocks; block += blocksPerRequest) {
	nvme_io_opcode opcode = nvme_write;
	int sc = doIO(&nvme, opcode, startBlock, blocksPerRequest, (opcode == nvme_read ? 2 : 1));
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
