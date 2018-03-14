
#include <stdio.h>
#include <VaddRequest.h>
#include <VaddResponse.h>

volatile int finished = 0;
class VaddResponse : public VaddResponseWrapper
{
private:
  int i;
public:
  virtual void data ( const uint32_t out ) {
    fprintf(stderr, "data[%d] = %d\n", i, out);
    if (i == 63)
      finished = 1;
    i = (i + 1) % 64;
  }
  VaddResponse(unsigned int id, PortalTransportFunctions *transport = 0, void *param = 0, PortalPoller *poller = 0)
    : VaddResponseWrapper(id, transport, param, poller) {
    i = 0;
  }
};

int main(int argc, const char **argv)
{
  VaddResponse response(IfcNames_VaddResponseH2S);
  VaddRequestProxy *request = new VaddRequestProxy(IfcNames_VaddRequestS2H);

  for (int i = 0; i < 64; i++) {
    request->data(i, i*2);
  }

  while (!finished)
    sleep(1);
  return 0;
}
