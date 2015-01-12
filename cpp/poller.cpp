
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
#include <fcntl.h>

#include "portal.h"
#include "sock_utils.h"

#ifndef NO_CPP_PORTAL_CODE
PortalPoller *defaultPoller = new PortalPoller();
uint64_t poll_enter_time, poll_return_time; // for performance measurement

PortalPoller::PortalPoller()
  : portal_wrappers(0), portal_fds(0), numFds(0), inited(0), numWrappers(0), stopping(0)
{
    int rc = pipe(pipefd);
    sem_init(&sem_startup, 0, 0);
    pthread_mutex_init(&mutex, NULL);
    fcntl(pipefd[0], F_SETFL, O_NONBLOCK);
    addFd(pipefd[0]);
}

int PortalPoller::unregisterInstance(Portal *portal)
{
  int i = 0;
  pthread_mutex_lock(&mutex);
  while(i < numWrappers){
    if(portal_wrappers[i]->pint.fpga_number == portal->pint.fpga_number) {
      fprintf(stderr, "PortalPoller::unregisterInstance %d %d\n", i, portal->pint.fpga_number);
      break;
    }
    i++;
  }

  while(i < numWrappers-1){
    portal_wrappers[i] = portal_wrappers[i+1];
    i++;
  }
  numWrappers--;
  i = 0;
  while(i < numFds){
    if(portal_fds[i].fd == portal->pint.fpga_fd)
      break;
    i++;
  }

  while(i < numFds-1){
    portal_fds[i] = portal_fds[i+1];
    i++;
  }
  numFds--;
  pthread_mutex_unlock(&mutex);
  return 0;
}

void PortalPoller::addFd(int fd)
{
    /* this internal function assumes mutex locked by caller.
     * since it can be called from addFdToPoller(), which was called under mutex lock
     * portalExec_event().
     */
    numFds++;
    portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
    struct pollfd *pollfd = &portal_fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = fd;
    pollfd->events = POLLIN;
}
int PortalPoller::registerInstance(Portal *portal)
{
    uint8_t ch = 0;
    int rc;
    pthread_mutex_lock(&mutex);
    rc = write(pipefd[1], &ch, 1); // get poll to return, so that it is no long using portal_fds (which gets realloc'ed)
    numWrappers++;
    fprintf(stderr, "Portal::registerInstance fpga%d fd %d clients %d\n", portal->pint.fpga_number, portal->pint.fpga_fd, portal->pint.client_fd_number);
    portal_wrappers = (Portal **)realloc(portal_wrappers, numWrappers*sizeof(Portal *));
    portal_wrappers[numWrappers-1] = portal;

    if (portal->pint.fpga_fd != -1)
        addFd(portal->pint.fpga_fd);
    for (int i = 0; i < portal->pint.client_fd_number; i++)
        addFd(portal->pint.client_fd[i]);
    portal->pint.item->enableint(&portal->pint, 1);
    pthread_mutex_unlock(&mutex);
    portalExec_start();
    return 0;
}

void* PortalPoller::portalExec_init(void)
{
    portalExec_timeout = -1; // no interrupt timeout
#ifdef XSIM
    portalExec_timeout = 100;
#endif
#ifdef BSIM
    portalExec_timeout = 100;
    if (global_sockfd != -1) {
        pthread_mutex_lock(&mutex);
        addFd(global_sockfd);
        pthread_mutex_unlock(&mutex);
    }
#endif
#if 0
    pthread_mutex_lock(&mutex);
    if (!numFds) {
        fprintf(stderr, "portalExec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
    for (int i = 0; i < numWrappers; i++) {
      Portal *instance = portal_wrappers[i];
      //fprintf(stderr, "portalExec::enabling interrupts portal %d fpga%d\n", i, instance->pint.fpga_number);
      instance->pint.item->enableint(&instance->pint, 1);
    }
    pthread_mutex_unlock(&mutex);
#endif
    fprintf(stderr, "portalExec::about to enter loop, numFds=%d\n", numFds);
    return NULL;
}
void PortalPoller::portalExec_stop(void)
{
    uint8_t ch = 0;
    int rc;
    stopping = 1;
    rc = write(pipefd[1], &ch, 1);
}
void PortalPoller::portalExec_end(void)
{
    stopping = 1;
    printf("%s: don't disable interrupts when stopping\n", __FUNCTION__);
    return;
    pthread_mutex_lock(&mutex);
    for (int i = 0; i < numWrappers; i++) {
      Portal *instance = portal_wrappers[i];
      fprintf(stderr, "portalExec::disabling interrupts portal %d fpga%d\n", i, instance->pint.fpga_number);
      instance->pint.item->enableint(&instance->pint, 0);
    }
    pthread_mutex_unlock(&mutex);
}

void* PortalPoller::portalExec_poll(int timeout)
{
    long rc = 0;
    if (timeout != 0)
      rc = poll(portal_fds, numFds, timeout);
    if(rc < 0) {
      // return only in error case
      fprintf(stderr, "poll returned rc=%ld errno=%d:%s\n", rc, errno, strerror(errno));
    }
    return (void*)rc;
}

void* PortalPoller::portalExec_event(void)
{
    uint8_t ch;
    int rc;
    pthread_mutex_lock(&mutex);
    rc = read(pipefd[0], &ch, 1);
    for (int i = 0; i < numWrappers; i++) {
       if (!portal_wrappers)
           fprintf(stderr, "No portal_instances revents=%d\n", portal_fds[i].revents);
       Portal *instance = portal_wrappers[i];
       if (instance->pint.handler) {
           instance->pint.item->event(&instance->pint);
           // re-enable interrupt which was disabled by portal_isr
           instance->pint.item->enableint(&instance->pint, 1);
       }
    }
    pthread_mutex_unlock(&mutex);
    return NULL;
}
extern "C" void addFdToPoller(struct PortalPoller *poller, int fd)
{
    poller->addFd(fd);
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
    pthread_mutex_lock(&mutex);
    if (inited) {
        pthread_mutex_unlock(&mutex);
        return;
    }
    inited = 1;
    pthread_mutex_unlock(&mutex);
    pthread_create(&threaddata, NULL, &pthread_worker, (void *)this);
    sem_wait(&sem_startup);
}
void portalExec_start()
{
    defaultPoller->portalExec_start();
}
void portalExec_stop()
{
    defaultPoller->portalExec_stop();
}

#endif // NO_CPP_PORTAL_CODE
