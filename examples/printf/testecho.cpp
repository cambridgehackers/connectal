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

#include "EchoIndication.h"
#include "DisplayInd.h"
#include "EchoRequest.h"
#include "GeneratedTypes.h"
#include "Swallow.h"

#define LOOP_COUNT 1//000
#define SEPARATE_EVENT_THREAD
//#define USE_MUTEX_SYNC

EchoRequestProxy *echoRequestProxy = 0;

#ifndef SEPARATE_EVENT_THREAD
typedef int SEM_TYPE;
#define SEMPOST(A) (*(A))++
#define SEMWAIT pthread_worker
#elif defined(USE_MUTEX_SYNC)
typedef pthread_mutex_t SEM_TYPE;
#define SEMINIT(A) pthread_mutex_lock(A);
#define SEMWAIT(A) pthread_mutex_lock(A);
#define SEMPOST(A) pthread_mutex_unlock(A);
#else // use semaphores
typedef sem_t SEM_TYPE;
#define SEMINIT(A) sem_init(A, 0, 0);
#define SEMWAIT(A) sem_wait(A);
#define SEMPOST(A) sem_post(A)
#endif

#ifdef SEPARATE_EVENT_THREAD
#define PREPAREWAIT(A)
#define CHECKSEM(A) 1
#else // use inline sync
#define PREPAREWAIT(A) (A) = 0
#define CHECKSEM(A) (!(A))
#endif

static SEM_TYPE sem_heard2;

PortalPoller *poller = 0;

static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (CHECKSEM(sem_heard2) && !rc && !poller->stopping) {
        rc = poller->pollFn(poller->timeout);
        if ((long)rc >= 0)
            rc = poller->event();
    }
    return rc;
}
static void init_thread()
{
#ifdef SEPARATE_EVENT_THREAD
    pthread_t threaddata;
    SEMINIT(&sem_heard2);
    pthread_create(&threaddata, NULL, &pthread_worker, (void*)poller);
#endif
}

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(uint32_t v) {
        fprintf(stderr, "heard an echo: %d\n", v);
	echoRequestProxy->say2(v, 2*v);
    }
    virtual void heard2(uint16_t a, uint16_t b) {
        portalTimerCatch(20);
        SEMPOST(&sem_heard2);
        //fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
        //portalTimerCatch(25);
    }
    EchoIndication(unsigned int id, PortalPoller *poller) : EchoIndicationWrapper(id, poller) {}
};

#include "printfInd.h"

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    portalTimerStart(0);
    PREPAREWAIT(sem_heard2);
    echoRequestProxy->say(v);
    SEMWAIT(&sem_heard2);
    printf("call_say: elapsed %" PRIu64 "\n", portalTimerLap(0));
}

static void call_say2(int v, int v2)
{
    portalTimerStart(0);
    PREPAREWAIT(sem_heard2);
    portalTimerCatch(0);
    echoRequestProxy->say2(v, v2);
    portalTimerCatch(19);
    SEMWAIT(&sem_heard2);
    portalTimerCatch(30);
}

int main(int argc, const char **argv)
{
    poller = new PortalPoller();
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication, poller);
    DisplayInd *dispIndication = new DisplayInd(IfcNames_DisplayInd, poller);
    // these use the default poller
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);

    poller->init();
    init_thread();

#if 0
    printf("Timer tests\n");
    portalTimerInit();
    for (int i = 0; i < 1000; i++) {
      portalTimerStart(0);
      portalTimerCatch(1);
      portalTimerCatch(2);
      portalTimerCatch(3);
      portalTimerCatch(4);
      portalTimerCatch(5);
      portalTimerCatch(6);
      portalTimerCatch(7);
      portalTimerCatch(8);
    }
    portalTimerPrint(1000);
#endif

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    printf("[%s:%d] run %d loops\n\n", __FUNCTION__, __LINE__, LOOP_COUNT);
    portalTimerInit();
    portalTimerStart(1);
    for (int i = 0; i < LOOP_COUNT; i++)
        call_say2(v, v*3);
uint64_t elapsed = portalTimerLap(1);
    printf("TEST TYPE: "
#ifndef SEPARATE_EVENT_THREAD
       "INLINE"
#elif defined(USE_MUTEX_SYNC)
       "MUTEX"
#else
       "SEM"
#endif
       "\n");
    portalTimerPrint(LOOP_COUNT);
    printf("call_say: elapsed %g average %g\n", (double) elapsed, (double) elapsed/ (double) LOOP_COUNT);
    echoRequestProxy->setLeds(9);
    return 0;
}
