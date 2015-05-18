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
#include "monkit.h"
#include "StdDmaIndication.h"
#include "MMURequest.h"
#include "MemwriteIndication.h"
#include "MemwriteRequest.h"

#if defined(BSIM) || defined(BOARD_xsim)
#ifdef BOARD_xsim
static int numWords = 0x5000/4;
static int iterCnt = 1;
#else
static int numWords = 0x124000/4;
static int iterCnt = 2;
#endif
#else
static int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
static int iterCnt = 128;
#endif
#ifdef PCIE
static int burstLen = 32;
#else
static int burstLen = 16;
#endif

static sem_t test_sem;
static size_t alloc_sz = numWords*sizeof(unsigned int);

class MemwriteIndication : public MemwriteIndicationWrapper
{
public:
    MemwriteIndication(int id) : MemwriteIndicationWrapper(id) {}
    void started(uint32_t words) {
        fprintf(stderr, "Memwrite::started: words=%x\n", words);
    }
    void writeDone ( uint32_t srcGen ) {
        fprintf(stderr, "Memwrite::writeDone (%08x)\n", srcGen);
        sem_post(&test_sem);
    }
    void reportStateDbg(uint32_t streamWrCnt, uint32_t srcGen) {
        fprintf(stderr, "Memwrite::reportStateDbg: streamWrCnt=%08x srcGen=%d\n", streamWrCnt, srcGen);
    }
};

int main(int argc, const char **argv)
{
    int mismatch = 0;
    uint32_t sg = 0;
    int max_error = 10;

    if (sem_init(&test_sem, 1, 0)) {
        fprintf(stderr, "error: failed to init test_sem\n");
        exit(1);
    }
    fprintf(stderr, "testmemwrite: start %s %s\n", __DATE__, __TIME__);
    MemwriteRequestProxy *device = new MemwriteRequestProxy(IfcNames_MemwriteRequestS2H);
    MemwriteIndication deviceIndication(IfcNames_MemwriteIndicationH2S);
    MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_MemServerRequestS2H);
    MMURequestProxy *dmap = new MMURequestProxy(IfcNames_MMURequestS2H);
    DmaManager *dma = new DmaManager(dmap);
    MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_MemServerIndicationH2S);
    MMUIndication hostMMUIndication(dma, IfcNames_MMUIndicationH2S);

    fprintf(stderr, "parent::allocating memory...\n");
    int dstAlloc = portalAlloc(alloc_sz, 0);
    unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
#ifdef FPGA0_CLOCK_FREQ
    long req_freq = FPGA0_CLOCK_FREQ, freq = 0;
    setClockFrequency(0, req_freq, &freq);
    fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
#endif
    unsigned int ref_dstAlloc = dma->reference(dstAlloc);
    for (int i = 0; i < numWords; i++)
        dstBuffer[i] = 0xDEADBEEF;
    portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
    fprintf(stderr, "testmemwrite: flush and invalidate complete\n");
    fprintf(stderr, "testmemwrite: starting write %08x\n", numWords);
    portalTimerStart(0);
    device->startWrite(ref_dstAlloc, 0, numWords, burstLen, iterCnt);
    sem_wait(&test_sem);
    for (int i = 0; i < numWords; i++) {
        if (dstBuffer[i] != sg) {
            mismatch++;
            if (max_error-- > 0)
                fprintf(stderr, "testmemwrite: [%d] actual %08x expected %08x\n", i, dstBuffer[i], sg);
        }
        sg++;
    }
    uint64_t cycles = portalTimerLap(0);
    hostMemServerRequest->memoryTraffic(ChannelType_Write);
    uint64_t beats = hostMemServerIndication->receiveMemoryTraffic();
    float write_util = (float)beats/(float)cycles;
    fprintf(stderr, "   beats: %"PRIx64"\n", beats);
    fprintf(stderr, "numWords: %x\n", numWords);
    fprintf(stderr, "     est: %"PRIx64"\n", (beats*2)/iterCnt);
    fprintf(stderr, "memory write utilization (beats/cycle): %f\n", write_util);
    fprintf(stderr, "testmemwrite: mismatch count %d.\n", mismatch);
    sleep(2);

    MonkitFile("perf.monkit")
      .setHwCycles(cycles)
      .setWriteBwUtil(write_util)
      .writeFile();
    exit(mismatch);
}
