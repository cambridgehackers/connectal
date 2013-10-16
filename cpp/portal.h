
#include <semaphore.h>
#include <sys/types.h>
#include <linux/ioctl.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>

#define PORTAL_ALLOC _IOWR('B', 10, PortalAlloc)
#define PORTAL_DCACHE_FLUSH_INVAL _IOWR('B', 11, PortalAlloc)
#define PORTAL_SET_FCLK_RATE _IOWR('B', 40, PortalClockRequest)

typedef unsigned int PARef;

typedef struct PortalAlloc {
  size_t size;
  int fd;
  struct {
    unsigned long dma_address;
    unsigned long length;
  } entries[64];
  int numEntries;
} PortalAlloc;

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

class PortalInstance;

typedef struct PortalClockRequest {
    int clknum;
    long requested_rate;
    long actual_rate;
} PortalClockRequest;

class PortalIndication {
 public:
#ifdef ZYNQ
  virtual int handleMessage(unsigned int channel, volatile unsigned int* ind_fifo_base) {};
#else
  virtual int handleMessage(unsigned int channel, PortalInstance* instance) {};
#endif
  virtual ~PortalIndication() {};
};

class PortalInstance {
public:
    int sendMessage(PortalMessage *msg);
    void close();
    PARef reference(PortalAlloc* pa);
protected:
    PortalIndication *indication;
    PortalInstance(const char *instanceName, PortalIndication *indication=0);
    ~PortalInstance();
    int open();
 public:
    int fd;
    struct portal p;
#ifdef ZYNQ
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
    char *instanceName;
    static int registerInstance(PortalInstance *instance);
    static int unregisterInstance(PortalInstance *instance);
    friend void* portalExec(void* __x);
    static int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
};

void* portalExec(void* __x);

class PortalMemory {
 public:
    static int dCacheFlushInval(PortalAlloc *portalAlloc);
    static int alloc(size_t size, PortalAlloc *portalAlloc);
};


