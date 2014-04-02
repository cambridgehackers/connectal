
#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <unistd.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "FibIndicationWrapper.h"
#include "FibRequestProxy.h"
#include "GeneratedTypes.h"

class FibIndication : public FibIndicationWrapper
{
public:
    virtual void fibresult(uint32_t v) {
        printf("fibresult: %d\n", v);
	sem_post(&test_sem);
    }
    FibIndication(unsigned int id) : FibIndicationWrapper(id) {}
};

FibRequestProxy *fibRequestProxy;
FibIndication *fibIndication;

sem_t test_sem;


int main(int argc, const char **argv)
{
  int i;
  fibIndication = new FibIndication(IfcNames_FibIndication);
  // these use the default poller
  fibRequestProxy = new FibRequestProxy(IfcNames_FibRequest);
  
  if(sem_init(&test_sem, 1, 0)){
    printf("failed to init test_sem\n");
    return -1;
  }

  for (i = 0; i < 5; i += 1) {
    printf("fib(%d)\n", i);
    fibRequestProxy.fib(i);
    sem_wait(&test_sem);
  }
  return 0;
}
