
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


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
  virtual void pulse_width( const uint32_t v){
    // MaxSonar uses a scaling factor of 147 microseconds/inch
    // in its pulse-width output.  This design will be clocked
    // at 100 mHz on the zedboard.  We count accordingly
    fprintf(stderr, "(%d microseconds == %f inches)\n", v/100, ((float)v)/100.0/147.0);
  }
};

int main(int argc, const char **argv)
{
  MaxSonarCtrlIndication *ind = new MaxSonarCtrlIndication(IfcNames_ControllerIndication);
  MaxSonarCtrlRequestProxy *device = new MaxSonarCtrlRequestProxy(IfcNames_ControllerRequest);

  portalExec_start();

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);

  device->range_ctrl(true);
  while(true){
    device->pulse_width();
    sleep(1);
  }
}
