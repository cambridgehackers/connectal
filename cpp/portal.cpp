
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
#include <pcieportal.h> // BNOC_TRACE
#endif

#include "portal.h"
#include "sock_utils.h"

#define MAX_TIMER_COUNT      16
#define TIMING_INTERVAL_SIZE  6

#define USE_INTERRUPTS
#ifdef USE_INTERRUPTS
#define ENABLE_INTERRUPTS(A) WRITEL((A), &((A)->map_base[IND_REG_INTERRUPT_MASK]), 1)
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

Directory globalDirectory;

static PortalPoller *defaultPoller = new PortalPoller();
static uint64_t c_start[MAX_TIMER_COUNT];
static uint64_t lap_timer_temp;
static TIMETYPE timers[MAX_TIMERS];

void start_timer(unsigned int i) 
{
  assert(i < MAX_TIMER_COUNT);
  c_start[i] = globalDirectory.cycle_count();
}

uint64_t lap_timer(unsigned int i)
{
  assert(i < MAX_TIMER_COUNT);
  uint64_t temp = globalDirectory.cycle_count();
  lap_timer_temp = temp;
  return temp - c_start[i];
}

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

void init_portal_internal(PortalInternal *pint, int fpga_number, int addrbits)
{
    int rc = 0;
    char buff[128];
    volatile unsigned int * dev_base = 0;
    pint->fpga_number = fpga_number;
    pint->fpga_fd = -1;
    pint->map_base = 0x0;
    pint->parent = NULL;
    sprintf(buff, "fpga%d", pint->fpga_number);
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
    snprintf(buff, sizeof(buff), "/dev/fpga%d", pint->fpga_number);
#ifdef ZYNQ
    pint->fpga_fd = ::open(buff, O_RDWR);
    ioctl(pint->fpga_fd, PORTAL_ENABLE_INTERRUPT, &intsettings);
#else
    // FIXME: bluenoc driver only opens readonly for some reason
    pint->fpga_fd = ::open(buff, O_RDONLY);
#endif
    if (pint->fpga_fd < 0) {
	ALOGE("Failed to open %s fd=%d errno=%d\n", buff, pint->fpga_fd, errno);
	rc = -errno;
	goto errlab;
    }
    dev_base = (volatile unsigned int*)mmap(NULL, 1<<addrbits, PROT_READ|PROT_WRITE, MAP_SHARED, pint->fpga_fd, 0);
    if (dev_base == MAP_FAILED) {
        ALOGE("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", pint->fpga_fd, errno);
        rc = -errno;
	goto errlab;
    }  
    pint->map_base   = (volatile unsigned int*)dev_base;
#else
    connect_socket(&pint->p_read, "fpga%d_rc", pint->fpga_number);
    connect_socket(&pint->p_write, "fpga%d_wc", pint->fpga_number);
#endif

errlab:
    if (rc != 0) {
      printf("[%s:%d] failed to open Portal fpga%d\n", __FUNCTION__, __LINE__, pint->fpga_number);
      ALOGD("PortalInternalCpp::PortalInternalCpp failure rc=%d\n", rc);
      exit(1);
    }
}

PortalInternalCpp::PortalInternalCpp(int id)
{
    unsigned int addrbits = 16, fpga_number = 0;
    if (id != -1) {    // not Directory
      fpga_number = globalDirectory.get_fpga(id);
      addrbits = globalDirectory.get_addrbits(id);
    }
    init_portal_internal(&pint, fpga_number, addrbits);
    pint.parent = (void *)this; /* used for callback functions */
}

PortalInternalCpp::~PortalInternalCpp()
{
    if (pint.fpga_fd > 0) {
        ::close(pint.fpga_fd);
        pint.fpga_fd = -1;
    }    
}

Portal::Portal(int id, PortalPoller *poller)
  : PortalInternalCpp(id)
{
  if (poller == 0)
    poller = defaultPoller;
  pint.poller = poller;
  pint.poller->registerInstance(this);
}

Portal::~Portal()
{
  pint.poller->unregisterInstance(this);
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
    if(portal_fds[i].fd == portal->pint.fpga_fd)
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
    pollfd->fd = portal->pint.fpga_fd;
    pollfd->events = POLLIN;
    fprintf(stderr, "Portal::registerInstance fpga%d\n", portal->pint.fpga_number);
    return 0;
}

int PortalPoller::setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
{
    int status = 0;
    if (!numFds) {
	ALOGE("%s No fds open\n", __FUNCTION__);
	return -ENODEV;
    }
#ifdef ZYNQ
    PortalClockRequest request;
    request.clknum = clkNum;
    request.requested_rate = requestedFrequency;
    status = ioctl(portal_fds[0].fd, PORTAL_SET_FCLK_RATE, (long)&request);
    if (status == 0 && actualFrequency)
	*actualFrequency = request.actual_rate;
    if (status < 0)
	status = errno;
#endif
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
      //fprintf(stderr, "portalExec::enabling interrupts portal %d fpga%d\n", i, instance->pint.fpga_number);
      ENABLE_INTERRUPTS(&instance->pint);
    }
    fprintf(stderr, "portalExec::about to enter loop, numFds=%d\n", numFds);
    return NULL;
}
void PortalPoller::portalExec_end(void)
{
    stopping = 1;
    for (int i = 0; i < numFds; i++) {
      Portal *instance = portal_wrappers[i];
      fprintf(stderr, "portalExec::disabling interrupts portal %d fpga%d\n", i, instance->pint.fpga_number);
      WRITEL(&instance->pint, &(instance->pint.map_base)[IND_REG_INTERRUPT_MASK], 0);
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
      volatile unsigned int *map_base = instance->pint.map_base;
    
      // sanity check, to see the status of interrupt source and enable
      unsigned int queue_status;
    
      // handle all messasges from this portal instance
      while ((queue_status= READL(&instance->pint, &map_base[IND_REG_QUEUE_STATUS]))) {
        if(0) {
          unsigned int int_src = READL(&instance->pint, &map_base[IND_REG_INTERRUPT_FLAG]);
          unsigned int int_en  = READL(&instance->pint, &map_base[IND_REG_INTERRUPT_MASK]);
          unsigned int ind_count  = READL(&instance->pint, &map_base[IND_REG_INTERRUPT_COUNT]);
          fprintf(stderr, "(%d:fpga%d) about to receive messages int=%08x en=%08x qs=%08x\n", i, instance->pint.fpga_number, int_src, int_en, queue_status);
        }
        instance->handleMessage(queue_status-1);
	mcnt++;
      }
      // re-enable interrupt which was disabled by portal_isr
      ENABLE_INTERRUPTS(&instance->pint);
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
  : PortalInternalCpp(-1)
{
#ifdef ZYNQ /* There is no way to set userclock freq from host on PCIE */
  // start by setting the clock frequency (this only has any effect on the zynq platform)
  PortalClockRequest request;
  long reqF = 100000000; // 100 Mhz
  request.clknum = 0;
  request.requested_rate = reqF;
  int status = ioctl(pint.fpga_fd, PORTAL_SET_FCLK_RATE, (long)&request);
  if (status < 0)
    fprintf(stderr, "Directory::Directory() error setting fclk0, errno=%d\n", errno);
  fprintf(stderr, "Directory::Directory() set fclk0 (%ld,%ld)\n", reqF, request.actual_rate);
#endif

  // finally scan
  unsigned int i;
  if(1) fprintf(stderr, "Directory::scan(fpga%d)\n", pint.fpga_number);
  if(1){
    time_t timestamp  = READL(&pint, PORTAL_DIRECTORY_TIMESTAMP);
    uint32_t numportals = READL(&pint, PORTAL_DIRECTORY_NUMPORTALS);
    fprintf(stderr, "version=%d\n",  READL(&pint, PORTAL_DIRECTORY_VERSION));
    fprintf(stderr, "timestamp=%s",  ctime(&timestamp));
    fprintf(stderr, "numportals=%d\n", numportals);
    fprintf(stderr, "addrbits=%d\n", READL(&pint, PORTAL_DIRECTORY_ADDRBITS));
    for(i = 0; (i < numportals) && (i < 32); i++)
      fprintf(stderr, "portal[%d]: ifcid=%d, ifctype=%08x\n", i, READL(&pint, PORTAL_DIRECTORY_PORTAL_ID(i)), READL(&pint, PORTAL_DIRECTORY_PORTAL_TYPE(i)));
  }
}

uint64_t Directory::cycle_count()
{
  unsigned int high_bits = READL(&pint, PORTAL_DIRECTORY_COUNTER_MSB);
  unsigned int low_bits  = READL(&pint, PORTAL_DIRECTORY_COUNTER_LSB);
  return (((uint64_t)high_bits)<<32) | ((uint64_t)low_bits);
}
unsigned int Directory::get_fpga(unsigned int id)
{
  int i;
  int numportals = READL(&pint, PORTAL_DIRECTORY_NUMPORTALS);
  for(i = 0; i < numportals; i++){
    if(READL(&pint, PORTAL_DIRECTORY_PORTAL_ID(i)) == id)
      return i+1;
  }
  fprintf(stderr, "Directory::fpga(id=%d) id not found\n", id);
  exit(1);
}

unsigned int Directory::get_addrbits(unsigned int id)
{
  return READL(&pint, PORTAL_DIRECTORY_ADDRBITS);
}

void portalTrace_start()
{
#ifndef ZYNQ
  tTraceInfo traceInfo;
  traceInfo.trace = 1;
  int res = ioctl(globalDirectory.pint.fpga_fd,BNOC_TRACE,&traceInfo);
  if (res)
    fprintf(stderr, "Failed to start tracing. errno=%d\n", errno);
#endif
}
void portalTrace_stop()
{
#ifndef ZYNQ
  tTraceInfo traceInfo;
  traceInfo.trace = 0;
  int res = ioctl(globalDirectory.pint.fpga_fd,BNOC_TRACE,&traceInfo);
  if (res)
    fprintf(stderr, "Failed to stop tracing. errno=%d\n", errno);
#endif
}
