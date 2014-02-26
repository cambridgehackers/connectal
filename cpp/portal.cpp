
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
#include <pthread.h>
#include <semaphore.h>

#ifdef ZYNQ
#include <android/log.h>
#endif

#include "portal.h"
#include "sock_utils.h"
#include "sock_fd.h"

static PortalPoller *defaultPoller = new PortalPoller();
static Directory dir;
static Directory *pdir;
static uint64_t c_start[16];

#define USE_INTERRUPTS
#ifdef USE_INTERRUPTS
#define ENABLE_INTERRUPTS(A) ((A)[1] = 1)
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

void print_dbg_request_intervals()
{
  pdir->printDbgRequestIntervals();
}

void start_timer(unsigned int i) 
{
  assert(i < 16);
  c_start[i] = pdir->cycle_count();
}

static uint64_t lap_timer_temp;
uint64_t lap_timer(unsigned int i)
{
  assert(i < 16);
  uint64_t temp = pdir->cycle_count();
  lap_timer_temp = temp;
  return temp - c_start[i];
}

static TIMETYPE timers[MAX_TIMERS];

void init_timer(void)
{
    memset(timers, 0, sizeof(timers));
    for (int i = 0; i < MAX_TIMERS; i++)
      timers[i].min = 1LL << 63;
}

uint64_t catch_timer(unsigned int i)
{
    uint64_t val = lap_timer(0);
    if (i >= MAX_TIMERS)
        return 0;
    if (val > timers[i].max)
        timers[i].max = val;
    if (val < timers[i].min)
        timers[i].min = val;
    if (val == 000000)
        timers[i].over++;
    timers[i].total += val;
    return lap_timer_temp;
}
void print_timer(int loops)
{
    for (int i = 0; i < MAX_TIMERS; i++) {
      if ((timers[i].min != (1LL << 63)))
           printf("[%d]: avg %lld min %lld max %lld over %lld\n",
               i, timers[i].total/loops, timers[i].min, timers[i].max, timers[i].over);
    }
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

void PortalInternal::portalClose()
{
    if (fd > 0) {
        ::close(fd);
        fd = -1;
    }    
}

PortalInternal::PortalInternal(PortalInternal *p)
  : fd(p->fd),
    ind_reg_base(p->ind_reg_base),
    ind_fifo_base(p->ind_fifo_base),
    req_reg_base(p->req_reg_base),
    req_fifo_base(p->req_fifo_base),
    name(strdup(p->name)),
    p(p->p)
{
}


PortalInternal::PortalInternal(int id)
  : fd(-1),
    ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0)
{
  char buff[128];
  sprintf(buff, "fpga%d", dir.get_fpga(id));
  name = strdup(buff);
  int rc = portalOpen(dir.get_addrbits(id));
  if (rc != 0) {
    printf("[%s:%d] failed to open Portal %s\n", __FUNCTION__, __LINE__, name);
    ALOGD("PortalInternal::PortalInternal failure rc=%d\n", rc);
    exit(1);
  }
}

PortalInternal::PortalInternal(const char* devname, unsigned int addrbits)
  : fd(-1),
    ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0)
{
  name = strdup(devname);
  int rc = portalOpen(addrbits);
  if (rc != 0) {
    printf("[%s:%d] failed to open Portal %s\n", __FUNCTION__, __LINE__, name);
    ALOGD("PortalInternal::PortalInternal failure rc=%d\n", rc);
    exit(1);
  }
}

PortalInternal::~PortalInternal()
{
  portalClose();
  free(name);
}


int PortalInternal::portalOpen(int addrbits)
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
    req_fifo_base  = (volatile unsigned int*)(((unsigned char *)dev_base)+(0<<14));
    req_reg_base   = (volatile unsigned int*)(((unsigned char *)dev_base)+(1<<14));
    ind_fifo_base  = (volatile unsigned int*)(((unsigned char *)dev_base)+(2<<14));
    ind_reg_base   = (volatile unsigned int*)(((unsigned char *)dev_base)+(3<<14));
 
#else
    p = (struct portal*)malloc(sizeof(struct portal));
    snprintf(p->read.path, sizeof(p->read.path), "%s_rc", name);
    connect_socket(&(p->read));
    snprintf(p->write.path, sizeof(p->read.path), "%s_wc", name);
    connect_socket(&(p->write));

    uint32_t dev_base = 0;
    req_fifo_base  = dev_base+(0<<14);
    req_reg_base   = dev_base+(1<<14);
    ind_fifo_base  = dev_base+(2<<14);
    ind_reg_base   = dev_base+(3<<14);

    unsigned int addr = ind_reg_base+0x4;
    write_portal(p, addr, 1, name);
      
#endif
    return 0;
}

int PortalInternal::sendMessage(PortalMessage *msg)
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
    volatile unsigned int *addr = (volatile unsigned int *)(((unsigned char *)req_fifo_base) + msg->channel * 256);
    *addr = data;   /* send request data to the hardware! */
#if 0
    uint64_t after_requestt = catch_timer(12);
    pdir->printDbgRequestIntervals();
#endif
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

Portal::Portal(int id, PortalPoller *poller)
  : PortalInternal(id)
{
  if (poller == 0)
    poller = defaultPoller;
  this->poller = poller;
  poller->registerInstance(this);
}

Portal::Portal(PortalInternal *p, PortalPoller *poller) 
  : PortalInternal(p)
{
  if (poller == 0)
    poller = defaultPoller;
  this->poller = poller;
  poller->registerInstance(this);
}

Portal::~Portal()
{
  poller->unregisterInstance(this);
}

PortalPoller::PortalPoller()
  : portal_wrappers(0), portal_fds(0), numFds(0), stopping(0)
{
    sem_init(&sem_startup, 0, 0);
}

int PortalPoller::unregisterInstance(Portal *portal)
{
  int i = 0;
  while(i < numFds)
    if(portal_fds[i].fd == portal->fd)
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
    pollfd->fd = portal->fd;
    pollfd->events = POLLIN;
    fprintf(stderr, "Portal::registerInstance %s\n", portal->name);
    return 0;
}

int PortalPoller::setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
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

void* PortalPoller::portalExec_init(void)
{
#ifdef USE_INTERRUPTS
    portalExec_timeout = -1; // no interrupt timeout 
#else
    portalExec_timeout = 100;
#endif
#ifdef MMAP_HW
    if (!numFds) {
        ALOGE("portalExec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
    for (int i = 0; i < numFds; i++) {
      Portal *instance = portal_wrappers[i];
      fprintf(stderr, "portalExec::enabling interrupts portal %d %s\n", i, instance->name);
      ENABLE_INTERRUPTS(instance->ind_reg_base);
    }
    fprintf(stderr, "portalExec::about to enter loop\n");
#else // BSIM
    fprintf(stderr, "about to enter bsim while(true), numFds=%d\n", numFds);
#endif
    return NULL;
}
void PortalPoller::portalExec_end(void)
{
    stopping = 1;
#ifdef MMAP_HW
    for (int i = 0; i < numFds; i++) {
      Portal *instance = portal_wrappers[i];
      fprintf(stderr, "portalExec::disabling interrupts portal %d %s\n", i, instance->name);
      (instance->ind_reg_base)[1] = 0;
    }
#endif
}

void* PortalPoller::portalExec_event(int timeout)
{
#ifdef MMAP_HW
    long rc = 0;
    // LCS bypass the call to poll if the timeout is 0
    if (timeout != 0)
      rc = poll(portal_fds, numFds, timeout);
    if(rc >= 0) {
	for (int i = 0; i < numFds; i++) {
	  if (!portal_wrappers) {
	    fprintf(stderr, "No portal_instances but rc=%ld revents=%d\n", rc, portal_fds[i].revents);
	  }
	
	  Portal *instance = portal_wrappers[i];
	  volatile unsigned int *ind_reg_base = instance->ind_reg_base;
	
	  // sanity check, to see the status of interrupt source and enable
	  unsigned int queue_status;
	
	  // handle all messasges from this portal instance
	  while ((queue_status= ind_reg_base[6])) {
	    if(0) {
	      unsigned int int_src = ind_reg_base[0];
	      unsigned int int_en  = ind_reg_base[1];
	      unsigned int ind_count  = ind_reg_base[2];
	      fprintf(stderr, "(%d:%s) about to receive messages int=%08x en=%08x qs=%08x\n", i, instance->name, int_src, int_en, queue_status);
	    }
	    instance->handleMessage(queue_status-1);
	  }
	  // re-enable interrupt which was disabled by portal_isr
	  ENABLE_INTERRUPTS(ind_reg_base);
	}
    } else {
	// return only in error case
	fprintf(stderr, "poll returned rc=%ld errno=%d:%s\n", rc, errno, strerror(errno));
	//return (void*)rc;
    }
#else // BSIM
    for(int i = 0; i < numFds; i++) {
	Portal *instance = portal_wrappers[i];
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

void* PortalPoller::portalExec(void* __x)
{
    void *rc = portalExec_init();
    sem_post(&sem_startup);
    while (!rc && !stopping)
        rc = portalExec_event(portalExec_timeout);
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

void* portalExec_event(int timeout)
{
  return defaultPoller->portalExec_event(timeout);
}

void portalExec_end(void)
{
  defaultPoller->portalExec_end();
}

static void *pthread_worker(void *__x)
{
    ((PortalPoller *)__x)->portalExec(__x);
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

Directory::Directory() 
  : PortalInternal("fpga0", 16),
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

void Directory::printDbgRequestIntervals()
{
  unsigned int i, c, j;
  uint64_t x[6] = {0,0,0,0,0,0};
  fprintf(stderr, "Rd ");
  for(j = 0; j < 2; j++){
    for(i = 0; i < 6; i++){
#ifdef MMAP_HW
      c = *(intervals_offset+(j * 6 + i));
#else
      unsigned int addr = intervals_offset+((j * 6 + i)*4);
      c = read_portal(p, addr, name);
#endif
      x[i] = (((uint64_t)c) << 32) | (x[i] >> 32);
    }
  }

  for(i = 0; i < 6; i++){
    fprintf(stderr, "%016zx ", x[i]);
    if (i == 2)
      fprintf(stderr, "\nWr ");
  }
  fprintf(stderr, "\n");
}

uint64_t Directory::cycle_count()
{
#ifdef MMAP_HW
  unsigned int high_bits = counter_offset[0];
  unsigned int low_bits = counter_offset[1];
#else
  unsigned int high_bits = read_portal(p, (counter_offset+0), name);
  unsigned int low_bits = read_portal(p, (counter_offset+4), name);
#endif
  return (((uint64_t)high_bits)<<32)|((uint64_t)low_bits);
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
  version = *ptr++;
  timestamp = (long int)*ptr++;
  numportals = *ptr++;
  addrbits = *ptr++;
  portal_ids = (unsigned int *)malloc(sizeof(portal_ids[0])*numportals);
  portal_types = (unsigned int *)malloc(sizeof(portal_types[0])*numportals);
  for(i = 0; (i < numportals) && (i < 32); i++){
    portal_ids[i] = *ptr++;
    portal_types[i] = *ptr++;
  }
  counter_offset = ptr;
  intervals_offset = ptr+2;
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
  intervals_offset = ptr+8;
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

