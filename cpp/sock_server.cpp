
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
#include <signal.h>

#include "dmaManager.h"

sock_server::sock_server(int p)
{
  verbose = 0;
  wrap_cnt = 0;
  addr = 0;
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

int sock_server::read_circ_buff(int buff_len, unsigned int ref_dstAlloc, int dstAlloc, char* dstBuffer, char *snapshot, int write_addr, int write_wrap_cnt)
{
  int dwc = write_wrap_cnt - wrap_cnt;
  int two,top,bottom,datalen=0;
  if(dwc == 0){
    assert(addr <= write_addr);
    two = false;
    top = write_addr;
    bottom = addr;
    datalen = write_addr - addr;
  } else if (dwc == 1 && addr > write_addr) {
    two = true;
    top = addr;
    bottom = write_addr;
    datalen = (buff_len-top)+bottom;
  } else if (write_addr == 0) {
    two = false;
    top = buff_len;
    bottom = 0;
    datalen = buff_len;
  } else {
    two = true;
    top = write_addr;
    bottom = write_addr;
    datalen = buff_len;
  }
  top = (top/6)*6;
  bottom = (bottom/6)*6;
  portalDCacheInval(dstAlloc, buff_len, dstBuffer);    
  if (verbose) fprintf(stderr, "two:%d, top:%4x, bottom:%4x, datalen:%4x, dwc:%d\n", two,top,bottom,datalen,dwc);
  if (datalen){
    if (two) {
      memcpy(snapshot,                  dstBuffer+top,    datalen-bottom);
      memcpy(snapshot+(datalen-bottom), dstBuffer,        bottom        );
    } else {
      memcpy(snapshot,                  dstBuffer+bottom, datalen       );
  }
  }
  addr = write_addr;
  wrap_cnt = write_wrap_cnt;
  return datalen;
}
