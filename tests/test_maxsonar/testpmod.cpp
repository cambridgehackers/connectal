
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

#include "MaxSonarCtrlRequest.h"
#include "MaxSonarCtrlIndication.h"
#include "GeneratedTypes.h"


class MaxSonarCtrlIndication : public MaxSonarCtrlIndicationWrapper
{
public:
  MaxSonarCtrlIndication(int id) : MaxSonarCtrlIndicationWrapper(id) {}
  virtual void range_ctrl ( const uint32_t v){
    fprintf(stderr, "MaxSonarCtrlIndication::range_ctrl(v=%0d)\n", v);
  }
};

int main(int argc, const char **argv)
{
  MaxSonarCtrlIndication *ind = new MaxSonarCtrlIndication(IfcNames_ControllerIndication);
  MaxSonarCtrlRequestProxy *device = new MaxSonarCtrlRequestProxy(IfcNames_ControllerRequest);

  portalExec_start();

  bool s = false;
  while(true){
    device->range_ctrl(s);
    s = !s;
    sleep(1);
  }
}
