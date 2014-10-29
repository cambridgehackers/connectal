
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "SimpleIndication.h"
#include "SimpleRequest.h"
#include "GeneratedTypes.h"


int v1a = 42;


class SimpleIndication : public SimpleIndicationWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 1)
      exit(0);
  }
  virtual void heard1(uint32_t a) {
    fprintf(stderr, "heard1(%d)\n", a);
    assert(a == v1a);
    incr_cnt();
  }
  SimpleIndication(unsigned int id) : SimpleIndicationWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  SimpleIndication *indication = new SimpleIndication(IfcNames_SimpleIndication);
  SimpleRequestProxy *device = new SimpleRequestProxy(IfcNames_SimpleRequest);

  portalExec_start();

  fprintf(stderr, "Main::calling say1(%d)\n", v1a);
  device->say1(v1a);  

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
