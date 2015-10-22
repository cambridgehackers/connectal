
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
#include <netdb.h>
#include <netinet/in.h>
#include <signal.h>
#include "dmaManager.h"
#include "sock_utils.h"
#include "GyroSampleStream.h"
#include "gyro_simple.h"
#include "read_buffer.h"

static int spew = 1;
static int host_sw = 1;
#ifdef SIMULATION
static int alloc_sz = 1<<7;
#else
static int alloc_sz = 1<<10;
#endif

int main(int argc, const char **argv)
{
  // this is because I don't want the server to abort when the client goes offline
  signal(SIGPIPE, SIG_IGN); 

  GyroCtrlIndication *ind = new GyroCtrlIndication(IfcNames_GyroCtrlIndicationH2S);
  GyroCtrlRequestProxy *device = new GyroCtrlRequestProxy(IfcNames_GyroCtrlRequestS2H);
  DmaManager *dma = platformInit();

  PortalSocketParam param;
  getaddrinfo("0.0.0.0", "5000", NULL, &param.addr);
  GyroSampleStreamProxy *gssp = new GyroSampleStreamProxy(IfcNames_GyroSampleStream, &transportSocketResp, &param, &GyroSampleStreamJsonProxyReq, 1000);

  int dstAlloc = portalAlloc(alloc_sz, 0);
  char *dstBuffer = (char *)portalMmap(dstAlloc, alloc_sz);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
  
  char* snapshot = (char*)malloc(alloc_sz);
  reader* r = new reader();

  // setup gyro registers and dma infra
  setup_registers(ind,device, ref_dstAlloc, alloc_sz);  
  int drop = 0;

  while(true){
#ifdef SIMULATION
    sleep(5);
#else
    usleep(80000);
#endif
    set_en(ind,device, 0);
    int datalen = r->read_circ_buff(alloc_sz, ref_dstAlloc, dstAlloc, dstBuffer, snapshot, ind->write_addr, ind->write_wrap_cnt); 
    set_en(ind,device, 2);
    drop = send(gssp, snapshot, datalen, drop, spew, host_sw);
  }
}
