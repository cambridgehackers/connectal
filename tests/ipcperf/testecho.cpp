
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <pthread.h>
#include <string.h>

#include "EchoIndication.h"
#include "EchoRequest.h"
#include "GeneratedTypes.h"
#include "Swallow.h"
#include <sys/ioctl.h>
#include "zynqportal.h"
#include <errno.h>

#define LOOP_COUNT 5
#define SEPARATE_EVENT_THREAD

EchoRequestProxy *echoRequestProxy = 0;

#ifdef SEPARATE_EVENT_THREAD
#define CHECKSEM(A) 1
#else // use inline sync
#define CHECKSEM(A) (!(A))
#endif

static int silent;
static int flag_heard;
static sem_t sem_heard;
static pthread_mutex_t mutex_heard;

PortalPoller *poller = 0;
static int use_mutex = 0;
static int use_inline = 0;
pthread_t threaddata;

static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (CHECKSEM(sem_heard) && !rc && !poller->stopping) {
        rc = poller->portalExec_poll(poller->portalExec_timeout);
        if ((long) rc >= 0)
            rc = poller->portalExec_event();
    }
    return rc;
}
class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(uint32_t v) {
        if (!silent)
            fprintf(stderr, "heard an echo: %d\n", v);
        flag_heard++;
        if (use_mutex)
            pthread_mutex_unlock(&mutex_heard);
        else
            sem_post(&sem_heard);
    }
    virtual void heard2(uint32_t v1, uint32_t v2) {}
    EchoIndication(unsigned int id, PortalPoller *poller) : EchoIndicationWrapper(id, poller) {}
};

static void run_test(void)
{
#define PCYC_LEN 20
  int i;
  uint64_t pcyc[PCYC_LEN];
  uint64_t lastp;
  PortalInterruptTime inttime;

  memset(pcyc, 0, sizeof(pcyc));
  pcyc[0] = portalCycleCount();
  flag_heard = 0;
  pcyc[3] = portalCycleCount();
    echoRequestProxy->say(22);
  pcyc[8] = portalCycleCount();
  if (use_inline) {
    while (!flag_heard) {
        //void *rc = poller->portalExec_poll(poller->portalExec_timeout);
        //if ((long) rc >= 0)
        poller->portalExec_event();
    }
    pcyc[9] = pcyc[8];
    pcyc[12] = pcyc[8];
    pcyc[17] = pcyc[8];
  }
  else {
  if (use_mutex)
    pthread_mutex_lock(&mutex_heard);
  else
    sem_wait(&sem_heard);
  ioctl(globalDirectory.fpga_fd, PORTAL_INTERRUPT_TIME, &inttime);
  pcyc[9] = (((uint64_t)inttime.msb)<<32) | ((uint64_t)inttime.lsb);
  pcyc[12] = poll_return_time; // time after poll() returns
  pcyc[17] = poll_enter_time; // time poll() reentered
  }
  pcyc[18] = portalCycleCount();
  for (i = 0; i < PCYC_LEN; i++)
      if (pcyc[i]) {
          if (i)
              printf("  %d:%5lld;", i, (long long)(pcyc[i] - lastp));
          lastp = pcyc[i];
      }
  printf("\n");
}

int main(int argc, const char **argv)
{
    int i;

    poller = new PortalPoller();
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication, poller);
    // these use the default poller
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);
    pthread_mutex_lock(&mutex_heard);
    sem_init(&sem_heard, 0, 0);

    poller->portalExec_init();
    pthread_create(&threaddata, NULL, &pthread_worker, (void*)poller);
    portalExec_start();
#ifdef ZYNQ
    uint64_t portcyc2 = portalCycleCount();
    unsigned int high_bits = ioctl(globalDirectory.fpga_fd, PORTAL_DIRECTORY_READ, ((unsigned long)PORTAL_DIRECTORY_COUNTER_MSB) - (unsigned long) &globalDirectory.map_base[0]);
    unsigned int low_bits = ioctl(globalDirectory.fpga_fd, PORTAL_DIRECTORY_READ, ((unsigned long)PORTAL_DIRECTORY_COUNTER_LSB) - (unsigned long) &globalDirectory.map_base[0]);
    uint64_t portcyc = portalCycleCount();
    printf("kernel crossing fpga cycles IN: %lld BACK: %lld\n", (long long)low_bits - portcyc2, (long long)portcyc - low_bits);
#endif

    run_test();
    printf("turn off printf in responder\n");
    silent = 1;
    for (i = 0; i < LOOP_COUNT; i++)
        run_test();
    printf("now try as mutex\n");
    use_mutex = 1;
    for (i = 0; i < LOOP_COUNT; i++)
        run_test();
    use_mutex = 0;

    struct sched_param sched_param;
    int sched_policy;
    pthread_getschedparam(pthread_self(), &sched_policy, &sched_param);
    sched_param.sched_priority = sched_get_priority_max(SCHED_RR);
    pthread_setschedparam(pthread_self(), SCHED_RR, &sched_param);
    printf("[%s:%d] scheduling policy changed to SCHED_RR\n", __FUNCTION__, __LINE__);
    for (i = 0; i < LOOP_COUNT; i++)
        run_test();
    printf("disable interrupts for echoIndication\n");
    poller->portalExec_stop();
    printf("now try inline\n");
    use_inline = 1;
    for (i = 0; i < LOOP_COUNT; i++)
        run_test();
printf("[%s:%d] end\n", __FUNCTION__, __LINE__);
    return 0;
}
