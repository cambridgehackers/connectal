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


struct DUTputMSG : public UshwMessage
{
unsigned int a;
unsigned int b;

};

void DUT::put ( unsigned int a, unsigned int b )
{
    DUTputMSG msg;
    msg.argsize = sizeof(msg)-sizeof(UshwMessage);
    msg.resultsize = 0;
msg.a = a;
msg.b = b;

    p->sendMessage(&msg);
};

struct DUTgetMSG : public UshwMessage
{

};

void DUT::get (  )
{
    DUTgetMSG msg;
    msg.argsize = sizeof(msg)-sizeof(UshwMessage);
    msg.resultsize = 0;

    p->sendMessage(&msg);
};
