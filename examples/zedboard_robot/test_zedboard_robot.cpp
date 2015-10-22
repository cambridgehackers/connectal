
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
#include <assert.h>
#include <netinet/in.h>
#include "maxsonar_simple.h"
#include "gyro_simple.h"
#include "hbridge_simple.h"
#include "sock_utils.h"
#include "MaxSonarSampleStream.h"
#include "GyroSampleStream.h"
#include "HBridgeCtrlRequest.h"
#include "MaxSonarCtrlRequest.h"
#include "GyroCtrlRequest.h"
#include "dmaManager.h"
#include "read_buffer.h"

static int spew = 1;
static int host_sw = 1;
static int alloc_sz = 1<<10;

void* drive_hbridges(void *_x)
{
  HBridgeCtrlRequestProxy *device = (HBridgeCtrlRequestProxy*)_x;
  sleep(20);
  // for(int i = 0; i < 2; i++){
  //   MOVE_FOREWARD(POWER_5);
  //   sleep(1);
  //   STOP;
    
  //   MOVE_BACKWARD(POWER_5);
  //   sleep(1);
  //   STOP;
    
  //   TURN_RIGHT(POWER_5);
  //   sleep(1);
  //   STOP;
    
  //   TURN_LEFT(POWER_5);
  //   sleep(1);
  //   STOP;

  //   sleep(1);
  // }
  for(int i = 0; i < 30; i++){
    TURN_RIGHT(POWER_4);
    usleep(100000);
    STOP;
    sleep(1);
  }
  STOP;
  return NULL;
}

int send_aux(GyroSampleStreamProxy *gssp, void*b, int len, int drop, int spew, int send, MaxSonarSampleStreamProxy *msssp, int usecs)
{
  int16_t *ss = (int16_t*)b;
  int i = 3+drop;
  while(i < len/2){
    if (send) {
      gssp->sample(ss[(i-3)+0], ss[(i-3)+1], ss[(i-3)+2]);
      // this is a bit wasteful, but it simplifies test_zedboard_robot.py
      msssp->sample(usecs);
    }
    if (spew) fprintf(stderr, "%8d %8d %8d\n", ss[(i-3)+0], ss[(i-3)+1], ss[(i-3)+2]);
    i+=3;
  }
  int missing = i-(len/2);
  return missing;
}

int main(int argc, const char **argv)
{

  // portals communicating between "main" running on the ARM and the logic running in the FPGA
  HBridgeCtrlIndication hbridge_ind(IfcNames_HBridgeCtrlIndicationH2S);
  HBridgeCtrlRequestProxy *hbridge_ctrl = new HBridgeCtrlRequestProxy(IfcNames_HBridgeCtrlRequestS2H);
  MaxSonarCtrlIndication *maxsonar_ind = new MaxSonarCtrlIndication(IfcNames_MaxSonarCtrlIndicationH2S);
  MaxSonarCtrlRequestProxy *maxsonar_ctrl = new MaxSonarCtrlRequestProxy(IfcNames_MaxSonarCtrlRequestS2H);
  GyroCtrlIndication *gyro_ind = new GyroCtrlIndication(IfcNames_GyroCtrlIndicationH2S);
  GyroCtrlRequestProxy *gyro_ctrl = new GyroCtrlRequestProxy(IfcNames_GyroCtrlRequestS2H);
  DmaManager *dma = platformInit();

  // portals communicating between "main" running on the ARM and SW running on a server somewhere on the network (HOST_SW)
  PortalSocketParam param0;
  getaddrinfo("0.0.0.0", "5000", NULL, &param0.addr);
  GyroSampleStreamProxy *gssp = new GyroSampleStreamProxy(IfcNames_GyroSampleStream, &transportSocketResp, &param0, &GyroSampleStreamJsonProxyReq, 1000);
  PortalSocketParam param1;
  getaddrinfo("0.0.0.0", "5001", NULL, &param1.addr);
  MaxSonarSampleStreamProxy *msssp = new MaxSonarSampleStreamProxy(IfcNames_MaxSonarSampleStream, &transportSocketResp, &param1, &MaxSonarSampleStreamJsonProxyReq, 1000);

  // allocate memory for the gyro controller to write samples to
  int dstAlloc = portalAlloc(alloc_sz, 0);
  char *dstBuffer = (char *)portalMmap(dstAlloc, alloc_sz);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  // set design clock frequency (this is important since our PW modulators depend on this number)
  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
  
  char* snapshot = (char*)malloc(alloc_sz);
  reader* r = new reader();
  //r->verbose = 1;

  // setup gyro registers and dma infra (setup_registers defined gyro_simple.h)
  setup_registers(gyro_ind,gyro_ctrl, ref_dstAlloc, alloc_sz);  
  maxsonar_ctrl->range_ctrl(1);
  int drop = 0;

  // start up the thread to drive the hbridges
  pthread_t threaddata;
  pthread_create(&threaddata, NULL, &drive_hbridges, (void*)hbridge_ctrl);
  
  while(true){
#ifdef SIMULATION
    sleep(5);
#else
    usleep(50000*2);
#endif
    // first read the "current" sonar distance
    maxsonar_ctrl->pulse_width();
    sem_wait(&(maxsonar_ind->pulse_width_sem));
    float distance = ((float)maxsonar_ind->useconds)/147.0;

    // now get the latest window of gyro samples.  begin by disabling gyro writes to the memory buffer
    set_en(gyro_ind,gyro_ctrl, 0);
    // read the memory from the circular buffer into "snapshot"
    int datalen = r->read_circ_buff(alloc_sz, ref_dstAlloc, dstAlloc, dstBuffer, snapshot, gyro_ind->write_addr, gyro_ind->write_wrap_cnt); 
    // re-enable the gyro memwrite
    set_en(gyro_ind,gyro_ctrl, 2);
    
    if (spew) fprintf(stderr, "(%d microseconds == %f inches)\n", maxsonar_ind->useconds, distance);
    // 'datalen' corresponds to the amount of "new" samples the gyro controller has written to memory.
    drop = send_aux(gssp, snapshot, datalen, drop, spew, host_sw, msssp, maxsonar_ind->useconds);
  }
}
