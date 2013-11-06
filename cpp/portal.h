
#include <semaphore.h>
#include <sys/types.h>
#include <linux/ioctl.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>

#include "drivers/alloc/portalalloc.h"
#include "drivers/portal/portal.h"


struct channel{
  int s1;
  int s2;
  struct sockaddr_un local;
  bool connected;
};

struct portal{
  struct channel read;
  struct channel write;
};

struct memrequest{
  bool write;
  unsigned int addr;
  unsigned int data;
};

class PortalMessage {
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
}; 

class PortalRequest;

class PortalIndication {
 public:
#ifdef MMAP_HW
  virtual int handleMessage(unsigned int channel, volatile unsigned int* ind_fifo_base) {};
#else
  virtual int handleMessage(unsigned int channel, PortalRequest* request) {};
#endif
  virtual ~PortalIndication() {};
};

class PortalRequest {
public:
    int sendMessage(PortalMessage *msg);
    void close();
protected:
    PortalIndication *indication;
    PortalRequest(const char *name, PortalIndication *indication=0);
    ~PortalRequest();
    int open();
 public:
    int fd;
    struct portal p;
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
    char *name;
    static int registerInstance(PortalRequest *request);
    static int unregisterInstance(PortalRequest *request);
    friend void* portalExec(void* __x);
    static int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
};

void* portalExec(void* __x);

class PortalMemory : public PortalRequest {
 private:
  int handle;
 protected:
  PortalMemory(const char* name, PortalIndication *indication=0);
 public:
  int pa_fd;
  int dCacheFlushInval(PortalAlloc *portalAlloc, void *__p);
  int alloc(size_t size, PortalAlloc *portalAlloc);
  int reference(PortalAlloc* pa);
  virtual void sglist(unsigned long off, unsigned long long addr, unsigned long len) = 0;
  virtual void paref(unsigned long off, unsigned long long ref) = 0;
};


// ugly hack (mdk)
typedef int SGListId;


