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
#include <signal.h>

#include "dmaManager.h"
#include "read_buffer.h"


int reader::read_circ_buff(int buff_len, unsigned int ref_dstAlloc, int dstAlloc, char* dstBuffer, char *snapshot, int write_addr, int write_wrap_cnt)
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
    fprintf(stderr, "WARNING: sock_server::read_circ_buffer dwc>1\n");
  }
  portalCacheFlush(dstAlloc, dstBuffer, buff_len, 1);
  if (verbose) fprintf(stderr, "bottom:%4x, top:%4x, two:%d, datalen:%4x, dwc:%d\n", bottom,top,two,datalen,dwc);
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
