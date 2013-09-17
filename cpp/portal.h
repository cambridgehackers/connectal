
#include <sys/types.h>


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

typedef struct PortalMessage {
    size_t size;
    size_t channel;
    size_t portal_num;
} PortalMessage;

typedef struct PortalClockRequest {
    int clknum;
    long requested_rate;
    long actual_rate;
} PortalClockRequest;

class PortalIndication {
 public:
    virtual void handleMessage(PortalMessage *msg) { };
    virtual ~PortalIndication() {};
};

class PortalInstance {
public:
    int sendMessage(PortalMessage *msg);
    void close();
    void dumpRegs();
protected:
    PortalIndication *indication;
    int receiveMessage(PortalMessage *msg);
    PortalInstance(const char *instanceName, PortalIndication *indication=0);
    ~PortalInstance();
    int open();
private:
    int fd;
    volatile unsigned int *hwregs;
    char *instanceName;
    static int registerInstance(PortalInstance *instance);
    static int unregisterInstance(PortalInstance *instance);
    friend PortalInstance *portalOpen(const char *instanceName);
    friend void* portalExec(void* __x);
    static int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
};

PortalInstance *portalOpen(const char *instanceName);
void* portalExec(void* __x);

class PortalMemory {
 public:
    static int dCacheFlushInval(PortalAlloc *portalAlloc);
    static int alloc(size_t size, int *fd, PortalAlloc *portalAlloc);
};


