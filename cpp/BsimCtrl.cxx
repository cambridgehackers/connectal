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
    int sockfd;
    unsigned int pnum;
    int valid;
    int inflight;
} head;
static struct memresponse respitem;
static int dma_fd = -1;
static sem_t dma_waiting;
static pthread_mutex_t socket_mutex;
int global_sockfd = -1;
static int trace_port;// = 1;

extern "C" {

void initPortal(unsigned long id){
    static int once = 1;
    if (once) {
        sem_init(&dma_waiting, 0, 0);
        pthread_mutex_init(&socket_mutex, NULL);
        bsim_wait_for_connect();
    }
    once = 0;
}

void interruptLevel(uint32_t ivalue){
    static uint32_t last_level;

    if (ivalue != last_level) {
        last_level = ivalue;
        if (trace_port)
            printf("%s: %d\n", __FUNCTION__, ivalue);
        pthread_mutex_lock(&socket_mutex);
        bsim_ctrl_interrupt(ivalue);
        pthread_mutex_unlock(&socket_mutex);
    }
}

int pareff_fd(int *fd)
{
  if (trace_port)
    printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  sem_wait(&dma_waiting);
  *fd = dma_fd;
  dma_fd = -1;
  return 0;
}

  bool processReq32(uint32_t rr){
    if (!head.valid){
	int rv = bsim_ctrl_recv(&head.sockfd, &head.req);
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
	  if(trace_port) {
	      fprintf(stderr, "processr p=%d w=%d, a=%8lx", 
		  head.req.portal, head.req.write_flag, (long)head.req.addr);
              if (head.req.write_flag)
	          fprintf(stderr, ", d=%8x:", head.req.data);
              else
	          fprintf(stderr, "            :%8x", head.req.data);
          }
	}
    }
    return head.valid && head.inflight == 1 && head.req.write_flag == (int)rr;
  }

  long processAddr32(int rr){
    if(trace_port)
        fprintf(stderr, " addr");
    head.inflight = 0;
    return (long)head.req.addr;
  }
  
  unsigned int writeData32(){
    if(trace_port)
        fprintf(stderr, " write\n");
    head.valid = 0;
    return head.req.data;
  }
  
  void readData32(unsigned int x){
    if(trace_port)
        fprintf(stderr, " read = %x\n", x);
    pthread_mutex_lock(&socket_mutex);
    respitem.data = x;
    bsim_ctrl_send(head.sockfd, &respitem);
    pthread_mutex_unlock(&socket_mutex);
    head.valid = 0;
  }
}
