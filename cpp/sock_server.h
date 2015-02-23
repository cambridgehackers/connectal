
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

#ifndef _SOCK_SERVER_H_
#define _SOCK_SERVER_H_

class sock_server
{
 private:
  int wrap_cnt;
  int addr;
  int verbose;
 public:
  sock_server(int p);
  int clientsockfd;
  int serversockfd;
  int portno;
  pthread_t threaddata;
  int connecting_to_client;
  void* connect_to_client();
  void send_data(char* data, int len);
  int start_server();
  bool disconnected();
  int read_circ_buff(int buff_len, unsigned int ref_dstAlloc, int dstAlloc, char* dstBuffer,char *snapshot, int write_addr, int write_wrap_cnt, int align); 
};
void* connect_to_client_wrapper(void *server);
#endif //_SOCK_SERVER_H_
