
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

#include "EchoIndicationWrapper.h"
#include "EchoRequestProxy.h"
#include "GeneratedTypes.h"
#include "SwallowProxy.h"

#define LOOP_COUNT 5 //1000
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
    while (CHECKSEM(sem_heard2) && !rc && !poller->stopping)
        rc = poller->portalExec_event(poller->portalExec_timeout);
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
    virtual void heard2(uint32_t a, uint32_t b) {
        catch_timer(20);
        SEMPOST(&sem_heard2);
        //fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
        //catch_timer(25);
    }
    EchoIndication(unsigned int id, PortalPoller *poller) : EchoIndicationWrapper(id, poller) {}
};

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    start_timer(0);
    PREPAREWAIT(sem_heard2);
    echoRequestProxy->say(v);
    SEMWAIT(&sem_heard2);
    printf("call_say: elapsed %zd\n", lap_timer(0));
}

static void call_say2(int v, int v2)
{
    start_timer(0);
    PREPAREWAIT(sem_heard2);
    catch_timer(0);
    echoRequestProxy->say2(v, v2);
    catch_timer(19);
    SEMWAIT(&sem_heard2);
    catch_timer(30);
}

int main(int argc, const char **argv)
{
    poller = new PortalPoller();
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication, poller);
    // these use the default poller
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);

    poller->portalExec_init();
    init_thread();
    portalExec_start();

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    printf("[%s:%d] run %d loops\n\n", __FUNCTION__, __LINE__, LOOP_COUNT);
    init_timer();
    start_timer(1);
printf("[%s:%d] sleep2\n", __FUNCTION__, __LINE__); sleep(2);
    for (int i = 0; i < LOOP_COUNT; i++)
        call_say2(v, v*3);
uint64_t elapsed = lap_timer(1);
    printf("TEST TYPE: "
#ifndef SEPARATE_EVENT_THREAD
       "INLINE"
#elif defined(USE_MUTEX_SYNC)
       "MUTEX"
#else
       "SEM"
#endif
       "\n");
    print_timer(LOOP_COUNT);
    printf("call_say: elapsed %zd average %zd\n", elapsed, elapsed/LOOP_COUNT);
    echoRequestProxy->setLeds(9);
    poller->portalExec_end();
    portalExec_end();
    return 0;
}
