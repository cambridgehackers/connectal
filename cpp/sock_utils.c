
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
#define SOCKET_NAME                 "socket_for_bluesim"

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

static pthread_mutex_t socket_mutex;
static int global_sockfd = -1;
static int trace_socket;// = 1;
#define MAX_FD_ARRAY 10
static int fd_array[MAX_FD_ARRAY];
static int fd_array_index = 0;

void connect_to_bsim(void)
{
  int connect_attempts = 0;

  if (global_sockfd != -1)
    return;
  if ((global_sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s\n",__FUNCTION__, SOCKET_NAME, strerror(errno));
    exit(1);
  }

  if (trace_socket)
    fprintf(stderr, "%s (%s) trying to connect...\n",__FUNCTION__, SOCKET_NAME);
  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, SOCKET_NAME);
  while (connect(global_sockfd, (struct sockaddr *)&local, strlen(local.sun_path) + sizeof(local.sun_family)) == -1) {
    if(connect_attempts++ > 16){
      fprintf(stderr,"%s (%s) connect error %s\n",__FUNCTION__, SOCKET_NAME, strerror(errno));
      exit(1);
    }
    if (trace_socket)
      fprintf(stderr, "%s (%s) retrying connection\n",__FUNCTION__, SOCKET_NAME);
    sleep(1);
  }
  fprintf(stderr, "%s (%s) connected.  Attempts %d\n",__FUNCTION__, SOCKET_NAME, connect_attempts);
  pthread_mutex_init(&socket_mutex, NULL);
}

static void *pthread_worker(void *p)
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
  strcpy(local.sun_path, SOCKET_NAME);
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
    fprintf(stderr, "%s[%d]: waiting for a connection...\n",__FUNCTION__, listening_socket);
  while (1) {
  int sockfd;
  if ((sockfd = accept(listening_socket, NULL, NULL)) == -1) {
    fprintf(stderr, "%s[%d]: accept error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  if (trace_socket)
    printf("[%s:%d] sockfd %d\n", __FUNCTION__, __LINE__, sockfd);
  fd_array[fd_array_index++] = sockfd;
  }
}

void bsim_wait_for_connect(void)
{
  pthread_t threaddata;

  pthread_create(&threaddata, NULL, &pthread_worker, NULL);
}

/* Thanks to keithp.com for readable examples how to do this! */

#define COMMON_SOCK_FD \
    struct msghdr   msg; \
    struct iovec    iov; \
    union { \
        struct cmsghdr  cmsghdr; \
        char        control[CMSG_SPACE(sizeof (int))]; \
    } cmsgu; \
    struct cmsghdr  *cmsg; \
    \
    iov.iov_base = buf; \
    iov.iov_len = sizeof(buf); \
    msg.msg_name = NULL; \
    msg.msg_namelen = 0; \
    msg.msg_iov = &iov; \
    msg.msg_iovlen = 1; \
    msg.msg_control = cmsgu.control; \
    msg.msg_controllen = sizeof(cmsgu.control);

ssize_t sock_fd_write(int sockfd, int fd)
{
    char buf[] = "1";
    int *iptr;
    COMMON_SOCK_FD;
    cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_len = CMSG_LEN(sizeof (int));
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    iptr = (int *) CMSG_DATA(cmsg);
    *iptr = fd;

printf("[%s:%d] fd %d\n", __FUNCTION__, __LINE__, fd);
  int rv = sendmsg(sockfd, &msg, 0);
  return rv;
}

ssize_t bluesim_sock_fd_write(long fd)
{
  struct memrequest foo = {MAGIC_PORTAL_FOR_SENDING_FD};

  pthread_mutex_lock(&socket_mutex);
  if (send(global_sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s: send error sending fd\n",__FUNCTION__);
    //exit(1);
  }
  int rv = sock_fd_write(global_sockfd, fd);
  pthread_mutex_unlock(&socket_mutex);
  return rv;
}

ssize_t sock_fd_read(int sock, int *fd)
{
    ssize_t     size;
    char buf[16];
    int *iptr;

    if (trace_socket)
        printf("[%s:%d] sock %d\n", __FUNCTION__, __LINE__, sock);
    COMMON_SOCK_FD;
    *fd = -1;
    size = recvmsg (sock, &msg, 0);
    cmsg = CMSG_FIRSTHDR(&msg);
    if (size > 0 && cmsg && cmsg->cmsg_len == CMSG_LEN(sizeof(int))) {
        if (cmsg->cmsg_level != SOL_SOCKET || cmsg->cmsg_type != SCM_RIGHTS) {
            fprintf(stderr, "%s: invalid message\n", __FUNCTION__);
            exit(1);
        }
        iptr = (int *)CMSG_DATA(cmsg);
        *fd = *iptr;
    }
    else {
        printf("sock_fd_read: error in receiving fd %d size %ld len %ld\n", *fd, (long)size, (long)(cmsg?cmsg->cmsg_len:-666));
        printf("sock_fd_read: controllen %lx control %lx\n", (long)msg.msg_controllen, (long)msg.msg_control);
        exit(-1);
    }
    return size;
}

static uint32_t interrupt_value;
unsigned int bsim_poll_interrupt(void)
{
  struct memresponse rv;
  int rc;

  if (global_sockfd == -1)
      return 0;
  pthread_mutex_lock(&socket_mutex);
  rc = recv(global_sockfd, &rv, sizeof(rv), MSG_DONTWAIT);
  if (rc == sizeof(rv) && rv.portal == MAGIC_PORTAL_FOR_SENDING_INTERRUPT)
      interrupt_value = rv.data;
  pthread_mutex_unlock(&socket_mutex);
  return interrupt_value;
}
/* functions called by READL() and WRITEL() macros in application software */
unsigned int read_portal_bsim(volatile unsigned int *addr, int id)
{
  struct memrequest foo = {id, 0,addr,0};
  struct memresponse rv;

  pthread_mutex_lock(&socket_mutex);
  if (send(global_sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (fpga%d) send error, errno=%s\n",__FUNCTION__, id, strerror(errno));
    exit(1);
  }
  while (1) {
    if(recv(global_sockfd, &rv, sizeof(rv), 0) == -1){
      fprintf(stderr, "%s (fpga%d) recv error\n",__FUNCTION__, id);
      exit(1);	  
    }
    if (rv.portal == MAGIC_PORTAL_FOR_SENDING_INTERRUPT)
      interrupt_value = rv.data;
    else
      break;
  }
  pthread_mutex_unlock(&socket_mutex);
  return rv.data;
}

void write_portal_bsim(volatile unsigned int *addr, unsigned int v, int id)
{
  struct memrequest foo = {id, 1,addr,v};

  pthread_mutex_lock(&socket_mutex);
  if (send(global_sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (fpga%d) send error\n",__FUNCTION__, id);
    exit(1);
  }
  pthread_mutex_unlock(&socket_mutex);
}

int bsim_ctrl_recv(int *sockfd, struct memrequest *data)
{
  int i, rc = -1;
  for (i = 0; i < fd_array_index; i++) {
  *sockfd = fd_array[i];
  rc = recv(*sockfd, data, sizeof(*data), MSG_DONTWAIT);
  if (0 && rc > 0 && trace_socket)
      printf("[%s:%d] sock %d rc %d\n", __FUNCTION__, __LINE__, *sockfd, rc);
  if (rc == sizeof(*data) && data->portal == MAGIC_PORTAL_FOR_SENDING_FD) {
    int new_fd;
    sock_fd_read(*sockfd, &new_fd);
    data->data = new_fd;
  }
  if (rc > 0)
    break;
  }
  return rc;
}
void bsim_ctrl_interrupt(int ivalue)
{
  static struct memresponse respitem;
  int i;

  for (i = 0; i < fd_array_index; i++) {
     respitem.portal = MAGIC_PORTAL_FOR_SENDING_INTERRUPT;
     respitem.data = ivalue;
     bsim_ctrl_send(fd_array[i], &respitem);
  }
}

int bsim_ctrl_send(int sockfd, struct memresponse *data)
{
  return send(sockfd, data, sizeof(*data), 0);
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

ssize_t xbsv_kernel_read (struct file *f, char __user *arg, size_t len, loff_t *data)
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
    if (upreq.portal == MAGIC_PORTAL_FOR_SENDING_FD) // part of sock_fd_write() processing
        upreq.addr = (void *)(long)dma_buf_fd((struct dma_buf *)upreq.addr, O_CLOEXEC); /* get an fd in user process!! */
    err = copy_to_user((void __user *) arg, &upreq, len);
    have_request = 0;
    up(&bsim_avail);
    return len;
}
ssize_t xbsv_kernel_write (struct file *f, const char __user *arg, size_t len, loff_t *data)
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
ssize_t bluesim_sock_fd_write(long fd)
{
    struct memrequest foo = {MAGIC_PORTAL_FOR_SENDING_FD};
    struct file *fmem;

    if (main_program_finished)
        return 0;
    fmem = fget(fd);
    foo.addr = fmem->private_data;
    printk("[%s:%d] fd %lx dmabuf %p\n", __FUNCTION__, __LINE__, fd, foo.addr);
    fput(fmem);
    down_interruptible(&bsim_avail);
    memcpy(&upreq, &foo, sizeof(upreq));
    have_request = 1;
    down_interruptible(&bsim_have_response);
    return 0;
}
#endif
