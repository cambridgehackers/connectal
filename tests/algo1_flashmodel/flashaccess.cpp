#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <monkit.h>
#include <semaphore.h>

#include <list>
#include <time.h>

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "FlashIndication.h"
#include "FlashRequest.h"

#define PAGE_SIZE 8192
#define NUM_TAGS 128

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
bool dstBufBusy[NUM_TAGS]; 
bool srcBufBusy[NUM_TAGS]; 
bool eraseTagBusy[NUM_TAGS]; 

bool verbose = true;
int curReadsInFlight = 0;
int curWritesInFlight = 0;
int curErasesInFlight = 0;

double timespec_diff_sec( timespec start, timespec end ) {
	double t = end.tv_sec - start.tv_sec;
	t += ((double)(end.tv_nsec - start.tv_nsec)/1000000000L);
	return t;
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

			pthread_mutex_lock(&flashReqMutex);
			curReadsInFlight --;
			if ( curReadsInFlight < 0 ) {
				fprintf(stderr, "Read requests in flight cannot be negative %d\n", curReadsInFlight );
				curReadsInFlight = 0;
			}
			if ( dstBufBusy[tag] == false ) {
				fprintf(stderr, "**ERROR: received unused buffer read done %d\n", tag);
			}
			dstBufBusy[tag] = false;
			//pthread_cond_broadcast(&flashFreeTagCond);
			pthread_mutex_unlock(&flashReqMutex);
		}

		virtual void writeDone(unsigned int tag) {
			printf("LOG: writedone, tag=%d\n", tag); fflush(stdout);
			//TODO probably should use a diff lock
			pthread_mutex_lock(&flashReqMutex);
			curWritesInFlight--;
			if ( curWritesInFlight < 0 ) {
				fprintf(stderr, "Write requests in flight cannot be negative %d\n", curWritesInFlight );
				curWritesInFlight = 0;
			}
			if ( srcBufBusy[tag] == false ) {
				fprintf(stderr, "**ERROR: received unused buffer Write done %d\n", tag);
			}
			srcBufBusy[tag] = false;
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
				fprintf(stderr, "erase requests in flight cannot be negative %d\n", curErasesInFlight );
				curErasesInFlight = 0;
			}
			if ( eraseTagBusy[tag] == false ) {
				fprintf(stderr, "**ERROR: received unused tag erase done %d\n", tag);
			}
			eraseTagBusy[tag] = false;
			pthread_mutex_unlock(&flashReqMutex);
		}

		virtual void debugDumpResp (unsigned int debug0, unsigned int debug1,  unsigned int debug2, unsigned int debug3) {
			//uint64_t cntHi = debugRdCntHi;
			//uint64_t rdCnt = (cntHi<<32) + debugRdCntLo;
			fprintf(stderr, "DEBUG DUMP: gearSend = %d, gearRec = %d, aurSend = %d, aurRec = %d\n", debug0, debug1, debug2, debug3);
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
			if ( !eraseTagBusy[t] ) {
				eraseTagBusy[t] = true;
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
			if ( !srcBufBusy[t] ) {
				srcBufBusy[t] = true;
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
			if ( !dstBufBusy[t] ) {
				dstBufBusy[t] = true;
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
	pthread_mutex_unlock(&flashReqMutex);

	if ( verbose ) fprintf(stderr, "LOG: sending erase block request with tag=%d @%d %d %d 0\n", tag, bus, chip, block );
	device->eraseBlock(bus,chip,block,tag);
}



void writePage(int bus, int chip, int block, int page, int tag) {
	pthread_mutex_lock(&flashReqMutex);
	curWritesInFlight ++;
	pthread_mutex_unlock(&flashReqMutex);

	if ( verbose ) fprintf(stderr, "LOG: sending write page request with tag=%d @%d %d %d %d\n", tag, bus, chip, block, page );
	device->writePage(bus,chip,block,page,tag);
}

void readPage(int bus, int chip, int block, int page, int tag) {
	pthread_mutex_lock(&flashReqMutex);
	curReadsInFlight ++;
	pthread_mutex_unlock(&flashReqMutex);

	if ( verbose ) fprintf(stderr, "LOG: sending read page request with tag=%d @%d %d %d %d\n", tag, bus, chip, block, page );
	device->readPage(bus,chip,block,page,tag);
}


int main(int argc, const char **argv)
{

	MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
	MMURequestProxy *dmap = new MMURequestProxy(IfcNames_BackingStoreMMURequest);
	DmaManager *dma = new DmaManager(dmap);
	MemServerIndication *hostMemServerIndication = new MemServerIndication(IfcNames_HostMemServerIndication);
	MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_BackingStoreMMUIndication);

	fprintf(stderr, "Main::allocating memory...\n");

	device = new FlashRequestProxy(IfcNames_NandCfgRequest);
	FlashIndication *deviceIndication = new FlashIndication(IfcNames_NandCfgIndication);
	
	srcAlloc = portalAlloc(srcAlloc_sz);
	dstAlloc = portalAlloc(dstAlloc_sz);
	srcBuffer = (unsigned int *)portalMmap(srcAlloc, srcAlloc_sz);
	dstBuffer = (unsigned int *)portalMmap(dstAlloc, dstAlloc_sz);

	fprintf(stderr, "dstAlloc = %x\n", dstAlloc); 
	fprintf(stderr, "srcAlloc = %x\n", srcAlloc); 
	
	pthread_mutex_init(&flashReqMutex, NULL);
	pthread_cond_init(&flashFreeTagCond, NULL);

	printf( "Done initializing hw interfaces\n" ); fflush(stdout);

	portalExec_start();
	printf( "Done portalExec_start\n" ); fflush(stdout);

	portalDCacheFlushInval(dstAlloc, dstAlloc_sz, dstBuffer);
	portalDCacheFlushInval(srcAlloc, srcAlloc_sz, srcBuffer);
	ref_dstAlloc = dma->reference(dstAlloc);
	ref_srcAlloc = dma->reference(srcAlloc);

	for (int t = 0; t < NUM_TAGS; t++) {
		dstBufBusy[t] = false;
		srcBufBusy[t] = false;
		int byteOffset = t * PAGE_SIZE;
		device->addDmaWriteRefs(ref_dstAlloc, byteOffset, t);
		device->addDmaReadRefs(ref_srcAlloc, byteOffset, t);
		readBuffers[t] = dstBuffer + byteOffset/sizeof(unsigned int);
		writeBuffers[t] = srcBuffer + byteOffset/sizeof(unsigned int);
	}
	
	for (int t = 0; t < NUM_TAGS; t++) {
		for ( int i = 0; i < PAGE_SIZE/sizeof(unsigned int); i++ ) {
			readBuffers[t][i] = 0;
			writeBuffers[t][i] = (t<<16)+i;
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
	for (int blk = 0; blk < 1024; blk++){
		for (int chip = 7; chip >= 0; chip--){
			for (int bus = 7; bus >= 0; bus--){
				eraseBlock(bus, chip, blk, waitIdleEraseTag());
			}
		}
	}

	while (true) {
		usleep(100);
		if ( getNumErasesInFlight() == 0 ) break;
	}
	


	
	for (int blk = 0; blk < 1; blk++){
		for (int chip = 7; chip >= 0; chip--){
			for (int bus = 0; bus >= 0; bus--){
				int page = 0;
				writePage(bus, chip, blk, page, waitIdleWriteBuffer());
			}
		}
	}
	
	while (true) {
		usleep(100);
		if ( getNumWritesInFlight() == 0 ) break;
	}
	

	timespec start, now;
	clock_gettime(CLOCK_REALTIME, & start);

	for (int repeat = 0; repeat < 1; repeat++){
		for (int blk = 0; blk < 1; blk++){
			for (int chip = 7; chip >= 0; chip--){
				for (int bus = 7; bus >= 0; bus--){

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
	printf( "finished reading from page! %f\n", timespec_diff_sec(start, now) );

	for ( int t = 0; t < NUM_TAGS; t++ ) {
		for ( int i = 0; i < PAGE_SIZE/sizeof(unsigned int); i++ ) {
			fprintf(stderr,  "%x %x %x\n", t, i, readBuffers[t][i] );
		}
	}
}
