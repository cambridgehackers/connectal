
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
  virtual void debug(uint32_t channelUp, uint32_t laneUp, uint32_t hardErr, uint32_t softErr, uint32_t qpllLock, uint32_t qpllRefClkLost) {
    fprintf(stderr, "debug: channelUp=%d laneUp=%d hardErr=%d, softErr=%d qpllLock=%d qpllRefClkLost=%d\n", channelUp, laneUp, hardErr, softErr, qpllLock, qpllRefClkLost);
  }
  virtual void userClkElapsedCycles(uint32_t ec) {
    fprintf(stderr, "userClk freq=%f MHz\n", (float)ec / 5.0);
  }
  virtual void mgtRefClkElapsedCycles(uint32_t ec) {
    fprintf(stderr, "mgtRefClk freq=%f MHz\n", (float)ec / 5.0);
  }
  virtual void outClkElapsedCycles(uint32_t ec) {
    fprintf(stderr, "outClk freq=%f MHz\n", (float)ec / 5.0);
  }
  virtual void outRefClkElapsedCycles(uint32_t ec) {
    fprintf(stderr, "outRefClk freq=%f MHz\n", (float)ec / 5.0);
  }
  virtual void drpResponse(uint32_t v) {
    fprintf(stderr, "drp response %#x\n", v);
  }
  AuroraIndication(unsigned int id) : AuroraIndicationWrapper(id), cnt(0){}
};



int main(int argc, const char **argv)
{
  PortalPoller *poller = new PortalPoller();
  AuroraIndication *indication = new AuroraIndication(IfcNames_AuroraIndication);
  AuroraRequestProxy *device = new AuroraRequestProxy(IfcNames_AuroraRequest, poller);

  long freq = 0;
  poller->setClockFrequency(0, 200000000, &freq);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }

  fprintf(stderr, "Main::calling say1(%d)\n", 0);
  device->send(0);

  fprintf(stderr, "Main::about to go to sleep\n");
  int count = 0;
  while(true){
    device->debug();
    device->userClkElapsedCycles(1000);
    device->mgtRefClkElapsedCycles(1000);
    device->outClkElapsedCycles(1000);
    device->outRefClkElapsedCycles(1000);
    device->qpllReset(count < 2);
    if (count < 0x14) {
      fprintf(stderr, "Reading drp reg %x\n", count+0x30);
      device->drpRequest(count+0x30, 0, 0);
    }
    count++;
    sleep(1);
  }
}
