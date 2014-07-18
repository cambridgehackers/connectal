
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

#include "sock_utils.h"

void connect_socket(channel *c, const char *format, int id)
{
  int connect_attempts = 0;

  snprintf(c->path, sizeof(c->path), format, id);
  if ((c->sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }

  //fprintf(stderr, "%s (%s) trying to connect...\n",__FUNCTION__, c->path);
  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, c->path);
  while (connect(c->sockfd, (struct sockaddr *)&local, strlen(local.sun_path) + sizeof(local.sun_family)) == -1) {
    if(connect_attempts++ > 16){
      fprintf(stderr,"%s (%s) connect error %s\n",__FUNCTION__, c->path, strerror(errno));
      exit(1);
    }
    //fprintf(stderr, "%s (%s) retrying connection\n",__FUNCTION__, c->path);
    sleep(1);
  }
  fprintf(stderr, "%s (%s) connected\n",__FUNCTION__, c->path);
}

static void* init_socket(void *_xx)
{
  struct channel *c = (struct channel *)_xx;
  int listening_socket;
  //fprintf(stderr, "%s (%s)\n",__FUNCTION__,c->path);
  if ((listening_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }

  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, c->path);
  unlink(local.sun_path);
  int len = strlen(local.sun_path) + sizeof(local.sun_family);
  if (bind(listening_socket, (struct sockaddr *)&local, len) == -1) {
    fprintf(stderr, "%s (%s) bind error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }
  
  if (listen(listening_socket, 5) == -1) {
    fprintf(stderr, "%s (%s) listen error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }
  
  //fprintf(stderr, "%s (%s) waiting for a connection...\n",__FUNCTION__, c->path);
  if ((c->sockfd = accept(listening_socket, NULL, NULL)) == -1) {
    fprintf(stderr, "%s (%s) accept error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }
  return NULL;
}

void thread_socket(struct channel* rc, const char *format, int id)
{
   pthread_t tid;
   snprintf(rc->path, sizeof(rc->path), format, id);

   if(pthread_create(&tid, NULL, init_socket, (void*)rc)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
   }
}

/* Thanks to keithp.com for readable examples how to do this! */

#define COMMON_SOCK_FD \
    ssize_t     size; \
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
