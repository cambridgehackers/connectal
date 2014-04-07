
#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <unistd.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "FibIndicationWrapper.h"
#include "FibRequestProxy.h"
#include "GeneratedTypes.h"

sem_t test_sem;

class FibIndication : public FibIndicationWrapper
{
public:
    virtual void fibresult(uint32_t v) {
      fprintf(stderr, "fibresult: %d\n", v);
	sem_post(&test_sem);
    }
    FibIndication(unsigned int id) : FibIndicationWrapper(id) {}
};

FibRequestProxy *fibRequestProxy = 0;
FibIndication *fibIndication;


int main(int argc, const char **argv)
{
  int i;
  // these use the default poller
  fibRequestProxy = new FibRequestProxy(IfcNames_FibRequest);
  fibIndication = new FibIndication(IfcNames_FibIndication);
  
  if(sem_init(&test_sem, 1, 0)){
    fprintf(stderr, "failed to init test_sem\n");
    return -1;
  }
  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  for (i = 0; i < 20; i += 1) {
    fprintf(stderr, "fib(%d)\n", i);
    fibRequestProxy->fib(i);
    sem_wait(&test_sem);
  }

  return 0;
}
