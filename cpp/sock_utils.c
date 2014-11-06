
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
#include <netdb.h>

static int trace_socket;// = 1;

int init_listening(const char *arg_name, PortalSocketParam *param)
{
  int listening_socket;

  if (trace_socket)
    printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  if (param) {
       listening_socket = socket(param->addr->ai_family, param->addr->ai_socktype, param->addr->ai_protocol);
       if (listening_socket == -1 || bind(listening_socket, param->addr->ai_addr, param->addr->ai_addrlen) == -1) {
           fprintf(stderr, "%s[%d]: bind error %s\n",__FUNCTION__, listening_socket, strerror(errno));
           exit(1);
       }
  }
  else {
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
    int rc = sendmsg(sockfd, &msg, MSG_DONTWAIT);
    if (rc != nbytes) {
        printf("[%s:%d] error in sendmsg %d %d\n", __FUNCTION__, __LINE__, rc, errno);
        exit(1);
    }
    return rc;
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
printf("[%s:%d] got fd %d\n", __FUNCTION__, __LINE__, *foo);
    }
    return n;
}

void portalSendFd(int fd, void *data, int len, int sendFd)
{
    int rc;
    if (trace_socket)
        printf("%s: fd %d data %p len %d\n", __FUNCTION__, fd, data, len);
    if ((rc = sock_fd_write(fd, data, len, sendFd)) != len) {
        fprintf(stderr, "%s: send len %d error %d\n",__FUNCTION__, rc, errno);
        exit(1);
    }
}
int portalRecvFd(int fd, void *data, int len, int *recvFd)
{
    int rc = sock_fd_read(fd, data, len, recvFd);
    if (trace_socket && rc && rc != -1)
        printf("%s: fd %d data %p len %d rc %d\n", __FUNCTION__, fd, data, len, rc);
    return rc;
}
