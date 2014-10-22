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

#include "EchoIndicationWrapper.h"
#include "EchoRequestProxy.h"
#include "GeneratedTypes.h"
#include "SwallowProxy.h"

#include "SRequestWrapper.h"
#include "SIndicationProxy.h"

EchoRequestProxy *echoRequestProxy;
SIndicationProxy *sIndicationProxy;

static sem_t sem_heard2;

PortalPoller *poller = 0;

static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (!rc && !poller->stopping) {
        rc = poller->portalExec_poll(poller->portalExec_timeout);
        if ((long) rc >= 0)
            rc = poller->portalExec_event();
    }
    return rc;
}
static void init_thread()
{
    pthread_t threaddata;
    sem_init(&sem_heard2, 0, 0);
    pthread_create(&threaddata, NULL, &pthread_worker, (void*)poller);
}

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(uint32_t v) {
        fprintf(stderr, "heard an echo: %d\n", v);
	echoRequestProxy->say2(v, 2*v);
    }
    virtual void heard2(uint32_t a, uint32_t b) {
        sem_post(&sem_heard2);
        //fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
    }
    EchoIndication(unsigned int id, PortalPoller *poller) : EchoIndicationWrapper(id, poller) {}
};

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    echoRequestProxy->say(v);
    sem_wait(&sem_heard2);
}

static void call_say2(int v, int v2)
{
    echoRequestProxy->say2(v, v2);
    sem_wait(&sem_heard2);
}

class SRequest : public SRequestWrapper
{
public:
    void say ( const uint32_t v ) {
        fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    }
    void say2 ( const uint32_t a, const uint32_t b ) {
        fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    }
    void setLeds ( const uint32_t v ) {
        fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    }
    SRequest(unsigned int id, PortalPoller *poller) : SRequestWrapper(id, poller) {}
};

int main(int argc, const char **argv)
{
    poller = new PortalPoller();
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication, poller);
    // these use the default poller
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);
    sIndicationProxy = new SIndicationProxy(IfcNames_SIndication);
    SRequest *sRequest = new SRequest(IfcNames_SRequest, poller);

    poller->portalExec_init();
    init_thread();
    portalExec_start();

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    portalTimerInit();
    call_say2(v, v*3);
    printf("TEST TYPE: SEM\n");
    echoRequestProxy->setLeds(9);
    poller->portalExec_end();
    portalExec_end();
    return 0;
}
