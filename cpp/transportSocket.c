
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
#include <assert.h>

static int trace_socket; // = 1;

static unsigned int tag_counter;
#define MAX_BSIM_TILES     4
typedef struct bsim_fpga_map_entry{
  uint32_t name;
  int offset;
  int valid;
} bsim_fpga_map_entry;
static bsim_fpga_map_entry bsim_fpga_map[MAX_BSIM_TILES][MAX_BSIM_PORTAL_ID];

static uint32_t read_bsim(uint32_t portal_index, long base, uint32_t offset)
{
    static PortalInternal p;
    p.fpga_number = portal_index;
    volatile unsigned int *ptemp = &((volatile unsigned int *)base)[offset];
    return transportBsim.read(&p, &ptemp);
}
static void initialize_bsim_map(void)
{
  long base_tile = 0;
  uint32_t tile_index = 0;
  uint32_t num_tiles = read_bsim(0, base_tile, PORTAL_CTRL_NUM_TILES);
  if (num_tiles >= MAX_BSIM_TILES) {
      PORTAL_PRINTF("%s: Number of tiles %d exceeds max allowed %d\n", num_tiles, MAX_BSIM_TILES);
      exit(-1);
  }
  do{
    uint32_t portal_index = 0;
    long base_ptr = base_tile;
    uint32_t num_portals = read_bsim(portal_index, base_ptr, PORTAL_CTRL_NUM_PORTALS);
    do{
      uint32_t id = read_bsim(portal_index, base_ptr, PORTAL_CTRL_PORTAL_ID);
      assert(num_portals == read_bsim(portal_index, base_ptr, PORTAL_CTRL_NUM_PORTALS));
      assert(num_tiles   == read_bsim(portal_index, base_ptr, PORTAL_CTRL_NUM_TILES));
      if (id >= MAX_BSIM_PORTAL_ID) {
	PORTAL_PRINTF("%s: [%d] readid too large %d\n", __FUNCTION__, portal_index, id);
	break;
      }
      bsim_fpga_map[tile_index][portal_index].name = id;
      bsim_fpga_map[tile_index][portal_index].offset = portal_index;
      bsim_fpga_map[tile_index][portal_index].valid = 1;
      if (trace_socket)
	PORTAL_PRINTF("%s: bsim_fpga_map[%d/%d][%d/%d]=%d (%d)\n", __FUNCTION__, tile_index, num_tiles, portal_index, num_portals,
		      bsim_fpga_map[tile_index][portal_index].name, (portal_index+1==num_portals));
      portal_index++;
      base_ptr += PORTAL_BASE_OFFSET;
    } while (portal_index < num_portals && portal_index < 32);
    tile_index++;
    base_tile += TILE_BASE_OFFSET;
  } while (tile_index < num_tiles && tile_index < MAX_BSIM_TILES);
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
#include <netdb.h>

void memdump(unsigned char *p, int len, const char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                fprintf(stderr, "\n");
            fprintf(stderr, "%s: ",title);
        }
        fprintf(stderr, "%02x ", *p++);
        i++;
        len--;
    }
    fprintf(stderr, "\n");
}

static pthread_mutex_t socket_mutex;
int global_sockfd = -1;

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
    const char *name = getenv("SOFTWARE_SOCKET_NAME");
    if (!name)
	name = "SWSOCK";
    sprintf(buff, "%s%d", name, pint->fpga_number);
    pint->fpga_fd = init_listening(buff, param);
    ioctl(pint->fpga_fd, FIONBIO, &on);
    pint->map_base = (volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo));
    pint->poller_register = 1;
    return 0;
}
static int init_socketInit(struct PortalInternal *pint, void *aparam)
{
    PortalSocketParam *param = (PortalSocketParam *)aparam;
    char buff[128];
    const char *name = getenv("SOFTWARE_SOCKET_NAME");
    if (!name)
	name = "SWSOCK";
    sprintf(buff, "%s%d", name, pint->fpga_number);
    pint->client_fd[pint->client_fd_number++] = init_connecting(buff, param);
    pint->accept_finished = 1;
    pint->map_base = (volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo));
    pint->poller_register = 1;
    return 0;
}
volatile unsigned int *mapchannel_socket(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[1];
}
static int recv_socket(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    int rc = portalRecvFd(pint->client_fd[pint->indication_index], (void *)buffer, len * sizeof(uint32_t), recvfd);
    if(trace_socket) {
        fprintf(stderr, "[%s:%d] len %d fd %d rc %d\n", __FUNCTION__, __LINE__, len, pint->client_fd[pint->indication_index], rc);
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
       if (len==sizeof(uint32_t) && trace_socket) fprintf(stderr, "[%s:%d] %d\n", __FUNCTION__, __LINE__, pint->map_base[0]);
       if (len == 0) { /* EOF */
           close(pint->client_fd[i]);
           pint->client_fd_number--;
           for (j = i; j < pint->client_fd_number; j++)
                pint->client_fd[j] = pint->client_fd[j+1];
fprintf(stderr, "[%s:%d] disconnect num %d cb %p\n", __FUNCTION__, __LINE__, pint->client_fd_number, pint->cb);
           if (pint->cb)
               pint->cb->disconnect(pint);
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
            if (trace_socket)
                fprintf(stderr, "[%s:%d]afteracc %p accfd %d fd %d\n", __FUNCTION__, __LINE__, pint, pint->fpga_fd, sockfd);
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
        fprintf(stderr, "[%s:%d] hdr %x fpga %x num %d\n", __FUNCTION__, __LINE__, hdr, pint->fpga_number, pint->client_fd_number);
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
PortalTransportFunctions transportSocketResp = {
    init_socketResp, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_req_generic,
    send_socket, recv_socket, busy_portal_null, enableint_portal_null, event_socket, notfull_null};
PortalTransportFunctions transportSocketInit = {
    init_socketInit, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_req_generic,
    send_socket, recv_socket, busy_portal_null, enableint_portal_null, event_socket, notfull_null};


static int init_mux(struct PortalInternal *pint, void *aparam)
{
    PortalMuxParam *param = (PortalMuxParam *)aparam;
    if(trace_socket)
        fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    pint->mux = param->pint;
    pint->map_base = ((volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo) + sizeof(uint32_t))) + 1;
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
        fprintf(stderr, "[%s:%d] hdr %x fpga %x\n", __FUNCTION__, __LINE__, hdr, pint->fpga_number);
    buffer[0] = hdr;
    pint->mux->request_index = pint->request_index;
    pint->mux->item->send(pint->mux, buffer, (pint->fpga_number << 16) | ((hdr + 1) & 0xffff), sendFd);
}
static int recv_mux(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    return pint->mux->item->recv(pint->mux, buffer, len, recvfd);
}
int portal_mux_handler(struct PortalInternal *pint, unsigned int channel, int messageFd)
{
    int i, dummy;
    for (i = 0; i < pint->mux_ports_number; i++) {
        PortalInternal *p = pint->mux_ports[i].pint;
        if (channel == p->fpga_number && p->handler) {
            p->item->recv(p, p->map_base, 1, &dummy);
            p->handler(p, *p->map_base >> 16, messageFd);
        }
    }
    return -1;
}
PortalTransportFunctions transportMux = {
    init_mux, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_socket, mapchannel_req_generic,
    send_mux, recv_mux, busy_portal_null, enableint_portal_null, event_null, notfull_null};

/*
 * BSIM
 */
static struct memresponse shared_response;
static int shared_response_valid;
static uint32_t interrupt_value;
int poll_response(uint32_t id)
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
static void write_fd_portal_bsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  struct memrequest foo = {pint->fpga_number, 1,*addr,v};

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
unsigned int bsim_poll_interrupt(void)
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
void write_fd_portal_bsim(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
    struct memrequest foo = {pint->fpga_number, MAGIC_PORTAL_FOR_SENDING_FD,*addr,v};
    struct file *fmem;

    if (main_program_finished)
        return;
    fmem = fget(v);
    foo.addr = fmem->private_data;
    //printk("[%s:%d] fd %x dmabuf %p\n", __FUNCTION__, __LINE__, v, foo.addr);
    fput(fmem);
    down_interruptible(&bsim_avail);
    memcpy(&upreq, &foo, sizeof(upreq));
    have_request = 1;
    down_interruptible(&bsim_have_response);
}
#endif
static int init_bsim(struct PortalInternal *pint, void *param)
{
#ifdef BSIM
    int found = 0;
    int i;
    initPortalHardware();
    connect_to_bsim();
#ifndef __KERNEL__
    assert(pint->fpga_number < MAX_BSIM_PORTAL_ID);
#endif
    struct bsim_fpga_map_entry* entry = bsim_fpga_map[pint->fpga_tile];
    for (i = 0; entry[i].valid; i++)
      if (entry[i].name == pint->fpga_number) {
	found = 1;
	pint->fpga_number = entry[i].offset;
	break;
      }
    if (!found) {
      PORTAL_PRINTF( "Error: init_bsim: did not find fpga_number %d in tile %d\n", pint->fpga_number, pint->fpga_tile);
      PORTAL_PRINTF( "    Found fpga numbers:");
      for (i = 0; entry[i].valid; i++)
	PORTAL_PRINTF( " %d", entry[i].name);
      PORTAL_PRINTF( "\n");
    }
#ifndef __KERNEL__
    assert(found);
#endif
    pint->map_base = (volatile unsigned int*)(long)((pint->fpga_tile * TILE_BASE_OFFSET)+(pint->fpga_number * PORTAL_BASE_OFFSET));
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
PortalTransportFunctions transportBsim = {
    init_bsim, read_portal_bsim, write_portal_bsim, write_fd_portal_bsim, mapchannel_hardware, mapchannel_req_generic,
    send_portal_null, recv_portal_null, busy_hardware, enableint_hardware, event_portal_bsim, notfull_hardware};
