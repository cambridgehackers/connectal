
#include <sys/types.h>
#include <bitset>

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

class PortalInstance {
public:
    typedef void (*MessageHandler)(PortalMessage *msg);
    MessageHandler *messageHandlers;

    int sendMessage(PortalMessage *msg);
    void close();
protected:
    int receiveMessage(PortalMessage *msg);
    virtual void handleMessage(PortalMessage *msg) { };
    PortalInstance(const char *instanceName);
    ~PortalInstance();
    friend PortalInstance *portalOpen(const char *instanceName);
private:
    int fd;
    char *instanceName;
    friend class PortalInterface;
};
PortalInstance *portalOpen(const char *instanceName);

class PortalInterface {
public:
    PortalInterface();
    ~PortalInterface();
    typedef void (*idleFunc)(void);
    static int exec(idleFunc func = 0);
    static int alloc(size_t size, int *fd, PortalAlloc *portalAlloc);
    static int free(int fd);
    int registerInstance(PortalInstance *instance);
    int dumpRegs();
private:
    PortalInstance **instances;
    struct pollfd *fds;
    int numFds;
};

extern PortalInterface portal;

