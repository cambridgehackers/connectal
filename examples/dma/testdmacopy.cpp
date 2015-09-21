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

class DmaIndication;
DmaManager *dma;
static int proxyNames[] = { IfcNames_DmaRequestS2H0, IfcNames_DmaRequestS2H1 };
static int wrapperNames[] = { IfcNames_DmaIndicationH2S0, IfcNames_DmaIndicationH2S1 };

pthread_t threads[2];

class Channel {
  PortalPoller *poller;
  DmaIndication *dmaIndication;
  DmaRequestProxy *dmaRequest;
  int channel;
  int srcfd;
  int dstfd;
  char *srcbuffer;
  char *dstbuffer;
  int srcRef;
  int dstRef;
  int size;
  volatile int waitCount;
public:
    Channel(int channel);
    void run();
    void post() { waitCount--; }
    static void *threadfn(void *c);
};

class DmaIndication : public DmaIndicationWrapper
{
    Channel *channel;
    sem_t sem;
public:
    DmaIndication(unsigned int id, PortalPoller *poller = 0, Channel *channel = 0)
	: DmaIndicationWrapper(id, poller), channel(channel) {
	sem_init(&sem, 0, 0);
    }

    void readDone ( uint32_t sglId, uint32_t base, const uint8_t tag ) {
    fprintf(stderr, "[%s:%d] sglId=%d base=%08x tag=%d\n", __FUNCTION__, __LINE__, sglId, base, tag);
	sem_post(&sem);
	if (channel)
	    channel->post();
    }
    void writeDone ( uint32_t sglId, uint32_t base, uint8_t tag ) {
    fprintf(stderr, "[%s:%d] sglId=%d base=%08x tag=%d\n", __FUNCTION__, __LINE__, sglId, base, tag);
	sem_post(&sem);
	if (channel)
	    channel->post();
    }
    void wait() {
	sem_wait(&sem);
    }
};

Channel::Channel(int channel)
  : poller(new PortalPoller(0)), channel(channel), size(1024*1024), waitCount(0)
{
    dmaRequest    = new DmaRequestProxy(proxyNames[channel], poller);
    dmaIndication = new DmaIndication(wrapperNames[channel], poller, this);
    fprintf(stderr, "[%s:%d] channel %d allocating buffers\n", __FUNCTION__, __LINE__, channel);
    srcfd = portalAlloc(size, 0);
    dstfd = portalAlloc(size, 0);
    srcbuffer = (char *)portalMmap(srcfd, size);
    dstbuffer = (char *)portalMmap(dstfd, size);
    srcRef = dma->reference(srcfd);
    dstRef = dma->reference(dstfd);
  }

void Channel::run()
{
    fprintf(stderr, "[%s:%d] channel %d requesting first dma\n", __FUNCTION__, __LINE__, channel);
    dmaRequest->read(srcRef, 0, size/2, 0);
    waitCount++;

    dmaRequest->write(dstRef, 0, size/2, 1);
    waitCount++;

    fprintf(stderr, "[%s:%d] channel %d requesting second dma\n", __FUNCTION__, __LINE__, channel);
    dmaRequest->read(srcRef, size/2, size/2, 2);
    waitCount++;

    dmaRequest->write(dstRef, size/2, size/2, 3);
    waitCount++;

    fprintf(stderr, "[%s:%d] channel %d waiting for responses\n", __FUNCTION__, __LINE__, channel);
    // poll
    while (waitCount > 0) {
	poller->event();
    }
}

void *Channel::threadfn(void *c)
{
    Channel *channelp = (Channel *)c;
    channelp->run();
    return 0;
}

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
