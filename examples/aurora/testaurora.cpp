
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "AuroraIndicationWrapper.h"
#include "AuroraRequestProxy.h"
#include "GeneratedTypes.h"


class AuroraIndication : public AuroraIndicationWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 7)
      exit(0);
  }
  virtual void received(uint64_t v) {
    fprintf(stderr, "Received v=%lld", v);
  }
  virtual void debug(uint32_t channelUp, uint32_t laneUp, uint32_t hardErr, uint32_t softErr) {
    fprintf(stderr, "debug: channelUp=%d laneUp=%d hardErr=%d, softErr=%d\n", channelUp, laneUp, hardErr, softErr);
  }
  AuroraIndication(unsigned int id) : AuroraIndicationWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  AuroraIndication *indication = new AuroraIndication(IfcNames_AuroraIndication);
  AuroraRequestProxy *device = new AuroraRequestProxy(IfcNames_AuroraRequest);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }

  fprintf(stderr, "Main::calling say1(%d)\n", 0);
  device->send(0);

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){
    device->debug();
    sleep(1);
  }
}
