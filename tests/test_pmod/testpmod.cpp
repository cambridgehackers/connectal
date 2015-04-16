
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

#include "PmodControllerRequest.h"
#include "PmodControllerIndication.h"
#include "GeneratedTypes.h"


class PmodControllerIndication : public PmodControllerIndicationWrapper
{
public:
  PmodControllerIndication(int id) : PmodControllerIndicationWrapper(id) {}
  virtual void rst ( const uint32_t v ) {
    fprintf(stderr, "PmodControllerIndication::rst(%08x)\n", v);
  }
};


int main(int argc, const char **argv)
{
  PmodControllerIndication *ind = new PmodControllerIndication(IfcNames_ControllerIndication);
  PmodControllerRequestProxy *device = new PmodControllerRequestProxy(IfcNames_ControllerRequest);

  for(int i = 0; i < 10; i++) {
    device->rst(i);
    sleep(1);
  }
}
