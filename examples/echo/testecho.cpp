
#include "Echo.h"
#include <stdio.h>

class TestEcho : public Echo
{
public:
    TestEcho(const char *instanceName) : Echo(instanceName) {};
    
    void heard(unsigned long v) {
        fprintf(stderr, "heard an echo: %d\n", v);
        exit(0);
    }
};

int main(int argc, const char **argv)
{
    TestEcho *echo = new TestEcho("fpga0");
    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    echo->say(v);
    PortalInterface::exec();
}
