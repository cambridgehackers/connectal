
#include <getopt.h>
#include <stdlib.h>

#include <GeneratedTypes.h>
#include <PcieMemCheckIndication.h>
#include <PcieMemCheckRequest.h>

volatile int done = 0;
class PcieMemCheckIndication : public PcieMemCheckIndicationWrapper {
public:
    virtual void checkFinished() {
	fprintf(stderr, "finished\n");
	done = 1;
    }
    PcieMemCheckIndication(unsigned int id) : PcieMemCheckIndicationWrapper(id) {}
};

int main(int argc, char* const*argv)
{
    int opt;
    int numIterations = 100000;
    int verbose = 0;
    while ((opt = getopt(argc, argv, "n:v")) != -1) {
        switch (opt) {
	case 'n':
	    numIterations = strtoul(optarg, 0, 0);
	    break;
	case 'v':
            verbose = 1;
	    break;
        }
    }
    fprintf(stderr, "numIterations=%d\n", numIterations);
    PcieMemCheckRequestProxy *request = new PcieMemCheckRequestProxy(IfcNames_PcieMemCheckRequestS2H);
    request->startCheck(numIterations, verbose);
    while (!done) {
        sleep(1);
    }
    return 0;
}
