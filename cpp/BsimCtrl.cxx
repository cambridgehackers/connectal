
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
#include <sys/types.h>
#include <sys/socket.h>

#include "portal.h"

#include "sock_utils.h"

static struct {
    struct memrequest req;
    unsigned int pnum;
    int valid;
    int inflight;
} head;
static int sockfd;
static struct memresponse respitem;
static int cleanedup;
#define MAX_PATH_LENGTH 100
static char path[MAX_PATH_LENGTH];

extern "C" {
  void initPortal(unsigned long id){
    static int once = 1;
    if (once)
        thread_socket(&sockfd, "fpga0_rc", id);
    once = 0;
  }

  bool processReq32(uint32_t rr){
    if (!head.valid){
	int rv = recv(sockfd, &head.req, sizeof(memrequest), MSG_DONTWAIT);
	if(rv > 0){
	  //fprintf(stderr, "recv size %d\n", rv);
	  assert(rv == sizeof(memrequest));
	  respitem.portal = head.req.portal;
	  head.valid = 1;
	  head.inflight = 1;
	  head.req.addr = (unsigned int *)(((long) head.req.addr) | head.req.portal << 16);
	  if(0)
	  fprintf(stderr, "processReq32(i=%d,rr=%d) {write=%d, addr=%08lx, data=%08x}\n", 
		  head.req.portal, rr, head.req.write_flag, (long)head.req.addr, head.req.data);
          if (!cleanedup && head.req.portal) {
               cleanedup = 1;
               snprintf(path, sizeof(path), "fpga0_rc", 0);
               remove(path);
               remove("fd_sock_wc");
          }
	}
    }
    return head.valid && head.inflight == 1 && head.req.write_flag == rr;
  }

  long processAddr32(int v){
    //fprintf(stderr, "processAddr32()\n");
    head.inflight = 0;
    return (long)head.req.addr;
  }
  
  unsigned int writeData32(){
    //fprintf(stderr, "writeData32()\n");
    head.valid = 0;
    return head.req.data;
  }
  
  void readData32(unsigned int x){
    //fprintf(stderr, "readData()\n");
    respitem.data = x;
    head.valid = 0;
    int send_attempts = 0;
    while(send(sockfd, &respitem, sizeof(respitem), 0) == -1){
      if(send_attempts++ > 16){
	fprintf(stderr, "(%d) send failure\n", respitem.portal);
	exit(1);
      }
      sleep(1);
    }
  }
}
