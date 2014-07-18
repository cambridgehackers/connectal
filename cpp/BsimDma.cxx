
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

static struct channel dma_sockfd;
static struct {
    unsigned char *buffer;
    uint32_t buffer_len;
    int size_accum;
} dma_info[32];

extern "C" {
  void init_pareff(){
    fprintf(stderr, "BsimDma::init_pareff()\n");
    thread_socket(&dma_sockfd, "fd_sock_wc", 0);
  }

  void write_pareff32(uint32_t pref, uint32_t offset, unsigned int data){
    if(dma_info[pref-1].buffer_len <= offset)
      fprintf(stderr, "write_pareff32(pref=%08x, offset=%08x len=%x) going off the reservation \n", pref, offset, dma_info[pref-1].buffer_len);
    *(unsigned int *)&dma_info[pref-1].buffer[offset] = data;
  }

  unsigned int read_pareff32(uint32_t pref, uint32_t offset){
    if(dma_info[pref-1].buffer_len <= offset)
      fprintf(stderr, "read_pareff32(pref=%08x, offset=%08x len=%x) going off the reservation \n", pref, offset, dma_info[pref-1].buffer_len);
    unsigned int rv = *(unsigned int *)&dma_info[pref-1].buffer[offset];
    //fprintf(stderr, "read_pareff32(pref=%08x, offset=%08x)=%08x\n", pref, offset,rv);
    return rv;
  }

  void write_pareff64(uint32_t pref, uint32_t offset, uint64_t data){
    if(dma_info[pref-1].buffer_len <= offset)
      fprintf(stderr, "write_pareff64(pref=%08x, offset=%08x, len=%08x) going off the reservation \n", pref, offset, dma_info[pref-1].buffer_len);
    *(uint64_t *)&dma_info[pref-1].buffer[offset] = data;
    //fprintf(stderr, "write_pareff64(pref=%08x, offset=%08x, data=%016llx)\n", pref, offset, data);
  }

  uint64_t read_pareff64(uint32_t pref, uint32_t offset){
    if(dma_info[pref-1].buffer_len <= offset)
      fprintf(stderr, "read_pareff64(pref=%08x, offset=%08x len=%x) going off the reservation \n", pref, offset, dma_info[pref-1].buffer_len);
    uint64_t rv = *(uint64_t *)&dma_info[pref-1].buffer[offset];
    //fprintf(stderr, "read_pareff64(pref=%08x, offset=%08x)=%016llx\n", pref, offset,rv);
    return rv;
  }

  void pareff(uint32_t pref, uint32_t size){
    //fprintf(stderr, "BsimDma::pareff pref=%ld, size=%08x size_accum=%08x\n", pref, size, dma_info[pref-1].size_accum);
    assert(pref < 32);
    dma_info[pref-1].size_accum += size;
    if(size == 0){
      int fd;
      sock_fd_read(dma_sockfd.sockfd, &fd);
      dma_info[pref-1].buffer = (unsigned char *)mmap(0,
          dma_info[pref-1].size_accum, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
      dma_info[pref-1].buffer_len = dma_info[pref-1].size_accum/sizeof(unsigned char);
    }
  }
}
