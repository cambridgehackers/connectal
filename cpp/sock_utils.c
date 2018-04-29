
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
#include <arpa/inet.h>

static int trace_socket ;//= 1;

const char *bluesimSocketName()
{
  char *name = getenv("BLUESIM_SOCKET_NAME");
  return name ? name : "socket_for_bluesim";
}

int init_listening(const char *arg_name, PortalSocketParam *param)
{
    int listening_socket;
    struct sockaddr_un sa = {0};
    sa.sun_family = AF_UNIX;
    strcpy(sa.sun_path, arg_name);
    struct addrinfo addrinfo = { 0, AF_UNIX, SOCK_STREAM, 0};
    addrinfo.ai_addrlen =
#ifdef __APPLE__
        SUN_LEN(&sa);
#else
        sizeof(sa.sun_family) + strlen(sa.sun_path);
#endif
    addrinfo.ai_addr = (struct sockaddr *)&sa;
    struct addrinfo *addr = &addrinfo;

    if (trace_socket)
        fprintf(stderr, "[%s:%d] listenName %s\n", __FUNCTION__, __LINE__, arg_name);
    if (param && param->addr) {
        fprintf(stderr, "[%s:%d] TCP\n", __FUNCTION__, __LINE__);
        addr = param->addr;
        // added these for android
        addr->ai_socktype = SOCK_STREAM;
        addr->ai_protocol = 0;
    }
    else
        unlink(sa.sun_path);
    listening_socket = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol);

    int tmp = 1;
    setsockopt(listening_socket, SOL_SOCKET, SO_REUSEADDR, &tmp, sizeof(tmp));
    if (listening_socket == -1 || bind(listening_socket, addr->ai_addr, addr->ai_addrlen) == -1) {
        fprintf(stderr, "%s[%d]: bind error %s\n",__FUNCTION__, listening_socket, strerror(errno));
        exit(1);
    }

    if (listen(listening_socket, 5) == -1) {
        fprintf(stderr, "%s[%d]: listen error %s\n",__FUNCTION__, listening_socket, strerror(errno));
        exit(1);
    }
    if (trace_socket)
        fprintf(stderr, "%s: listen(%d)\n", __FUNCTION__, listening_socket);
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
        fprintf(stderr, "%s: accept(%d) = %d\n", __FUNCTION__, arg_listening, sockfd);
    return sockfd;
}

int init_connecting(const char *arg_name, PortalSocketParam *param)
{
    int connect_attempts = 0;
    int sockfd;
    struct sockaddr_un sa = {0};
    struct addrinfo addrinfo = { 0, AF_UNIX, SOCK_STREAM, 0};
    struct addrinfo *addr = &addrinfo;

    sa.sun_family = AF_UNIX;
    strcpy(sa.sun_path, arg_name);
    addrinfo.ai_addrlen = 
#ifdef __APPLE__
        SUN_LEN(&sa);
#else
        sizeof(sa.sun_family) + strlen(sa.sun_path);
#endif
    addrinfo.ai_addr = (struct sockaddr *)&sa;

    if (param && param->addr) {
	if (trace_socket) fprintf(stderr, "[%s:%d] TCP\n", __FUNCTION__, __LINE__);
        addr = param->addr;
    }
    if ((sockfd = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol)) == -1) {
        PORTAL_PRINTF( "%s[%d]: socket error %s\n",__FUNCTION__, sockfd, strerror(errno));
	return -1;
    }
    if (trace_socket)
        PORTAL_PRINTF( "%s (%s) trying to connect...\n",__FUNCTION__, arg_name);

    while (connect(sockfd, addr->ai_addr, addr->ai_addrlen) == -1) {
        if(connect_attempts++ > 16){
            PORTAL_PRINTF( "%s (%s) connect error %s\n",__FUNCTION__, arg_name, strerror(errno));
            return -1;
        }
        if (trace_socket)
            PORTAL_PRINTF( "%s (%s) retrying connection\n",__FUNCTION__, arg_name);
        sleep(1);
    }
    if (trace_socket) PORTAL_PRINTF( "%s (%s) connected.  Attempts %d\n",__FUNCTION__, arg_name, connect_attempts);
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
        memset(&control_un, 0, sizeof(control_un));
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
#ifdef __APPLE__
    ssize_t bytesSent = send(sockfd, ptr, nbytes, 0);
#else
    ssize_t bytesSent = sendmsg(sockfd, &msg, 0);
#endif
    if (bytesSent != (ssize_t)nbytes) {
        fprintf(stderr, "[%s:%d] error in sendmsg %ld %d\n", __FUNCTION__, __LINE__, (long)bytesSent, errno);
        exit(1);
    }
    return bytesSent;
}

ssize_t sock_fd_read(int sockfd, void *ptr, size_t nbytes, int *recvfd)
{
    struct msghdr    msg;
    struct iovec     iov[1];
    ssize_t          n;
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
    if ((n = recvmsg(sockfd, &msg, MSG_DONTWAIT)) <= 0)
        return n;
    if ((cmptr = CMSG_FIRSTHDR(&msg)) && cmptr->cmsg_len == CMSG_LEN(sizeof(int))) {
        if (cmptr->cmsg_level != SOL_SOCKET || cmptr->cmsg_type != SCM_RIGHTS) {
            fprintf(stderr, "%s failed\n", __FUNCTION__);
            exit(1);
        }
        int *datap = (int *)CMSG_DATA(cmptr);
        *recvfd = *datap;
        if (trace_socket)
            fprintf(stderr, "[%s:%d] got fd %d\n", __FUNCTION__, __LINE__, *datap);
    }
    if (n != (ssize_t)nbytes) {
        iov[0].iov_base = (void *)((unsigned long)iov[0].iov_base + n);
        iov[0].iov_len -= n;
        if ((n = recvmsg(sockfd, &msg, 0)) <= 0)
            return n;
    }
    return n;
}

void portalSendFd(int fd, void *data, int len, int sendFd)
{
    int rc;
    if (trace_socket)
        fprintf(stderr, "%s: fd %d data %p len %d\n", __FUNCTION__, fd, data, len);
    if ((rc = sock_fd_write(fd, data, len, sendFd)) != len) {
        fprintf(stderr, "%s: send len %d error %d\n",__FUNCTION__, rc, errno);
        exit(1);
    }
}
int portalRecvFd(int fd, void *data, int len, int *recvFd)
{
    int rc = sock_fd_read(fd, data, len, recvFd);
    if (trace_socket && rc && rc != -1)
        fprintf(stderr, "%s: fd %d data %p len %d rc %d\n", __FUNCTION__, fd, data, len, rc);
    return rc;
}
