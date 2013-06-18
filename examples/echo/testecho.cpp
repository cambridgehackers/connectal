
#include "Echo.h"
#include <stdio.h>

class TestEchoIndications : public EchoIndications
{
    virtual void heard(unsigned long v) {
        fprintf(stderr, "heard an echo: %d\n", v);
        exit(0);
    }
};

int main(int argc, const char **argv)
{
    Echo *echo = Echo::createEcho("fpga0", new TestEchoIndications);
    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    echo->say(v);
    PortalInterface::exec();
}
