
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

#include "GyroCtrlRequest.h"
#include "GyroCtrlIndication.h"
#include "GeneratedTypes.h"

#include "gyro.h"

class GyroCtrlIndication : public GyroCtrlIndicationWrapper
{
public:
  GyroCtrlIndication(int id) : GyroCtrlIndicationWrapper(id) {}
  virtual void read_reg_resp ( const uint32_t v){
    fprintf(stderr, "GyroCtrlIndication::read_reg_resp(v=%0d)\n", v);
  }
};


int main(int argc, const char **argv)
{
  GyroCtrlIndication *ind = new GyroCtrlIndication(IfcNames_ControllerIndication);
  GyroCtrlRequestProxy *device = new GyroCtrlRequestProxy(IfcNames_ControllerRequest);

  portalExec_start();

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
  sleep(1);

  // setup
  device->write_reg(CTRL_REG3, 0);
  device->write_reg(CTRL_REG1, CTRL_REG1_PD | CTRL_REG1_ZEN | CTRL_REG1_YEN | CTRL_REG1_XEN);

  sleep(1);

  while(true){
    fprintf(stderr, "emitting request\n");
    device->read_reg_req(OUT_X_L);
    sleep(2);
  }

  while(true) sleep(1);

}
