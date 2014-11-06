
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <semaphore.h>

#include "Tiny3Indication.h"
#include "Tiny3Request.h"
#include "GeneratedTypes.h"

sem_t sem_sync;

class Tiny3Indication : public Tiny3IndicationWrapper
{  
public:
  virtual void outputdata(uint32_t a) {
    fprintf(stderr, "outputdata(%d)\n", a);
  }
  virtual void inputresponse() {
    fprintf(stderr, "inputresponse\n");
    sem_post(&sem_sync);
  }
  Tiny3Indication(unsigned int id) : Tiny3IndicationWrapper(id){}
};



int main(int argc, const char **argv)
{
  Tiny3Indication *indication = new Tiny3Indication(IfcNames_Tiny3Indication);
  Tiny3RequestProxy *device = new Tiny3RequestProxy(IfcNames_Tiny3Request);

  sem_init(&sem_sync, 0, 0);

  portalExec_start();

  fprintf(stderr, "Main::starting\n");

  device->inputdata(17);  
  sem_wait(&sem_sync);

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
