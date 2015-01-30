
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

#ifdef BSIM
int alloc_sz = 1<<6;
#else
int alloc_sz = 1<<8;
#endif
static sem_t wrap_sem;
static sem_t read_sem;
static sem_t write_sem;
static uint32_t read_val;

class GyroCtrlIndication : public GyroCtrlIndicationWrapper
{
public:
  GyroCtrlIndication(int id) : GyroCtrlIndicationWrapper(id) {}
  virtual void read_reg_resp ( const uint32_t v){
    //fprintf(stderr, "GyroCtrlIndication::read_reg_resp(v=%x)\n", v);
    read_val = v;
    sem_post(&read_sem);
  }
  virtual void write_reg_resp ( const uint32_t v){
    //fprintf(stderr, "GyroCtrlIndication::write_reg_resp(v=%x)\n", v);
    sem_post(&write_sem);
  }
  virtual void sample_wrap(const uint32_t v){
    //fprintf(stderr, "GyroCtrlIndication::sample_wrap(v=%08x)\n", v);
    sem_post(&wrap_sem);
  }
};

int clientsockfd = -1;
int serversockfd = -1;
int portno = 1234;
int connecting_to_client = 0;

void* connect_to_client(void *_x)
{
  struct sockaddr cli_addr;
  socklen_t clilen;
  int *x = (int*)_x;
  listen(serversockfd,5);
  clilen = sizeof(cli_addr);
  clientsockfd = accept(serversockfd, &cli_addr, &clilen);
  if (clientsockfd < 0){ 
    fprintf(stderr, "ERROR on accept\n");
    *x = -1;
    return NULL;
  }
  *x = 0;
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
  bzero((char *) &serv_addr, sizeof(serv_addr));
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


int main(int argc, const char **argv)
{
  GyroCtrlIndication *ind = new GyroCtrlIndication(IfcNames_ControllerIndication);
  GyroCtrlRequestProxy *device = new GyroCtrlRequestProxy(IfcNames_ControllerRequest);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  MMURequestProxy *dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);

  sem_init(&wrap_sem,1,0);
  sem_init(&read_sem,1,0);
  sem_init(&write_sem,1,0);

  portalExec_start();
  start_server();

  int dstAlloc = portalAlloc(alloc_sz);
  unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);

  // setup
  write_reg(device, CTRL_REG1, 0b00001111);  // ODR:100Hz Cutoff:12.5
  write_reg(device, CTRL_REG2, 0b00000000);
  write_reg(device, CTRL_REG3, 0b00000000);
  write_reg(device, CTRL_REG4, 0b10100000);  // BDU:1, Range:2000 dps
  write_reg(device, CTRL_REG5, 0b00000000);
  
  
  if(0){
    for(int i = 0; i < 128; i++){
      short int tmp;
      read_reg(device, OUT_X_H);
      tmp = read_val << 8;
      read_reg(device, OUT_X_L);
      tmp |= read_val;
      fprintf(stderr, "%8d, ", (short int)tmp);
      
      read_reg(device, OUT_Y_H);
      tmp = read_val << 8;
      read_reg(device, OUT_Y_L);
      tmp |= read_val;
      fprintf(stderr, "%8d, ", (short int)tmp);
      
      read_reg(device, OUT_Z_H);
      tmp = read_val << 8;
      read_reg(device, OUT_Z_L);
      tmp |= read_val;
      fprintf(stderr, "%8d\n", (short int)tmp);
    }
  }

  // sample has one two-byte component for each axis (x,y,z).  I want the 
  // wrap-around to work so that the X component always lands in offset 0
  int sample_size = 6;
  int bus_data_width = 8;
  int wrap_limit = alloc_sz-(alloc_sz%(sample_size*bus_data_width)); // want lcm
  fprintf(stderr, "wrap_limit:%08x\n", wrap_limit);

#ifdef BSIM
  device->sample(ref_dstAlloc, wrap_limit, 10);
#else
  // sampling rate of 100Hz. Model running at 100 MHz. 
  device->sample(ref_dstAlloc, wrap_limit, 1000000);
#endif

  signal(SIGPIPE, SIG_IGN);
  pthread_t threaddata;
  int rv;

  while(true){
    sem_wait(&wrap_sem);
    portalDCacheInval(dstAlloc, alloc_sz, dstBuffer);
    if (clientsockfd == -1 && !connecting_to_client){
      connecting_to_client = 1;
      pthread_create(&threaddata, NULL, &connect_to_client, &rv);
    }
    if(0){
      short *ss = (short*)dstBuffer;
      for(int i = 0; i < wrap_limit/2; i+=3){
	fprintf(stderr, "%8d %8d %8d\n", ss[i], ss[i+1], ss[i+2]);
	usleep(100);
      }
    }
    if (clientsockfd != -1){
      int failed = 0;
      if(write(clientsockfd, &(wrap_limit), sizeof(int)) != sizeof(int)){
	failed = 1;
      } else if(write(clientsockfd, dstBuffer,  wrap_limit) != wrap_limit) {
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
}
