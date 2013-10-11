
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
#include <sys/socket.h>
#include <semaphore.h>
#include <assert.h>

#ifdef ZYNQ
#include <android/log.h>
#endif

#include "portal.h"

#ifdef ZYNQ
#define ALOGD(fmt, ...) __android_log_print(ANDROID_LOG_DEBUG, "PORTAL", fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "PORTAL", fmt, __VA_ARGS__)
#else
#define ALOGD(fmt, ...) fprintf(stderr, "PORTAL", fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) fprintf(stderr, "PORTAL", fmt, __VA_ARGS__)
#endif


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
  : ind_reg_base(NULL), 
    ind_fifo_base(NULL),
    req_reg_base(NULL),
    req_fifo_base(NULL),
    indication(indication), fd(-1), instanceName(strdup(instanceName))
{
  int rc = open();
  if (rc != 0) {
printf("[%s:%d] failed to open PortalInstance %s\n", __FUNCTION__, __LINE__, instanceName);
    ALOGD("PortalInstance::PortalInstance failure rc=%d\n", rc);
    exit(1);
  }
}

PortalInstance::~PortalInstance()
{
  close();
  if (instanceName)
    free(instanceName);
  unregisterInstance(this);
}


static void init_socket(channel *c, const char* path)
{
  int len;
  if ((c->s2 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "(%s) socket error", path);
    exit(1);
  }
  
  printf("(%s) trying to connect...\n", path);
  
  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, path);
  len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  if (connect(c->s2, (struct sockaddr *)&(c->local), len) == -1) {
    fprintf(stderr,"(%s) connect error", path);
    exit(1); 
  }
  // int sockbuffsz = sizeof(memrequest);
  // setsockopt(c->s2, SOL_SOCKET, SO_SNDBUF, &sockbuffsz, sizeof(sockbuffsz));
  // sockbuffsz = sizeof(unsigned int);
  // setsockopt(c->s2, SOL_SOCKET, SO_RCVBUF, &sockbuffsz, sizeof(sockbuffsz));
  fprintf(stderr, "(%s) connected\n", path);
}

int PortalInstance::open()
{
#ifdef ZYNQ
    FILE *pgfile = fopen("/sys/devices/amba.0/f8007000.devcfg/prog_done", "r");
    if (!pgfile) {
        // 3.9 kernel uses amba.2
        pgfile = fopen("/sys/devices/amba.2/f8007000.devcfg/prog_done", "r");
    }
    if (pgfile == 0) {
	ALOGE("failed to open /sys/devices/amba.[02]/f8007000.devcfg/prog_done %d\n", errno);
	printf("failed to open /sys/devices/amba.[02]/f8007000.devcfg/prog_done %d\n", errno);
	return -1;
    }
    char line[128];
    fgets(line, sizeof(line), pgfile);
    if (line[0] != '1') {
	ALOGE("FPGA not programmed: %s\n", line);
	printf("FPGA not programmed: %s\n", line);
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
    volatile unsigned int *dev_base = (volatile unsigned int*)mmap(NULL, 1<<16, PROT_READ|PROT_WRITE, MAP_SHARED, this->fd, 0);
    if (dev_base == MAP_FAILED) {
      ALOGE("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", this->fd, errno);
      return -errno;
    }  
    ind_reg_base   = (volatile unsigned int*)(((unsigned long)dev_base)+(3<<14));
    ind_fifo_base  = (volatile unsigned int*)(((unsigned long)dev_base)+(2<<14));
    req_reg_base   = (volatile unsigned int*)(((unsigned long)dev_base)+(1<<14));
    req_fifo_base  = (volatile unsigned int*)(((unsigned long)dev_base)+(0<<14));
    registerInstance(this);
    return 0;
#else
    char path[128];
    snprintf(path, sizeof(path), "/tmp/%s_rc", instanceName);
    init_socket(&(p.read),path);
    snprintf(path, sizeof(path), "/tmp/%s_wc", instanceName);
    init_socket(&(p.write),path);

    unsigned long dev_base = 0;
    ind_reg_base   = dev_base+(3<<14);
    ind_fifo_base  = dev_base+(2<<14);
    req_reg_base   = dev_base+(1<<14);
    req_fifo_base  = dev_base+(0<<14);
    registerInstance(this);
    return 0;
#endif
}

int PortalInstance::sendMessage(PortalMessage *msg)
{
  unsigned int buf[128];
  msg->marshall(buf);

  // mutex_lock(&portal_data->reg_mutex);
  // mutex_unlock(&portal_data->reg_mutex);
  // fprintf(stderr, "msg->size() = %d\n", msg->size());
  for (int i = (msg->size()/4)-1; i >= 0; i--){
    unsigned int data = buf[i];
#ifdef ZYNQ
    // fprintf(stderr, "%08x\n", val);
    unsigned int addr = ((unsigned int)req_fifo_base) + msg->channel * 256;
    *((volatile unsigned int*)addr) = data;
#else
    unsigned int addr = req_fifo_base + msg->channel * 256;
    struct memrequest foo = {true,addr,data};
    if (send(p.write.s2, &foo, sizeof(foo), 0) == -1) {
      fprintf(stderr, "(%s) send error\n", instanceName);
      exit(1);
    }
    //fprintf(stderr, "(%s) sendMessage\n", instanceName);
#endif
  }
  return 0;
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

PARef PortalInstance::reference(PortalAlloc* pa)
{
  return pa->entries[0].dma_address;
}

int PortalMemory::alloc(size_t size, PortalAlloc *portalAlloc)
{
    if (!numFds) {
	ALOGE("%s No fds open\n", __FUNCTION__);
	return -ENODEV;
    }
    memset(portalAlloc, 0, sizeof(PortalAlloc));
    portalAlloc->size = size;
    int rc = ioctl(portal_fds[0].fd, PORTAL_ALLOC, portalAlloc);
    if (rc){
      fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
      return rc;
    }
    fprintf(stderr, "alloc size=%d rc=%d fd=%d numEntries=%d\n", size, rc, portalAlloc->fd, portalAlloc->numEntries);
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

void* portalExec(void* __x)
{
#ifdef ZYNQ
    int rc;
    int timeout = -1;
    if(0)
    fprintf(stderr, "about to invoke poll(%x, %d, %d)\n", portal_fds, numFds, timeout);
    if (!numFds) {
        ALOGE("PortalMemory::exec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
    while ((rc = poll(portal_fds, numFds, timeout)) >= 0) {
      // fprintf(stderr, "poll returned rc=%d\n", rc);
      for (int i = 0; i < numFds; i++) {
	if (portal_fds[i].revents == 0)
	  continue;
	if (!portal_instances) {
	  fprintf(stderr, "No portal_instances but rc=%d revents=%d\n", rc, portal_fds[i].revents);
	}
	
	PortalInstance *instance = portal_instances[i];
	
	// sanity check, to see the status of interrupt source and enable
	volatile unsigned int int_src = *(instance->ind_reg_base+0x0);
	volatile unsigned int int_en  = *(instance->ind_reg_base+0x1);
	volatile unsigned int queue_status = *(instance->ind_reg_base+0x8);
	if(0)
	fprintf(stderr, "about to receive messages %08x %08x %08x\n", int_src, int_en, queue_status);


	// handle all messasges from this portal instance
	while (queue_status) {
	  instance->indication->handleMessage(queue_status-1, instance->ind_fifo_base);
	  queue_status = *(instance->ind_reg_base+0x8);
	}
	
	// rc of 0 indicates timeout
	if (rc == 0) {
	  // do something if we timeout??
	}
	// re-enable interupt which was disabled by portal_isr
	*(instance->ind_reg_base+0x1) = 1;
      }
    }
    // return only in error case
    fprintf(stderr, "poll returned rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return (void*)rc;
#else
    fprintf(stderr, "about to enter while(true)\n");
    while (true){
      sleep(0);
      for(int i = 0; i < numFds; i++){
	PortalInstance *instance = portal_instances[i];
	unsigned int addr = instance->ind_reg_base+0x20;
	struct memrequest foo = {false,addr,0};
	//fprintf(stderr, "sending read request\n");
	if (send(instance->p.read.s2, &foo, sizeof(foo), 0) == -1) {
	  fprintf(stderr, "(%s) send error\n", instance->instanceName);
	  exit(1);
	}
	unsigned int queue_status;
	//fprintf(stderr, "about to get read response\n");
	if(recv(instance->p.read.s2, &queue_status, sizeof(queue_status), 0) == -1){
	  fprintf(stderr, "(%s) recv error\n", instance->instanceName);
	  exit(1);	  
	}
	//fprintf(stderr, "(%s) queue_status : %08x\n", instance->instanceName, queue_status);
	if (queue_status){
	  instance->indication->handleMessage(queue_status-1, instance);	
	}
      }
    }
#endif
}

