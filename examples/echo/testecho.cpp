
#include "Echo.h"
#include <stdio.h>
#include <stdlib.h>

CoreEchoRequest *echo = 0;

class TestEchoIndications : public CoreEchoIndication
{
    virtual void heard(unsigned long v) {
        fprintf(stderr, "heard an echo: %d\n", v);
	echo->say2(v, 2*v);
    }
    virtual void heard2(unsigned long a, unsigned long b) {
      fprintf(stderr, "heard an echo2: %d %d\n", a, b);
      exit(0);
    }
    virtual void putFailed(long unsigned int v) {
	fprintf(stderr, "putFailed %lx\n", v);
    }
};

int main(int argc, const char **argv)
{
    echo = CoreEchoRequest::createCoreEchoRequest(new TestEchoIndications);
    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    echo->say(v);
    echo->setLeds(9);
    portalExec(0);
}
