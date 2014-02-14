
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>

#include "EchoIndicationWrapper.h"
#include "EchoRequestProxy.h"
#include "GeneratedTypes.h"
#include "SwallowProxy.h"

#define SEPARATE_EVENT_THREAD

EchoRequestProxy *echoRequestProxy = 0;

#ifdef SEPARATE_EVENT_THREAD
static sem_t sem_heard2;

static void *pthread_worker(void *ptr)
{
    void *rc = NULL;
    while (!rc)
        rc = portalExec_event(portalExec_timeout);
    return rc;
}
#else
static int sem_heard2;
#endif

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(unsigned long v) {
        fprintf(stderr, "heard an echo: %ld\n", v);
	echoRequestProxy->say2(v, 2*v);
    }
    virtual void heard2(unsigned long a, unsigned long b) {
#ifdef SEPARATE_EVENT_THREAD
        sem_post(&sem_heard2);
#else
        sem_heard2++;
#endif
        fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
    }
    EchoIndication(unsigned int id) : EchoIndicationWrapper(id){
    }
};

static void wait_heard(void)
{
#ifdef SEPARATE_EVENT_THREAD
    sem_wait(&sem_heard2);
#else
    void *rc = NULL;
    sem_heard2 = 0;
    while (!sem_heard2 && !rc)
        rc = portalExec_event(portalExec_timeout);
#endif
}

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    start_timer(0);
    echoRequestProxy->say(v);
    wait_heard();
    printf("call_say: elapsed %lld\n", stop_timer(0));
}

static void call_say2(int v, int v2)
{
    printf("[%s:%d] %d, %d\n", __FUNCTION__, __LINE__, v, v2);
    start_timer(0);
    echoRequestProxy->say2(v, v2);
    wait_heard();
    printf("call_say: elapsed %lld\n", stop_timer(0));
}

int main(int argc, const char **argv)
{
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication);
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);

    portalExec_init();
#ifdef SEPARATE_EVENT_THREAD
    pthread_t threaddata;
    sem_init(&sem_heard2, 0, 0);
    pthread_create(&threaddata, NULL, &pthread_worker, NULL);
#endif

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
