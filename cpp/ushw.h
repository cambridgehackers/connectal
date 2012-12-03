
#include <sys/types.h>

struct UshwMessage {
    size_t size; // number of bytes
};

class UshwInstance {
public:
    typedef void (*MessageHandler)(UshwMessage *msg);
    MessageHandler *messageHandlers;

    int sendMessage(UshwMessage *msg);
    int receiveMessage(UshwMessage *msg);
    int exec();
    void close();
private:
    UshwInstance(const char *instanceName);
    ~UshwInstance();
    friend UshwInstance *ushwOpen(const char *instanceName);
private:
    int fd;
    char *instanceName;
};
UshwInstance *ushwOpen(const char *instanceName);

