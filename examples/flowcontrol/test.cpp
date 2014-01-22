
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "SinkIndicationWrapper.h"
#include "SinkRequestProxy.h"
#include "GeneratedTypes.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

pthread_mutex_t count_mutex     = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  condition_var   = PTHREAD_COND_INITIALIZER;
int count = 0;

class SinkIndication : public SinkIndicationWrapper
{
public:
  virtual void returnTokens(unsigned long v) {
    // Lock mutex and update the count variable
    pthread_mutex_lock( &count_mutex );
    count += v;

    // Signal to main() thread that more tokens have been
    // returned from the SinkRequest hardware and unlock mutex
    pthread_cond_signal( &condition_var );
    pthread_mutex_unlock( &count_mutex );
  }
  SinkIndication(unsigned int id) : SinkIndicationWrapper(id){}
};

int main(int argc, const char **argv)
{

  int tokens = 0;
  pthread_t tid;
  SinkIndication *sinkIndication = new SinkIndication(IfcNames_SinkIndication);
  SinkRequestProxy *sinkRequestProxy = new SinkRequestProxy(IfcNames_SinkRequest);
  
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "error creating exec thread\n");
    exit(1);
  }
  
  sinkRequestProxy->init(0);
  while(tokens < 32){

    // Lock mutex and then wait for signal to relase mutex
    pthread_mutex_lock( &count_mutex );

    // Wait while SinkIndication::returnTokens updates count
    // mutex unlocked if condition varialbe is signaled.
    pthread_cond_wait( &condition_var, &count_mutex );

    // consume the credit
    int local_count = count;
    count = 0;

    // Unlock the mutex so SinkIndication::returnTokens can
    // accept more tokens from the SinkRequest hardware
    pthread_mutex_unlock( &count_mutex );

    while(local_count){
      fprintf(stderr, "main() count:%d\n", local_count--);
      sinkRequestProxy->put(tokens++);
    }

  }
  
  return 0;
}
