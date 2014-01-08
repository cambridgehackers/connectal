
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>

#include "EchoIndicationWrapper.h"
#include "EchoRequestProxy.h"
#include "GeneratedTypes.h"
#include "SwallowProxy.h"

EchoRequestProxy *echoRequestProxy = 0;

#define DECL(A) \
    static sem_t sem_ ## A; \
    static unsigned long cv_ ## A;

DECL(heard2)


static void init_local_semaphores(void)
{
    sem_init(&sem_heard2, 0, 0);
}

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(unsigned long v) {
        fprintf(stderr, "heard an echo: %ld\n", v);
	echoRequestProxy->say2(v, 2*v);
    }
    virtual void heard2(unsigned long a, unsigned long b) {
      fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
      sem_post(&sem_heard2);
      //exit(0);
    }
  EchoIndication(unsigned int id) : EchoIndicationWrapper(id){}
};
static void *pthread_worker(void *ptr)
{
    portalExec(NULL);
    return NULL;
}

static void call_say(int v)
{
printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    echoRequestProxy->say(v);
    sem_wait(&sem_heard2);
}

static void call_say2(int v, int v2)
{
printf("[%s:%d] %d, %d\n", __FUNCTION__, __LINE__, v, v2);
    echoRequestProxy->say2(v, v2);
    sem_wait(&sem_heard2);
}

EchoIndication *echoIndication = 0;
SwallowProxy *swallowProxy = 0;

int main(int argc, const char **argv)
{
    pthread_t threaddata;

    init_local_semaphores();

    echoIndication = new EchoIndication(IfcNames_EchoIndication);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);
    swallowProxy = new SwallowProxy(IfcNames_Swallow);

    pthread_create(&threaddata, NULL, &pthread_worker, NULL);
    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    call_say2(v, v*3);
    echoRequestProxy->setLeds(9);
}
