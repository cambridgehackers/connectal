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
static int dma_fd = -1;
static sem_t dma_waiting;

extern "C" {
  void initPortal(unsigned long id){
    static int once = 1;
    if (once) {
        sem_init(&dma_waiting, 0, 0);
        bsim_wait_for_connect(&sockfd);
    }
    once = 0;
  }

void init_pareff()
{
}

int pareff_fd(int *fd)
{
  sem_wait(&dma_waiting);
  *fd = dma_fd;
  dma_fd = -1;
  return 0;
}

  bool processReq32(uint32_t rr){
    if (!head.valid){
	int rv = bsim_ctrl_recv(sockfd, &head.req);
	if(rv > 0){
	  //fprintf(stderr, "recv size %d\n", rv);
	  assert(rv == sizeof(memrequest));
	  respitem.portal = head.req.portal;
	  if (head.req.portal == MAGIC_PORTAL_FOR_SENDING_FD) {
              dma_fd = head.req.data;
              sem_post(&dma_waiting);
              return 0;
          }
	  head.valid = 1;
	  head.inflight = 1;
	  head.req.addr = (unsigned int *)(((long) head.req.addr) | head.req.portal << 16);
	  if(0)
	  fprintf(stderr, "processReq32(i=%d,rr=%d) {write=%d, addr=%08lx, data=%08x}\n", 
		  head.req.portal, rr, head.req.write_flag, (long)head.req.addr, head.req.data);
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
    bsim_ctrl_send(sockfd, &respitem);
  }
}
