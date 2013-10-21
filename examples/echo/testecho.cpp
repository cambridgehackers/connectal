
#include "Echo.h"
#include <stdio.h>
#include <stdlib.h>

CoreEchoRequest *echo = 0;

class TestEchoIndications : public CoreEchoIndication
{
    virtual void heard(unsigned long v) {
        fprintf(stderr, "heard an echo: %ld\n", v);
	echo->say2(v, 2*v);
    }
    virtual void heard2(unsigned long a, unsigned long b) {
      fprintf(stderr, "heard an echo2: %ld %ld\n", a, b);
      exit(0);
    }
};

int main(int argc, const char **argv)
{
    echo = CoreEchoRequest::createCoreEchoRequest(new TestEchoIndications);
    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    echo->say(v);
    echo->say(v*5);
    echo->say(v*17);
    echo->say(v*93);
    echo->say2(v, v*3);
    echo->setLeds(9);
    portalExec(0);
}
