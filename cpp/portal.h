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
#include <bitset>
#include <assert.h>
#include <semaphore.h>
#include <pthread.h>

typedef unsigned long dma_addr_t;
#include "drivers/portalmem/portalmem.h"
#include "drivers/zynqportal/zynqportal.h"

#include "sock_utils.h"

struct memrequest{
  bool write;
  unsigned int addr;
  unsigned int data;
};

#define MAX_TIMERS 50
typedef struct {
    uint64_t total, min, max, over;
} TIMETYPE;

class PortalPoller;
class PortalMessage 
{
 public:
  size_t channel;
  // size of bsv bit-representation in bytes
  virtual size_t size() = 0; 
  // convert to bsv bit-representation
  virtual void marshall(unsigned int *buff) = 0;
  // convert from bsv bit representation
  virtual void demarshall(unsigned int *buff) = 0;
  // invoke the corresponding indication message
  virtual void indicate(void* ind) = 0;
  virtual ~PortalMessage() {};
}; 

class PortalInternal
{
 public:
  PortalPoller *poller;
 public:
  int portalOpen(int length);
  void portalClose();
  PortalInternal(int id);
  PortalInternal(PortalInternal* p);
  PortalInternal(const char *name, unsigned int addrbits);
  ~PortalInternal();
  int fd;
  struct portal *p;
  char *name;
#ifdef MMAP_HW
  volatile unsigned int *ind_reg_base;
  volatile unsigned int *ind_fifo_base;
  volatile unsigned int *req_reg_base;
  volatile unsigned int *req_fifo_base;
#else
  unsigned int ind_reg_base;
  unsigned int ind_fifo_base;
  unsigned int req_reg_base;
  unsigned int req_fifo_base;
#endif
  int sendMessage(PortalMessage *msg);
};
class Portal : public PortalInternal
{
 public:
  ~Portal();
  Portal(PortalInternal *p, PortalPoller *poller = 0);
  Portal(int id, PortalPoller *poller = 0);
  Portal(const char* devname, unsigned int addrbits, PortalPoller *poller = 0);
  virtual int handleMessage(unsigned int channel) {};
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
  void *portalExec_event(int timeout);
  void portalExec_end(void);
  void portalExec_start();
  int portalExec_timeout;
  int stopping;
  sem_t sem_startup;

  void* portalExec(void* __x);
  int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
};

class Directory : public PortalInternal
{
 private:
  unsigned int version;
  time_t timestamp;
  unsigned int addrbits;
  unsigned int numportals;
  unsigned int *portal_ids;
  unsigned int *portal_types;
#ifdef MMAP_HW
  volatile unsigned int *counter_offset;
  volatile unsigned int *intervals_offset;
#else
  unsigned int counter_offset;
  unsigned int intervals_offset;
#endif
 public:
  Directory(const char* devname, unsigned int addrbits);
  Directory();
  void scan(int display);
  unsigned int get_fpga(unsigned int id);
  unsigned int get_addrbits(unsigned int id);
  uint64_t cycle_count();
  void printDbgRequestIntervals();
};

unsigned int read_portal(portal *p, unsigned int addr, char *name);
void write_portal(portal *p, unsigned int addr, unsigned int v, char *name);

void start_timer(unsigned int i);
uint64_t lap_timer(unsigned int i);
void print_dbg_request_intervals();
void init_timer(void);
uint64_t catch_timer(int i);
void print_timer(int loops);

// uses the default poller
void* portalExec(void* __x);
/* fine grained functions for building custom portalExec */
//void* portalExec_init(void);
//void* portalExec_event(int timeout);
void portalExec_start();
void portalExec_end(void);
extern int portalExec_timeout;

#endif // _PORTAL_H_
