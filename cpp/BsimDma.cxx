
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

#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <assert.h>
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include <portal.h>
#include "sock_utils.h"

struct channel p_fd_write;
static int fd[32];
static unsigned char *buffer[32];
static uint32_t buffer_len[32];
static int size_accum[32]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

extern "C" {
  void init_pareff(){
    fprintf(stderr, "BsimDma::init_pareff()\n");
    thread_socket(&p_fd_write, "fd_sock_wc", 0);
  }

  void write_pareff32(uint32_t pref, uint32_t offset, unsigned int data){
    if(buffer_len[pref-1] <= offset)
      fprintf(stderr, "write_pareff32(pref=%08x, offset=%08x len=%x) going off the reservation \n", pref, offset, buffer_len[pref-1]);
    *(unsigned int *)&buffer[pref-1][offset] = data;
  }

  unsigned int read_pareff32(uint32_t pref, uint32_t offset){
    if(buffer_len[pref-1] <= offset)
      fprintf(stderr, "read_pareff32(pref=%08x, offset=%08x len=%x) going off the reservation \n", pref, offset, buffer_len[pref-1]);
    unsigned int rv = *(unsigned int *)&buffer[pref-1][offset];
    //fprintf(stderr, "read_pareff32(pref=%08x, offset=%08x)=%08x\n", pref, offset,rv);
    return rv;
  }

  void write_pareff64(uint32_t pref, uint32_t offset, uint64_t data){
    if(buffer_len[pref-1] <= offset)
      fprintf(stderr, "write_pareff64(pref=%08x, offset=%08x, len=%08x) going off the reservation \n", pref, offset, buffer_len[pref-1]);
    *(uint64_t *)&buffer[pref-1][offset] = data;
    //fprintf(stderr, "write_pareff64(pref=%08x, offset=%08x, data=%016llx)\n", pref, offset, data);
  }

  uint64_t read_pareff64(uint32_t pref, uint32_t offset){
    if(buffer_len[pref-1] <= offset)
      fprintf(stderr, "read_pareff64(pref=%08x, offset=%08x len=%x) going off the reservation \n", pref, offset, buffer_len[pref-1]);
    uint64_t rv = *(uint64_t *)&buffer[pref-1][offset];
    //fprintf(stderr, "read_pareff64(pref=%08x, offset=%08x)=%016llx\n", pref, offset,rv);
    return rv;
  }


  void pareff(uint32_t pref, uint32_t size){
    //fprintf(stderr, "BsimDma::pareff pref=%ld, size=%08x size_accum=%08x\n", pref, size, size_accum[pref-1]);
    assert(pref < 32);
    size_accum[pref-1] += size;
    if(size == 0){
      sock_fd_read(p_fd_write.sockfd, &(fd[pref-1]));
      buffer[pref-1] = (unsigned char *)mmap(0, size_accum[pref-1], PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd[pref-1], 0);
      buffer_len[pref-1] = size_accum[pref-1]/sizeof(unsigned char);
      // fprintf(stderr, "pareff %d %d\n", pref, size_accum[pref-1]);
      uint32_t* ff = (uint32_t*) buffer[pref-1];
      // fprintf(stderr, "%d: ", pref);
      // for(int i = 0; i < 6; i++)
      // 	fprintf(stderr, "%08x ", ff[i]);
      // fprintf(stderr, "\n");
    }
  }
}
