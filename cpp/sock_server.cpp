
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
#include <semaphore.h>
#include <pthread.h>
#include <assert.h>
#include <netdb.h>
#include <arpa/inet.h>
#include "sock_server.h"

sock_server::sock_server(int p)
{
  clientsockfd = -1;
  serversockfd = -1;
  connecting_to_client = 0;
  portno = p;
  // this is because I don't want the server to abort when the client goes offline
  signal(SIGPIPE, SIG_IGN); 
}

void* sock_server::connect_to_client()
{
  connecting_to_client = 1;
  struct sockaddr cli_addr;
  socklen_t clilen;
  listen(serversockfd,5);
  clilen = sizeof(cli_addr);
  clientsockfd = accept(serversockfd, &cli_addr, &clilen);
  if (clientsockfd < 0){ 
    fprintf(stderr, "ERROR on accept\n");
    return NULL;
  }
  fprintf(stderr, "connected to client\n");
  connecting_to_client = 0;
  return NULL;
}

int sock_server::start_server()
{
  int n;
  socklen_t clilen;
  struct sockaddr_in serv_addr;
  serversockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (serversockfd < 0) {
    fprintf(stderr, "ERROR opening socket");
    return -1;
  }
  memset((char *) &serv_addr, 0x0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = htons(portno);
  if (bind(serversockfd, (struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
    fprintf(stderr, "ERROR on binding");
    return -1;
  }
  return 0;
}

void sock_server::send_data(char *snapshot, int datalen)
{
  if (clientsockfd == -1 && !connecting_to_client){
    connecting_to_client = 1;
    pthread_create(&threaddata, NULL, &connect_to_client_wrapper, this);
  }
  if (datalen){
    if (clientsockfd != -1){
      int failed = 0;
      if(write(clientsockfd, &(datalen), sizeof(int)) != sizeof(int)){
	failed = 1;
      } else if (write(clientsockfd, snapshot,  datalen) != datalen) {
	failed = 1;
      }
      if (failed){
	fprintf(stderr, "write to clientsockfd failed\n");
	shutdown(clientsockfd, 2);
	close(clientsockfd);
	clientsockfd = -1;
      }
    }
  }
}

void* connect_to_client_wrapper(void *server)
{
  return ((sock_server*)server)->connect_to_client();
}

