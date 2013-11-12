#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>


#include "sock_utils.h"

void* init_socket(void* _xx)
{

  struct channel *c = (struct channel *)_xx;

  printf("(%s) init_socket\n",c->path);
  if ((c->s1 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "(%s) socket error", c->path);
    exit(1);
  }

  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, c->path);
  unlink(c->local.sun_path);
  int len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  if (bind(c->s1, (struct sockaddr *)&c->local, len) == -1) {
    fprintf(stderr, "(%s) bind error", c->path);
    exit(1);
  }
  
  if (listen(c->s1, 5) == -1) {
    fprintf(stderr, "(%s) listen error", c->path);
    exit(1);
  }
  
  fprintf(stderr, "(%s) waiting for a connection...\n", c->path);
  if ((c->s2 = accept(c->s1, NULL, NULL)) == -1) {
    fprintf(stderr, "(%s) accept error", c->path);
    exit(1);
  }
  
  fprintf(stderr, "(%s) connected\n",c->path);
  c->connected = true;
  return _xx;
}


void connect_socket(channel *c)
{
  int len;
  if ((c->s2 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "(%s) socket error", c->path);
    exit(1);
  }

  printf("(%s) trying to connect...\n", c->path);
  
  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, c->path);
  len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  if (connect(c->s2, (struct sockaddr *)&(c->local), len) == -1) {
    fprintf(stderr,"(%s) connect error", c->path);
    exit(1); 
  }
  // int sockbuffsz = sizeof(memrequest);
  // setsockopt(c->s2, SOL_SOCKET, SO_SNDBUF, &sockbuffsz, sizeof(sockbuffsz));
  // sockbuffsz = sizeof(unsigned int);
  // setsockopt(c->s2, SOL_SOCKET, SO_RCVBUF, &sockbuffsz, sizeof(sockbuffsz));
  fprintf(stderr, "(%s) connected\n", c->path);
}

