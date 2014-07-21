
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

#ifndef _PORTAL_H_
#define _PORTAL_H_

#include <stdint.h>
#include <sys/types.h>
#include <linux/ioctl.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <assert.h>
#include <semaphore.h>
#include <pthread.h>

typedef unsigned long dma_addr_t;
#include "drivers/portalmem/portalmem.h"
#include "drivers/zynqportal/zynqportal.h"

#include "sock_utils.h"

struct memrequest{
  int write_flag;
  volatile unsigned int *addr;
  unsigned int data;
};

#define MAX_TIMERS 50
typedef struct {
    uint64_t total, min, max, over;
} TIMETYPE;

class PortalInternalCpp
{
 public:
  PortalInternal pint;
  PortalInternalCpp(int id);
  virtual ~PortalInternalCpp();
};

class Portal : public PortalInternalCpp
{
 public:
  virtual ~Portal();
  Portal(int id, PortalPoller *poller = 0);
  virtual int handleMessage(unsigned int channel) { return 0; };
};

class PortalPoller {
private:
  Portal **portal_wrappers;
  struct pollfd *portal_fds;
  int numFds;
public:
  PortalPoller();
  int registerInstance(Portal *portal);
  int unregisterInstance(Portal *portal);
  void *portalExec_init(void);
  void *portalExec_poll(int timeout);
  void *portalExec_event(void);
  void portalExec_end(void);
  void portalExec_start();
  int portalExec_timeout;
  int stopping;
  sem_t sem_startup;

  void* portalExec(void* __x);
  int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
};

class Directory : public PortalInternalCpp
{
 private:
  unsigned int version;
  time_t timestamp;
  unsigned int addrbits;
  unsigned int numportals;
  unsigned int *portal_ids;
  unsigned int *portal_types;
  volatile unsigned int *counter_offset;
  volatile unsigned int *intervals_offset;
 public:
  Directory();
  void scan(int display);
  unsigned int get_fpga(unsigned int id);
  unsigned int get_addrbits(unsigned int id);
  uint64_t cycle_count();
  void printDbgRequestIntervals();
  void traceStart();
  void traceStop();
};

void start_timer(unsigned int i);
uint64_t lap_timer(unsigned int i);
void print_dbg_request_intervals();
void init_timer(void);
uint64_t catch_timer(unsigned int i);
void print_timer(int loops);

// uses the default poller
void* portalExec(void* __x);
/* fine grained functions for building custom portalExec */
void* portalExec_init(void);
void* portalExec_poll(int timeout);
void* portalExec_event(void);
void portalExec_start();
void portalExec_end(void);
void portalTrace_start();
void portalTrace_stop();
extern int portalExec_timeout;

extern Directory globalDirectory;

#endif // _PORTAL_H_
