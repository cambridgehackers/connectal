
#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <unistd.h>

#include "PipeMulIndicationWrapper.h"
#include "PipeMulRequestProxy.h"
#include "GeneratedTypes.h"


class PipeMulIndication : public PipeMulIndicationWrapper
{
public:
    virtual void res(uint32_t v) {
      fprintf(stderr, "res: %d\n", v);
      exit(0);
    }
    PipeMulIndication(unsigned int id) : PipeMulIndicationWrapper(id) {}
};


int main(int argc, const char **argv)
{
  PipeMulIndication *indication = new PipeMulIndication(IfcNames_PipeMulIndication);
  PipeMulRequestProxy *device = new PipeMulRequestProxy(IfcNames_PipeMulRequest);
  portalExec_start();
  device->mul(3,4);  
  while(true);
}
