
#include "Periodic.h"
#include <stdio.h>
#include <stdlib.h>

Periodic *periodic = 0;

class TestPeriodicIndications : public PeriodicIndications
{
    virtual void fired ( unsigned long v ){
        fprintf(stderr, "event: %ld\n", v);
    }
    virtual void timerUpdated ( unsigned long v ){
	fprintf(stderr, "timerUpdated %ld\n", v);
    }
};

int main(int argc, const char **argv)
{
    periodic = Periodic::createPeriodic("fpga0", new TestPeriodicIndications);
    unsigned long v = 100000000;
    if (argc > 1)
	v = strtoul(argv[1], 0, 0);
    fprintf(stderr, "Setting period %ld\n", v);
    periodic->setPeriod(v);
    periodic->start();
    portalExec(0);
}
