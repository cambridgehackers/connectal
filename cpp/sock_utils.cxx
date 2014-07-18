
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

static void* init_socket(void *_xx)
{
  struct channel *c = (struct channel *)_xx;
  //fprintf(stderr, "%s (%s)\n",__FUNCTION__,c->path);
  if ((c->s1 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }

  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, c->path);
  unlink(c->local.sun_path);
  int len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  if (bind(c->s1, (struct sockaddr *)&c->local, len) == -1) {
    fprintf(stderr, "%s (%s) bind error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }
  
  if (listen(c->s1, 5) == -1) {
    fprintf(stderr, "%s (%s) listen error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }
  
  //fprintf(stderr, "%s (%s) waiting for a connection...\n",__FUNCTION__, c->path);
  if ((c->s2 = accept(c->s1, NULL, NULL)) == -1) {
    fprintf(stderr, "%s (%s) accept error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }
  
  //fprintf(stderr, "%s (%s) connected\n",__FUNCTION__,c->path);
  c->connected = true;
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

void connect_socket(channel *c)
{
  int len;
  int connect_attempts = 0;

  if ((c->s2 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s\n",__FUNCTION__, c->path, strerror(errno));
    exit(1);
  }

  //fprintf(stderr, "%s (%s) trying to connect...\n",__FUNCTION__, c->path);
  
  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, c->path);
  len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  while (connect(c->s2, (struct sockaddr *)&(c->local), len) == -1) {
    if(connect_attempts++ > 16){
      fprintf(stderr,"%s (%s) connect error %s\n",__FUNCTION__, c->path, strerror(errno));
      exit(1);
    }
    //fprintf(stderr, "%s (%s) retrying connection\n",__FUNCTION__, c->path);
    sleep(1);
  }
  // int sockbuffsz = sizeof(memrequest);
  // setsockopt(c->s2, SOL_SOCKET, SO_SNDBUF, &sockbuffsz, sizeof(sockbuffsz));
  // sockbuffsz = sizeof(unsigned int);
  // setsockopt(c->s2, SOL_SOCKET, SO_RCVBUF, &sockbuffsz, sizeof(sockbuffsz));
  fprintf(stderr, "%s (%s) connected\n",__FUNCTION__, c->path);
}

