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

#include "BscanIndication.h"
#include "BscanRequest.h"
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
    portalExec_start();

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

    //print_dbg_requeste_intervals();
    poller->portalExec_end();
    return 0;
}
