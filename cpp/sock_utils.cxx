
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
#include <sys/socket.h>
#include <sys/un.h>
#include <pthread.h>
#include <semaphore.h>

#include "portal.h"
#include "sock_utils.h"

#define MAX_PATH_LENGTH 100
typedef struct {
    int *psocket;
    int listening_socket;
} SOCKPARAM;

static sem_t socket_mutex;
static int sockfd = -1;

static void connect_socket_internal(int *psockfd, const char *format, int id)
{
  int connect_attempts = 0;
  char path[MAX_PATH_LENGTH];

  snprintf(path, sizeof(path), format, id);
  if ((*psockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s\n",__FUNCTION__, path, strerror(errno));
    exit(1);
  }

  //fprintf(stderr, "%s (%s) trying to connect...\n",__FUNCTION__, path);
  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, path);
  while (connect(*psockfd, (struct sockaddr *)&local, strlen(local.sun_path) + sizeof(local.sun_family)) == -1) {
    if(connect_attempts++ > 16){
      fprintf(stderr,"%s (%s) connect error %s\n",__FUNCTION__, path, strerror(errno));
      exit(1);
    }
    //fprintf(stderr, "%s (%s) retrying connection\n",__FUNCTION__, path);
    sleep(1);
  }
  fprintf(stderr, "%s (%s) connected\n",__FUNCTION__, path);
}

void connect_socket(int *psockfd, const char *format, int id)
{
  if (strncmp(format, "fpga", 4))
    connect_socket_internal(psockfd, format, id);
  else {
    if (sockfd == -1) {
        connect_socket_internal(&sockfd, format, 0);
        sem_init(&socket_mutex, 0, 1);
    }
    *psockfd = sockfd;
  }
}

static void* socket_listen_task(void *_xx)
{
  SOCKPARAM *c = (SOCKPARAM *)_xx;
  
  if (listen(c->listening_socket, 5) == -1) {
    fprintf(stderr, "%s[%d]: listen error %s\n",__FUNCTION__, c->listening_socket, strerror(errno));
    exit(1);
  }
  
  //fprintf(stderr, "%s[%d]: waiting for a connection...\n",__FUNCTION__, c->listening_socket);
  if ((*c->psocket = accept(c->listening_socket, NULL, NULL)) == -1) {
    fprintf(stderr, "%s[%d]: accept error %s\n",__FUNCTION__, c->listening_socket, strerror(errno));
    exit(1);
  }
  return NULL;
}

void thread_socket(int* psockfd, const char *format, int id)
{
  pthread_t tid;
  char path[MAX_PATH_LENGTH];
  SOCKPARAM *param = (SOCKPARAM *)malloc(sizeof(SOCKPARAM));
  snprintf(path, sizeof(path), format, id);

  if ((param->listening_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s: socket error %s",__FUNCTION__, strerror(errno));
    exit(1);
  }

  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, path);
  unlink(local.sun_path);
  int len = strlen(local.sun_path) + sizeof(local.sun_family);
  if (bind(param->listening_socket, (struct sockaddr *)&local, len) == -1) {
    fprintf(stderr, "%s[%d]: bind error %s\n",__FUNCTION__, param->listening_socket, strerror(errno));
    exit(1);
  }

  param->psocket = psockfd;
  if(pthread_create(&tid, NULL, socket_listen_task, (void*)param)){
     fprintf(stderr, "error creating init thread\n");
     exit(1);
  }
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

ssize_t sock_fd_write(int sock, int fd)
{
    char buf[] = "1";
    COMMON_SOCK_FD;
    cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_len = CMSG_LEN(sizeof (int));
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    *((int *) CMSG_DATA(cmsg)) = fd;
    return sendmsg(sock, &msg, 0);
}

ssize_t
sock_fd_read(int sock, int *fd)
{
    ssize_t     size;
    char buf[16];

    COMMON_SOCK_FD;
    *fd = -1;
    size = recvmsg (sock, &msg, 0);
    cmsg = CMSG_FIRSTHDR(&msg);
    if (size > 0 && cmsg && cmsg->cmsg_len == CMSG_LEN(sizeof(int))) {
        if (cmsg->cmsg_level != SOL_SOCKET || cmsg->cmsg_type != SCM_RIGHTS) {
            fprintf(stderr, "%s: invalid message\n", __FUNCTION__);
            exit(1);
        }
        *fd = *((int *) CMSG_DATA(cmsg));
    }
    return size;
}

/* functions called by READL() and WRITEL() macros in application software */
unsigned int read_portal_bsim(volatile unsigned int *addr, int id)
{
  struct memresponse rv;
  struct memrequest foo = {id, 0,addr,0};

  sem_wait(&socket_mutex);
  if (send(sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (fpga%d) send error, errno=%s\n",__FUNCTION__, id, strerror(errno));
    exit(1);
  }
  if(recv(sockfd, &rv, sizeof(rv), 0) == -1){
    fprintf(stderr, "%s (fpga%d) recv error\n",__FUNCTION__, id);
    exit(1);	  
  }
  sem_post(&socket_mutex);
  return rv.data;
}

void write_portal_bsim(volatile unsigned int *addr, unsigned int v, int id)
{
  struct memrequest foo = {id, 1,addr,v};

  sem_wait(&socket_mutex);
  if (send(sockfd, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (fpga%d) send error\n",__FUNCTION__, id);
    //exit(1);
  }
  sem_post(&socket_mutex);
}
