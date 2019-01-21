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
#include "dmaManager.h"
#include "MemwriteIndication.h"
#include "MemwriteRequest.h"

#ifdef BOARD_xsim
static int numWords = 0x5000/4;
static int iterCnt = 1;
#elif defined(SIMULATION)
static int numWords = 4096;
static int iterCnt = 8;
#else
static int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
static int iterCnt = 8;
#endif
#ifdef PCIE
static int burstLen = 32;
static int burstLenMin = 32;
static int burstLenMax = 32;
#elif defined(ZynqUltrascale)
static int burstLen = 16;
static int burstLenMin = 4;
static int burstLenMax = 64; // 256byte = 16beats of 128bit
#else
static int burstLen = 16;
static int burstLenMin = 16;
static int burstLenMax = 16;
#endif

#ifdef NumEngineServers
int numEngineServers = NumEngineServers;
#else
int numEngineServers = 1;
#endif

static sem_t test_sem;
static size_t alloc_sz = numWords*sizeof(unsigned int);

class MemwriteIndication : public MemwriteIndicationWrapper
{
public:
    MemwriteIndication(int id, int tile=DEFAULT_TILE) : MemwriteIndicationWrapper(id,tile) {}
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
    DmaManager *dma = platformInit();
    MemwriteRequestProxy *device = new MemwriteRequestProxy(IfcNames_MemwriteRequestS2H);
    MemwriteIndication deviceIndication(IfcNames_MemwriteIndicationH2S);

    alloc_sz *= numEngineServers;

    fprintf(stderr, "main::allocating %lx bytes of memory...\n", (long)alloc_sz);
    int dstAlloc = portalAlloc(alloc_sz, 0);
    unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
#ifdef FPGA0_CLOCK_FREQ
    long req_freq = FPGA0_CLOCK_FREQ, freq = 0;
    setClockFrequency(0, req_freq, &freq);
    fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
#endif
    unsigned int ref_dstAlloc = dma->reference(dstAlloc);
    for (int i = 0; i < numWords*numEngineServers; i++)
        dstBuffer[i] = 0xDEADBEEF;
    portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);
    fprintf(stderr, "testmemwrite: flush and invalidate complete\n");

    burstLen = burstLenMin; // words
    while (burstLen <= burstLenMax) {
      fprintf(stderr, "testmemwrite: starting write %#08x words burstLen=%d words\n", numWords, burstLen);
      portalTimerStart(0);
      device->startWrite(ref_dstAlloc, 0, numWords, burstLen, iterCnt);
      sem_wait(&test_sem);
      mismatch = 0;
	  sg = 0;
      for (int i = 0; i < numWords; i++) {
        if (dstBuffer[i] != sg) {
	  mismatch++;
	  if (max_error-- > 0)
	    fprintf(stderr, "testmemwrite: [%d] actual %08x expected %08x\n", i, dstBuffer[i], sg);
        }
        sg++;
      }
      platformStatistics();
      fprintf(stderr, "testmemwrite: mismatch count %d.\n", mismatch);
      burstLen *= 2;
      if (mismatch)
	exit(mismatch);

      // now try with larger burstLen
      burstLen *= 2;
    }
}
