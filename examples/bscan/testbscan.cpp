
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>

#include "BscanIndicationWrapper.h"
#include "BscanRequestProxy.h"
#include "GeneratedTypes.h"

#define LOOP_COUNT 1000
#define SEPARATE_EVENT_THREAD
//#define USE_MUTEX_SYNC

BscanRequestProxy *bscanRequestProxy = 0;

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

static SEM_TYPE sem_bscan;

PortalPoller *poller = 0;

static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (CHECKSEM(sem_bscan) && !rc)
        rc = poller->portalExec_event(poller->portalExec_timeout);
    return rc;
}
static void init_thread()
{
#ifdef SEPARATE_EVENT_THREAD
    pthread_t threaddata;
    SEMINIT(&sem_bscan);
    pthread_create(&threaddata, NULL, &pthread_worker, (void*)poller);
#endif
}

class BscanIndication : public BscanIndicationWrapper
{
public:
    virtual void bscanGet(unsigned long v) {
        fprintf(stderr, "bscanGet: %lx\n", v);
    }
    BscanIndication(unsigned int id, PortalPoller *poller) : BscanIndicationWrapper(id, poller) {
    }
};

static void bscanPut(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    start_timer(0);
    PREPAREWAIT(sem_bscan);
    bscanRequestProxy->bscanPut(v);
    SEMWAIT(&sem_bscan);
    printf("bscanPut: elapsed %lld\n", lap_timer(0));
}

int main(int argc, const char **argv)
{
    poller = new PortalPoller();
    BscanIndication *bscanIndication = new BscanIndication(IfcNames_BscanIndication, poller);
    // these use the default poller
    bscanRequestProxy = new BscanRequestProxy(IfcNames_BscanRequest);

    poller->portalExec_init();
    init_thread();
    pthread_t tid;
    if(pthread_create(&tid, NULL,  portalExec, NULL)){
	fprintf(stderr, "error creating default exec thread\n");
	exit(1);
    }

    int v = 42;
    fprintf(stderr, "Bscan put %x\n", v);
    bscanPut(v);
    //print_dbg_requeste_intervals();
    poller->portalExec_end();
    return 0;
}
