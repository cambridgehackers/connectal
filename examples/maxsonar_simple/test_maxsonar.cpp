
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
#include "maxsonar_simple.h"
#include "MaxSonarCtrlRequest.h"
#include "read_buffer.h"

int main(int argc, const char **argv)
{
  MaxSonarCtrlIndication *ind = new MaxSonarCtrlIndication(IfcNames_MaxSonarCtrlIndicationH2S);
  MaxSonarCtrlRequestProxy *device = new MaxSonarCtrlRequestProxy(IfcNames_MaxSonarCtrlRequestS2H);
  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
  device->range_ctrl(1);

  while(true){
    usleep(50000);
    device->pulse_width();
    sem_wait(&(ind->pulse_width_sem));
    float distance = ((float)ind->useconds)/147.0;
    fprintf(stderr, "(%8d microseconds == %8f inches)\n", ind->useconds, distance);
  }
}
