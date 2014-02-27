// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.



#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

#include "PortalPerfIndicationWrapper.h"
#include "PortalPerfRequestProxy.h"
#include "GeneratedTypes.h"

#define DEBUG 1

#ifdef DEBUG
#define DEBUGWHERE() \
  fprintf(stderr, "at %s, %s:%d\n", __FUNCTION__, __FILE__, __LINE__)
#else
#define DEBUGWHERE()
#endif



#define LOOP_COUNT 5
#define SEPARATE_EVENT_THREAD
//#define USE_MUTEX_SYNC

PortalPerfRequestProxy *portalPerfRequestProxy = 0;

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

static SEM_TYPE sem_heard;

PortalPoller *poller = 0;

#ifdef SEPARATE_EVENT_THREAD

static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (CHECKSEM(sem_heard) && !rc && !poller->stopping)
        rc = poller->portalExec_event(poller->portalExec_timeout);
    return rc;
}
#endif

static void init_thread()
{
#ifdef SEPARATE_EVENT_THREAD
    pthread_t threaddata;
    SEMINIT(&sem_heard);
    pthread_create(&threaddata, NULL, &pthread_worker, (void*)poller);
#endif
}

class PortalPerfIndication : public PortalPerfIndicationWrapper
{
public:
  virtual void spitl(uint32_t v1) {
	DEBUGWHERE();
        catch_timer(20);
	SEMPOST(&sem_heard);
    }
  virtual void spitll(uint32_t v1, uint32_t v2) {
	DEBUGWHERE();
        catch_timer(20);
        SEMPOST(&sem_heard);
    }
  virtual void spitlll(uint32_t v1, uint32_t v2, uint32_t v3) {
	DEBUGWHERE();
        catch_timer(20);
        SEMPOST(&sem_heard);
    }
  virtual void spitllll(uint32_t v1, uint32_t v2, uint32_t v3, uint32_t v4) {
	DEBUGWHERE();
        catch_timer(20);
        SEMPOST(&sem_heard);
    }
  virtual void spitd(uint64_t v1) {
	DEBUGWHERE();
        catch_timer(20);
        SEMPOST(&sem_heard);
    }
  virtual void spitdd(uint64_t v1, uint64_t v2) {
	DEBUGWHERE();
        catch_timer(20);
        SEMPOST(&sem_heard);
    }
  virtual void spitddd(uint64_t v1, uint64_t v2, uint64_t v3) {
	DEBUGWHERE();
        catch_timer(20);
        SEMPOST(&sem_heard);
    }
  virtual void spitdddd(uint64_t v1, uint64_t v2, uint64_t v3, uint64_t v4) {
	DEBUGWHERE();
        catch_timer(20);
        SEMPOST(&sem_heard);
    }
    PortalPerfIndication(unsigned int id, PortalPoller *poller) : PortalPerfIndicationWrapper(id, poller) {}
};

uint32_t vl1, vl2, vl3, vl4;
uint64_t vd1, vd2, vd3, vd4;

void call_swallowl(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowl(vl1);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_swallowll(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowll(vl1, vl2);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_swallowlll(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowlll(vl1, vl2, vl3);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_swallowllll(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowllll(vl1, vl2, vl3, vl4);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_swallowd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowd(vd1);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_swallowdd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowdd(vd1, vd2);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_swallowddd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowddd(vd1, vd2, vd3);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_swallowdddd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->swallowdddd(vd1, vd2, vd3, vd4);
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitl(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitl();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitll(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitll();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitlll(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitlll();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitllll(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitllll();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitd();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitdd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitdd();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitddd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitddd();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void call_dospitdddd(void)
{
  DEBUGWHERE();
    start_timer(0);
    PREPAREWAIT(sem_heard);
    catch_timer(0);
    portalPerfRequestProxy->dospitdddd();
    catch_timer(19);
    SEMWAIT(&sem_heard);
    catch_timer(30);
}

void dotest(const char *testname, void (*testfn)(void))
{
  uint64_t elapsed;
  init_timer();
  start_timer(1);
  for (int i = 0; i < LOOP_COUNT; i++) {
    testfn();
  }
  elapsed = lap_timer(1);
  printf("test %s: elapsed %g average %g\n", testname, (double) elapsed, (double) elapsed/ (double) LOOP_COUNT);
  print_timer(LOOP_COUNT);
}


int main(int argc, const char **argv)
{
    poller = new PortalPoller();
    PortalPerfIndication *portalPerfIndication = new PortalPerfIndication(IfcNames_PortalPerfIndication, poller);
    // these use the default poller
    portalPerfRequestProxy = new PortalPerfRequestProxy(IfcNames_PortalPerfRequest);

    poller->portalExec_init();
    init_thread();
    portalExec_start();


    printf("Timer tests\n");
    init_timer();
    for (int i = 0; i < 1000; i++) {
      start_timer(0);
      catch_timer(1);
      catch_timer(2);
      catch_timer(3);
      catch_timer(4);
      catch_timer(5);
      catch_timer(6);
      catch_timer(7);
      catch_timer(8);
    }
    printf("Each line 1-8 is one more call to catch_timer()\n");
    print_timer(1000);



    printf("TEST TYPE: "
#ifndef SEPARATE_EVENT_THREAD
       "INLINE"
#elif defined(USE_MUTEX_SYNC)
       "MUTEX"
#else
       "SEM"
#endif
       "\n");

    dotest("swallowl", call_swallowl);
    dotest("swallowll", call_swallowll);
    dotest("swallowlll", call_swallowlll);
    dotest("swallowllll", call_swallowllll);
    dotest("swallowd", call_swallowd);
    dotest("swallowdd", call_swallowdd);
    dotest("swallowddd", call_swallowddd);
    dotest("swallowdddd", call_swallowdddd);
    dotest("spitl", call_dospitl);
    dotest("spitll", call_dospitll);
    dotest("spitlll", call_dospitlll);
    dotest("spitllll", call_dospitllll);
    dotest("spitd", call_dospitd);
    dotest("spitdd", call_dospitdd);
    dotest("spitddd", call_dospitddd);
    dotest("spitdddd", call_dospitdddd);

    poller->portalExec_end();
    portalExec_end();
    return 0;
}
