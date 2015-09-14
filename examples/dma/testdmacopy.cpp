/* Copyright (c) 2015 Connectal Project
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

#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "dmaManager.h"
#include "DmaIndication.h"
#include "DmaRequest.h"

class DmaIndication : public DmaIndicationWrapper
{
    sem_t sem;
public:
    DmaIndication(unsigned int id) : DmaIndicationWrapper(id){
	sem_init(&sem, 0, 0);
    }

    void readDone ( uint32_t sglId, uint32_t base, const uint8_t tag ) {
    fprintf(stderr, "[%s:%d] sglId=%d base=%08x tag=%d\n", __FUNCTION__, __LINE__, sglId, base, tag);
	sem_post(&sem);
    }
    void writeDone ( uint32_t sglId, uint32_t base, uint8_t tag ) {
    fprintf(stderr, "[%s:%d] sglId=%d base=%08x tag=%d\n", __FUNCTION__, __LINE__, sglId, base, tag);
	sem_post(&sem);
    }
    void wait() {
	sem_wait(&sem);
    }
};

DmaManager *dma;
DmaIndication *dmaIndication;
DmaRequestProxy *dmaRequest;

int main(int argc, const char **argv)
{
    fprintf(stderr, "[%s:%d] calling platformInit\n", __FUNCTION__, __LINE__);
    dma = platformInit();
    fprintf(stderr, "[%s:%d] creating proxy and wrapper\n", __FUNCTION__, __LINE__);
    dmaRequest    = new DmaRequestProxy(IfcNames_DmaRequestS2H);
    dmaIndication = new DmaIndication(IfcNames_DmaIndicationH2S);

    fprintf(stderr, "[%s:%d] allocating buffers\n", __FUNCTION__, __LINE__);
    int srcAlloc = portalAlloc(8192, 0);
    int dstAlloc = portalAlloc(8192, 0);
    int srcRef = dma->reference(srcAlloc);
    int dstRef = dma->reference(dstAlloc);

    fprintf(stderr, "[%s:%d] requesting first dma\n", __FUNCTION__, __LINE__);
    dmaRequest->read(srcRef, 0, 4096, 0);
    dmaRequest->write(dstRef, 0, 4096, 1);
    fprintf(stderr, "[%s:%d] requesting second dma\n", __FUNCTION__, __LINE__);
    dmaRequest->read(srcRef, 4096, 4096, 2);
    dmaRequest->write(dstRef, 4096, 4096, 3);
    fprintf(stderr, "[%s:%d] waiting for responses\n", __FUNCTION__, __LINE__);
    dmaIndication->wait();
    dmaIndication->wait();
    dmaIndication->wait();
    dmaIndication->wait();
    return 0;
}
