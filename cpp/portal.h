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

#include "drivers/portalmem/portalmem.h"
#include "drivers/zynqportal/zynqportal.h"

#include "sock_utils.h"

struct memrequest{
  bool write;
  unsigned int addr;
  unsigned int data;
};

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
void loadPortalDirectory();

class Portal
{
 private:
  Portal(char *name, int length)
 public:
  int open(int length);
  void close();
  Portal(int id);
  ~Portal();
  int fd;
  struct portal p;
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
  friend void* portalExec(void* __x);
};

class PortalWrapper : private Portal
{
 private:
  static int registerInstance();
  static int unregisterInstance();
 public:
  ~PortalWrapper();
  PortalWrapper(int id);
  virtual int handleMessage(unsigned int channel) = 0;
};

class PortalProxy : private Portal
{
 public:
  ~PortalProxy();
  PortalProxy(int id);
};

class PortalMemory : public PortalProxy 
{
 private:
  int handle;
#ifndef MMAP_HW
  portal p_fd;
#endif
 public:
  PortalMemory(int id);
  int pa_fd;
  void *mmap(PortalAlloc *portalAlloc);
  int dCacheFlushInval(PortalAlloc *portalAlloc, void *__p);
  int alloc(size_t size, PortalAlloc **portalAlloc);
  int reference(PortalAlloc* pa);
  virtual void sglist(unsigned long pref, unsigned long long addr, unsigned long len) = 0;
  virtual void paref(unsigned long pref, unsigned long size) = 0;
};

// ugly hack (mdk)
typedef int SGListId;

#endif // _PORTAL_H_
