#include "ushw.h"
#include "dut.h"

DUT *DUT::createDUT(const char *instanceName)
{
    UshwInstance *p = ushwOpen(instanceName);
    DUT *instance = new DUT(p);
    return instance;
}


DUT::DUT(UshwInstance *p)
{
    this->p = p;
}
DUT::~DUT()
{
    p->close();
}


struct DUToperateMSG : public UshwMessage
{
struct Request {
unsigned int a;
unsigned int b;

} request;
unsigned int response;
};

unsigned int DUT::operate ( unsigned int a, unsigned int b )
{
    DUToperateMSG msg;
    msg.argsize = sizeof(msg.request);
    msg.resultsize = sizeof(msg.response);
msg.request.a = a;
msg.request.b = b;

    p->sendMessage(&msg);
    return msg.response;
};
