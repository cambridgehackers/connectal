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
#include <fcntl.h>
#include <sys/types.h>
#include <sys/un.h>
#include <pthread.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <poll.h>

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
	    return 0;
        }
        if (trace_port)
            printf("[%s:%d] sockfd %d\n", __FUNCTION__, __LINE__, sockfd);
        fd_array[fd_array_index++] = sockfd;
    }
    return 0;
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
            if (rv == 0) {
printf("[%s:%d] bluesim socket closed\n", __FUNCTION__, __LINE__);
                exit(0);
            }
	    else if(rv > 0){
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

#define NUM_LINKS 16

struct linkInfo {
    char name[128];
    int listening;
    int socket[1];
    int fd[1];
    uint64_t rxdata[1];
    uint64_t txdata[1];
    pthread_mutex_t mutex;
    int up;
} linkInfo[NUM_LINKS];

struct linkInfo *getLinkInfo(int linknumber, int listening)
{
    char name[128];
    snprintf(name, sizeof(name), "sim.link.%d", linknumber);
    for (int i = 0; i < NUM_LINKS; i++) {
	struct linkInfo *li = &linkInfo[i];
	if (li->name[0] == 0) {
	    strncpy(li->name, name, sizeof(li->name));;
	    li->listening = listening;
	    return li;
	} else if ((strcmp(li->name, name) == 0)
		   && li->listening == listening) {
	    return li;
	}
    }
    return 0;
}

static void *bsimLinkWorker(void *p)
{
    struct linkInfo *li = (struct linkInfo *)p;
    char iname[128];
    int i;
    const char *socketdir = ".";
    if (getenv("SIM_LINK_DIR"))
	socketdir = getenv("SIM_LINK_DIR");

    for (i = 0; i < 1; i++) {
	snprintf(iname, sizeof(iname), "%s/%s", socketdir, li->name);
	if (li->listening) {
	    li->socket[i] = init_listening(iname, NULL);
	    li->fd[i] = accept(li->socket[i], NULL, NULL);
	    if (li->fd[i] == -1) {
		fprintf(stderr, "%s:%d[%d]: accept error %s\n",__FUNCTION__, __LINE__, li->socket[i], strerror(errno));
		return 0;
	    }
	    //fprintf(stderr, "%s:%d[%d]: accept ok fd=%d\n",__FUNCTION__, __LINE__, li->socket[i], li->fd[i]);
	} else {
	    li->socket[i] = 0;
	    li->fd[i] = init_connecting(iname, NULL);
	    //fprintf(stderr, "%s:%d[%d]: connect ok fd=%d\n",__FUNCTION__, __LINE__, li->socket[i], li->fd[i]);
	}
	fcntl(li->fd[i], F_SETFL, O_NONBLOCK);
    }
    li->up = 1;
    return 0;
}

extern "C" void bsimLinkOpen(int linknumber, int listening)
{
    //fprintf(stderr, "%s:%d pid=%d linknumber=%d listening=%d\n", __func__, __LINE__, getpid(), linknumber, listening);
    struct linkInfo *li = getLinkInfo(linknumber, listening);
    if (li) {
	li->listening = listening;
	pthread_mutex_init(&li->mutex, NULL);
	pthread_t threaddata;
	pthread_create(&threaddata, NULL, &bsimLinkWorker, li);
    }
}
extern "C" int bsimLinkUp(int linknumber, int listening)
{
  struct linkInfo *li = getLinkInfo(linknumber, listening);
  if (li)
      return li->up;
  else
      return 0;
}


extern "C" int bsimLinkCanReceive(int linknumber, int listening)
{
    struct linkInfo *li = getLinkInfo(linknumber, listening);
    struct pollfd pollfd[1];
    int i = 0;
    if (!li->fd[i])
	return 0;
    pollfd[0].fd = li->fd[i];
    pollfd[0].events = POLLIN|POLLRDHUP;
    int status = poll(pollfd, 1, 0);
    if (status && pollfd[0].revents & POLLRDHUP) {
	//fprintf(stderr, "%s:%d revents=%d, closing link %s\n", __FUNCTION__, __LINE__, pollfd[0].revents, li->name);
	//close(li->fd[0]);
	//li->fd[0] = 0;
	return 0;
    }
    return status;
}
extern "C" int bsimLinkCanTransmit(int linknumber, int listening)
{
    struct linkInfo *li = getLinkInfo(linknumber, listening);
    struct pollfd pollfd[1];
    int i = 0;
    if (!li->fd[i])
	return 0;
    pollfd[0].fd = li->fd[i];
    pollfd[0].events = POLLOUT|POLLHUP;
    int status = poll(pollfd, 1, 0);
    if (status && pollfd[0].revents&POLLHUP) {
	//fprintf(stderr, "%s:%d revents=%d, closing link %s\n", __FUNCTION__, __LINE__, pollfd[0].revents, li->name);
	//close(li->fd[i]);
	//li->fd[i] = 0;
	return 0;
    }
    return status;
}
extern "C" uint32_t bsimLinkReceive32(int linknumber, int listening)
{
    struct linkInfo *li = getLinkInfo(linknumber, listening);
    uint32_t *prxdata = (uint32_t *)&li->rxdata;
    int i = 0;
    memset(li->rxdata, 0xbc, sizeof(uint32_t));
    int numBytes = read(li->fd[i], li->rxdata, sizeof(uint32_t));
    if (0 && numBytes > 0)
	fprintf(stderr, "%s:%d linknumber=%d listening=%d numBytes=%d\n", __func__, __LINE__, linknumber, listening, numBytes);
    if (numBytes <= 0)
      fprintf(stderr, "%s:%d linknumber=%d listening=%d numBytes=%d errno=%d\n", __func__, __LINE__, linknumber, listening, numBytes, errno);
    return *prxdata;
}
extern "C" int bsimLinkTransmit32(int linknumber, int listening, uint32_t val)
{
    struct linkInfo *li = getLinkInfo(linknumber, listening);
    //fprintf(stderr, "%s:%d linknumber=%d listening=%d val=%d\n", __func__, __LINE__, linknumber, listening, val);
    int i = 0;
    int numBytes = write(li->fd[i], &val, sizeof(uint32_t));
    //fprintf(stderr, "%s:%d linknumber=%d val=%d numBytes=%d\n", __func__, __LINE__, linknumber, val, numBytes);
    return 0;
}
extern "C" uint64_t bsimLinkReceive64(int linknumber, int listening)
{
    struct linkInfo *li = getLinkInfo(linknumber, listening);
    int i = 0;
    memset(li->rxdata, 0xbc, sizeof(uint64_t));
    int numBytes = read(li->fd[i], li->rxdata, sizeof(uint64_t));
    if (0 && numBytes > 0)
	fprintf(stderr, "%s:%d linknumber=%d listening=%d numBytes=%d\n", __func__, __LINE__, linknumber, listening, numBytes);
    if (numBytes <= 0)
      fprintf(stderr, "%s:%d linknumber=%d listening=%d numBytes=%d errno=%d\n", __func__, __LINE__, linknumber, listening, numBytes, errno);
    return *(uint64_t*)&li->rxdata;
}
extern "C" int bsimLinkTransmit64(int linknumber, int listening, uint64_t val)
{
    struct linkInfo *li = getLinkInfo(linknumber, listening);
    //fprintf(stderr, "%s:%d linknumber=%d listening=%d val=%d\n", __func__, __LINE__, linknumber, listening, val);
    int i = 0;
    int numBytes = write(li->fd[i], &val, sizeof(uint64_t));
    //fprintf(stderr, "%s:%d linknumber=%d val=%lld numBytes=%d\n", __func__, __LINE__, linknumber, val, numBytes);
    return 0;
}

