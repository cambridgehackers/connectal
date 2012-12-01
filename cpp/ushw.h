
#include <sys/types.h>

struct UshwMessage {
    size_t argsize;
    size_t resultsize;
};

class UshwInstance {
public:
    friend UshwInstance *ushwOpen(const char *instanceName);
    int sendMessage(UshwMessage *msg);
    int receiveMessage(UshwMessage *msg);
    void close();
private:
    UshwInstance(const char *instanceName);
    ~UshwInstance();
private:
    int fd;
    char *instanceName;
};
UshwInstance *ushwOpen(const char *instanceName);

