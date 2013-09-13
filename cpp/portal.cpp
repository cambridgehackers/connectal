
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
#define PORTAL_DCACHE_FLUSH_INVAL _IOWR('B', 11, PortalMessage)
#define PORTAL_PUT _IOWR('B', 18, PortalMessage)
#define PORTAL_GET _IOWR('B', 19, PortalMessage)
#define PORTAL_SET_FCLK_RATE _IOWR('B', 40, PortalClockRequest)

PortalInstance **portal_instances = 0;
struct pollfd *portal_fds = 0;
int numFds = 0;

void PortalInstance::close()
{
    if (fd > 0) {
        ::close(fd);
        fd = -1;
    }    
}

PortalInstance::PortalInstance(const char *instanceName, PortalIndication *indication)
  : hwregs(NULL), indication(indication), fd(-1), instanceName(strdup(instanceName))
{
}

PortalInstance::~PortalInstance()
{
  close();
  if (instanceName)
    free(instanceName);
  unregisterInstance(this);
}

int PortalInstance::open()
{
    if (this->fd >= 0)
	return 0;

    FILE *pgfile = fopen("/sys/devices/amba.0/f8007000.devcfg/prog_done", "r");
    if (pgfile == 0) {
	ALOGE("failed to open /sys/devices/amba.0/f8007000.devcfg/prog_done %d\n", errno);
	return -1;
    }
    char line[128];
    fgets(line, sizeof(line), pgfile);
    if (line[0] != '1') {
	ALOGE("FPGA not programmed: %s\n", line);
	return -ENODEV;
    }
    fclose(pgfile);


    char path[128];
    snprintf(path, sizeof(path), "/dev/%s", instanceName);
    this->fd = ::open(path, O_RDWR);
    if (this->fd < 0) {
	ALOGE("Failed to open %s fd=%d errno=%d\n", path, this->fd, path);
	return -errno;
    }
    hwregs = (volatile unsigned int*)mmap(NULL, 2<<PAGE_SHIFT, PROT_READ|PROT_WRITE, MAP_SHARED, this->fd, 0);
    if (hwregs == MAP_FAILED) {
      ALOGE("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", this->fd, errno);
      return -errno;
    }  
    registerInstance(this);
    return 0;
}

PortalInstance *portalOpen(const char *instanceName)
{
    PortalInstance *instance = new PortalInstance(instanceName);
    instance->open();
    return instance;
}

int PortalInstance::sendMessage(PortalMessage *msg)
{
    int rc = open();
    if (rc != 0) {
	ALOGD("PortalInstance::sendMessage fd=%d rc=%d\n", fd, rc);
	return rc;
    }

    rc = ioctl(fd, PORTAL_PUT, msg);
    //ALOGD("sendmessage portal fd=%d rc=%d\n", fd, rc);
    if (rc)
        ALOGE("PortalInstance::sendMessage fd=%d rc=%d errno=%d:%s PUT=%x GET=%x\n", fd, rc, errno, strerror(errno), PORTAL_PUT, PORTAL_GET);
    return rc;
}

int PortalInstance::receiveMessage(PortalMessage *msg)
{
    int rc = open();
    if (rc != 0) {
	ALOGD("PortalInstance::receiveMessage fd=%d rc=%d\n", fd, rc);
	return 0;
    }

    int status  = ioctl(fd, PORTAL_GET, msg);
    if (status) {
        if (errno != EAGAIN)
            fprintf(stderr, "receiveMessage rc=%d errno=%d:%s\n", status, errno, strerror(errno));
        return 0;
    }
    return 1;
}


int PortalInstance::unregisterInstance(PortalInstance *instance)
{
  int i = 0;
  while(i < numFds)
    if(portal_fds[i].fd == instance->fd)
      break;
    else
      i++;

  while(i < numFds-1){
    portal_fds[i] = portal_fds[i+1];
    portal_instances[i] = portal_instances[i+1];
  }

  numFds--;
  portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
  portal_instances = (PortalInstance **)realloc(portal_instances, numFds*sizeof(PortalInstance *));  
  return 0;
}

int PortalInstance::registerInstance(PortalInstance *instance)
{
    numFds++;
    portal_instances = (PortalInstance **)realloc(portal_instances, numFds*sizeof(PortalInstance *));
    portal_instances[numFds-1] = instance;
    portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
    struct pollfd *pollfd = &portal_fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = instance->fd;
    pollfd->events = POLLIN;
    return 0;
}

int PortalMemory::dCacheFlushInval(PortalAlloc *portalAlloc)
{
    if (!numFds) {
	ALOGE("%s No fds open\n", __FUNCTION__);
	return -ENODEV;
    }
    int rc = ioctl(portal_fds[0].fd, PORTAL_DCACHE_FLUSH_INVAL, portalAlloc);
    if (rc){
      fprintf(stderr, "portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
      return rc;
    }
    //fprintf(stderr, "dcache flush\n");
    return 0;
}

int PortalMemory::alloc(size_t size, int *fd, PortalAlloc *portalAlloc)
{
    if (!numFds) {
	ALOGE("%s No fds open\n", __FUNCTION__);
	return -ENODEV;
    }

    PortalAlloc alloc;
    memset(&alloc, 0, sizeof(alloc));
    alloc.size = size;
    int rc = ioctl(portal_fds[0].fd, PORTAL_ALLOC, &alloc);
    if (rc){
      fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
      return rc;
    }
    fprintf(stderr, "alloc size=%d rc=%d alloc.fd=%d\n", size, rc, alloc.fd);
    if (fd)
      *fd = alloc.fd;
    if (portalAlloc)
      *portalAlloc = alloc;
    return 0;
}

int PortalInstance::setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
{
    if (!numFds) {
	ALOGE("%s No fds open\n", __FUNCTION__);
	return -ENODEV;
    }

    PortalClockRequest request;
    request.clknum = clkNum;
    request.requested_rate = requestedFrequency;
    int status = ioctl(portal_fds[0].fd, PORTAL_SET_FCLK_RATE, (long)&request);
    if (status == 0 && actualFrequency)
	*actualFrequency = request.actual_rate;
    if (status < 0)
	status = errno;
    return status;
}

void PortalInstance::dumpRegs()
{
  for(int j = 0; j < 0x10; j++){
    fprintf(stderr, "reg[%08x] = %08x\n", j*4, *(hwregs+j));
  }
}

void* portalExec(void* __x)
{
    unsigned int *buf = new unsigned int[1024];
    PortalMessage *msg = (PortalMessage *)(buf);

    if (!numFds) {
        ALOGE("PortalMemory::exec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
    
    int rc;
    while ((rc = poll(portal_fds, numFds, -1)) >= 0) {
      for (int i = 0; i < numFds; i++) {
	if (portal_fds[i].revents == 0)
	  continue;
	if (!portal_instances) {
	  fprintf(stderr, "No portal_instances but rc=%d revents=%d\n", rc, portal_fds[i].revents);
	}

	PortalInstance *instance = portal_instances[i];
	memset(buf, 0, 1024);
	
	// sanity check, to see the status of interrupt source and enable
	volatile unsigned int int_src = *(instance->hwregs+0x0);
	volatile unsigned int int_en  = *(instance->hwregs+0x1);

	// handle all messasges from this portal instance
	int messageReceived = instance->receiveMessage(msg);
	while (messageReceived) {
	  //fprintf(stderr, "messageReceived: msg->size=%d msg->channel=%d\n", msg->size, msg->channel);
	  if (msg->size && instance->indication)
	    instance->indication->handleMessage(msg);
	  messageReceived = instance->receiveMessage(msg);
	}

	// re-enable interupt which was disabled by portal_isr
	*(instance->hwregs+0x1) = 1;
      }

      // rc of 0 indicates timeout
      if (rc == 0) {
	// do something if we timeout??
      }
    }

    // return only in error case
    fprintf(stderr, "poll returned rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return (void*)rc;
}
