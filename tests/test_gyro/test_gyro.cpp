
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
#include <pthread.h>
#include <netdb.h>

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "dmaManager.h"
#include "sock_utils.h"

#include "GyroCtrlRequest.h"
#include "GyroCtrlIndication.h"
#include "GeneratedTypes.h"

#include "gyro.h"

#ifdef BSIM
int alloc_sz = 64;
#else
int alloc_sz = 1024;
#endif
int wrapped = false;
int ss[3];

class GyroCtrlIndication : public GyroCtrlIndicationWrapper
{
public:
  GyroCtrlIndication(int id) : GyroCtrlIndicationWrapper(id) {}
  virtual void read_reg_resp ( const uint32_t v){
    fprintf(stderr, "GyroCtrlIndication::read_reg_resp(v=%x)\n", v);
  }
  virtual void sample_wrap(const uint32_t v){
    //fprintf(stderr, "GyroCtrlIndication::sample_wrap(v=%08x)\n", v);
    wrapped = true;
  }
};

int main(int argc, const char **argv)
{
  GyroCtrlIndication *ind = new GyroCtrlIndication(IfcNames_ControllerIndication);
  GyroCtrlRequestProxy *device = new GyroCtrlRequestProxy(IfcNames_ControllerRequest);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);

  portalExec_start();
  int dstAlloc = portalAlloc(alloc_sz);
  unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
  sleep(1);

  // setup
  device->write_reg(CTRL_REG3, 0);
  device->write_reg(CTRL_REG1, CTRL_REG1_PD | CTRL_REG1_ZEN | CTRL_REG1_YEN | CTRL_REG1_XEN);
  sleep(2);

  // sample has one two-byte component for each axis (x,y,z).  I want the 
  // wrap-around to work so that the X component always lands in offset 0
  int sample_size = 6;
  int bus_data_width = 8;
  int wrap_limit = alloc_sz-(alloc_sz%(sample_size*bus_data_width)); // want lcm
  int cnt = 0;

#ifdef BSIM
  device->sample(ref_dstAlloc, wrap_limit, 10);
#else
  device->sample(ref_dstAlloc, wrap_limit, 1000);
#endif

  while(true){

    while(!wrapped) usleep(1000);
    wrapped = false;
    int s[3] = {0,0,0};
    portalDCacheInval(dstAlloc, alloc_sz, dstBuffer);
    for(int i = 0; i < wrap_limit; i+=6){
      short* foo = (short*)(((char*)(dstBuffer))+i);
      for(int j = 0; j < 3; j++)
	s[j] += (int)(foo[j]);
    }
    for(int j = 0; j < 3; j++)
      ss[j] = s[j]/(wrap_limit/6);

    fprintf(stderr, "x:%8d, y:%8d, z:%8d\n", ss[0], ss[1], ss[2]);
  }

}
