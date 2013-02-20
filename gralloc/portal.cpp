
// Copyright (c) 2012 Nokia, Inc.

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

#include <errno.h>
#include <fcntl.h>
#include <linux/ioctl.h>
#include <linux/types.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "portal.h"

#include <sys/cdefs.h>
#include <android/log.h>
#define ALOGD(fmt, ...) __android_log_print(ANDROID_LOG_DEBUG, "PORTAL", fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "PORTAL", fmt, __VA_ARGS__)

#define PORTAL_ALLOC _IOWR('B', 10, PortalAlloc)
#define PORTAL_PUTGET _IOWR('B', 17, PortalMessage)
#define PORTAL_PUT _IOWR('B', 18, PortalMessage)
#define PORTAL_GET _IOWR('B', 19, PortalMessage)
#define PORTAL_REGS _IOWR('B', 20, PortalMessage)
#define PORTAL_CLK_ROUND _IOWR('B', 40, PortalClockConfig)

PortalInterface portal;

void PortalInstance::close()
{
    if (fd > 0) {
        ::close(fd);
        fd = -1;
    }    
}

PortalInstance::PortalInstance(const char *instanceName)
{
    this->instanceName = strdup(instanceName);
    char path[128];
    snprintf(path, sizeof(path), "/dev/%s", instanceName);
    this->fd = open(path, O_RDWR);
    void *mappedAddress = mmap(0, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, this->fd, 0);
    fprintf(stderr, "Mapped device %s at %p\n", instanceName, mappedAddress);
    ALOGD("Mapped device %s at %p path=%s fd=%d\n", instanceName, mappedAddress, path, this->fd);
    portal.registerInstance(this);
}

PortalInstance::~PortalInstance()
{
    close();
    if (instanceName)
        free(instanceName);
}


PortalInstance *portalOpen(const char *instanceName)
{
    return new PortalInstance(instanceName);
}

int PortalInstance::sendMessage(PortalMessage *msg)
{
    int rc = ioctl(fd, PORTAL_PUT, msg);
    if (rc)
        ALOGE("PortalInstance::sendMessage fd=%d channel=%d rc=%d errno=%d:%s\n",
              fd, msg->channel,
              rc, errno, strerror(errno));
    return rc;
}

int PortalInstance::receiveMessage(PortalMessage *msg)
{
    int status  = ioctl(fd, PORTAL_GET, msg);
    if (status) {
        fprintf(stderr, "receiveMessage channel=%d rc=%d errno=%d:%s\n", msg->channel, status, errno, strerror(errno));
        return -status;
    }
    return 1;
}

PortalInterface::PortalInterface()
    : fds(0), numFds(0)
{
}

PortalInterface::~PortalInterface()
{
    if (fds) {
        ::free(fds);
        fds = 0;
    }
}

int PortalInterface::registerInstance(PortalInstance *instance)
{
    numFds++;
    instances = (PortalInstance **)realloc(instances, numFds*sizeof(PortalInstance *));
    instances[numFds-1] = instance;
    fds = (struct pollfd *)realloc(fds, numFds*sizeof(struct pollfd));
    struct pollfd *pollfd = &fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = instance->fd;
    pollfd->events = POLLIN;
    return 0;
}

int PortalInterface::alloc(size_t size, int *fd, PortalAlloc *portalAlloc)
{
    PortalAlloc alloc;
    memset(&alloc, 0, sizeof(alloc));
    void *ptr = 0;
    alloc.size = size;
    int rc = ioctl(portal.fds[0].fd, PORTAL_ALLOC, &alloc);
    if (rc)
      return rc;
    ptr = mmap(0, alloc.size, PROT_READ|PROT_WRITE, MAP_SHARED, alloc.fd, 0);
    fprintf(stderr, "alloc size=%d rc=%d alloc.fd=%d ptr=%p\n", size, rc, alloc.fd, ptr);
    if (fd)
      *fd = alloc.fd;
    if (portalAlloc)
      *portalAlloc = alloc;
    return 0;
}

int PortalInterface::free(int fd)
{
    return 0;
}

int PortalInterface::dumpRegs()
{
    int foo = 0;
    int rc = ioctl(portal.fds[0].fd, PORTAL_REGS, &foo);
    return rc;
}

int PortalInterface::exec(idleFunc func)
{
    unsigned int *buf = new unsigned int[1024];
    PortalMessage *msg = (PortalMessage *)(buf);
    fprintf(stderr, "PortalInterface::exec()\n");
    int messageReceived = 0;

    if (!portal.numFds) {
        fprintf(stderr, "PortalInterface::exec No fds open\n");
        return -ENODEV;
    }

    int rc;
    while ((rc = poll(portal.fds, portal.numFds, 100)) >= 0) {
        //fprintf(stderr, "pid %d poll rc=%d\n", getpid(), rc);
        for (int i = 0; i < portal.numFds; i++) {
            if (portal.fds[i].revents == 0)
                continue;
            if (!portal.instances) {
                fprintf(stderr, "No instances but rc=%d revents=%d\n", rc, portal.fds[i].revents);
            }
            PortalInstance *instance = portal.instances[i];
            memset(buf, 0, 1024);
            int messageReceived = instance->receiveMessage(msg);
            //fprintf(stderr, "messageReceived=%d\n", messageReceived);
            if (!messageReceived)
                continue;
            size_t size = msg->size;
            //fprintf(stderr, "msg->size=%d msg->channel=%d\n", msg->size, msg->channel);
            if (!size)
                continue;
            instance->handleMessage(msg);
        }
        if (rc == 0) {
            if (0)
            ALOGD("poll returned rc=%d errno=%d:%s func=%p\n",
                  rc, errno, strerror(errno), func);
          if (func)
            func();
        }
    }
    if (rc < 0) {
        fprintf(stderr, "poll returned rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
        return rc;
    }

    return 0;
}

static const char *si570path = "/sys/devices/amba.0/e0004000.i2c/i2c-0/i2c-1/1-005d/frequency";

int PortalInstance::updateFrequency(long frequency)
{
    PortalClockConfig clockConfig;
    clockConfig.clock = 1;
    clockConfig.requested_frequency = frequency;
    int status = ioctl(fd, PORTAL_CLK_ROUND, &clockConfig);
    ALOGD("requested_frequency=%d granted_frequency=%d status=%d\n",
          clockConfig.requested_frequency, clockConfig.granted_frequency, status);

#if 0
    int si570fd = open(si570path, O_RDWR);
    fprintf(stderr, "updateFrequency fd=%d freq=%ld\n", si570fd, frequency);
    if (si570fd < 0)
        return errno;
    char freqstring[32];
    snprintf(freqstring, sizeof(freqstring), "%ld", frequency);
    int rc = write(si570fd, freqstring, strlen(freqstring));
    if (rc < 0)
        return errno;
    ::close(si570fd);
#endif
    return 0;
}
