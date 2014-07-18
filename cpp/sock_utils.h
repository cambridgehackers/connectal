
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

#include <sys/un.h>

struct channel{
  int s1;
  int s2;
  struct sockaddr_un local;
  bool connected;
  char path[100];
};

struct portal{
  struct channel read;
  struct channel write;
};

static struct portal iport = {{0,0,{0,""},false, ""},
			      {0,0,{0,""},false, ""}};

void connect_socket(channel *c);
void thread_socket(struct channel* rc, const char *format, int id);
ssize_t sock_fd_write(int sock, int fd);
ssize_t sock_fd_read(int sock, int *fd);

#endif //_SOCK_UTILS_H_
