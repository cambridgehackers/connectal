
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "FpIndicationWrapper.h"
#include "FpRequestProxy.h"
#include "GeneratedTypes.h"

class FpIndication : public FpIndicationWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 7)
      exit(0);
  }
  virtual void heard1(uint32_t a) {
    fprintf(stderr, "heard1(%d)\n", a);
    assert(a == v1a);
    incr_cnt();
  }
  FpIndication(unsigned int id) : FpIndicationWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  FpIndication *indication = new FpIndication(IfcNames_FpIndication);
  FpRequestProxy *device = new FpRequestProxy(IfcNames_FpRequest);

  pthread_t tid;
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }

}
