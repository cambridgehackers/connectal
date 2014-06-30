
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "BscanIndicationWrapper.h"
#include "BscanRequestProxy.h"
#include "GeneratedTypes.h"

#define LOOP_COUNT 1000

BscanRequestProxy *bscanRequestProxy = 0;

typedef sem_t SEM_TYPE;
#define SEMINIT(A) sem_init(A, 0, 0);
#define SEMWAIT(A) sem_wait(A);
#define SEMPOST(A) sem_post(A)

static SEM_TYPE sem_bscan;

PortalPoller *poller = 0;

static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (!rc) {
        rc = poller->portalExec_poll(poller->portalExec_timeout);
        if ((long) rc >= 0)
            rc = poller->portalExec_event();
    }
    return rc;
}
static void init_thread()
{
    pthread_t threaddata;
    SEMINIT(&sem_bscan);
    pthread_create(&threaddata, NULL, &pthread_worker, (void*)poller);
}

class BscanIndication : public BscanIndicationWrapper
{
public:
    virtual void bscanGet(uint64_t v) {
        printf("bscanGet: %"PRIx64"\n", v);
        SEMPOST(&sem_bscan);
    }
    virtual void bscanGetValue(uint32_t v) {
        printf("bscanGetValue: 0x%x\n", v);
        SEMPOST(&sem_bscan);
    }
    BscanIndication(unsigned int id, PortalPoller *poller) : BscanIndicationWrapper(id, poller) {
    }
};

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

    if (argc == 1) {
    int v = 42;
    printf("Bscan put %x\n", v);
    for (int i = 0; i < 255; i++)
      bscanRequestProxy->bscanPut(i, i*v);
    }
    else if (argc == 2) {
      bscanRequestProxy->bscanGet(atoll(argv[1]));
      SEMWAIT(&sem_bscan);
    }
    else if (argc == 3)
      bscanRequestProxy->bscanPut(atoll(argv[1]), atoll(argv[2]));
    else if (argc == 4) {
      printf("testbscan: get address: ");
      bscanRequestProxy->bscanGetA();
      SEMWAIT(&sem_bscan);
      printf("testbscan: get select: ");
      bscanRequestProxy->bscanGetS();
      SEMWAIT(&sem_bscan);
      printf("testbscan: get width: ");
      bscanRequestProxy->bscanGetW();
      SEMWAIT(&sem_bscan);
    }

    //print_dbg_requeste_intervals();
    poller->portalExec_end();
    return 0;
}
