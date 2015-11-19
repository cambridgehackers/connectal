
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

#ifndef _SOCK_UTILS_H_
#define _SOCK_UTILS_H_
#include "portal.h"   // ssize_t and uint32_t

#define MAX_SIMULATOR_PORTAL_ID 128
#define MAGIC_PORTAL_FOR_SENDING_FD                 666
#define MAGIC_PORTAL_FOR_SENDING_INTERRUPT          999
#define SOCKET_NAME                 bluesimSocketName()

typedef struct PortalSocketParam {
    struct addrinfo *addr;
} PortalSocketParam; /* for ITEMINIT function */

struct memrequest{
  uint32_t portal;
  int write_flag;
  volatile unsigned int *addr;
  unsigned int data_or_tag;
};
struct memresponse{
  uint32_t portal;
  unsigned int data;
  unsigned int tag;
};

#ifdef __cplusplus
extern "C" {
#endif
const char *bluesimSocketName();
void connect_to_bsim(void);
ssize_t sock_fd_write(int sockfd, void *ptr, size_t nbytes, int sendfd);
ssize_t sock_fd_read(int sockfd, void *ptr, size_t nbytes, int *recvfd);
int pareff_fd(int *fd);
void init_pareff(void);
int init_connecting(const char *arg_name, struct PortalSocketParam *param);
int init_listening(const char *arg_name, struct PortalSocketParam *param);
int accept_socket(int arg_listening);
#ifdef __cplusplus
}
#endif

#endif //_SOCK_UTILS_H_
