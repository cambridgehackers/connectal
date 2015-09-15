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
  static int proxyNames[] = { IfcNames_DmaRequestS2H0, IfcNames_DmaRequestS2H1 };
  static int wrapperNames[] = { IfcNames_DmaIndicationH2S0, IfcNames_DmaIndicationH2S1 };
class Channel {
  DmaIndication *dmaIndication;
  DmaRequestProxy *dmaRequest;
  int channel;
  int srcAlloc;
  int dstAlloc;
  int srcRef;
  int dstRef;
  int size;
public:
  Channel(int channel) : channel(channel), size(1024*1024) {
    dmaRequest    = new DmaRequestProxy(proxyNames[channel]);
    dmaIndication = new DmaIndication(wrapperNames[channel]);
    fprintf(stderr, "[%s:%d] channel %d allocating buffers\n", __FUNCTION__, __LINE__, channel);
    srcAlloc = portalAlloc(size, 0);
    dstAlloc = portalAlloc(size, 0);
    srcRef = dma->reference(srcAlloc);
    dstRef = dma->reference(dstAlloc);
  }
  void run() {
    fprintf(stderr, "[%s:%d] channel %d requesting first dma\n", __FUNCTION__, __LINE__, channel);
    dmaRequest->read(srcRef, 0, size/2, 0);
    dmaRequest->write(dstRef, 0, size/2, 1);
    fprintf(stderr, "[%s:%d] channel %d requesting second dma\n", __FUNCTION__, __LINE__, channel);
    dmaRequest->read(srcRef, size/2, size/2, 2);
    dmaRequest->write(dstRef, size/2, size/2, 3);
    fprintf(stderr, "[%s:%d] channel %d waiting for responses\n", __FUNCTION__, __LINE__, channel);
    dmaIndication->wait();
    dmaIndication->wait();
    dmaIndication->wait();
    dmaIndication->wait();
  }
  static void *threadfn(void *c) {
    Channel *channelp = (Channel *)c;
    channelp->run();
    return 0;
  }
};



pthread_t threads[2];

int main(int argc, const char **argv)
{
    fprintf(stderr, "[%s:%d] calling platformInit\n", __FUNCTION__, __LINE__);
    dma = platformInit();
    fprintf(stderr, "[%s:%d] creating proxy and wrapper\n", __FUNCTION__, __LINE__);

    for (int i = 0; i < 2; i++) {
      Channel *channel = new Channel(i);
      pthread_create(&threads[i], 0, channel->threadfn, channel);
    }

    // wait for threads to exit
    for (int i = 0; i < 2; i++) {
      void *ret;
      pthread_join(threads[i], &ret);
      fprintf(stderr, "thread exited ret=%p\n", ret);
    }
    return 0;
}
