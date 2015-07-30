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
#include <unistd.h>
#include <pthread.h>
#include <string.h>

#include "IpcTestIndication.h"
#include "IpcTestRequest.h"
#include "GeneratedTypes.h"
#include <sys/ioctl.h>
#include "drivers/zynqportal/zynqportal.h"
#include <errno.h>

#define LOOP_COUNT 5

IpcTestRequestProxy *ipcTestRequestProxy = 0;

static int silent;
static int flag_heard;
static sem_t sem_heard;
static pthread_mutex_t mutex_heard;

PortalPoller *poller = 0;
static int use_mutex = 0;
static int use_inline = 0;
pthread_t threaddata;

class IpcTestIndication : public IpcTestIndicationWrapper
{
public:
    virtual void heard(uint32_t v) {
        if (!silent)
            fprintf(stderr, "heard an ipcTest: %d\n", v);
        flag_heard++;
        if (use_mutex)
            pthread_mutex_unlock(&mutex_heard);
        else
            sem_post(&sem_heard);
    }
    virtual void heard2(uint16_t v1, uint16_t v2) {}
    IpcTestIndication(unsigned int id, PortalPoller *poller) : IpcTestIndicationWrapper(id, poller) {}
};

static void run_test(void)
{
#define PCYC_LEN 20
  int i;
  uint64_t pcyc[PCYC_LEN];
  uint64_t lastp = 0;

  memset(pcyc, 0, sizeof(pcyc));
  pcyc[0] = portalCycleCount();
  flag_heard = 0;
  pcyc[3] = portalCycleCount();
    ipcTestRequestProxy->say(22);
  pcyc[8] = portalCycleCount();
  if (use_inline) {
    while (!flag_heard) {
        poller->event();
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
  if (ipcTestRequestProxy->pint.fpga_fd >= 0) {
      PortalInterruptTime inttime;
      ioctl(ipcTestRequestProxy->pint.fpga_fd, PORTAL_INTERRUPT_TIME, &inttime);
      pcyc[9] = (((uint64_t)inttime.msb)<<32) | ((uint64_t)inttime.lsb);
  }
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
    IpcTestIndication ipcTestIndication(IfcNames_IpcTestIndicationH2S, poller);
    ipcTestRequestProxy = new IpcTestRequestProxy(IfcNames_IpcTestRequestS2H);
    pthread_mutex_lock(&mutex_heard);
    sem_init(&sem_heard, 0, 0);

    poller->start();

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
    printf("disable interrupts for ipcTestIndication\n");
    poller->stop();
    printf("now try inline\n");
    use_inline = 1;
    for (i = 0; i < LOOP_COUNT; i++)
        run_test();
printf("[%s:%d] end\n", __FUNCTION__, __LINE__);
    return 0;
}
