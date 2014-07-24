
// Copyright (c) 2012 Nokia, Inc.
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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

#include <string.h>
#include <poll.h>
#include <errno.h>
#include <pthread.h>

#include "portal.h"

#ifdef ZYNQ
#include <android/log.h>
#endif

#define USE_INTERRUPTS
#ifdef USE_INTERRUPTS
#define ENABLE_INTERRUPTS(A) WRITEL((A), &((A)->map_base[IND_REG_INTERRUPT_MASK]), 1)
#else
#define ENABLE_INTERRUPTS(A)
#endif

#ifdef ZYNQ
#define ALOGD(fmt, ...) __android_log_print(ANDROID_LOG_DEBUG, "PORTAL", fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "PORTAL", fmt, __VA_ARGS__)
#else
#define ALOGD(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#endif

#ifndef NO_CPP_PORTAL_CODE
PortalPoller *defaultPoller = new PortalPoller();

PortalPoller::PortalPoller()
  : portal_wrappers(0), portal_fds(0), numFds(0), stopping(0)
{
    sem_init(&sem_startup, 0, 0);
}

int PortalPoller::unregisterInstance(Portal *portal)
{
  int i = 0;
  while(i < numFds)
    if(portal_fds[i].fd == portal->pint.fpga_fd)
      break;
    else
      i++;

  while(i < numFds-1){
    portal_fds[i] = portal_fds[i+1];
    portal_wrappers[i] = portal_wrappers[i+1];
  }

  numFds--;
  portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
  portal_wrappers = (Portal **)realloc(portal_wrappers, numFds*sizeof(Portal *));  
  return 0;
}

int PortalPoller::registerInstance(Portal *portal)
{
    numFds++;
    portal_wrappers = (Portal **)realloc(portal_wrappers, numFds*sizeof(Portal *));
    portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
    portal_wrappers[numFds-1] = portal;
    struct pollfd *pollfd = &portal_fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = portal->pint.fpga_fd;
    pollfd->events = POLLIN;
    fprintf(stderr, "Portal::registerInstance fpga%d\n", portal->pint.fpga_number);
    return 0;
}

void* PortalPoller::portalExec_init(void)
{
#ifdef USE_INTERRUPTS
    portalExec_timeout = -1; // no interrupt timeout 
#else
    portalExec_timeout = 100;
#endif
    if (!numFds) {
        ALOGE("portalExec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
    for (int i = 0; i < numFds; i++) {
      Portal *instance = portal_wrappers[i];
      //fprintf(stderr, "portalExec::enabling interrupts portal %d fpga%d\n", i, instance->pint.fpga_number);
      ENABLE_INTERRUPTS(&instance->pint);
    }
    fprintf(stderr, "portalExec::about to enter loop, numFds=%d\n", numFds);
    return NULL;
}
void PortalPoller::portalExec_end(void)
{
    stopping = 1;
    for (int i = 0; i < numFds; i++) {
      Portal *instance = portal_wrappers[i];
      fprintf(stderr, "portalExec::disabling interrupts portal %d fpga%d\n", i, instance->pint.fpga_number);
      WRITEL(&instance->pint, &(instance->pint.map_base)[IND_REG_INTERRUPT_MASK], 0);
    }
}

void* PortalPoller::portalExec_poll(int timeout)
{
    long rc = 0;
#ifdef MMAP_HW
    // LCS bypass the call to poll if the timeout is 0
    if (timeout != 0)
      rc = poll(portal_fds, numFds, timeout);
#endif
    if(rc < 0) {
	// return only in error case
	fprintf(stderr, "poll returned rc=%ld errno=%d:%s\n", rc, errno, strerror(errno));
    }
    return (void*)rc;
}

void* PortalPoller::portalExec_event(void)
{
    int mcnt = 0;
    for (int i = 0; i < numFds; i++) {
      if (!portal_wrappers) {
        fprintf(stderr, "No portal_instances revents=%d\n", portal_fds[i].revents);
      }
      Portal *instance = portal_wrappers[i];
      volatile unsigned int *map_base = instance->pint.map_base;
    
      // sanity check, to see the status of interrupt source and enable
      unsigned int queue_status;
    
      // handle all messasges from this portal instance
      while ((queue_status= READL(&instance->pint, &map_base[IND_REG_QUEUE_STATUS]))) {
        if(0) {
          unsigned int int_src = READL(&instance->pint, &map_base[IND_REG_INTERRUPT_FLAG]);
          unsigned int int_en  = READL(&instance->pint, &map_base[IND_REG_INTERRUPT_MASK]);
          unsigned int ind_count  = READL(&instance->pint, &map_base[IND_REG_INTERRUPT_COUNT]);
          fprintf(stderr, "(%d:fpga%d) about to receive messages int=%08x en=%08x qs=%08x cnt=%x\n", i, instance->pint.fpga_number, int_src, int_en, queue_status, ind_count);
        }
        instance->pint.handler(&instance->pint, queue_status-1);
	mcnt++;
      }
      // re-enable interrupt which was disabled by portal_isr
      ENABLE_INTERRUPTS(&instance->pint);
    }
    //if(timeout == -1 && !mcnt)
    //  fprintf(stderr, "poll returned even though no messages were detected\n");
    return NULL;
}

void* PortalPoller::portalExec(void* __x)
{
    void *rc = portalExec_init();
    sem_post(&sem_startup);
    while (!rc && !stopping) {
        rc = portalExec_poll(portalExec_timeout);
        if ((long) rc >= 0)
            rc = portalExec_event();
    }
    portalExec_end();
    printf("[%s] thread ending\n", __FUNCTION__);
    return rc;
}

void* portalExec(void* __x)
{
  return defaultPoller->portalExec(__x);
}

void* portalExec_init(void)
{
  return defaultPoller->portalExec_init();
}

void* portalExec_poll(int timeout)
{
  return defaultPoller->portalExec_poll(timeout);
}

void* portalExec_event(void)
{
  return defaultPoller->portalExec_event();
}

void portalExec_end(void)
{
  defaultPoller->portalExec_end();
}

static void *pthread_worker(void *__x)
{
    ((PortalPoller *)__x)->portalExec(__x);
    return 0;
}
void PortalPoller::portalExec_start()
{
    pthread_t threaddata;
    pthread_create(&threaddata, NULL, &pthread_worker, (void *)this);
    sem_wait(&sem_startup);
}
void portalExec_start()
{
    defaultPoller->portalExec_start();
}

#endif // NO_CPP_PORTAL_CODE
