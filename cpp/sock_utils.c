
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

#ifndef __KERNEL__
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <semaphore.h>
#include <pthread.h>
#include <assert.h>

int bsim_fpga_map[MAX_BSIM_PORTAL_ID];
static pthread_mutex_t socket_mutex;
int we_are_initiator;
int global_sockfd = -1;
static int trace_socket;// = 1;

int init_connecting(const char *arg_name)
{
  int connect_attempts = 0;
  int sockfd;

  if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s\n",__FUNCTION__, arg_name, strerror(errno));
    exit(1);
  }

  if (trace_socket)
    fprintf(stderr, "%s (%s) trying to connect...\n",__FUNCTION__, arg_name);
  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, arg_name);
  while (connect(sockfd, (struct sockaddr *)&local, strlen(local.sun_path) + sizeof(local.sun_family)) == -1) {
    if(connect_attempts++ > 16){
      fprintf(stderr,"%s (%s) connect error %s\n",__FUNCTION__, arg_name, strerror(errno));
      exit(1);
    }
    if (trace_socket)
      fprintf(stderr, "%s (%s) retrying connection\n",__FUNCTION__, arg_name);
    sleep(1);
  }
  fprintf(stderr, "%s (%s) connected.  Attempts %d\n",__FUNCTION__, arg_name, connect_attempts);
  return sockfd;
}

void connect_to_bsim(void)
{
  static PortalInternal p;
  if (global_sockfd != -1)
    return;
  global_sockfd = init_connecting(SOCKET_NAME);
  pthread_mutex_init(&socket_mutex, NULL);
  unsigned int last = 0;
  unsigned int idx = 0;
  while(!last && idx < 32){
    volatile unsigned int *ptr=(volatile unsigned int *)(long)(idx * PORTAL_BASE_OFFSET);
    volatile unsigned int *idp = &ptr[PORTAL_CTRL_REG_PORTAL_ID];
    volatile unsigned int *topp = &ptr[PORTAL_CTRL_REG_TOP];
    p.fpga_number = idx;
    unsigned int id = read_portal_bsim(&p, &idp);
    last = read_portal_bsim(&p, &topp);
    assert(id < MAX_BSIM_PORTAL_ID);
    bsim_fpga_map[id] = idx++;
    //fprintf(stderr, "%s bsim_fpga_map[%d]=%d (%d)\n", __FUNCTION__, id, bsim_fpga_map[id], last);
  }  
}

int init_listening(const char *arg_name)
{
  int listening_socket;

  if (trace_socket)
    printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  if ((listening_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s: socket error %s",__FUNCTION__, strerror(errno));
    exit(1);
  }

  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, arg_name);
  unlink(local.sun_path);
  int len = strlen(local.sun_path) + sizeof(local.sun_family);
  if (bind(listening_socket, (struct sockaddr *)&local, len) == -1) {
    fprintf(stderr, "%s[%d]: bind error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }

  if (listen(listening_socket, 5) == -1) {
    fprintf(stderr, "%s[%d]: listen error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  if (trace_socket)
      printf("%s: listen(%d)\n", __FUNCTION__, listening_socket);
  return listening_socket;
}

int accept_socket(int arg_listening)
{
    int sockfd = accept(arg_listening, NULL, NULL);
    if (sockfd == -1) {
        if (errno == EAGAIN)
            return -1;
        fprintf(stderr, "%s[%d]: accept error %s\n",__FUNCTION__, arg_listening, strerror(errno));
        exit(1);
    }
    if (trace_socket)
        printf("%s: accept(%d) = %d\n", __FUNCTION__, arg_listening, sockfd);
    return sockfd;
}

// Taken from: UNIX Network Programming, Richard Stevens
// http://www.kohala.com/start/unpv12e.html
ssize_t sock_fd_write(int sockfd, void *ptr, size_t nbytes, int sendfd)
{
    struct msghdr    msg;
    struct iovec     iov[1];
    union {
      struct cmsghdr cm;
      char           control[CMSG_SPACE(sizeof(int))];
    } control_un;
    struct cmsghdr   *cmptr;

    msg.msg_control = control_un.control;
    msg.msg_controllen = 0;
    if (sendfd >= 0) {
        msg.msg_controllen = sizeof(control_un.control);
        cmptr = CMSG_FIRSTHDR(&msg);
        cmptr->cmsg_len = CMSG_LEN(sizeof(int));
        cmptr->cmsg_level = SOL_SOCKET;
        cmptr->cmsg_type = SCM_RIGHTS;
        int *foo = (int *)CMSG_DATA(cmptr);
        *foo = sendfd;
    }
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    iov[0].iov_base = ptr;
    iov[0].iov_len = nbytes;
    msg.msg_iov = iov;
    msg.msg_iovlen = 1;
    return sendmsg(sockfd, &msg, 0);
}

ssize_t sock_fd_read(int sockfd, void *ptr, size_t nbytes, int *recvfd)
{
    struct msghdr    msg;
    struct iovec     iov[1];
    ssize_t          n;
    int              newfd;
    union {
      struct cmsghdr cm;
      char           control[CMSG_SPACE(sizeof(int))];
    } control_un;
    struct cmsghdr   *cmptr;

    //if (trace_socket)
    //    printf("[%s:%d] sock %d\n", __FUNCTION__, __LINE__, sockfd);
    msg.msg_control = control_un.control;
    msg.msg_controllen = sizeof(control_un.control);
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    iov[0].iov_base = ptr;
    iov[0].iov_len = nbytes;
    msg.msg_iov = iov;
    msg.msg_iovlen = 1;

    *recvfd = -1;        /* descriptor was not passed */
    if ( (n = recvmsg(sockfd, &msg, MSG_DONTWAIT)) <= 0)
        return n;
    if ( (cmptr = CMSG_FIRSTHDR(&msg)) && cmptr->cmsg_len == CMSG_LEN(sizeof(int))) {
        if (cmptr->cmsg_level != SOL_SOCKET || cmptr->cmsg_type != SCM_RIGHTS) {
            printf("%s failed\n", __FUNCTION__);
            exit(1);
        }
        int *foo = (int *)CMSG_DATA(cmptr);
        *recvfd = *foo;
    }
    return n;
}

static uint32_t interrupt_value;
void portalSendFd(int fd, void *data, int len, int sendFd)
{
    if (trace_socket)
        printf("%s: init %d fd %d data %p len %d\n", __FUNCTION__, we_are_initiator, fd, data, len);
    if (sock_fd_write(fd, data, len, sendFd) == -1) {
        fprintf(stderr, "%s: send error %d\n",__FUNCTION__, errno);
        exit(1);
    }
}
int portalRecvFd(int fd, void *data, int len, int *recvFd)
{
    int rc = sock_fd_read(fd, data, len, recvFd);
    if (trace_socket && rc && rc != -1)
        printf("%s: init %d fd %d data %p len %d rc %d\n", __FUNCTION__, we_are_initiator, fd, data, len, rc);
    return rc;
}
void portalSend(int fd, void *data, int len)
{
    portalSendFd(fd, data, len, -1);
}
int portalRecv(int fd, void *data, int len)
{
    int recvFd;
    return portalRecvFd(fd, data, len, &recvFd);
}
static struct memresponse shared_response;
static int shared_response_valid;
int poll_response(int id)
{
  if (!shared_response_valid) {
      if (portalRecv(global_sockfd, &shared_response, sizeof(shared_response)) == sizeof(shared_response)) {
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
unsigned int tag_counter;
unsigned int read_portal_bsim(PortalInternal *pint, volatile unsigned int **addr)
{
  struct memrequest foo = {pint->fpga_number, 0,*addr,0};

  pthread_mutex_lock(&socket_mutex);
  foo.data_or_tag = tag_counter++;
  portalSend(global_sockfd, &foo, sizeof(foo));
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

void write_portal_bsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  struct memrequest foo = {pint->fpga_number, 1,*addr,v};

  portalSend(global_sockfd, &foo, sizeof(foo));
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
    down_interruptible(&bsim_start);
}

unsigned int read_portal_bsim(volatile unsigned int *addr, int id)
{
    struct memrequest foo = {id, 0,addr,0};
    //printk("[%s:%d]\n", __FUNCTION__, __LINE__);
    if (main_program_finished)
        return 0;
    down_interruptible(&bsim_avail);
    memcpy(&upreq, &foo, sizeof(upreq));
    have_request = 1;
    down_interruptible(&bsim_have_response);
    return downresp.data;
}

void write_portal_bsim(volatile unsigned int *addr, unsigned int v, int id)
{
    struct memrequest foo = {id, 1,addr,v};
    //printk("[%s:%d]\n", __FUNCTION__, __LINE__);
    if (main_program_finished)
        return;
    down_interruptible(&bsim_avail);
    memcpy(&upreq, &foo, sizeof(upreq));
    have_request = 1;
}
void write_portal_fd_bsim(volatile unsigned int *addr, unsigned int v, int id)
{
    struct memrequest foo = {id, MAGIC_PORTAL_FOR_SENDING_FD,addr,v};
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
