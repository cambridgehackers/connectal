
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

#include "portal.h"
#include "sock_utils.h"

static unsigned int tag_counter;
typedef struct bsim_fpga_map_entry{
  int name;
  int offset;
  int valid;
} bsim_fpga_map_entry;
static bsim_fpga_map_entry bsim_fpga_map[MAX_BSIM_PORTAL_ID];

static void initialize_bsim_map(void)
{
    unsigned int last = 0, idx = 0;
    while (!last && idx < 32) {
        static PortalInternal p;
        volatile unsigned int *ptr=(volatile unsigned int *)(long)(idx * PORTAL_BASE_OFFSET);
        volatile unsigned int *idp = &ptr[PORTAL_CTRL_REG_PORTAL_ID];
        volatile unsigned int *topp = &ptr[PORTAL_CTRL_REG_TOP];
        unsigned int id;
        p.fpga_number = idx;
        id = bsimfunc.read(&p, &idp);
        last = bsimfunc.read(&p, &topp);
        if (id >= MAX_BSIM_PORTAL_ID) {
            PORTAL_PRINTF("%s: [%d] readid too large %d\n", __FUNCTION__, idx, id);
            break;
        }
        bsim_fpga_map[idx].name = id;
        bsim_fpga_map[idx].offset = idx;
        bsim_fpga_map[idx].valid = 1;
        //PORTAL_PRINTF("%s: bsim_fpga_map[%d]=%d (%d)\n", __FUNCTION__, id, bsim_fpga_map[id], last);
        idx++;
    }  
}

#ifndef __KERNEL__
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>      // FIONBIO
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <semaphore.h>
#include <pthread.h>
#include <assert.h>
#include <netdb.h>

void memdump(unsigned char *p, int len, const char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                printf("\n");
            printf("%s: ",title);
        }
        printf("%02x ", *p++);
        i++;
        len--;
    }
    printf("\n");
}

static pthread_mutex_t socket_mutex;
int global_sockfd = -1;
static int trace_socket;// = 1;

int init_connecting(const char *arg_name, PortalSocketParam *param)
{
  int connect_attempts = 0;
  int sockfd;
  struct sockaddr_un sa = {0};
  struct addrinfo addrinfo = { 0, AF_UNIX, SOCK_STREAM, 0};
  struct addrinfo *addr = &addrinfo;

  sa.sun_family = AF_UNIX;
  strcpy(sa.sun_path, arg_name);
  addrinfo.ai_addrlen = sizeof(sa.sun_family) + strlen(sa.sun_path);
  addrinfo.ai_addr = (struct sockaddr *)&sa;

  if (param && param->addr) {
printf("[%s:%d] TCP\n", __FUNCTION__, __LINE__);
      addr = param->addr;
  }
  if ((sockfd = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol)) == -1) {
    PORTAL_PRINTF( "%s[%d]: socket error %s\n",__FUNCTION__, sockfd, strerror(errno));
    exit(1);
  }
  if (trace_socket)
    PORTAL_PRINTF( "%s (%s) trying to connect...\n",__FUNCTION__, arg_name);

  while (connect(sockfd, addr->ai_addr, addr->ai_addrlen) == -1) {
    if(connect_attempts++ > 16){
      PORTAL_PRINTF( "%s (%s) connect error %s\n",__FUNCTION__, arg_name, strerror(errno));
      exit(1);
    }
    if (trace_socket)
      PORTAL_PRINTF( "%s (%s) retrying connection\n",__FUNCTION__, arg_name);
    sleep(1);
  }
  PORTAL_PRINTF( "%s (%s) connected.  Attempts %d\n",__FUNCTION__, arg_name, connect_attempts);
  return sockfd;
}

void connect_to_bsim(void)
{
  if (global_sockfd != -1)
    return;
  global_sockfd = init_connecting(SOCKET_NAME, NULL);
  pthread_mutex_init(&socket_mutex, NULL);
  initialize_bsim_map();
}

static int init_socketResp(struct PortalInternal *pint, void *aparam)
{
    PortalSocketParam *param = (PortalSocketParam *)aparam;
    char buff[128];
    int on = 1;
    sprintf(buff, "SWSOCK%d", pint->fpga_number);
    pint->fpga_fd = init_listening(buff, param);
    ioctl(pint->fpga_fd, FIONBIO, &on);
    pint->map_base = (volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo));
    return 0;
}
static int init_socketInit(struct PortalInternal *pint, void *aparam)
{
    PortalSocketParam *param = (PortalSocketParam *)aparam;
    char buff[128];
    sprintf(buff, "SWSOCK%d", pint->fpga_number);
    pint->client_fd[pint->client_fd_number++] = init_connecting(buff, param);
    pint->accept_finished = 1;
    pint->map_base = (volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo));
    return 0;
}
static volatile unsigned int *mapchannel_socket(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[1];
}
static int recv_socket(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    int rc = portalRecvFd(pint->client_fd[pint->indication_index], (void *)buffer, len * sizeof(uint32_t), recvfd);
    if(trace_socket) {
        printf("[%s:%d] len %d fd %d rc %d\n", __FUNCTION__, __LINE__, len, pint->client_fd[pint->indication_index], rc);
        if (rc > 0) {
        char bname[100];
        sprintf(bname,"RECV%d", pint->client_fd[pint->indication_index]);
        memdump((uint8_t*)buffer, rc, bname);
        }
    }
    return rc;
}
static int event_socket(struct PortalInternal *pint)
{
    int i, j, event_socket_fd;
    for (i = 0; i < pint->client_fd_number;) {
       int len = portalRecvFd(pint->client_fd[i], (void *)pint->map_base, sizeof(uint32_t), &event_socket_fd);
       if (len == 0) { /* EOF */
           close(pint->client_fd[i]);
           pint->client_fd_number--;
           for (j = i; j < pint->client_fd_number; j++)
                pint->client_fd[j] = pint->client_fd[j+1];
       }
       else if (len == -1 && errno == EAGAIN) {
           i++;
           continue;
       }
       else if (len == -1) {
           PORTAL_PRINTF( "%s[%d]: read error %d\n",__FUNCTION__, pint->client_fd[i], errno);
           exit(1);
       }
       pint->indication_index = i;
       if (pint->handler)
           pint->handler(pint, *pint->map_base >> 16, event_socket_fd);
       break;
    }
    if (pint->fpga_fd != -1) {
        int sockfd = accept_socket(pint->fpga_fd);
        if (sockfd != -1) {
printf("[%s:%d]afteracc %p accfd %d fd %d\n", __FUNCTION__, __LINE__, pint, pint->fpga_fd, sockfd);
            pint->client_fd[pint->client_fd_number++] = sockfd;
            pint->accept_finished = 1;
#ifndef NO_CPP_PORTAL_CODE
#ifndef NO_POLLER_SUPPORT
            if (pint->poller)
                addFdToPoller(pint->poller, sockfd);
#endif
#endif
            //return sockfd;
        }
    }
    return -1;
}
static void send_socket(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    volatile unsigned int *buffer = data-1;
    if(trace_socket)
        printf("[%s:%d] hdr %x fpga %x num %d\n", __FUNCTION__, __LINE__, hdr, pint->fpga_number, pint->client_fd_number);
    buffer[0] = hdr;
    while (pint->client_fd_number == 0)
        event_socket(pint);
    if(trace_socket) {
        char bname[100];
        sprintf(bname,"SEND%d", pint->client_fd[pint->request_index]);
        memdump((uint8_t*)buffer, (hdr & 0xffff) * sizeof(uint32_t), bname);
    }
    portalSendFd(pint->client_fd[pint->request_index], (void *)buffer, (hdr & 0xffff) * sizeof(uint32_t), sendFd);
}
PortalItemFunctions socketfuncResp = {
    init_socketResp, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_socket,
    send_socket, recv_socket, busy_portal_null, enableint_portal_null, event_socket, notfull_null};
PortalItemFunctions socketfuncInit = {
    init_socketInit, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_socket,
    send_socket, recv_socket, busy_portal_null, enableint_portal_null, event_socket, notfull_null};


static int init_mux(struct PortalInternal *pint, void *aparam)
{
    PortalMuxParam *param = (PortalMuxParam *)aparam;
    if(trace_socket)
        printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    pint->mux = param->pint;
    pint->map_base = (volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo));
    pint->mux->map_base[0] = -1;
    pint->mux->mux_ports_number++;
    pint->mux->mux_ports = (PortalMuxHandler *)realloc(pint->mux->mux_ports, pint->mux->mux_ports_number * sizeof(PortalMuxHandler));
    pint->mux->mux_ports[pint->mux->mux_ports_number-1].pint = pint;
    return 0;
}
static void send_mux(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    volatile unsigned int *buffer = data-1;
    if(trace_socket)
        printf("[%s:%d] hdr %x fpga %x\n", __FUNCTION__, __LINE__, hdr, pint->fpga_number);
    buffer[0] = hdr;
    pint->mux->request_index = pint->request_index;
    pint->mux->item->send(pint->mux, buffer, (pint->fpga_number << 16) | ((hdr + 1) & 0xffff), sendFd);
}
static int recv_mux(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    return pint->mux->item->recv(pint->mux, buffer, len, recvfd);
}
static int event_mux(struct PortalInternal *pint)
{
    return -1;
}
int portal_mux_handler(struct PortalInternal *pint, unsigned int channel, int messageFd)
{
    int i, dummy;
    for (i = 0; i < pint->mux_ports_number; i++) {
        PortalInternal *p = pint->mux_ports[i].pint;
        if (channel == p->fpga_number) {
            p->item->recv(p, p->map_base, 1, &dummy);
            p->handler(p, *p->map_base >> 16, messageFd);
        }
    }
    return -1;
}
PortalItemFunctions muxfunc = {
    init_mux, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_socket,
    send_mux, recv_mux, busy_portal_null, enableint_portal_null, event_mux, notfull_null};

/*
 * BSIM
 */
static struct memresponse shared_response;
static int shared_response_valid;
static uint32_t interrupt_value;
int poll_response(int id)
{
  int recvFd;
  if (!shared_response_valid) {
      if (portalRecvFd(global_sockfd, &shared_response, sizeof(shared_response), &recvFd) == sizeof(shared_response)) {
          if (shared_response.portal == MAGIC_PORTAL_FOR_SENDING_INTERRUPT)
              interrupt_value = shared_response.data;
          else
              shared_response_valid = 1;
      }
  }
  return shared_response_valid && shared_response.portal == id;
}
unsigned int bsim_poll_interrupt(void)
{
  if (global_sockfd == -1)
      return 0;
  pthread_mutex_lock(&socket_mutex);
  poll_response(-1);
  pthread_mutex_unlock(&socket_mutex);
  return interrupt_value;
}
/* functions called by READL() and WRITEL() macros in application software */
static unsigned int read_portal_bsim(PortalInternal *pint, volatile unsigned int **addr)
{
  struct memrequest foo = {pint->fpga_number, 0,*addr,0};

  pthread_mutex_lock(&socket_mutex);
  foo.data_or_tag = tag_counter++;
  portalSendFd(global_sockfd, &foo, sizeof(foo), -1);
  while (!poll_response(pint->fpga_number)) {
      struct timeval tv = {};
      tv.tv_usec = 10000;
      select(0, NULL, NULL, NULL, &tv);
  }
  unsigned int rc = shared_response.data;
  shared_response_valid = 0;
  pthread_mutex_unlock(&socket_mutex);
  return rc;
}

static void write_portal_bsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  struct memrequest foo = {pint->fpga_number, 1,*addr,v};

  portalSendFd(global_sockfd, &foo, sizeof(foo), -1);
}
void write_portal_fd_bsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  struct memrequest foo = {pint->fpga_number, 1,*addr,v};

printf("[%s:%d] fd %d\n", __FUNCTION__, __LINE__, v);
  portalSendFd(global_sockfd, &foo, sizeof(foo), v);
}
#else // __KERNEL__

/*
 * Used when running application in kernel and BSIM in userspace
 */

#include <linux/kernel.h>
#include <linux/uaccess.h> // copy_to/from_user
#include <linux/mutex.h>
#include <linux/semaphore.h>
#include <linux/slab.h>
#include <linux/dma-buf.h>

extern struct semaphore bsim_start;
static struct semaphore bsim_avail;
static struct semaphore bsim_have_response;
void memdump(unsigned char *p, int len, char *title);
static int have_request;
static struct memrequest upreq;
static struct memresponse downresp;
extern int bsim_relay_running;
extern int main_program_finished;

ssize_t connectal_kernel_read (struct file *f, char __user *arg, size_t len, loff_t *data)
{
    int err;
    if (!bsim_relay_running)
        up(&bsim_start);
    bsim_relay_running = 1;
    if (main_program_finished)
        return 0;          // all done!
    if (!have_request)
        return -EAGAIN;
    if (len > sizeof(upreq))
        len = sizeof(upreq);
    if (upreq.write_flag == MAGIC_PORTAL_FOR_SENDING_FD) // part of sock_fd_write() processing
        upreq.addr = (void *)(long)dma_buf_fd((struct dma_buf *)upreq.addr, O_CLOEXEC); /* get an fd in user process!! */
    err = copy_to_user((void __user *) arg, &upreq, len);
    have_request = 0;
    up(&bsim_avail);
    return len;
}
ssize_t connectal_kernel_write (struct file *f, const char __user *arg, size_t len, loff_t *data)
{
    int err;
    if (len > sizeof(downresp))
        len = sizeof(downresp);
    err = copy_from_user(&downresp, (void __user *) arg, len);
    if (!err)
        up(&bsim_have_response);
    return len;
}

void connect_to_bsim(void)
{
    printk("[%s:%d]\n", __FUNCTION__, __LINE__);
    if (bsim_relay_running)
        return;
    sema_init (&bsim_avail, 1);
    sema_init (&bsim_have_response, 0);
    initialize_bsim_map();
    printk("[%s:%d]\n", __FUNCTION__, __LINE__);
    down_interruptible(&bsim_start);
}

static struct memresponse shared_response;
static int shared_response_valid;
static uint32_t interrupt_value;
static int poll_response(int id)
{
  //int recvFd;
  if (!shared_response_valid) {
#if 0
      if (portalRecvFd(global_sockfd, &shared_response, sizeof(shared_response), &recvFd) == sizeof(shared_response)) {
          if (shared_response.portal == MAGIC_PORTAL_FOR_SENDING_INTERRUPT)
              interrupt_value = shared_response.data;
          else
              shared_response_valid = 1;
      }
#endif
  }
  return shared_response_valid && shared_response.portal == id;
}
static unsigned int bsim_poll_interrupt(void)
{
  if (global_sockfd == -1)
      return 0;
  //pthread_mutex_lock(&socket_mutex);
  poll_response(-1);
  //pthread_mutex_unlock(&socket_mutex);
  return interrupt_value;
}

static unsigned int read_portal_bsim(PortalInternal *pint, volatile unsigned int **addr)
{
  struct memrequest foo = {pint->fpga_number, 0,*addr,0};

    if (main_program_finished)
        return 0;
    foo.data_or_tag = tag_counter++;
    down_interruptible(&bsim_avail);
    memcpy(&upreq, &foo, sizeof(upreq));
    have_request = 1;
    down_interruptible(&bsim_have_response);
    return downresp.data;
}

static void write_portal_bsim(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
    struct memrequest foo = {pint->fpga_number, 1,*addr,v};
    //printk("[%s:%d]\n", __FUNCTION__, __LINE__);
    if (main_program_finished)
        return;
    down_interruptible(&bsim_avail);
    memcpy(&upreq, &foo, sizeof(upreq));
    have_request = 1;
}
void write_portal_fd_bsim(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
    struct memrequest foo = {pint->fpga_number, MAGIC_PORTAL_FOR_SENDING_FD,*addr,v};
    struct file *fmem;

    if (main_program_finished)
        return;
    fmem = fget(v);
    foo.addr = fmem->private_data;
    printk("[%s:%d] fd %x dmabuf %p\n", __FUNCTION__, __LINE__, v, foo.addr);
    fput(fmem);
    down_interruptible(&bsim_avail);
    memcpy(&upreq, &foo, sizeof(upreq));
    have_request = 1;
    down_interruptible(&bsim_have_response);
}
#endif
static int init_bsim(struct PortalInternal *pint, void *param)
{
    int found = 0;
    int i;
#ifdef BSIM
    connect_to_bsim();
#ifndef __KERNEL__
    assert(pint->fpga_number < MAX_BSIM_PORTAL_ID);
#endif
    for (i = 0; bsim_fpga_map[i].valid; i++)
      if (bsim_fpga_map[i].name == pint->fpga_number) {
	found = 1;
	pint->fpga_number = bsim_fpga_map[i].offset;
	break;
      }
    if (!found) {
      PORTAL_PRINTF( "Error: init_bsim: did not find fpga_number %d\n", pint->fpga_number);
      PORTAL_PRINTF( "    Found fpga numbers:");
      for (i = 0; bsim_fpga_map[i].valid; i++)
	PORTAL_PRINTF( " %d", bsim_fpga_map[i].name);
      PORTAL_PRINTF( "\n");
    }
#ifndef __KERNEL__
    assert(found);
#endif
    pint->map_base = (volatile unsigned int*)(long)(pint->fpga_number * PORTAL_BASE_OFFSET);
    pint->item->enableint(pint, 1);
#endif
    return 0;
}
int event_portal_bsim(struct PortalInternal *pint)
{
#ifdef BSIM
    if (pint->fpga_fd == -1 && !bsim_poll_interrupt())
        return -1;
#endif
    return event_hardware(pint);
}
PortalItemFunctions bsimfunc = {
    init_bsim, read_portal_bsim, write_portal_bsim, write_portal_fd_bsim, mapchannel_hardware, mapchannel_hardware,
    send_portal_null, recv_portal_null, busy_hardware, enableint_hardware, event_portal_bsim, notfull_hardware};
