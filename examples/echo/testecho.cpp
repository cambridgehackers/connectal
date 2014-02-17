
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>

#include "EchoIndicationWrapper.h"
#include "EchoRequestProxy.h"
#include "GeneratedTypes.h"
#include "SwallowProxy.h"

#define LOOP_COUNT 1000
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

static void *pthread_worker(void *ptr)
{
    void *rc = NULL;
    while (CHECKSEM(sem_heard2) && !rc)
        rc = portalExec_event(portalExec_timeout);
    return rc;
}
static void init_thread()
{
#ifdef SEPARATE_EVENT_THREAD
    pthread_t threaddata;
    SEMINIT(&sem_heard2);
    pthread_create(&threaddata, NULL, &pthread_worker, NULL);
#endif
}

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(unsigned long v) {
        fprintf(stderr, "heard an echo: %ld\n", v);
	echoRequestProxy->say2(v, 2*v);
    }
    virtual void heard2(unsigned long a, unsigned long b) {
        catch_timer(20);
        SEMPOST(&sem_heard2);
        //fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
        //catch_timer(25);
    }
    EchoIndication(unsigned int id) : EchoIndicationWrapper(id) {
    }
};

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    start_timer(0);
    PREPAREWAIT(sem_heard2);
    echoRequestProxy->say(v);
    SEMWAIT(&sem_heard2);
    printf("call_say: elapsed %lld\n", lap_timer(0));
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
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication);
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);

    portalExec_init();
    init_thread();

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    printf("[%s:%d] run %d loops\n\n", __FUNCTION__, __LINE__, LOOP_COUNT);
    init_timer();
    start_timer(1);
    for (int i = 0; i < LOOP_COUNT; i++)
        call_say2(v, v*3);
unsigned long long elapsed = lap_timer(1);
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
    printf("call_say: elapsed %lld average %lld\n", elapsed, elapsed/LOOP_COUNT);
    echoRequestProxy->setLeds(9);
    print_dbg_requeste_intervals();
    portalExec_end();
    return 0;
}
