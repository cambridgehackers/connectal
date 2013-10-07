
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

class PortalInterface;

typedef struct PortalAlloc {
        size_t size;
        int fd;
        struct {
                unsigned long dma_address;
                unsigned long length;
        } entries[64];
        int numEntries;
} PortalAlloc;

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
  virtual int handleMessage(unsigned int channel, int s, const char* id) {};
#endif
  virtual ~PortalIndication() {};
};

class PortalInstance {
public:
    int sendMessage(PortalMessage *msg);
    void close();
protected:
    PortalIndication *indication;
    int receiveMessage(unsigned int queue_status);
    PortalInstance(const char *instanceName, PortalIndication *indication=0);
    ~PortalInstance();
    int open();
private:
    int fd;
    int s;
    struct sockaddr_un remote;
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
    static int alloc(size_t size, int *fd, PortalAlloc *portalAlloc);
};


