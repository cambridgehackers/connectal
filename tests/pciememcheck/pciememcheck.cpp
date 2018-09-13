
#include <getopt.h>
#include <stdlib.h>

#include <GeneratedTypes.h>
#include <PcieMemCheckIndication.h>
#include <PcieMemCheckRequest.h>

int main(int argc, char* const*argv)
{
    int opt;
    int numIterations = 100000;
    while ((opt = getopt(argc, argv, "n:")) != -1) {
        switch (opt) {
	case 'n':
	    numIterations = strtoul(optarg, 0, 0);
        } break;
    }
    fprintf(stderr, "numIterations=%d\n", numIterations);
    PcieMemCheckRequestProxy *request = new PcieMemCheckRequestProxy(IfcNames_PcieMemCheckRequestS2H);
    request->startCheck(numIterations);
    while (1) {
        sleep(1);
    }
    return 0;
}
