// Copyright (c) 2015 The Connectal Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
#include <monkit.h>
#include <list>
#include <time.h>
#include "dmaManager.h"
#include "FlashIndication.h"
#include "FlashRequest.h"

static int trace_memory = 0;
extern "C" {
#include "userReference.h"
}


#define BLOCKS_PER_CHIP 2
#define CHIPS_PER_BUS 8
#define NUM_BUSES 8

#define PAGE_SIZE 8192
#define NUM_TAGS 128

typedef enum {
	UNINIT,
	ERASED,
	WRITTEN
} FlashStatusT;

typedef struct {
	bool busy;
	int bus;
	int chip;
	int block;
} TagTableEntry;

FlashRequestProxy *device;

pthread_mutex_t flashReqMutex;
pthread_cond_t flashFreeTagCond;

//8k * 128
size_t dstAlloc_sz = PAGE_SIZE * NUM_TAGS *sizeof(unsigned char);
size_t srcAlloc_sz = PAGE_SIZE * NUM_TAGS *sizeof(unsigned char);
int dstAlloc;
int srcAlloc;
unsigned int ref_dstAlloc; 
unsigned int ref_srcAlloc; 
unsigned int* dstBuffer;
unsigned int* srcBuffer;
unsigned int* readBuffers[NUM_TAGS];
unsigned int* writeBuffers[NUM_TAGS];
TagTableEntry readTagTable[NUM_TAGS]; 
TagTableEntry writeTagTable[NUM_TAGS]; 
TagTableEntry eraseTagTable[NUM_TAGS]; 
FlashStatusT flashStatus[NUM_BUSES][CHIPS_PER_BUS][BLOCKS_PER_CHIP];

int testPass = 1;
bool verbose = true;
int curReadsInFlight = 0;
int curWritesInFlight = 0;
int curErasesInFlight = 0;

double timespec_diff_sec( timespec start, timespec end ) {
	double t = end.tv_sec - start.tv_sec;
	t += ((double)(end.tv_nsec - start.tv_nsec)/1000000000L);
	return t;
}


unsigned int hashAddrToData(int bus, int chip, int blk, int word) {
	return ((bus<<24) + (chip<<20) + (blk<<16) + word);
}


bool checkReadData(int tag) {
	TagTableEntry e = readTagTable[tag];
	int goldenData;
	if (flashStatus[e.bus][e.chip][e.block]==WRITTEN) {
		int numErrors = 0;
		for (int word=0; word<PAGE_SIZE/sizeof(unsigned int); word++) {
			goldenData = hashAddrToData(e.bus, e.chip, e.block, word);
			if (goldenData != readBuffers[tag][word]) {
				fprintf(stderr, "LOG: **ERROR: read data mismatch! Expected: %x, read: %x\n", goldenData, readBuffers[tag][word]);
				numErrors++; 
				testPass = 0;
			}
		}
		if (numErrors==0) {
			fprintf(stderr, "LOG: Read data check passed on tag=%d!\n", tag);
		}
	}
	else if (flashStatus[e.bus][e.chip][e.block]==ERASED) {
		//only check first word. It may return 0 if bad block, or -1 if erased
		if (readBuffers[tag][0]==-1) {
			fprintf(stderr, "LOG: Read check pass on erased block!\n");
		}
		else if (readBuffers[tag][0]==0) {
			fprintf(stderr, "LOG: Warning: potential bad block, read erased data 0\n");
		}
		else {
			fprintf(stderr, "LOG: **ERROR: read data mismatch! Expected: ERASED, read: %x\n", readBuffers[tag][0]);
			testPass = 0;
		}
	}
	else {
		fprintf(stderr, "LOG: **ERROR: flash block state unknown. Did you erase before write?\n");
		testPass = 0;
	}
}

class FlashIndication : public FlashIndicationWrapper
{

	public:
		FlashIndication(unsigned int id) : FlashIndicationWrapper(id){}

		virtual void readDone(unsigned int tag) {

			if ( verbose ) {
				//printf( "%s received read page buffer: %d %d\n", log_prefix, rbuf, curReadsInFlight );
				printf( "LOG: pagedone: tag=%d; inflight=%d\n", tag, curReadsInFlight );
				fflush(stdout);
			}

			//check 
			checkReadData(tag);

			pthread_mutex_lock(&flashReqMutex);
			curReadsInFlight --;
			if ( curReadsInFlight < 0 ) {
				fprintf(stderr, "LOG: **ERROR: Read requests in flight cannot be negative %d\n", curReadsInFlight );
				curReadsInFlight = 0;
			}
			if ( readTagTable[tag].busy == false ) {
				fprintf(stderr, "LOG: **ERROR: received unused buffer read done %d\n", tag);
				testPass = 0;
			}
			readTagTable[tag].busy = false;
			//pthread_cond_broadcast(&flashFreeTagCond);
			pthread_mutex_unlock(&flashReqMutex);
		}

		virtual void writeDone(unsigned int tag) {
			printf("LOG: writedone, tag=%d\n", tag); fflush(stdout);
			//TODO probably should use a diff lock
			pthread_mutex_lock(&flashReqMutex);
			curWritesInFlight--;
			if ( curWritesInFlight < 0 ) {
				fprintf(stderr, "LOG: **ERROR: Write requests in flight cannot be negative %d\n", curWritesInFlight );
				curWritesInFlight = 0;
			}
			if ( writeTagTable[tag].busy == false ) {
				fprintf(stderr, "LOG: **ERROR: received unused buffer Write done %d\n", tag);
				testPass = 0;
			}
			writeTagTable[tag].busy = false;
			pthread_mutex_unlock(&flashReqMutex);
		}

		virtual void eraseDone(unsigned int tag, unsigned int status) {
			printf("LOG: eraseDone, tag=%d, status=%d\n", tag, status); fflush(stdout);
			if (status != 0) {
				printf("LOG: detected bad block with tag = %d\n", tag);
			}

			pthread_mutex_lock(&flashReqMutex);
			curErasesInFlight--;
			if ( curErasesInFlight < 0 ) {
				fprintf(stderr, "LOG: **ERROR: erase requests in flight cannot be negative %d\n", curErasesInFlight );
				curErasesInFlight = 0;
			}
			if ( eraseTagTable[tag].busy == false ) {
				fprintf(stderr, "LOG: **ERROR: received unused tag erase done %d\n", tag);
				testPass = 0;
			}
			eraseTagTable[tag].busy = false;
			pthread_mutex_unlock(&flashReqMutex);
		}

		virtual void debugDumpResp (unsigned int debug0, unsigned int debug1,  unsigned int debug2, unsigned int debug3) {
			//uint64_t cntHi = debugRdCntHi;
			//uint64_t rdCnt = (cntHi<<32) + debugRdCntLo;
			fprintf(stderr, "LOG: DEBUG DUMP: gearSend = %d, gearRec = %d, aurSend = %d, aurRec = %d\n", debug0, debug1, debug2, debug3);
		}


};




int getNumReadsInFlight() { return curReadsInFlight; }
int getNumWritesInFlight() { return curWritesInFlight; }
int getNumErasesInFlight() { return curErasesInFlight; }



//TODO: more efficient locking
int waitIdleEraseTag() {
	int tag = -1;
	while ( tag < 0 ) {
	pthread_mutex_lock(&flashReqMutex);

		for ( int t = 0; t < NUM_TAGS; t++ ) {
			if ( !eraseTagTable[t].busy ) {
				eraseTagTable[t].busy = true;
				tag = t;
				break;
			}
		}
	pthread_mutex_unlock(&flashReqMutex);
		/*
		if (tag < 0) {
			pthread_cond_wait(&flashFreeTagCond, &flashReqMutex);
		}
		else {
			pthread_mutex_unlock(&flashReqMutex);
			return tag;
		}
		*/
	}
	return tag;
}


//TODO: more efficient locking
int waitIdleWriteBuffer() {
	int tag = -1;
	while ( tag < 0 ) {
	pthread_mutex_lock(&flashReqMutex);

		for ( int t = 0; t < NUM_TAGS; t++ ) {
			if ( !writeTagTable[t].busy) {
				writeTagTable[t].busy = true;
				tag = t;
				break;
			}
		}
	pthread_mutex_unlock(&flashReqMutex);
		/*
		if (tag < 0) {
			pthread_cond_wait(&flashFreeTagCond, &flashReqMutex);
		}
		else {
			pthread_mutex_unlock(&flashReqMutex);
			return tag;
		}
		*/
	}
	return tag;
}



//TODO: more efficient locking
int waitIdleReadBuffer() {
	int tag = -1;
	while ( tag < 0 ) {
	pthread_mutex_lock(&flashReqMutex);

		for ( int t = 0; t < NUM_TAGS; t++ ) {
			if ( !readTagTable[t].busy ) {
				readTagTable[t].busy = true;
				tag = t;
				break;
			}
		}
	pthread_mutex_unlock(&flashReqMutex);
		/*
		if (tag < 0) {
			pthread_cond_wait(&flashFreeTagCond, &flashReqMutex);
		}
		else {
			pthread_mutex_unlock(&flashReqMutex);
			return tag;
		}
		*/
	}
	return tag;
}


void eraseBlock(int bus, int chip, int block, int tag) {
	pthread_mutex_lock(&flashReqMutex);
	curErasesInFlight ++;
	flashStatus[bus][chip][block] = ERASED;
	pthread_mutex_unlock(&flashReqMutex);

	if ( verbose ) fprintf(stderr, "LOG: sending erase block request with tag=%d @%d %d %d 0\n", tag, bus, chip, block );
	device->eraseBlock(bus,chip,block,tag);
}



void writePage(int bus, int chip, int block, int page, int tag) {
	pthread_mutex_lock(&flashReqMutex);
	curWritesInFlight ++;
	flashStatus[bus][chip][block] = WRITTEN;
	pthread_mutex_unlock(&flashReqMutex);

	if ( verbose ) fprintf(stderr, "LOG: sending write page request with tag=%d @%d %d %d %d\n", tag, bus, chip, block, page );
	device->writePage(bus,chip,block,page,tag);
}

void readPage(int bus, int chip, int block, int page, int tag) {
	pthread_mutex_lock(&flashReqMutex);
	curReadsInFlight ++;
	readTagTable[tag].bus = bus;
	readTagTable[tag].chip = chip;
	readTagTable[tag].block = block;
	pthread_mutex_unlock(&flashReqMutex);

	if ( verbose ) fprintf(stderr, "LOG: sending read page request with tag=%d @%d %d %d %d\n", tag, bus, chip, block, page );
	device->readPage(bus,chip,block,page,tag);
}


int main(int argc, const char **argv)
{
        DmaManager *dma = platformInit();
	fprintf(stderr, "Main::allocating memory...\n");

	device = new FlashRequestProxy(IfcNames_NandCfgRequest);
	FlashIndication *deviceIndication = new FlashIndication(IfcNames_NandCfgIndication);
	
	srcAlloc = portalAlloc(srcAlloc_sz, 0);
	dstAlloc = portalAlloc(dstAlloc_sz, 0);
	srcBuffer = (unsigned int *)portalMmap(srcAlloc, srcAlloc_sz);
	dstBuffer = (unsigned int *)portalMmap(dstAlloc, dstAlloc_sz);

	fprintf(stderr, "dstAlloc = %x\n", dstAlloc); 
	fprintf(stderr, "srcAlloc = %x\n", srcAlloc); 
	
	pthread_mutex_init(&flashReqMutex, NULL);
	pthread_cond_init(&flashFreeTagCond, NULL);

	printf( "Done initializing hw interfaces\n" ); fflush(stdout);

	portalCacheFlush(dstAlloc, dstBuffer, dstAlloc_sz, 1);
	portalCacheFlush(srcAlloc, srcBuffer, srcAlloc_sz, 1);
	ref_dstAlloc = dma->reference(dstAlloc);
	ref_srcAlloc = dma->reference(srcAlloc);

	for (int t = 0; t < NUM_TAGS; t++) {
		readTagTable[t].busy = false;
		writeTagTable[t].busy = false;
		int byteOffset = t * PAGE_SIZE;
		device->addDmaWriteRefs(ref_dstAlloc, byteOffset, t);
		device->addDmaReadRefs(ref_srcAlloc, byteOffset, t);
		readBuffers[t] = dstBuffer + byteOffset/sizeof(unsigned int);
		writeBuffers[t] = srcBuffer + byteOffset/sizeof(unsigned int);
	}
	
	for (int blk=0; blk<BLOCKS_PER_CHIP; blk++) {
		for (int c=0; c<CHIPS_PER_BUS; c++) {
			for (int bus=0; bus< CHIPS_PER_BUS; bus++) {
				flashStatus[bus][c][blk] = UNINIT;
			}
		}
	}


	for (int t = 0; t < NUM_TAGS; t++) {
		for ( int i = 0; i < PAGE_SIZE/sizeof(unsigned int); i++ ) {
			readBuffers[t][i] = 0;
			writeBuffers[t][i] = 0;
		}
	}

	device->start(0);
	device->setDebugVals(0,0); //flag, delay

	device->debugDumpReq(0);
	sleep(1);
	device->debugDumpReq(0);
	sleep(1);
	//TODO: test writes and erases
	


	//test erases
	for (int blk = 0; blk < BLOCKS_PER_CHIP; blk++){
		for (int chip = 0; chip < CHIPS_PER_BUS; chip++){
			for (int bus = 0; bus < NUM_BUSES; bus++){
				eraseBlock(bus, chip, blk, waitIdleEraseTag());
			}
		}
	}

	while (true) {
		usleep(100);
		if ( getNumErasesInFlight() == 0 ) break;
	}
	
	//read back erased pages
	for (int blk = 0; blk < BLOCKS_PER_CHIP; blk++){
		for (int chip = 0; chip < CHIPS_PER_BUS; chip++){
			for (int bus = 0; bus < NUM_BUSES; bus++){
				int page = 0;
				readPage(bus, chip, blk, page, waitIdleReadBuffer());
			}
		}
	}
	while (true) {
		usleep(100);
		if ( getNumReadsInFlight() == 0 ) break;
	}


	//write pages
	//FIXME: in old xbsv, simulatneous DMA reads using multiple readers cause kernel panic
	//Issue each bus separately for now
	for (int bus = 0; bus < NUM_BUSES; bus++){
	
		for (int blk = 0; blk < BLOCKS_PER_CHIP; blk++){
			for (int chip = 0; chip < CHIPS_PER_BUS; chip++){
				int page = 0;
				//get free tag
				int freeTag = waitIdleWriteBuffer();
				//fill write memory
				for (int w=0; w<PAGE_SIZE/sizeof(unsigned int); w++) {
					writeBuffers[freeTag][w] = hashAddrToData(bus, chip, blk, w);
				}
				//send request
				writePage(bus, chip, blk, page, freeTag);
			}
		}
		
		
		while (true) {
			usleep(100);
			if ( getNumWritesInFlight() == 0 ) break;
		}
	} //each bus
	

	timespec start, now;
	clock_gettime(CLOCK_REALTIME, & start);

	for (int repeat = 0; repeat < 1; repeat++){
		for (int blk = 0; blk < BLOCKS_PER_CHIP; blk++){
			for (int chip = 0; chip < CHIPS_PER_BUS; chip++){
				for (int bus = 0; bus < NUM_BUSES; bus++){

				//int blk = rand() % 1024;
				//int chip = rand() % 8;
				//int bus = rand() % 8;
					int page = 0;
					readPage(bus, chip, blk, page, waitIdleReadBuffer());
				}
			}
		}
	}
	
	int elapsed = 0;
	while (true) {
		usleep(100);
		if (elapsed == 0) {
			elapsed=10000;
			device->debugDumpReq(0);
		}
		else {
			elapsed--;
		}
		if ( getNumReadsInFlight() == 0 ) break;
	}
	device->debugDumpReq(0);

	clock_gettime(CLOCK_REALTIME, & now);
	fprintf(stderr, "LOG: finished reading from page! %f\n", timespec_diff_sec(start, now) );

	for ( int t = 0; t < NUM_TAGS; t++ ) {
		for ( int i = 0; i < PAGE_SIZE/sizeof(unsigned int); i++ ) {
			fprintf(stderr,  "%x %x %x\n", t, i, readBuffers[t][i] );
		}
	}
	if (testPass==1) {
		fprintf(stderr, "LOG: TEST PASSED!\n");
	}
	else {
		fprintf(stderr, "LOG: **ERROR: TEST FAILED!\n");
	}


}
