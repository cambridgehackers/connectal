
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
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
  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }
  device->mul(3,4);  
  while(true);
}
