
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
} PortalMessage;

typedef struct PortalClockRequest {
    int clknum;
    long requested_rate;
    long actual_rate;
} PortalClockRequest;

class PortalIndications {
 public:
    virtual void handleMessage(PortalMessage *msg) { };
    virtual ~PortalIndications() {};
};

class PortalInstance {
public:
    int sendMessage(PortalMessage *msg);
    int flushDMAChannels();
    void close();
protected:
    PortalIndications *indications;
    int receiveMessage(PortalMessage *msg);
    PortalInstance(const char *instanceName, PortalIndications *indications=0);
    ~PortalInstance();
    int open();
    friend PortalInstance *portalOpen(const char *instanceName);
private:
    int fd;
    volatile unsigned int *hwregs;
    char *instanceName;
    friend class PortalInterface;
};
PortalInstance *portalOpen(const char *instanceName);

class PortalInterface {
public:
    PortalInterface();
    ~PortalInterface();
    static void* exec(void* __x);
    static int dCacheFlushInval(PortalAlloc *portalAlloc);
    static int alloc(size_t size, int *fd, PortalAlloc *portalAlloc);
    static int free(int fd);
    static int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
    int registerInstance(PortalInstance *instance);
    int dumpRegs();
private:
    PortalInstance **instances;
    struct pollfd *fds;
    int numFds;
};

extern PortalInterface portal;

