#ifndef _PORTAL_H_
#define _PORTAL_H_

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

#include "drivers/portalmem/portalmem.h"
#include "drivers/zynqportal/zynqportal.h"

#include "sock_utils.h"

struct memrequest{
  bool write;
  unsigned int addr;
  unsigned int data;
};

unsigned int read_portal(portal *p, unsigned int addr, char *name);
void write_portal(portal *p, unsigned int addr, unsigned int v, char *name);
void start_timer(unsigned int i);
unsigned long long lap_timer(unsigned int i);
void print_dbg_requeste_intervals();

#define MAX_TIMERS 50
typedef struct {
    unsigned long long total, min, max, over;
} TIMETYPE;

void init_timer(void);
void catch_timer(int i);
void print_timer(int loops);

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

void* portalExec(void* __x);
/* fine grained functions for building custom portalExec */
void* portalExec_init(void);
void* portalExec_event(int timeout);
void portalExec_end(void);
extern int portalExec_timeout;

class Portal
{
 public:
  int portalOpen(int length);
  void portalClose();
  Portal(int id);
  Portal(Portal* p);
  Portal(const char *name, unsigned int addrbits);
  ~Portal();
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
  static int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
};

class Directory : public Portal
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
  unsigned long long cycle_count();
  void printDbgRequestIntervals();
};

class PortalWrapper : public Portal
{
 private:
  int registerInstance();
  int unregisterInstance();
 public:
  ~PortalWrapper();
  PortalWrapper(Portal *p);
  PortalWrapper(int id);
  PortalWrapper(const char* devname, unsigned int addrbits);
  virtual int handleMessage(unsigned int channel) = 0;
};

class PortalProxy : public Portal
{
 public:
  ~PortalProxy();
  PortalProxy(int id);
  PortalProxy(const char *devname, unsigned int addrbits);
};


#endif // _PORTAL_H_
