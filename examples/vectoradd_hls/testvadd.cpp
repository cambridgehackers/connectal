
#include <stdio.h>
#include <VaddRequest.h>
#include <VaddResponse.h>

volatile int finished = 0;
class VaddResponse : public VaddResponseWrapper
{
private:
  int i;
  int received_done;
public:
  virtual void data ( const uint32_t out ) {
    fprintf(stderr, "data[%d] = %d\n", i, out);
    i = i + 1;
    if (i >= 64 && received_done)
      finished = 1;
  }
  virtual void done() {
    fprintf(stderr, "done\n");
    received_done = 1;
    if (i >= 64 && received_done)
      finished = 1;
  }
  void clear() {
    i = 0;
    received_done = 0;
    finished = 0;
  }
  VaddResponse(unsigned int id, PortalTransportFunctions *transport = 0, void *param = 0, PortalPoller *poller = 0)
    : VaddResponseWrapper(id, transport, param, poller) {
    i = 0;
    received_done = 0;
  }
};

int main(int argc, const char **argv)
{
  // Instantiate response handler, which will run in a second thread
  VaddResponse response(IfcNames_VaddResponseH2S);
  // Instantiate the request proxy
  VaddRequestProxy *request = new VaddRequestProxy(IfcNames_VaddRequestS2H);

  // [1] Batch processing mode

  // send the data to the logic
  for (int i = 0; i < 64; i++) {
    request->data(i, i*2);
  }
  // start the computation
  request->start();

  // wait for responses
  while (!finished)
    sleep(1);

  // clear the response handler so we can use it again
  response.clear();

  // [2] Pipelined processing mode

  // start the computation
  request->start();

  // send the data
  for (int i = 0; i < 64; i++) {
    request->data(i, i*2);
  }

  // wait for responses
  while (!finished)
    sleep(1);


  return 0;
}
