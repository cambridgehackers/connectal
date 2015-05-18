/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#include <pthread.h>
#include <monkit.h>
#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "ReadTestRequest.h"
#include "ReadTestIndication.h"

#ifdef PCIE
int burstLen = 32;
#else
int burstLen = 16;
#endif

#if !defined(BSIM) && !defined(BOARD_xsim)
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
int iterCnt = 64;
#else
#if defined(BOARD_xsim)
int numWords = 0x40/4;
int iterCnt = 1;
#else
int numWords = 0x124000/4;
int iterCnt = 3;
#endif
#endif

static sem_t test_sem;
static size_t test_sz  = numWords*sizeof(unsigned int);
static size_t alloc_sz = test_sz;
static int mismatchCount = 0;
static ReadTestRequestProxy *device = 0;

class ReadTestIndication : public ReadTestIndicationWrapper
{
public:
    void readDone(uint32_t v) {
        fprintf(stderr, "ReadTest::readDone(%x)\n", v);
        mismatchCount += v;
        sem_post(&test_sem);
    }
    ReadTestIndication(int id) : ReadTestIndicationWrapper(id){}
};

int main(int argc, const char ** argv)
{
    int test_result = 0;
    int srcAlloc;
    unsigned int *srcBuffer = 0;

    fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);
    device = new ReadTestRequestProxy(IfcNames_ReadTestRequestS2H);
    MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_MemServerRequestS2H);
    MMURequestProxy *dmap = new MMURequestProxy(IfcNames_MMURequestS2H);
    DmaManager *dma = new DmaManager(dmap);
    MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_MemServerIndicationH2S);
    ReadTestIndication memReadIndication(IfcNames_ReadTestIndicationH2S);
    MMUIndication mmuIndication(dma, IfcNames_MMUIndicationH2S);

    fprintf(stderr, "Main::allocating memory...\n");
    srcAlloc = portalAlloc(alloc_sz, 0);
    srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
    for (int i = 0; i < numWords; i++)
        srcBuffer[i] = i;
    portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
    fprintf(stderr, "Main::flush and invalidate complete\n");

#ifdef FPGA0_CLOCK_FREQ
    long req_freq = FPGA0_CLOCK_FREQ;
    long freq = 0;
    setClockFrequency(0, req_freq, &freq);
    fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
#endif

    /* Test 1: check that match is ok */
    unsigned int ref_srcAlloc = dma->reference(srcAlloc);
    fprintf(stderr, "ref_srcAlloc=%d\n", ref_srcAlloc);
    fprintf(stderr, "Main::orig_test read numWords=%d burstLen=%d iterCnt=%d\n", numWords, burstLen, iterCnt);
    portalTimerStart(0);
    device->startRead(ref_srcAlloc, numWords * 4, burstLen * 4, iterCnt);
    sem_wait(&test_sem);
    if (mismatchCount) {
        fprintf(stderr, "Main::first test failed to match %d.\n", mismatchCount);
        test_result++;     // failed
    }
    uint64_t cycles = portalTimerLap(0);
    hostMemServerRequest->memoryTraffic(ChannelType_Read);
    uint64_t beats = hostMemServerIndication->receiveMemoryTraffic();
    float read_util = (float)beats/(float)cycles;
    fprintf(stderr, " iterCnt: %d\n", iterCnt);
    fprintf(stderr, "   beats: %llx\n", (long long)beats);
    fprintf(stderr, "numWords: %x\n", numWords);
    fprintf(stderr, "     est: %llx\n", (long long)(beats*2)/iterCnt);
    fprintf(stderr, "memory read utilization (beats/cycle): %f\n", read_util);

    /* Test 2: check that mismatch is detected */
    srcBuffer[0] = -1;
    srcBuffer[numWords/2] = -1;
    srcBuffer[numWords-1] = -1;
    portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);

    fprintf(stderr, "Starting second read, mismatches expected\n");
    mismatchCount = 0;
    device->startRead(ref_srcAlloc, numWords * 4, burstLen * 4, iterCnt);
    sem_wait(&test_sem);
    if (mismatchCount != 3/*number of errors introduced above*/ * iterCnt) {
        fprintf(stderr, "Main::second test failed to match mismatchCount=%d (expected %d) iterCnt=%d numWords=%d.\n",
            mismatchCount, 3*iterCnt,
            iterCnt, numWords);
        test_result++;     // failed
    }
#if 0
    MonkitFile pmf("perf.monkit");
    pmf.setHwCycles(cycles)
        .setReadBwUtil(read_util)
        .writeFile();
#endif
    return test_result;
}

