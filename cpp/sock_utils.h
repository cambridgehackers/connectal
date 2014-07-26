
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

struct memrequest{
  int portal;
  int write_flag;
  volatile unsigned int *addr;
  unsigned int data;
};
struct memresponse{
  int portal;
  unsigned int data;
};

#ifdef __cplusplus
extern "C" {
#endif
void connect_to_bsim(void);
void bsim_wait_for_connect(int* psockfd);
ssize_t sock_fd_write(long fd);
int pareff_fd(int *fd);
void init_pareff(void);
int bsim_ctrl_recv(int sockfd, struct memrequest *data);
int bsim_ctrl_send(int sockfd, struct memresponse *data);
#ifdef __cplusplus
}
#endif

#endif //_SOCK_UTILS_H_
