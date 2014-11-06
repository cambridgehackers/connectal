
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "FpIndication.h"
#include "FpRequest.h"
#include "GeneratedTypes.h"

class FpIndication : public FpIndicationWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 1)
      exit(0);
  }
  void added ( float a ) {
    fprintf(stderr, "Result=%f\n", a);
    incr_cnt();
  }
  FpIndication(unsigned int id) : FpIndicationWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  FpIndication *indication = new FpIndication(IfcNames_FpIndication);
  FpRequestProxy *device = new FpRequestProxy(IfcNames_FpRequest);

  portalExec_start();

  float a = 1.0;
  float b = 0.5;

  device->add(a, b);

  // wait for answer
  while(true){sleep(2);}
}
