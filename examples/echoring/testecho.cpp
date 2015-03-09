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

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

#include "MMURequest.h"
#include "StdDmaIndication.h"
#include "dmaManager.h"

#include "EchoIndication.h"
#include "EchoRequest.h"
#include "SharedMemoryPortalConfig.h"
#include "GeneratedTypes.h"
#include "Swallow.h"

EchoRequestProxy *echoRequestProxy = 0;

static sem_t sem_heard2;

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(uint32_t v) {
        fprintf(stderr, "heard an echo: %d\n", v);
	echoRequestProxy->say2(v, 2*v);
    }
    virtual void heard2(uint16_t a, uint16_t b) {
        sem_post(&sem_heard2);
        //fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
    }
  EchoIndication(unsigned int id, PortalPoller *poller = 0) : EchoIndicationWrapper(id, poller) {}
};

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    echoRequestProxy->say(v);
    fprintf(stderr, "[%s:%d] waiting for echo\n", __FUNCTION__, __LINE__);
    sem_wait(&sem_heard2);
}

static void call_say2(int v, int v2)
{
    echoRequestProxy->say2(v, v2);
    sem_wait(&sem_heard2);
}

int allocateShared(DmaManager *dma, MMURequestProxy *dmap, uint32_t interfaceId, PortalInternal *p, uint32_t size)
{
    int fd = portalAlloc(size);
    fprintf(stderr, "%s:%d fd=%d\n", __FILE__, __LINE__, fd);
    p->map_base = (volatile unsigned int *)portalMmap(fd, size);
    fprintf(stderr, "%s:%d map_base=%p\n", __FILE__, __LINE__, p->map_base);
    p->map_base[SHARED_LIMIT] = size/sizeof(uint32_t);
    p->map_base[SHARED_WRITE] = SHARED_START;
    p->map_base[SHARED_READ] = SHARED_START;
    p->map_base[SHARED_START] = 0;
    fprintf(stderr, "allocateShared calling reference\n");
    unsigned int ref = dma->reference(fd);
    fprintf(stderr, "allocateShared ref=%d\n", ref);
    dmap->setInterface(interfaceId, ref);
    fprintf(stderr, "called setInterface\n");
    return fd;
}


int main(int argc, const char **argv)
{
    int alloc_sz = 1024*1024;
//1000;

    MMURequestProxy *dmap = new MMURequestProxy(IfcNames_MMURequest);
    DmaManager *dma = new DmaManager(dmap);
    MMUIndication *mIndication = new MMUIndication(dma, IfcNames_MMUIndication);

    SharedMemoryPortalConfigProxy *smpConfig = new SharedMemoryPortalConfigProxy(IfcNames_ConfigWrapper);
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication);
    // these use the default poller
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);

    portalExec_start();

    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest, &sharedfunc, NULL);
    int fd = allocateShared(dma, dmap, IfcNames_EchoRequest, &echoRequestProxy->pint, alloc_sz);
    unsigned int ref = dma->reference(fd);
    smpConfig->setSglId(ref);

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    call_say2(v, v*3);
    printf("TEST TYPE: SEM\n");
    echoRequestProxy->setLeds(9);
    portalExec_end();
    return 0;
}
