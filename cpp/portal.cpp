
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
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#ifdef ZYNQ
#include <android/log.h>
#include <zynqportal.h>
#else
#include <../drivers/pcieportal/pcieportal.h>
#endif

#include "portal.h"
#include "sock_utils.h"

#define MAX_TIMER_COUNT      16
#define TIMING_INTERVAL_SIZE  6

#define USE_INTERRUPTS
#ifdef USE_INTERRUPTS
#define ENABLE_INTERRUPTS(A) WRITEL(A, &((A)->map_base[IND_REG_INTERRUPT_MASK]), 1)
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

static PortalPoller *defaultPoller = new PortalPoller();
static Directory dir;
static Directory *pdir;
static uint64_t c_start[MAX_TIMER_COUNT];

void start_timer(unsigned int i) 
{
  assert(i < MAX_TIMER_COUNT);
  c_start[i] = pdir->cycle_count();
}

static uint64_t lap_timer_temp;
uint64_t lap_timer(unsigned int i)
{
  assert(i < MAX_TIMER_COUNT);
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
      if (timers[i].min != (1LL << 63))
           printf("[%d]: avg %" PRIu64 " min %" PRIu64 " max %" PRIu64 " over %" PRIu64 "\n",
               i, timers[i].total/loops, timers[i].min, timers[i].max, timers[i].over);
    }
}

unsigned int read_portal_bsim(int sockfd, volatile unsigned int *addr, char *name)
{
  unsigned int rv;
  struct memrequest foo = {false,addr,0};

  if (send(sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (%s) send error, errno=%s\n",__FUNCTION__, name, strerror(errno));
    exit(1);
  }
  if(recv(sockfd, &rv, sizeof(rv), 0) == -1){
    fprintf(stderr, "%s (%s) recv error\n",__FUNCTION__, name);
    exit(1);	  
  }
  return rv;
}

void write_portal_bsim(int sockfd, volatile unsigned int *addr, unsigned int v, char *name)
{
  struct memrequest foo = {true,addr,v};

  if (send(sockfd, &foo, sizeof(foo), 0) == -1) {
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
    p_read(p->p_read),
    p_write(p->p_write),
    name(strdup(p->name)),
    map_base(p->map_base)
{
}


PortalInternal::PortalInternal(int id)
  : fd(-1),
    map_base(0x0)
{
    int rc = 0;
    char buff[128];
    unsigned int addrbits = 16;
    volatile unsigned int * dev_base = 0;
    if (id == -1)     // opening Directory
      name = strdup("fpga0");
    else {
      sprintf(buff, "fpga%d", dir.get_fpga(id));
      addrbits = dir.get_addrbits(id);
      name = strdup(buff);
    }
#ifdef ZYNQ
    PortalEnableInterrupt intsettings = {3 << 14, (3 << 14) + 4};
    FILE *pgfile = fopen("/sys/devices/amba.0/f8007000.devcfg/prog_done", "r");
    if (!pgfile) {
        // 3.9 kernel uses amba.2
        pgfile = fopen("/sys/devices/amba.2/f8007000.devcfg/prog_done", "r");
    }
    if (pgfile == 0) {
	ALOGE("failed to open /sys/devices/amba.[02]/f8007000.devcfg/prog_done %d\n", errno);
	printf("failed to open /sys/devices/amba.[02]/f8007000.devcfg/prog_done %d\n", errno);
	rc = -1;
	goto errlab;
    }
    fgets(buff, sizeof(buff), pgfile);
    if (buff[0] != '1') {
	ALOGE("FPGA not programmed: %s\n", buff);
	printf("FPGA not programmed: %s\n", buff);
	rc = -ENODEV;
	goto errlab;
    }
    fclose(pgfile);
#endif
#ifdef MMAP_HW
    snprintf(buff, sizeof(buff), "/dev/%s", name);
#ifdef ZYNQ
    this->fd = ::open(buff, O_RDWR);
    ioctl(this->fd, PORTAL_ENABLE_INTERRUPT, &intsettings);
#else
    // FIXME: bluenoc driver only opens readonly for some reason
    this->fd = ::open(buff, O_RDONLY);
#endif
    if (this->fd < 0) {
	ALOGE("Failed to open %s fd=%d errno=%d\n", buff, this->fd, errno);
	rc = -errno;
	goto errlab;
    }
    dev_base = (volatile unsigned int*)mmap(NULL, 1<<addrbits, PROT_READ|PROT_WRITE, MAP_SHARED, this->fd, 0);
    if (dev_base == MAP_FAILED) {
        ALOGE("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", this->fd, errno);
        rc = -errno;
	goto errlab;
    }  
    map_base   = (volatile unsigned int*)dev_base;
#else
    connect_socket(&p_read, "%s_rc", name);
    connect_socket(&p_write, "%s_wc", name);
#endif

errlab:
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
    PortalClockRequest request;
    if (!numFds) {
	ALOGE("%s No fds open\n", __FUNCTION__);
	return -ENODEV;
    }
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
    if (!numFds) {
        ALOGE("portalExec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
    for (int i = 0; i < numFds; i++) {
      Portal *instance = portal_wrappers[i];
      //fprintf(stderr, "portalExec::enabling interrupts portal %d %s\n", i, instance->name);
      ENABLE_INTERRUPTS(instance);
    }
    fprintf(stderr, "portalExec::about to enter loop, numFds=%d\n", numFds);
    return NULL;
}
void PortalPoller::portalExec_end(void)
{
    stopping = 1;
    for (int i = 0; i < numFds; i++) {
      Portal *instance = portal_wrappers[i];
      fprintf(stderr, "portalExec::disabling interrupts portal %d %s\n", i, instance->name);
      WRITEL(instance, &(instance->map_base)[IND_REG_INTERRUPT_MASK], 0);
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
      volatile unsigned int *map_base = instance->map_base;
    
      // sanity check, to see the status of interrupt source and enable
      unsigned int queue_status;
    
      // handle all messasges from this portal instance
      while ((queue_status= READL(instance, &map_base[IND_REG_QUEUE_STATUS]))) {
        if(0) {
          unsigned int int_src = READL(instance, &map_base[IND_REG_INTERRUPT_FLAG]);
          unsigned int int_en  = READL(instance, &map_base[IND_REG_INTERRUPT_MASK]);
          unsigned int ind_count  = READL(instance, &map_base[IND_REG_INTERRUPT_COUNT]);
          fprintf(stderr, "(%d:%s) about to receive messages int=%08x en=%08x qs=%08x\n", i, instance->name, int_src, int_en, queue_status);
        }
        instance->handleMessage(queue_status-1);
	mcnt++;
      }
      // re-enable interrupt which was disabled by portal_isr
      ENABLE_INTERRUPTS(instance);
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

Directory::Directory() 
  : PortalInternal(-1), //"fpga0", 16),
    version(0),
    timestamp(0),
    addrbits(0),
    numportals(0),
    portal_ids(NULL),
    portal_types(NULL),
    counter_offset(0)
{
  pdir=this;
  
#ifdef ZYNQ /* There is no way to set userclock freq from host on PCIE */
  // start by setting the clock frequency (this only has any effect on the zynq platform)
  PortalClockRequest request;
  long reqF = 100000000; // 100 Mhz
  request.clknum = 0;
  request.requested_rate = reqF;
  int status = ioctl(fd, PORTAL_SET_FCLK_RATE, (long)&request);
  if (status < 0)
    fprintf(stderr, "Directory::Directory() error setting fclk0, errno=%d\n", errno);
  fprintf(stderr, "Directory::Directory() set fclk0 (%ld,%ld)\n", reqF, request.actual_rate);
#endif

  // finally scan
  scan(1);
}

void Directory::printDbgRequestIntervals()
{
  unsigned int i, c, j;
  uint64_t x[TIMING_INTERVAL_SIZE] = {0,0,0,0,0,0};
  fprintf(stderr, "Rd ");
  for(j = 0; j < 2; j++){
    for(i = 0; i < TIMING_INTERVAL_SIZE; i++){
      volatile unsigned int *addr = intervals_offset+(j * TIMING_INTERVAL_SIZE + i);
      c = READL(this, addr);
      x[i] = (((uint64_t)c) << 32) | (x[i] >> 32);
    }
  }

  for(i = 0; i < TIMING_INTERVAL_SIZE; i++){
    fprintf(stderr, "%016zx ", x[i]);
    if (i == 2)
      fprintf(stderr, "\nWr ");
  }
  fprintf(stderr, "\n");
}

void print_dbg_request_intervals()
{
  pdir->printDbgRequestIntervals();
}

uint64_t Directory::cycle_count()
{
  unsigned int high_bits = READL(this, counter_offset+0);
  unsigned int low_bits  = READL(this, counter_offset+1);
  return (((uint64_t)high_bits)<<32) | ((uint64_t)low_bits);
}
unsigned int Directory::get_fpga(unsigned int id)
{
  int i;
  for(i = 0; i < numportals; i++){
    if(portal_ids[i] == id)
      return i+1;
  }
  fprintf(stderr, "Directory::fpga(id=%d) id not found\n", id);
  exit(1);
}

unsigned int Directory::get_addrbits(unsigned int id)
{
  return addrbits;
}

void Directory::scan(int display)
{
  unsigned int i;
  if(display) fprintf(stderr, "Directory::scan(%s)\n", name);
  volatile unsigned int *ptr = &map_base[PORTAL_REQ_FIFO(0)+128];
  version    = READL(this, ptr++);
  timestamp  = READL(this, ptr++);
  numportals = READL(this, ptr++);
  addrbits   = READL(this, ptr++);
  portal_ids   = (unsigned int *)malloc(sizeof(portal_ids[0])*numportals);
  portal_types = (unsigned int *)malloc(sizeof(portal_types[0])*numportals);
  for(i = 0; (i < numportals) && (i < 32); i++){
    portal_ids[i] = READL(this, ptr++);
    portal_types[i] = READL(this, ptr++);
  }
  counter_offset = ptr;
  intervals_offset = ptr+2;
  if(display){
    fprintf(stderr, "version=%d\n",  version);
    fprintf(stderr, "timestamp=%s",  ctime(&timestamp));
    fprintf(stderr, "numportals=%d\n", numportals);
    fprintf(stderr, "addrbits=%d\n", addrbits);
    for(i = 0; i < numportals; i++)
      fprintf(stderr, "portal[%d]: ifcid=%d, ifctype=%08x\n", i, portal_ids[i], portal_types[i]);
  }
}

void Directory::traceStart()
{
#ifndef ZYNQ
  tTraceInfo traceInfo;
  traceInfo.trace = 1;
  int res = ioctl(fd,BNOC_TRACE,&traceInfo);
  if (res)
    fprintf(stderr, "Failed to start tracing. errno=%d\n", errno);
#endif
}

void Directory::traceStop()
{
#ifndef ZYNQ
  tTraceInfo traceInfo;
  traceInfo.trace = 0;
  int res = ioctl(fd,BNOC_TRACE,&traceInfo);
  if (res)
    fprintf(stderr, "Failed to stop tracing. errno=%d\n", errno);
#endif
}
void portalTrace_start()
{
  pdir->traceStart();
}
void portalTrace_stop()
{
  pdir->traceStop();
}
