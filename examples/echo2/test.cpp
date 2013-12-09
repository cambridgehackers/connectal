
// library header files
#include "DirectoryResponseStandard.h"

// generated header files
#include "Say.h"
#include "SayProxy.h"
#include "DirectoryResponse.h"
#include "DirectoryRequestProxy.h"


sem_t echo_sem;

class MySay : public Say
{
  virtual void say(unsigned long v){
    fprintf(stderr, "say(%ld)\n", v);
    sem_post(&echo_sem);
  }

  virtual void say2(unsigned long a, unsigned long b){
    fprintf(stderr, "say2(%ld, %ld)\n", a,b);
    sem_post(&echo_sem);
  }

  MySay(int id, DirectoryProxy *dirP, DirectoryResponse *dirR)
    : Say(id, dirP, dirR) {}
}

int main(int argc, const char **argv)
{

  DirectoryRequestProxy *dirP = new DirectoryRequestProxy("fpga0");
  DirectoryResponseStandard *dirR = new DirectoryResponseStandard("fpga1");

  SayProxy *sayP = new SayProxy(1008, dirP, dirR);
  MySay *say = new MySay(7, dirP, dirR); 

  pthread_t tid;
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  if(sem_init(&echo_sem, 1, 0)){
    fprintf(stderr, "failed to init echo_sem\n");
    return -1;
  }

  sayHW->say(0);
  sem_wait(&echo_sem);

  sayHW->say2(1,2);
  sem_wait(&echo_sem);

}
