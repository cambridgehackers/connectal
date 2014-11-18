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

#define MAX_FD_ARRAY 10

static struct {
    struct memrequest req;
    int sockfd;
    int valid;
    int inflight;
} head;
static struct memresponse respitem;
static int trace_port;// = 1;
static int fd_array[MAX_FD_ARRAY];
static int fd_array_index = 0;

static void *pthread_worker(void *p)
{
    int listening_socket = init_listening(SOCKET_NAME, NULL);
    if (trace_port)
        fprintf(stderr, "%s[%d]: waiting for a connection...\n",__FUNCTION__, listening_socket);
    while (1) {
        int sockfd = accept(listening_socket, NULL, NULL);
        if (sockfd == -1) {
            fprintf(stderr, "%s[%d]: accept error %s\n",__FUNCTION__, listening_socket, strerror(errno));
            exit(1);
        }
        if (trace_port)
            printf("[%s:%d] sockfd %d\n", __FUNCTION__, __LINE__, sockfd);
        fd_array[fd_array_index++] = sockfd;
    }
}

extern "C" void initPortal(void)
{
    pthread_t threaddata;
    pthread_create(&threaddata, NULL, &pthread_worker, NULL);
}

extern "C" void interruptLevel(uint32_t ivalue)
{
    static struct memresponse respitem;
    int i;
    if (ivalue != respitem.data) {
        respitem.portal = MAGIC_PORTAL_FOR_SENDING_INTERRUPT;
        respitem.data = ivalue;
        if (trace_port)
            printf("%s: %d\n", __FUNCTION__, ivalue);
        for (i = 0; i < fd_array_index; i++)
           portalSendFd(fd_array[i], &respitem, sizeof(respitem), -1);
    }
}

#if 0
static unsigned long long int rdtsc(void)
{
   unsigned long long int x;
   unsigned a, d;

   __asm__ volatile("rdtsc" : "=a" (a), "=d" (d));

   return ((unsigned long long)a) | (((unsigned long long)d) << 32);;
}
#endif
extern "C" bool checkForRequest(uint32_t rr)
{
#if 0
static int counter;
static int timeoutcount;
static int last_short;
static long long last_val;
long long this_val = rdtsc();
last_val = (this_val - last_val)/1000;
counter++;
if (last_val <= 3)
   last_short++;
if (last_short == 2) {
timeoutcount++;
    last_short = 0;
    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 10000;
    select(0, NULL, NULL, NULL, &timeout);
}
last_val = this_val;
#endif
    if (!head.valid){
	int rv = -1, i, recvfd;
        for (i = 0; i < fd_array_index; i++) {
            head.sockfd = fd_array[i];
            rv = portalRecvFd(head.sockfd, &head.req, sizeof(head.req), &recvfd);
	    if(rv > 0){
	        assert(rv == sizeof(memrequest));
	        respitem.portal = head.req.portal;
	        head.valid = 1;
	        head.inflight = 1;
                if (recvfd != -1)
                    head.req.data_or_tag = recvfd;
	        if(trace_port)
	            fprintf(stderr, "processr p=%d w=%d, a=%8lx, dt=%8x:", 
		        head.req.portal, head.req.write_flag, (long)head.req.addr, head.req.data_or_tag);
                break;
	    }
        }
    }
    return head.valid && head.inflight == 1 && head.req.write_flag == (int)rr;
}

extern "C" unsigned long long getRequest32(uint32_t rr)
{
    if(trace_port)
        fprintf(stderr, " get%c", rr ? '\n' : ':');
    if (rr)
        head.valid = 0;
    head.inflight = 0;
    return (((unsigned long long)head.req.data_or_tag) << 32) | ((long)head.req.addr);
}
  
extern "C" void readResponse32(unsigned int data, unsigned int tag)
{
    if(trace_port)
        fprintf(stderr, " read = %x\n", data);
    head.valid = 0;
    respitem.data = data;
    respitem.tag = tag;
    portalSendFd(head.sockfd, &respitem, sizeof(respitem), -1);
}
