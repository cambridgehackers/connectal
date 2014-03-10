
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/un.h>
#include <pthread.h>
#include <assert.h>
#include <portal.h>

#include "sock_utils.h"

static struct portal portals[16] = {iport,iport,iport,iport,iport,iport,
				    iport,iport,iport,iport,iport,iport,
				    iport,iport,iport,iport};

struct queuestatus{
  struct memrequest req;
  unsigned int pnum;
  bool valid;
  bool inflight;
};

static struct queuestatus  read_head = {{},0,false,false,};
static struct queuestatus write_head = {{},0,false,false,};

static void recv_request(bool rr)
{
  struct queuestatus* head = rr ? &read_head : &write_head;
  if (!head->valid && !head->inflight){
    for(int i = 0; i < 16; i++){
      struct channel* chan = rr ? &(portals[i].read) : &(portals[i].write);
      if(chan->connected){
	int rv = recv(chan->s2, &(head->req), sizeof(memrequest), MSG_DONTWAIT);
	if(rv > 0){
	  //fprintf(stderr, "recv size %d\n", rv);
	  assert(rv == sizeof(memrequest));
	  head->pnum = i;
	  head->valid = true;
	  head->inflight = rr ? false : true;
	  head->req.addr = (unsigned int *)(((long) head->req.addr) | i << 16);
	  if(0)
	  fprintf(stderr, "recv_request(i=%d,rr=%d) {write=%d, addr=%08lx, data=%08x}\n", 
		  i, rr, head->req.write, (long)head->req.addr, head->req.data);
	  break;
	}
      }
    }
  } else {
    //fprintf(stderr, "blocked %d %d %d\n", head->pnum, head->valid, head->inflight);
  }
}

extern "C" {
  void initPortal(unsigned long id){


    pthread_t tid;
    struct channel* rc;
    struct channel* wc;

    assert(id < 16);    

    rc = &(portals[id].read);
    wc = &(portals[id].write);
    
    snprintf(rc->path, sizeof(rc->path), "fpga%ld_rc", id);
    snprintf(wc->path, sizeof(wc->path), "fpga%ld_wc", id);

    if(pthread_create(&tid, NULL,  init_socket, (void*)rc)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }

    if(pthread_create(&tid, NULL,  init_socket, (void*)wc)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }
  }

  bool writeReq32(){
    recv_request(false);
    return (write_head.req.write && write_head.valid && write_head.inflight);
  }
  
  long writeAddr32(){
    //fprintf(stderr, "writeAddr32()\n");
    write_head.inflight = false;
    return (long)write_head.req.addr;
  }
  
  unsigned int writeData32(){
    //fprintf(stderr, "writeData32()\n");
    write_head.valid = false;
    return write_head.req.data;
  }
  
  bool readReq32(){
    recv_request(true);
    return (!read_head.req.write && read_head.valid && !read_head.inflight);
  }
  
  long readAddr32(){
    //fprintf(stderr, "readAddr32()\n");
    read_head.inflight = true;
    return (long)read_head.req.addr;
  }
  
  void readData32(unsigned int x){
    //fprintf(stderr, "readData()\n");
    read_head.valid = false;
    read_head.inflight = false;
    int send_attempts = 0;
    while(send(portals[read_head.pnum].read.s2, &x, sizeof(x), 0) == -1){
      if(send_attempts++ > 16){
	fprintf(stderr, "(%d) send failure\n", read_head.pnum);
	exit(1);
      }
      sleep(1);
    }
  }

}
