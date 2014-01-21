
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

void *functionCount1(void*);
void *functionCount2(void*);
int  count = 0;
#define COUNT_DONE  10
#define COUNT_HALT1  3
#define COUNT_HALT2  6

main()
{
  pthread_t thread1, thread2;

  pthread_create( &thread1, NULL, &functionCount1, NULL);
  pthread_create( &thread2, NULL, &functionCount2, NULL);

  pthread_join( thread1, NULL);
  pthread_join( thread2, NULL);

  printf("Final count: %d\n",count);

  exit(0);
}

// Write numbers 1-3 and 8-10 as permitted by functionCount2()

void *functionCount1(void *__x)
{
  for(;;)
    {
      // Lock mutex and then wait for signal to relase mutex
      pthread_mutex_lock( &count_mutex );

      // Wait while functionCount2() operates on count
      // mutex unlocked if condition varialbe in functionCount2() signaled.
      pthread_cond_wait( &condition_var, &count_mutex );
      count++;
      printf("Counter value functionCount1: %d\n",count);

      pthread_mutex_unlock( &count_mutex );

      if(count >= COUNT_DONE) return(NULL);
    }
}

// Write numbers 4-7

void *functionCount2(void *__x)
{
  for(;;)
    {
      pthread_mutex_lock( &count_mutex );

      if( count < COUNT_HALT1 || count > COUNT_HALT2 )
	{
          // Condition of if statement has been met. 
          // Signal to free waiting thread by freeing the mutex.
          // Note: functionCount1() is now permitted to modify "count".
          pthread_cond_signal( &condition_var );
	}
      else
	{
          count++;
          printf("Counter value functionCount2: %d\n",count);
	}

      pthread_mutex_unlock( &count_mutex );

      if(count >= COUNT_DONE) return(NULL);
    }

}


class SinkIndication : public SinkIndicationWrapper
{
public:
  virtual void returnTokens(unsigned long v) {
  }
  SinkIndication(unsigned int id) : SinkIndicationWrapper(id){}
};

// int main(int argc, const char **argv)
// {

//   pthread_t tid;
//   int tokens = 0;
//   SinkIndication *sinkIndication = new SinkIndication(IfcNames_SinkIndication);
//   SinkRequestProxy *sinkRequestProxy = new SinkRequestProxy(IfcNames_SinkRequest);
  
//   fprintf(stderr, "Main::creating exec thread\n");
//   if(pthread_create(&tid, NULL,  portalExec, NULL)){
//     fprintf(stderr, "error creating exec thread\n");
//     exit(1);
//   }
  
//   sinkRequestProxy->init(0);
//   while (true){
//     //if(tokenQueue.try_dequeue(tokens)){
//     while(tokens){
//       sinkRequestProxy->put(0);
//       tokens--;
//     }
//     //}
//   }
  
//   return 0;
// }
