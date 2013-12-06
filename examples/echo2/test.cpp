
#include "Say.h"
#include "SayProxy.h"

sem_t say_sem;

class SaySW : public Say
{
  virtual void say(unsigned long v){
    fprintf(stderr, "say(%ld)\n", v);
    sem_post(&say_sem);
  }

  virtual void say2(unsigned long a, unsigned long b){
    fprintf(stderr, "say2(%ld, %ld)\n", a,b);
    sem_post(&say_sem);
  }

}

int main(int argc, const char **argv)
{

  SayProxy sayHW* = new SayProxy(1008);
  SaySW saySW* = new SaySW(7); 

  if(sem_init(&say_sem, 1, 0)){
    fprintf(stderr, "failed to init say_sem\n");
    return -1;
  }

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  sayHW->say(0);
  sem_wait(&say_sem);

  sayHW->say2(1,2);
  sem_wait(&say_sem);

}
