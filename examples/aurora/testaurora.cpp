/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "AuroraIndication.h"
#include "AuroraRequest.h"
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
  setClockFrequency(0, 200000000, &freq);

  fprintf(stderr, "Main::calling say1(%d)\n", 0);
  device->send(0);

  fprintf(stderr, "Main::about to go to sleep\n");
  int count = 0;
  while(true){
    device->debug();
    device->userClkElapsedCycles(1000);
    device->mgtRefClkElapsedCycles(1000);
    device->qpllReset(count < 2);
    device->pma_init(count < 2);
    device->loopback(1);
    if (count < 0x14) {
      fprintf(stderr, "Reading drp reg %x\n", count+0x30);
      device->drpRequest(count+0x30, 0, 0);
    }
    count++;
    sleep(1);
  }
}
