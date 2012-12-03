
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
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "ushw.h"

#define USHW_PUTGET _IOWR('B', 17, UshwMessage)
#define USHW_PUT _IOWR('B', 18, UshwMessage)
#define USHW_GET _IOWR('B', 19, UshwMessage)

UshwInterface ushw;

void UshwInstance::close()
{
    if (fd > 0) {
        ::close(fd);
        fd = -1;
    }    
}

UshwInstance::UshwInstance(const char *instanceName)
{
    this->instanceName = strdup(instanceName);
    char path[128];
    snprintf(path, sizeof(path), "/dev/%s", instanceName);
    this->fd = open(path, O_RDWR);
    ushw.registerInstance(this);
}

UshwInstance::~UshwInstance()
{
    close();
    if (instanceName)
        free(instanceName);
}


UshwInstance *ushwOpen(const char *instanceName)
{
    return new UshwInstance(instanceName);
}

int UshwInstance::sendMessage(UshwMessage *msg)
{
    int rc = ioctl(fd, USHW_PUT, msg);
    if (rc)
        fprintf(stderr, "sendMessage fd=%d rc=%d errno=%d:%s PUTGET=%x PUT=%x GET=%x\n", fd, rc, errno, strerror(errno),
                USHW_PUTGET, USHW_PUT, USHW_GET);
    return rc;
}

int UshwInstance::receiveMessage(UshwMessage *msg)
{
    int status  = ioctl(fd, USHW_GET, msg);
    if (status) {
        fprintf(stderr, "receiveMessage rc=%d errno=%d:%s\n", status, errno, strerror(errno));
        return -status;
    }
    return 1;
}

UshwInterface::UshwInterface()
    : fds(0), numFds(0)
{
}

UshwInterface::~UshwInterface()
{
    if (fds) {
        free(fds);
        fds = 0;
    }
}

int UshwInterface::registerInstance(UshwInstance *instance)
{
    numFds++;
    instances = (UshwInstance **)realloc(instances, numFds*sizeof(UshwInstance *));
    instances[numFds-1] = instance;
    fds = (struct pollfd *)realloc(fds, numFds*sizeof(struct pollfd));
    struct pollfd *pollfd = &fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = instance->fd;
    pollfd->events = POLLIN;
    return 0;
}

int UshwInterface::exec()
{
    unsigned int *buf = new unsigned int[1024];
    UshwMessage *msg = (UshwMessage *)(buf);
    fprintf(stderr, "exec()\n");
    int messageReceived = 0;

    int rc;
    while ((rc = poll(ushw.fds, ushw.numFds, 1000)) >= 0) {
        for (int i = 0; i < ushw.numFds; i++) {
            if (ushw.fds[i].revents == 0)
                continue;
            UshwInstance *instance = ushw.instances[i];
            int messageReceived = instance->receiveMessage(msg);
            if (!messageReceived)
                continue;
            size_t size = msg->size;
            if (!size)
                continue;
            int channel = *(buf+1+(size-1)/4); // channel number is last word of message
            if (0) fprintf(stderr, "channel %x messageHandlers=%p\n", channel, instance->messageHandlers);
            if (instance->messageHandlers && instance->messageHandlers[channel])
                instance->messageHandlers[channel](msg);
        }
    }
    if (rc < 0) {
        fprintf(stderr, "poll returned rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
        return rc;
    }

    return 0;
}
