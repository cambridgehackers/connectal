
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

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "dmaManager.h"
#include "sock_server.h"

#include "maxsonar_simple.h"
#include "MaxSonarCtrlRequest.h"
#include "GeneratedTypes.h"

int spew = 1;
int alloc_sz = 1<<8;

int main(int argc, const char **argv)
{
  MaxSonarCtrlIndication *ind = new MaxSonarCtrlIndication(IfcNames_ControllerIndication);
  MaxSonarCtrlRequestProxy *device = new MaxSonarCtrlRequestProxy(IfcNames_ControllerRequest);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);

  portalExec_start();

  int dstAlloc = portalAlloc(alloc_sz);
  char *dstBuffer = (char *)portalMmap(dstAlloc, alloc_sz);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);

  char* snapshot = (char*)malloc(alloc_sz);
  sock_server *ss = new sock_server(1234);
  ss->start_server();
  device->range_ctrl(0xFFFFFFFF);

#define MEM_PATH
#ifdef MEM_PATH
  device->sample(ref_dstAlloc, alloc_sz);
  while (true){
    usleep(1);
    set_en(ind,device, 0);
    int datalen = ss->read_circ_buff(alloc_sz, ref_dstAlloc, dstAlloc, dstBuffer, snapshot, ind->write_addr, ind->write_wrap_cnt, 1); 
    set_en(ind,device, 2);
    if (spew) display((uint32_t*)snapshot, datalen/4);
  }
#else
  while(true){
    device->pulse_width();
    sleep(1);
  }
#endif
}
