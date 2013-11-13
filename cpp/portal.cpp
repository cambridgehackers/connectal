
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
#include <assert.h>

#ifdef ZYNQ
#include <android/log.h>
#endif

#include "portal.h"
#include "sock_utils.h"
#include "sock_fd.h"

#ifdef ZYNQ
#define ALOGD(fmt, ...) __android_log_print(ANDROID_LOG_DEBUG, "PORTAL", fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "PORTAL", fmt, __VA_ARGS__)
#else
#define ALOGD(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#endif


PortalRequest **portal_requests = 0;
struct pollfd *portal_fds = 0;
int numFds = 0;

void PortalRequest::close()
{
    if (fd > 0) {
        ::close(fd);
        fd = -1;
    }    
}

PortalRequest::PortalRequest(const char *name, PortalIndication *indication)
  : ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0),
    indication(indication), 
    fd(-1),
    name((char*)strdup(name))
{
  int rc = open();
  if (rc != 0) {
    printf("[%s:%d] failed to open PortalRequest %s\n", __FUNCTION__, __LINE__, name);
    ALOGD("PortalRequest::PortalRequest failure rc=%d\n", rc);
    exit(1);
  }
}

PortalRequest::PortalRequest()
  : ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0),
    indication(NULL), 
    fd(-1),
    name(NULL)
{
}

PortalRequest::~PortalRequest()
{
  close();
  if (name)
    free(name);
  unregisterInstance(this);
}




int PortalRequest::open()
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
#endif
#ifdef MMAP_HW

    char path[128];
    snprintf(path, sizeof(path), "/dev/%s", name);
#ifdef ZYNQ
    this->fd = ::open(path, O_RDWR);
#else
    // FIXME: bluenoc driver only opens readonly for some reason
    this->fd = ::open(path, O_RDONLY);
#endif
    if (this->fd < 0) {
	ALOGE("Failed to open %s fd=%d errno=%d\n", path, this->fd, errno);
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

    // enable interrupts
    fprintf(stderr, "PortalRequest::enabling interrupts %s\n", name);
    *(ind_reg_base+0x1) = 1;

#else
    
    snprintf(p.read.path, sizeof(p.read.path), "/tmp/%s_rc", name);
    connect_socket(&(p.read));
    snprintf(p.write.path, sizeof(p.read.path), "/tmp/%s_wc", name);
    connect_socket(&(p.write));

    unsigned long dev_base = 0;
    ind_reg_base   = dev_base+(3<<14);
    ind_fifo_base  = dev_base+(2<<14);
    req_reg_base   = dev_base+(1<<14);
    req_fifo_base  = dev_base+(0<<14);
#endif
    registerInstance(this);
    return 0;
}

int PortalRequest::sendMessage(PortalMessage *msg)
{

  // TODO: this intermediate buffer (and associated copy) should be removed (mdk)
  unsigned int buf[128];
  msg->marshall(buf);

  // mutex_lock(&portal_data->reg_mutex);
  // mutex_unlock(&portal_data->reg_mutex);
  for (int i = msg->size()/4-1; i >= 0; i--) {
    unsigned int data = buf[i];
#ifdef MMAP_HW
    unsigned long addr = ((unsigned long)req_fifo_base) + msg->channel * 256;
    //fprintf(stderr, "%08lx %08x\n", addr, data);
    *((volatile unsigned int*)addr) = data;
#else
    unsigned int addr = req_fifo_base + msg->channel * 256;
    struct memrequest foo = {true,addr,data};
    if (send(p.write.s2, &foo, sizeof(foo), 0) == -1) {
      fprintf(stderr, "(%s) send error\n", name);
      exit(1);
    }
    //fprintf(stderr, "(%s) sendMessage\n", name);
#endif
  }
  return 0;
}

int PortalRequest::unregisterInstance(PortalRequest *instance)
{
  int i = 0;
  while(i < numFds)
    if(portal_fds[i].fd == instance->fd)
      break;
    else
      i++;

  while(i < numFds-1){
    portal_fds[i] = portal_fds[i+1];
    portal_requests[i] = portal_requests[i+1];
  }

  numFds--;
  portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
  portal_requests = (PortalRequest **)realloc(portal_requests, numFds*sizeof(PortalRequest *));  
  return 0;
}

int PortalRequest::registerInstance(PortalRequest *instance)
{
    numFds++;
    portal_requests = (PortalRequest **)realloc(portal_requests, numFds*sizeof(PortalRequest *));
    portal_requests[numFds-1] = instance;
    portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
    struct pollfd *pollfd = &portal_fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = instance->fd;
    pollfd->events = POLLIN;
    return 0;
}

PortalMemory::PortalMemory()
  : handle(0)
{
  const char* path = "/dev/portalalloc";
  this->pa_fd = ::open(path, O_RDWR);
  if (this->pa_fd < 0){
    ALOGE("Failed to open %s pa_fd=%ld errno=%d\n", path, (long)this->pa_fd, errno);
  }
}

PortalMemory::PortalMemory(const char *name, PortalIndication *indication)
  : handle(0),
    PortalRequest(name,indication)
{
#ifndef MMAP_HW
  snprintf(p_fd.read.path, sizeof(p_fd.read.path), "/tmp/fd_sock_rc");
  connect_socket(&(p_fd.read));
  snprintf(p_fd.write.path, sizeof(p_fd.write.path), "/tmp/fd_sock_wc");
  connect_socket(&(p_fd.write));
#endif
  const char* path = "/dev/portalalloc";
  this->pa_fd = ::open(path, O_RDWR);
  if (this->pa_fd < 0){
    ALOGE("Failed to open %s pa_fd=%ld errno=%d\n", path, (long)this->pa_fd, errno);
  }
}

int PortalMemory::dCacheFlushInval(PortalAlloc *portalAlloc, void *__p)
{
#if defined(__arm__)
  int rc = ioctl(this->pa_fd, PA_DCACHE_FLUSH_INVAL, portalAlloc);
  if (rc){
    fprintf(stderr, "portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
#elif defined(__i386__) || defined(__x86_64__)
  for(int i = 0; i < portalAlloc->header.size; i++){
    char foo = *(((volatile char *)__p)+i);
    asm volatile("clflush %0" :: "m" (foo));
  }
#else
#error("dCAcheFlush not defined for unspecified architecture")
#endif
  fprintf(stderr, "dcache flush\n");
  return 0;
}

int PortalMemory::reference(PortalAlloc* pa)
{
  int id = handle++;
#ifdef MMAP_HW
  int ne = pa->header.numEntries;
  assert(ne < 32);
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries;
  for(int i = 0; i <= pa->header.numEntries; i++){
    int offset = (id*32)+i;
    fprintf(stderr, "PortalMemory::sglist(%08x, %08lx, %08lx)\n", offset, pa->entries[i].dma_address, pa->entries[i].length);
    sglist(offset, pa->entries[i].dma_address, pa->entries[i].length);
    sleep(1);
  }
#else
  sock_fd_write(p_fd.write.s2, pa->header.fd);
  paref(id, id);
#endif
  return id;
}

int PortalMemory::alloc(size_t size, PortalAlloc *portalAlloc)
{
    memset(portalAlloc, 0, sizeof(PortalAlloc));
    portalAlloc->header.size = size;
    int rc = ioctl(this->pa_fd, PA_ALLOC, portalAlloc);
    if (rc){
      fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
      return rc;
    }
    fprintf(stderr, "alloc size=%ld rc=%d fd=%d numEntries=%d\n", 
	    portalAlloc->header.size, rc, portalAlloc->header.fd, portalAlloc->header.numEntries);
    return 0;
}

int PortalRequest::setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
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
#ifdef MMAP_HW
    long rc;
    int timeout = -1;
#ifndef ZYNQ
    timeout = 1; // interrupts not working yet on PCIe
#endif
    if (!numFds) {
        ALOGE("portalExec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
    while ((rc = poll(portal_fds, numFds, timeout)) >= 0) {
      if (0)
	fprintf(stderr, "poll returned rc=%ld\n", rc);
#ifndef ZYNQ
      // PCIE interrupts not working
      if (1)
	{
	  PortalRequest *instance = portal_requests[0];
	  unsigned int int_src = *(volatile int *)(instance->ind_reg_base+0x0);
	  unsigned int int_en  = *(volatile int *)(instance->ind_reg_base+0x1);
	  unsigned int ind_count  = *(volatile int *)(instance->ind_reg_base+0x2);
	  unsigned int queue_status = *(volatile int *)(instance->ind_reg_base+0x8);
	  if (0)
	    fprintf(stderr, "%d: int_src=%08x int_en=%08x ind_count=%08x queue_status=%08x\n",
		    __LINE__, int_src, int_en, ind_count, queue_status);
	}
#endif      
      for (int i = 0; i < numFds; i++) {
#ifndef ZYNQ
	// PCIE interrupts not working
	if (0)
#endif
	if (portal_fds[i].revents == 0)
	  continue;
	if (!portal_requests) {
	  fprintf(stderr, "No portal_instances but rc=%ld revents=%d\n", rc, portal_fds[i].revents);
	}
	
	PortalRequest *instance = portal_requests[i];
	
	// sanity check, to see the status of interrupt source and enable
	unsigned int int_src = *(volatile int *)(instance->ind_reg_base+0x0);
	unsigned int int_en  = *(volatile int *)(instance->ind_reg_base+0x1);
	unsigned int ind_count  = *(volatile int *)(instance->ind_reg_base+0x2);
	unsigned int queue_status = *(volatile int *)(instance->ind_reg_base+0x8);
	if(0)
	  fprintf(stderr, "(%d) about to receive messages %08x %08x %08x\n", i, int_src, int_en, queue_status);

	// handle all messasges from this portal instance
	while (queue_status) {
	  if(0)
	    fprintf(stderr, "queue_status %d\n", queue_status);
	  instance->indication->handleMessage(queue_status-1, instance->ind_fifo_base);
	  int_src = *(volatile int *)(instance->ind_reg_base+0x0);
	  int_en  = *(volatile int *)(instance->ind_reg_base+0x1);
	  ind_count  = *(volatile int *)(instance->ind_reg_base+0x2);
	  queue_status = *(volatile int *)(instance->ind_reg_base+0x8);
	  if (0)
	    fprintf(stderr, "%d: int_src=%08x int_en=%08x ind_count=%08x queue_status=%08x\n",
		    __LINE__, int_src, int_en, ind_count, queue_status);
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
    fprintf(stderr, "poll returned rc=%ld errno=%d:%s\n", rc, errno, strerror(errno));
    return (void*)rc;
#else // BSIM
    fprintf(stderr, "about to enter while(true)\n");
    while (true){
      sleep(0);
      for(int i = 0; i < numFds; i++){
	PortalRequest *instance = portal_requests[i];
	unsigned int addr = instance->ind_reg_base+0x20;
	struct memrequest foo = {false,addr,0};
	//fprintf(stderr, "sending read request\n");
	if (send(instance->p.read.s2, &foo, sizeof(foo), 0) == -1) {
	  fprintf(stderr, "(%s) send error\n", instance->name);
	  exit(1);
	}
	unsigned int queue_status;
	//fprintf(stderr, "about to get read response\n");
	if(recv(instance->p.read.s2, &queue_status, sizeof(queue_status), 0) == -1){
	  fprintf(stderr, "portalExec recv error (%s)\n", instance->name);
	  exit(1);	  
	}
	//fprintf(stderr, "(%s) queue_status : %08x\n", instance->name, queue_status);
	if (queue_status){
	  instance->indication->handleMessage(queue_status-1, instance);	
	}
      }
    }
#endif
}

