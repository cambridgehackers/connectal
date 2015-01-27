
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
int alloc_sz = 1<<8;
#else
int alloc_sz = 1<<14;
#endif
static sem_t wrap_sem;
int ss[3];

class GyroCtrlIndication : public GyroCtrlIndicationWrapper
{
public:
  GyroCtrlIndication(int id) : GyroCtrlIndicationWrapper(id) {}
  virtual void read_reg_resp ( const uint32_t v){
    fprintf(stderr, "GyroCtrlIndication::read_reg_resp(v=%x)\n", v);
  }
  virtual void sample_wrap(const uint32_t v){
    fprintf(stderr, "GyroCtrlIndication::sample_wrap(v=%08x)\n", v);
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
  portalExec_start();
  start_server();

  int dstAlloc = portalAlloc(alloc_sz);
  unsigned int *dstBuffer = (unsigned int *)portalMmap(dstAlloc, alloc_sz);
  unsigned int ref_dstAlloc = dma->reference(dstAlloc);

  long req_freq = 100000000; // 100 mHz
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);
  sleep(1);

  // setup
  // Enable x, y, z and turn off power down:
  device->write_reg(CTRL_REG1, 0b11001111);
  sleep(1);

  // If you'd like to adjust/use the HPF, you can edit the line below to configure CTRL_REG2:
  device->write_reg(CTRL_REG2, 0b00000000);
  sleep(1);

  // Configure CTRL_REG3 to generate data ready interrupt on INT2
  // No interrupts used on INT1, if you'd like to configure INT1
  // or INT2 otherwise, consult the datasheet:
  device->write_reg(CTRL_REG3, 0b00001000);
  sleep(1);

  // CTRL_REG4 controls the full-scale range, among other things:
  device->write_reg(CTRL_REG4, 0b00110000);
  sleep(1);

  // CTRL_REG5 controls high-pass filtering of outputs, use it
  // if you'd like:
  device->write_reg(CTRL_REG5, 0b00000000);
  sleep(1);

  // sample has one two-byte component for each axis (x,y,z).  I want the 
  // wrap-around to work so that the X component always lands in offset 0
  int sample_size = 6;
  int bus_data_width = 8;
  int wrap_limit = alloc_sz-(alloc_sz%(sample_size*bus_data_width)); // want lcm
  int cnt = 0;

  fprintf(stderr, "wrap_limit:%08x\n", wrap_limit);

#ifdef BSIM
  device->sample(ref_dstAlloc, wrap_limit, 10);
#else
  device->sample(ref_dstAlloc, wrap_limit, 200);
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
    if (0) {
      short *ss = (short*)dstBuffer;
      for(int i = 0; i < wrap_limit/2; i+=3){
	fprintf(stderr, "%d %d %d\r", ss[i], ss[i+1], ss[i+2]);
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
