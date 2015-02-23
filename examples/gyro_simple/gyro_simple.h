
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

#include "GyroCtrlRequest.h"
#include "GyroCtrlIndication.h"
#include "GeneratedTypes.h"
#include "gyro.h"

static int spew = 0;
static int alloc_sz = 1<<10;
static sem_t status_sem;
static sem_t read_sem;
static sem_t write_sem;
static uint32_t read_reg_val;
static int verbose = 0;
static uint32_t write_addr = 0;
static int write_wrap_cnt = 0;
static uint32_t addr = 0;
static int wrap_cnt = 0;

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

void setup_registers(GyroCtrlRequestProxy *device, int ref_dstAlloc, int wrap_limit)
{
  write_reg(device, CTRL_REG1, 0b11001111);  // ODR:800Hz Cutoff:30
  write_reg(device, CTRL_REG2, 0b00000000);
  write_reg(device, CTRL_REG3, 0b00000000);
  write_reg(device, CTRL_REG4, 0b10100000);  // BDU:1, Range:2000 dps
  write_reg(device, CTRL_REG5, 0b00000000);
  // make sure the memwrite is disabled before we start
  set_en(device,0); 
#ifdef BSIM
  device->sample(ref_dstAlloc, wrap_limit, 10);
#else
  // sampling rate of 800Hz. Model running at 100 MHz. 
  device->sample(ref_dstAlloc, wrap_limit, 1000000/8);
#endif
}

int sample_gyro(int wrap_limit, GyroCtrlRequestProxy *device, unsigned int ref_dstAlloc, 
		int dstAlloc, char* dstBuffer, char *snapshot)
{
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
  if (verbose) fprintf(stderr, "two:%d, top:%4x, bottom:%4x, datalen:%4x, dwc:%d\n", two,top,bottom,datalen,dwc);
  if (datalen){
    if (two) {
      memcpy(snapshot,                  dstBuffer+top,    datalen-bottom);
      memcpy(snapshot+(datalen-bottom), dstBuffer,        bottom        );
    } else {
      memcpy(snapshot,                  dstBuffer+bottom, datalen       );
  }
  }
  addr = write_addr;
  wrap_cnt = write_wrap_cnt;
  set_en(device, 2);
  return datalen;
}

