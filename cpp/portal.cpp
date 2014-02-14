
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
#include <time.h>

#ifdef ZYNQ
#include <android/log.h>
#endif

#include "portal.h"
#include "sock_utils.h"
#include "sock_fd.h"

PortalWrapper **portal_wrappers = 0;
struct pollfd *portal_fds = 0;
int numFds = 0;
Directory dir;
Directory *pdir;
unsigned long long c_start[16];

#ifdef ZYNQ
#define ALOGD(fmt, ...) __android_log_print(ANDROID_LOG_DEBUG, "PORTAL", fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "PORTAL", fmt, __VA_ARGS__)
#else
#define ALOGD(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#endif

void start_timer(unsigned int i) 
{
  assert(i < 16);
  c_start[i] = pdir->cycle_count();
}

unsigned long long stop_timer(unsigned int i)
{
  assert(i < 16);
  unsigned long long rv = pdir->cycle_count() - c_start[i];
  fprintf(stderr, "search time (hw cycles): %lld\n", rv);
  return rv;
}

unsigned int read_portal(portal *p, unsigned int addr, char *name)
{
  unsigned int rv;
  struct memrequest foo = {false,addr,0};

  if (send(p->read.s2, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (%s) send error, errno=%s\n",__FUNCTION__, name, strerror(errno));
    exit(1);
  }

  //fprintf(stderr, "read_portal: %s %x\n", p->read.path, addr);


  if(recv(p->read.s2, &rv, sizeof(rv), 0) == -1){
    fprintf(stderr, "%s (%s) recv error\n",__FUNCTION__, name);
    exit(1);	  
  }

  return rv;
}

void write_portal(portal *p, unsigned int addr, unsigned int v, char *name)
{
  struct memrequest foo = {true,addr,v};

  if (send(p->write.s2, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (%s) send error\n",__FUNCTION__, name);
    //exit(1);
  }

}

void Portal::close()
{
    if (fd > 0) {
        ::close(fd);
        fd = -1;
    }    
}

Portal::Portal(Portal *p)
  : fd(p->fd),
    ind_reg_base(p->ind_reg_base),
    ind_fifo_base(p->ind_fifo_base),
    req_reg_base(p->req_reg_base),
    req_fifo_base(p->req_fifo_base),
    name(strdup(p->name)),
    p(p->p)
{}


Portal::Portal(const char *devname, unsigned int addrbits)
  : fd(-1),
    ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0),
    name(strdup(devname))
{
  int rc = open(addrbits);
  if (rc != 0) {
    printf("[%s:%d] failed to open Portal %s\n", __FUNCTION__, __LINE__, name);
    ALOGD("Portal::Portal failure rc=%d\n", rc);
    exit(1);
  }
}
Portal::Portal(int id)
  : fd(-1),
    ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0)
{
  char buff[128];
  sprintf(buff, "fpga%d", dir.get_fpga(id));
  name = strdup(buff);
  int rc = open(dir.get_addrbits(id));
  if (rc != 0) {
    printf("[%s:%d] failed to open Portal %s\n", __FUNCTION__, __LINE__, name);
    ALOGD("Portal::Portal failure rc=%d\n", rc);
    exit(1);
  }
}

Portal::~Portal()
{
  close();
  free(name);
}


int Portal::open(int addrbits)
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
    volatile unsigned int *dev_base = (volatile unsigned int*)mmap(NULL, 1<<addrbits, PROT_READ|PROT_WRITE, MAP_SHARED, this->fd, 0);
    if (dev_base == MAP_FAILED) {
      ALOGE("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", this->fd, errno);
      return -errno;
    }  
    ind_reg_base   = (volatile unsigned int*)(((unsigned long)dev_base)+(3<<14));
    ind_fifo_base  = (volatile unsigned int*)(((unsigned long)dev_base)+(2<<14));
    req_reg_base   = (volatile unsigned int*)(((unsigned long)dev_base)+(1<<14));
    req_fifo_base  = (volatile unsigned int*)(((unsigned long)dev_base)+(0<<14));

    fprintf(stderr, "Portal::enabling interrupts %s\n", name);
    *(ind_reg_base+0x1) = 1;
 
#else
    p = (struct portal*)malloc(sizeof(struct portal));
    snprintf(p->read.path, sizeof(p->read.path), "%s_rc", name);
    connect_socket(&(p->read));
    snprintf(p->write.path, sizeof(p->read.path), "%s_wc", name);
    connect_socket(&(p->write));

    unsigned long dev_base = 0;
    ind_reg_base   = dev_base+(3<<14);
    ind_fifo_base  = dev_base+(2<<14);
    req_reg_base   = dev_base+(1<<14);
    req_fifo_base  = dev_base+(0<<14);

    fprintf(stderr, "Portal::enabling interrupts %s\n", name);
    unsigned int addr = ind_reg_base+0x4;
    write_portal(p, addr, 1, name);
      
#endif
    return 0;
}

int Portal::sendMessage(PortalMessage *msg)
{

  // TODO: this intermediate buffer (and associated copy) should be removed (mdk)
  unsigned int buf[128];
  msg->marshall(buf);

  // mutex_lock(&portal_data->reg_mutex);
  // mutex_unlock(&portal_data->reg_mutex);
#ifdef MMAP_HW
  if (0) {
    volatile unsigned int *addr = (volatile unsigned int *)req_reg_base;
    fprintf(stderr, "requestFiredCount=%x outOfRangeWriteCount=%x\n",addr[0], addr[1]);
    //addr[2] = 0xffffffff;
  }
#endif
  for (int i = msg->size()/4-1; i >= 0; i--) {
    unsigned int data = buf[i];
#ifdef MMAP_HW
    unsigned long addr = ((unsigned long)req_fifo_base) + msg->channel * 256;
    //fprintf(stderr, "%08lx %08x\n", addr, data);
    *((volatile unsigned int*)addr) = data;
#else
    unsigned int addr = req_fifo_base + msg->channel * 256;
    write_portal(p, addr, data, name);
    //fprintf(stderr, "(%s) sendMessage\n", name);
#endif
  }
#ifdef MMAP_HW
  if (0)
  for (int i = 0; i < 3; i++) {
    volatile unsigned int *addr = (volatile unsigned int *)req_reg_base;
    fprintf(stderr, "requestFiredCount=%x outOfRangeWriteCount=%x getWordCount=%x putWordCount=%x putEnable=%x\n",addr[0], addr[1], addr[7], addr[8], addr[2]);
  }
#endif
  return 0;
}



PortalWrapper::PortalWrapper(int id) 
  : Portal(id)
{
  registerInstance();
}

PortalWrapper::PortalWrapper(Portal *p) 
  : Portal(p)
{
  registerInstance();
}

PortalWrapper::PortalWrapper(const char *devname, unsigned int addrbits)
  : Portal(devname,addrbits)
{
  registerInstance();
}

PortalWrapper::~PortalWrapper()
{
  unregisterInstance();
}

PortalProxy::PortalProxy(int id)
  : Portal(id)
{
}

PortalProxy::PortalProxy(const char *devname, unsigned int addrbits)
  : Portal(devname,addrbits)
{
}

PortalProxy::~PortalProxy()
{
}

int PortalWrapper::unregisterInstance()
{
  int i = 0;
  while(i < numFds)
    if(portal_fds[i].fd == this->fd)
      break;
    else
      i++;

  while(i < numFds-1){
    portal_fds[i] = portal_fds[i+1];
    portal_wrappers[i] = portal_wrappers[i+1];
  }

  numFds--;
  portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
  portal_wrappers = (PortalWrapper **)realloc(portal_wrappers, numFds*sizeof(PortalWrapper *));  
  return 0;
}

int PortalWrapper::registerInstance()
{
    numFds++;
    portal_wrappers = (PortalWrapper **)realloc(portal_wrappers, numFds*sizeof(PortalWrapper *));
    portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
    portal_wrappers[numFds-1] = this;
    struct pollfd *pollfd = &portal_fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = this->fd;
    pollfd->events = POLLIN;
    fprintf(stderr, "PortalWrapper::registerInstance %s\n", name);
    return 0;
}

int Portal::setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
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

void* portalExec_init(void)
{
#ifdef MMAP_HW
    if (!numFds) {
        ALOGE("portalExec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
#ifndef ZYNQ
    if (0)
    for (int i = 0; i < numFds; i++) {
      PortalWrapper *instance = portal_wrappers[i];
      fprintf(stderr, "portalExec::enabling interrupts portal %d\n", i);
      *(volatile int *)(instance->ind_reg_base+0x1) = 1;
    }
#endif
    fprintf(stderr, "portalExec::about to enter loop\n");
#else // BSIM
    fprintf(stderr, "about to enter bsim while(true), numFds=%d\n", numFds);
#endif
    return NULL;
}

void* portalExec_event(int timeout)
{
#ifdef MMAP_HW
    long rc = poll(portal_fds, numFds, timeout);
    if(rc >= 0) {
	for (int i = 0; i < numFds; i++) {
	  if (!portal_wrappers) {
	    fprintf(stderr, "No portal_instances but rc=%ld revents=%d\n", rc, portal_fds[i].revents);
	  }
	
	  PortalWrapper *instance = portal_wrappers[i];
	
	  // sanity check, to see the status of interrupt source and enable
	  unsigned int int_src = *(volatile int *)(instance->ind_reg_base+0x0);
	  unsigned int int_en  = *(volatile int *)(instance->ind_reg_base+0x1);
	  unsigned int ind_count  = *(volatile int *)(instance->ind_reg_base+0x2);
	  unsigned int queue_status = *(volatile int *)(instance->ind_reg_base+0x6);
	  if(0)
	  fprintf(stderr, "(%d) about to receive messages int=%08x en=%08x qs=%08x\n", i, int_src, int_en, queue_status);
	
	  // handle all messasges from this portal instance
	  while (queue_status) {
	    if(0)
	      fprintf(stderr, "queue_status %d\n", queue_status);
	    instance->handleMessage(queue_status-1);
	    int_src = *(volatile int *)(instance->ind_reg_base+0x0);
	    int_en  = *(volatile int *)(instance->ind_reg_base+0x1);
	    ind_count  = *(volatile int *)(instance->ind_reg_base+0x2);
	    queue_status = *(volatile int *)(instance->ind_reg_base+0x6);
	    if (0)
	      fprintf(stderr, "%d: int_src=%08x int_en=%08x ind_count=%08x queue_status=%08x\n",
		      __LINE__, int_src, int_en, ind_count, queue_status);
	  }
	
	  // rc of 0 indicates timeout
	  if (rc == 0) {
	    // do something if we timeout??
	  }
	  // re-enable interrupt which was disabled by portal_isr
	  *(instance->ind_reg_base+0x1) = 1;
	}
    } else {
	// return only in error case
	fprintf(stderr, "poll returned rc=%ld errno=%d:%s\n", rc, errno, strerror(errno));
	//return (void*)rc;
    }
#else // BSIM
    for(int i = 0; i < numFds; i++) {
	PortalWrapper *instance = portal_wrappers[i];
	unsigned int int_status_addr = instance->ind_reg_base+0x0;
	//fprintf(stderr, "AAAA: %x %s\n", int_status_addr, instance->name);
	unsigned int int_status = read_portal((instance->p), int_status_addr, instance->name);
	//fprintf(stderr, "BBBB: %d\n", int_status);
	if(int_status){
	  unsigned int queue_status_addr = instance->ind_reg_base+0x18;
	  unsigned int queue_status = read_portal((instance->p), queue_status_addr, instance->name);
	  if (queue_status){
	    //fprintf(stderr, "(%s) queue_status : %08x\n", instance->name, queue_status);
	    instance->handleMessage(queue_status-1);	
	  } else {
	    fprintf(stderr, "WARNING: int_status and queue_status are incoherent (%s)\n", instance->name);
	  }
	}
    }
#endif
    return NULL;
}

int portalExec_timeout;
void* portalExec(void* __x)
{
    portalExec_timeout = -1; // no interrupt timeout on Zynq platform
#ifndef ZYNQ
    portalExec_timeout = 100; // interrupts not working yet on PCIe
#endif
    void *rc = portalExec_init();
    while (!rc)
        rc = portalExec_event(portalExec_timeout);
    return rc;
}

Directory::Directory() 
  : Portal("fpga0", 16),
    version(0),
    timestamp(0),
    addrbits(0),
    numportals(0),
    portal_ids(NULL),
    portal_types(NULL),
    counter_offset(0)
{
  pdir=this;
  scan(1);
}

unsigned long long Directory::cycle_count()
{
#ifdef MMAP_HW
  unsigned int high_bits = *(counter_offset+0);
  unsigned int low_bits = *(counter_offset+1);
#else
  unsigned int high_bits = read_portal(p, (counter_offset+0), name);
  unsigned int low_bits = read_portal(p, (counter_offset+4), name);
#endif
  return (((unsigned long long)high_bits)<<32)|((unsigned long long)low_bits);
}
unsigned int Directory::get_fpga(unsigned int id)
{
  int i;
  for(i = 0; i < numportals; i++){
    if(portal_ids[i] == id)
      return i+1;
  }
  fprintf(stderr, "Directory::fpga(id=%d) id not found\n", id);
}

unsigned int Directory::get_addrbits(unsigned int id)
{
  return addrbits;
}

void Directory::scan(int display)
{
  unsigned int i;
  if(display) fprintf(stderr, "Directory::scan(%s)\n", name);
#ifdef MMAP_HW
  volatile unsigned int *ptr = req_fifo_base+128;
  version = *ptr;
  ptr++;
  timestamp = (long int)*ptr;
  ptr++;
  numportals = *ptr;
  ptr++;
  addrbits = *ptr;
  ptr++;
  portal_ids = (unsigned int *)malloc(sizeof(unsigned int)*numportals);
  portal_types = (unsigned int *)malloc(sizeof(unsigned int)*numportals);
  for(i = 0; (i < numportals) && (i < 32); i++){
    portal_ids[i] = *ptr;
    ptr++;
    portal_types[i] = *ptr;
    ptr++;
  }
  counter_offset = ptr;
#else
  unsigned int ptr = 128*4;
  version = read_portal(p, ptr, name);
  ptr += 4;
  timestamp = (long int)read_portal(p, ptr, name);
  ptr += 4;
  numportals = read_portal(p, ptr, name);
  ptr += 4;
  addrbits = read_portal(p, ptr, name);
  ptr += 4;
  portal_ids = (unsigned int *)malloc(sizeof(unsigned int)*numportals);
  portal_types = (unsigned int *)malloc(sizeof(unsigned int)*numportals);
  for(i = 0; (i < numportals) && (i < 32); i++){
    portal_ids[i] = read_portal(p, ptr, name);
    ptr += 4;
    portal_types[i] = read_portal(p, ptr, name);
    ptr += 4;
  }
  counter_offset = ptr;
#endif
  if(display){
    fprintf(stderr, "version=%d\n",  version);
    fprintf(stderr, "timestamp=%s",  ctime(&timestamp));
    fprintf(stderr, "numportals=%d\n", numportals);
    fprintf(stderr, "addrbits=%d\n", addrbits);
    for(i = 0; i < numportals; i++)
      fprintf(stderr, "portal[%d]: ifcid=%d, ifctype=%08x\n", i, portal_ids[i], portal_types[i]);
  }
}

