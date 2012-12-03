
#include <sys/types.h>

class UshwInterface;

struct UshwMessage {
    size_t size; // number of bytes
};

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
    int registerInstance(UshwInstance *instance);
private:
    UshwInstance **instances;
    struct pollfd *fds;
    int numFds;
};

extern UshwInterface ushw;

