
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
#include "STestRequest.h"
#include "STestIndication.h"
#include "gyro.h"

class STestIndication: public STestIndicationWrapper {
public:
    STestIndication(int id): STestIndicationWrapper(id) {}
    void result(uint16_t val ) {
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    }
};

int main(int argc, const char **argv)
{
  STestIndication ind(IfcNames_STestIndicationH2S);
  STestRequestProxy *device = new STestRequestProxy(IfcNames_STestRequestS2H);
  device->write_reg(CTRL_REG1, 0b00001111);  // ODR:100Hz Cutoff:12.5
  device->write_reg(CTRL_REG2, 0b00000000);
  device->write_reg(CTRL_REG3, 0b00000000);
  device->write_reg(CTRL_REG4, 0b10100000);  // BDU:1, Range:2000 dps
  device->write_reg(CTRL_REG5, 0b00000000);

  while(1) {
    sleep(1);
  }
}
