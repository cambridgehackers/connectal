
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>

#include "EchoIndicationWrapper.h"
#include "EchoRequestProxy.h"
#include "GeneratedTypes.h"
#include "SwallowProxy.h"

#define SEPARATE_EVENT_THREAD
//#define USE_MUTEX_SYNC

EchoRequestProxy *echoRequestProxy = 0;

#ifdef SEPARATE_EVENT_THREAD
#ifdef USE_MUTEX_SYNC
static pthread_mutex_t sem_heard2 = PTHREAD_MUTEX_INITIALIZER;
#define SEMINIT(A) 
#define SEMWAIT(A) pthread_mutex_lock(&A);
#define SEMPOST(A) pthread_mutex_unlock(&A);
#else
static sem_t sem_heard2;
#define SEMINIT(A) sem_init(&A, 0, 0);
#define SEMWAIT(A) sem_wait(&A);
#define SEMPOST(A) sem_post(&A)
#endif

static void *pthread_worker(void *ptr)
{
    void *rc = NULL;
    while (!rc)
        rc = portalExec_event(portalExec_timeout);
    return rc;
}
static void init_thread()
{
    pthread_t threaddata;
    SEMINIT(sem_heard2);
    pthread_create(&threaddata, NULL, &pthread_worker, NULL);
}
static void wait_heard(void)
{
    SEMWAIT(sem_heard2);
}
#else // inline waiting
static int sem_heard2;
#define SEMPOST(A) A++
static void init_thread()
{
}
static void wait_heard(void)
{
    void *rc = NULL;
    sem_heard2 = 0;
    while (!sem_heard2 && !rc)
        rc = portalExec_event(portalExec_timeout);
}
#endif

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(unsigned long v) {
        lap_timer(0);
        fprintf(stderr, "heard an echo: %ld\n", v);
	echoRequestProxy->say2(v, 2*v);
    }
    virtual void heard2(unsigned long a, unsigned long b) {
        lap_timer(0);
        SEMPOST(sem_heard2);
        fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
        lap_timer(0);
    }
    EchoIndication(unsigned int id) : EchoIndicationWrapper(id){
    }
};

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    start_timer(0);
    echoRequestProxy->say(v);
    wait_heard();
    printf("call_say: elapsed %lld\n", lap_timer(0));
}

static void call_say2(int v, int v2)
{
    printf("[%s:%d] %d, %d\n", __FUNCTION__, __LINE__, v, v2);
    start_timer(0);
    echoRequestProxy->say2(v, v2);
    wait_heard();
    printf("call_say: elapsed %lld\n", lap_timer(0));
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
    call_say2(v, v*3);
    echoRequestProxy->setLeds(9);
    return 0;
}
