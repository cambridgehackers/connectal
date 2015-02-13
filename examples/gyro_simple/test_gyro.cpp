
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
#include <netinet/in.h>
#include <signal.h>

#include "StdDmaIndication.h"
#include "MemServerRequest.h"
#include "MMURequest.h"
#include "dmaManager.h"
#include "sock_utils.h"

#include "GyroCtrlRequest.h"
#include "GyroCtrlIndication.h"
#include "GeneratedTypes.h"

#include "gyro.h"

static int alloc_sz = 1<<10;
static sem_t status_sem;
static sem_t read_sem;
static sem_t write_sem;
static uint32_t read_reg_val;
static int verbose = 0;
static int spew = 0;
static int clientsockfd = -1;
static int serversockfd = -1;
static int portno = 1234;
static int connecting_to_client = 0;
static uint32_t write_addr = 0;
static int write_wrap_cnt = 0;

class GyroCtrlIndication : public GyroCtrlIndicationWrapper
{
public:
  GyroCtrlIndication(int id) : GyroCtrlIndicationWrapper(id) {}
  virtual void read_reg_resp ( const uint32_t v){
    //fprintf(stderr, "GyroCtrlIndication::read_reg_resp(v=%x)\n", v);
    read_reg_val = v;
    sem_post(&read_sem);
  }
  virtual void write_reg_resp ( const uint32_t v){
    //fprintf(stderr, "GyroCtrlIndication::write_reg_resp(v=%x)\n", v);
    sem_post(&write_sem);
  }
  virtual void memwrite_status(const uint32_t addr, const uint32_t wrap_cnt){
    //fprintf(stderr, "GyroCtrlIndication::memwrite_status(addr=%08x, wrap_cnt=%d)\n", addr, wrap_cnt);
    write_addr = addr;
    write_wrap_cnt = wrap_cnt;
    sem_post(&status_sem);
  }
};


void* connect_to_client(void *_x)
{
  struct sockaddr cli_addr;
  socklen_t clilen;
  listen(serversockfd,5);
  clilen = sizeof(cli_addr);
  clientsockfd = accept(serversockfd, &cli_addr, &clilen);
  if (clientsockfd < 0){ 
    fprintf(stderr, "ERROR on accept\n");
    return NULL;
  }
  fprintf(stderr, "connected to client\n");
  connecting_to_client = 0;
  return NULL;
}

int start_server()
{
  int n;
  socklen_t clilen;
  struct sockaddr_in serv_addr;

  serversockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (serversockfd < 0) {
    fprintf(stderr, "ERROR opening socket");
    return -1;
  }
  memset((char *) &serv_addr, 0x0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = htons(portno);
  if (bind(serversockfd, (struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
    fprintf(stderr, "ERROR on binding");
    return -1;
  }
  return 0;
}

void read_reg(GyroCtrlRequestProxy *device, unsigned short addr)
{
  device->read_reg_req(addr);
  sem_wait(&read_sem);
}

void write_reg(GyroCtrlRequestProxy *device, unsigned short addr, unsigned short val)
{
  device->write_reg_req(addr,val);
  sem_wait(&write_sem);
}

void set_en(GyroCtrlRequestProxy *device, unsigned int v)
{
  device->set_en(v);
  if(!v) sem_wait(&status_sem);
}

void display(void *b, int len){
  short *ss = (short*)b;
  for(int i = 0; i < len/2; i+=3){
    fprintf(stderr, "%8d %8d %8d\n", ss[i], ss[i+1], ss[i+2]);
  }
}

int main(int argc, const char **argv)
{
  GyroCtrlIndication *ind = new GyroCtrlIndication(IfcNames_ControllerIndication);
  GyroCtrlRequestProxy *device = new GyroCtrlRequestProxy(IfcNames_ControllerRequest);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);

  sem_init(&status_sem,1,0);
  sem_init(&read_sem,1,0);
  sem_init(&write_sem,1,0);

  portalExec_start();
  start_server();

  int dstAlloc = portalAlloc(alloc_sz);
  char *dstBuffer = (char *)portalMmap(dstAlloc, alloc_sz);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);

  // setup
  write_reg(device, CTRL_REG1, 0b11001111);  // ODR:800Hz Cutoff:30
  write_reg(device, CTRL_REG2, 0b00000000);
  write_reg(device, CTRL_REG3, 0b00000000);
  write_reg(device, CTRL_REG4, 0b10100000);  // BDU:1, Range:2000 dps
  write_reg(device, CTRL_REG5, 0b00000000);
  

#ifndef BSIM
  if(verbose){
    for(int i = 0; i < 32; i++){
      short int tmp;
      read_reg(device, OUT_X_H);
      tmp = read_reg_val << 8;
      read_reg(device, OUT_X_L);
      tmp |= read_reg_val;
      fprintf(stderr, "XXX %8d, ", (short int)tmp);

      read_reg(device, OUT_Y_H);
      tmp = read_reg_val << 8;
      read_reg(device, OUT_Y_L);
      tmp |= read_reg_val;
      fprintf(stderr, "%8d, ", (short int)tmp);

      read_reg(device, OUT_Z_H);
      tmp = read_reg_val << 8;
      read_reg(device, OUT_Z_L);
      tmp |= read_reg_val;
      fprintf(stderr, "%8d\n", (short int)tmp);
    }
  }
#endif
  
  // sample has one two-byte component for each axis (x,y,z).  This is to ensure 
  // that the X component always lands in offset 0 when the HW wraps around
  int sample_size = 6;
  int bus_data_width = 8;
  int wrap_limit = alloc_sz-(alloc_sz%(sample_size*bus_data_width)); 
  fprintf(stderr, "wrap_limit:%08x\n", wrap_limit);

  // make sure the memwrite is disabled before we start
  set_en(device,0); 
#ifdef BSIM
  device->sample(ref_dstAlloc, wrap_limit, 10);
#else
  // sampling rate of 800Hz. Model running at 100 MHz. 
  device->sample(ref_dstAlloc, wrap_limit, 1000000/8);
#endif

  // this is because I don't want the server to abort when the client goes offline
  signal(SIGPIPE, SIG_IGN); 
  pthread_t threaddata;

  uint32_t addr = 0;
  int wrap_cnt = 0;
  char* snapshot = (char*)malloc(alloc_sz);

  while(true){
#ifdef BSIM
    sleep(5);
#else
    usleep(50000);
#endif
    set_en(device, 0);
    int dwc = write_wrap_cnt - wrap_cnt;
    int two,top,bottom,datalen=0;
    if(dwc == 0){
      assert(addr <= write_addr);
      two = false;
      top = write_addr;
      bottom = addr;
      datalen = write_addr - addr;
    } else if (dwc == 1 && addr > write_addr) {
      two = true;
      top = addr;
      bottom = write_addr;
      datalen = (wrap_limit-top)+bottom;
    } else if (write_addr == 0) {
      two = false;
      top = wrap_limit;
      bottom = 0;
      datalen = wrap_limit;
    } else {
      two = true;
      top = write_addr;
      bottom = write_addr;
      datalen = wrap_limit;
    }
    top = (top/6)*6;
    bottom = (bottom/6)*6;
    portalDCacheInval(dstAlloc, alloc_sz, dstBuffer);    
    memcpy(snapshot,dstBuffer,wrap_limit); // we can copy fewer bytes if need be
    set_en(device, 2);
    if (verbose) fprintf(stderr, "two:%d, top:%4x, bottom:%4x, datalen:%4x, dwc:%d\n", two,top,bottom,datalen,dwc);
    if (datalen){
      if (clientsockfd == -1 && !connecting_to_client){
	connecting_to_client = 1;
	pthread_create(&threaddata, NULL, &connect_to_client, NULL);
      }
      if (two){
      	if (spew) display(snapshot+top, wrap_limit-top);
      	if (spew) display(snapshot, bottom);
      } else {
      	if (spew) display(snapshot+bottom, datalen);
      }
      if (clientsockfd != -1 && datalen > 0){
	int failed = 0;
	if(write(clientsockfd, &(datalen), sizeof(int)) != sizeof(int)){
	  failed = 1;
	} else if (two) {
	  if (write(clientsockfd, snapshot+top,  datalen-bottom) != datalen-bottom) {
	    failed = 1;
	  } else if (write(clientsockfd, snapshot,  bottom) != bottom) {
	    failed = 1;
	  }
	} else if (write(clientsockfd, snapshot+bottom,  datalen) != datalen) {
	  failed = 1;
	}
	if (failed){
	  fprintf(stderr, "write to clientsockfd failed\n");
	  shutdown(clientsockfd, 2);
	  close(clientsockfd);
	  clientsockfd = -1;
	}
      }
    }
    addr = write_addr;
    wrap_cnt = write_wrap_cnt;
  } 
}
