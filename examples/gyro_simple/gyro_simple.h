
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

#include "GyroCtrlIndication.h"
#include "GeneratedTypes.h"

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

