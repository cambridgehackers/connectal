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

  printf("%s (%s)\n",__FUNCTION__,c->path);
  if ((c->s1 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error",__FUNCTION__, c->path);
    exit(1);
  }

  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, c->path);
  unlink(c->local.sun_path);
  int len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  if (bind(c->s1, (struct sockaddr *)&c->local, len) == -1) {
    fprintf(stderr, "%s (%s) bind error\n",__FUNCTION__, c->path);
    exit(1);
  }
  
  if (listen(c->s1, 5) == -1) {
    fprintf(stderr, "%s (%s) listen error\n",__FUNCTION__, c->path);
    exit(1);
  }
  
  fprintf(stderr, "%s (%s) waiting for a connection...\n",__FUNCTION__, c->path);
  if ((c->s2 = accept(c->s1, NULL, NULL)) == -1) {
    fprintf(stderr, "%s (%s) accept error\n",__FUNCTION__, c->path);
    exit(1);
  }
  
  fprintf(stderr, "%s (%s) connected\n",__FUNCTION__,c->path);
  c->connected = true;
  return _xx;
}


void connect_socket(channel *c)
{
  int len;
  int connect_attempts = 0;

  if ((c->s2 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error\n",__FUNCTION__, c->path);
    exit(1);
  }

  printf("%s (%s) trying to connect...\n",__FUNCTION__, c->path);
  
  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, c->path);
  len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  while (connect(c->s2, (struct sockaddr *)&(c->local), len) == -1) {
    if(connect_attempts++ > 10){
      fprintf(stderr,"%s (%s) connect error\n",__FUNCTION__, c->path);
      exit(1);
    }
    sleep(1);
  }
  // int sockbuffsz = sizeof(memrequest);
  // setsockopt(c->s2, SOL_SOCKET, SO_SNDBUF, &sockbuffsz, sizeof(sockbuffsz));
  // sockbuffsz = sizeof(unsigned int);
  // setsockopt(c->s2, SOL_SOCKET, SO_RCVBUF, &sockbuffsz, sizeof(sockbuffsz));
  fprintf(stderr, "%s (%s) connected\n",__FUNCTION__, c->path);
}

