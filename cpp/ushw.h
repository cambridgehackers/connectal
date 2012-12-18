
#include <sys/types.h>

class UshwInterface;

typedef struct UshwAlloc {
    size_t size;
    unsigned char *kptr;
} UshwAlloc;

typedef struct UshwMessage {
    size_t size;
} UshwMessage;

class UshwInstance {
public:
    typedef void (*MessageHandler)(UshwMessage *msg);
    MessageHandler *messageHandlers;

    int sendMessage(UshwMessage *msg);
    int receiveMessage(UshwMessage *msg);
    void close();
private:
    UshwInstance(const char *instanceName);
    ~UshwInstance();
    friend UshwInstance *ushwOpen(const char *instanceName);
private:
    int fd;
    char *instanceName;
    friend class UshwInterface;
};
UshwInstance *ushwOpen(const char *instanceName);

class UshwInterface {
public:
    UshwInterface();
    ~UshwInterface();
    static int exec();
    static unsigned long alloc(size_t size);
    int registerInstance(UshwInstance *instance);
    int dumpRegs();
private:
    UshwInstance **instances;
    struct pollfd *fds;
    int numFds;
};

extern UshwInterface ushw;

