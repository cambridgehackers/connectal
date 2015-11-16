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
#include "portal.h"
#include "sock_utils.h"
#include <string.h>
#include <poll.h>
#include <errno.h>
#include <pthread.h>
#include <fcntl.h>

static int trace_poller;//=1;

#ifndef NO_CPP_PORTAL_CODE
PortalPoller *defaultPoller = new PortalPoller();
uint64_t poll_enter_time, poll_return_time; // for performance measurement

PortalPoller::PortalPoller(int autostart)
  : portal_wrappers(0), portal_fds(0), startThread(autostart), numWrappers(0), numFds(0), stopping(0)
{
    int rc = pipe(pipefd);
    if (rc != 0)
      fprintf(stderr, "[%s:%d] pipe error %d:%s\n", __FUNCTION__, __LINE__, errno, strerror(errno));
    sem_init(&sem_startup, 0, 0);
    pthread_mutex_init(&mutex, NULL);
    fcntl(pipefd[0], F_SETFL, O_NONBLOCK);
    addFd(pipefd[0]);

    timeout = -1;
#if defined(SIMULATION)
    timeout = 100;
#endif
}

int PortalPoller::unregisterInstance(Portal *portal)
{
    int i = 0;
    pthread_mutex_lock(&mutex);
    while(i < numWrappers){
        if(portal_wrappers[i]->pint.fpga_number == portal->pint.fpga_number) {
	    //fprintf(stderr, "PortalPoller::unregisterInstance %d %d\n", i, portal->pint.fpga_number);
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
     * event().
     */
    numFds++;
    struct pollfd *new_portal_fds = (struct pollfd *)malloc(numFds*sizeof(struct pollfd));
    if (portal_fds) {
	memcpy((void *)new_portal_fds, (const void *)portal_fds, (numFds-1)*sizeof(struct pollfd));
	free(portal_fds);
    }
    portal_fds = new_portal_fds;
    struct pollfd *pollfd = &portal_fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = fd;
    pollfd->events = POLLIN;
}

int PortalPoller::registerInstance(Portal *portal)
{
    uint8_t ch = 0;
    pthread_mutex_lock(&mutex);
    int rc = write(pipefd[1], &ch, 1); // get poll to return, so that it is no long using portal_fds (which gets realloc'ed)
    if (rc < 0)
        fprintf(stderr, "[%s:%d] write error %d\n", __FUNCTION__, __LINE__, errno);
    numWrappers++;
    if (trace_poller)
        fprintf(stderr, "Poller: registerInstance fpga%d fd %d clients %d\n", portal->pint.fpga_number, portal->pint.fpga_fd, portal->pint.client_fd_number);
    portal_wrappers = (Portal **)realloc(portal_wrappers, numWrappers*sizeof(Portal *));
    portal_wrappers[numWrappers-1] = portal;

    if (portal->pint.fpga_fd != -1)
        addFd(portal->pint.fpga_fd);
    for (int i = 0; i < portal->pint.client_fd_number; i++)
        addFd(portal->pint.client_fd[i]);
    portal->pint.item->enableint(&portal->pint, 1);
    pthread_mutex_unlock(&mutex);
    start();
    return 0;
}

void* PortalPoller::init(void)
{
#ifdef SIMULATION
    if (global_sockfd != -1) {
        pthread_mutex_lock(&mutex);
        addFd(global_sockfd);
        pthread_mutex_unlock(&mutex);
    }
#endif
    //fprintf(stderr, "Poller: about to enter loop, numFds=%d\n", numFds);
    return NULL;
}
void PortalPoller::stop(void)
{
    uint8_t ch = 0;
    int rc;
    stopping = 1;
    startThread = 0;
    rc = write(pipefd[1], &ch, 1);
    if (rc < 0)
        fprintf(stderr, "[%s:%d] write error %d\n", __FUNCTION__, __LINE__, errno);
}
void PortalPoller::end(void)
{
    stopping = 1;
    fprintf(stderr, "%s: don't disable interrupts when stopping\n", __FUNCTION__);
    return;
    pthread_mutex_lock(&mutex);
    for (int i = 0; i < numWrappers; i++) {
        Portal *instance = portal_wrappers[i];
        fprintf(stderr, "Poller::disabling interrupts portal %d fpga%d\n", i, instance->pint.fpga_number);
        instance->pint.item->enableint(&instance->pint, 0);
    }
    pthread_mutex_unlock(&mutex);
}

void* PortalPoller::pollFn(int timeout)
{
    long rc = 0;
    //printf("[%s:%d] before poll %d numFds %d\n", __FUNCTION__, __LINE__, timeout, numFds);
    //for (int i = 0; i < numFds; i++)
        //printf("%s: fd %d events %x\n", __FUNCTION__, portal_fds[i].fd, portal_fds[i].events);
    if (timeout != 0)
        rc = poll(portal_fds, numFds, timeout);
    if(rc < 0) {
        // return only in error case
        fprintf(stderr, "Poller: poll returned rc=%ld errno=%d:%s\n", rc, errno, strerror(errno));
    }
    return (void*)rc;
}

void* PortalPoller::event(void)
{
    uint8_t ch;
    pthread_mutex_lock(&mutex);
    size_t rc = read(pipefd[0], &ch, 1);
    if (rc < 0)
        fprintf(stderr, "[%s:%d] read error %d\n", __FUNCTION__, __LINE__, errno);
    for (int i = 0; i < numWrappers; i++) {
        if (!portal_wrappers)
            fprintf(stderr, "Poller: No portal_instances revents=%d\n", portal_fds[i].revents);
        Portal *instance = portal_wrappers[i];
        if (trace_poller)
            fprintf(stderr, "Poller: event tile %d fpga%d fd %d handler %p parent %p\n",
                instance->pint.fpga_tile, instance->pint.fpga_number, instance->pint.fpga_fd, instance->pint.handler, instance->pint.parent);
        instance->pint.item->event(&instance->pint);
        if (instance->pint.handler) {
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

void* PortalPoller::threadFn(void* __x)
{
    void *rc = init();
    sem_post(&sem_startup);
    while (!rc && !stopping) {
        rc = pollFn(timeout);
        if ((long) rc >= 0)
            rc = event();
    }
    end();
    fprintf(stderr, "[%s] thread ending\n", __FUNCTION__);
    return rc;
}

static void *pthread_worker(void *__x)
{
    ((PortalPoller *)__x)->threadFn(__x);
    return 0;
}

void PortalPoller::start()
{
    pthread_t threaddata;
    pthread_mutex_lock(&mutex);
    if (!startThread) {
        pthread_mutex_unlock(&mutex);
        return;
    }
    startThread = 0;
    pthread_mutex_unlock(&mutex);
    pthread_create(&threaddata, NULL, &pthread_worker, (void *)this);
    sem_wait(&sem_startup);
}
#endif // NO_CPP_PORTAL_CODE
