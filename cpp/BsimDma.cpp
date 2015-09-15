
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
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <assert.h>
#include <sys/mman.h>
#include <stdlib.h>
#include "sock_utils.h"

#define MAX_DMA_PORTS    4
#define MAX_DMA_IDS     32
typedef struct {
    int fd;
    unsigned char *buffer;
    uint32_t buffer_len;
    int size_accum;
} DMAINFO[MAX_DMA_IDS];
static DMAINFO dma_info[MAX_DMA_PORTS];
static int dma_trace ;//= 1;

#define BUFFER_CHECK \
    if (!dma_info[id][pref].buffer || offset >= dma_info[id][pref].buffer_len) { \
      fprintf(stderr, "BsimDma [%s:%d]: Error: offset %d too large for buffer %p len %d; reference id %d pref %d\n", __FUNCTION__, __LINE__, offset, dma_info[id][pref].buffer, dma_info[id][pref].buffer_len, id, pref); \
      exit(-1); \
    }

extern "C" void write_simDma32(uint32_t pref, uint32_t offset, unsigned int data, uint8_t byteEnable)
{
    uint32_t id = pref>>5;
    pref -= id<<5; 
    if (dma_trace)
      fprintf(stderr, "%s: %d [%d:%d] = %x\n", __FUNCTION__, id, pref, offset, data);
    BUFFER_CHECK
    if (byteEnable != 0xF) {
      uint32_t old_data = *(unsigned int *)&dma_info[id][pref].buffer[offset];
      uint32_t mask = 0;
      for (int i = 0; i < 4; i++) {
	if (byteEnable & (1 << i))
	  mask |= (0xFF << (i*8));
      }
      //fprintf(stderr, "write_simDma32 mask=%08x data=%08x old_data=%08x\n", mask, data, old_data);
      data &= mask;
      old_data &= ~mask;
      //fprintf(stderr, "write_simDma32 mask=%08x data=%08x old_data=%08x\n", mask, data, old_data);
      data = data | old_data;
    }
    *(unsigned int *)&dma_info[id][pref].buffer[offset] = data;
}

extern "C" unsigned int read_simDma32(uint32_t pref, uint32_t offset)
{
    uint32_t id = pref>>5;
    unsigned int ret;
    pref -= id<<5; 
    BUFFER_CHECK
    ret = *(unsigned int *)&dma_info[id][pref].buffer[offset];
    if (dma_trace)
      fprintf(stderr, "%s: %d [%d:%d] = %x\n", __FUNCTION__, id, pref, offset, ret);
    return ret;
}

extern "C" void write_simDma64(uint32_t pref, uint32_t offset, uint64_t data, uint8_t byteEnable)
{
    uint32_t id = pref>>5;
    pref -= id<<5; 
    if (dma_trace)
      fprintf(stderr, "%s: %d [%d:%d] = %llx\n", __FUNCTION__, id, pref, offset, (long long)data);
    BUFFER_CHECK
    if (byteEnable != 0xFF) {
      uint64_t old_data = *(uint64_t *)&dma_info[id][pref].buffer[offset];
      uint64_t mask = 0;
      for (int i = 0; i < 8; i++) {
	if (byteEnable & (1 << i))
	  mask |= (0xFF << (i*8));
      }
      data &= mask;
      old_data &= ~mask;
      data = data | old_data;
    }
    *(uint64_t *)&dma_info[id][pref].buffer[offset] = data;
}

extern "C" uint64_t read_simDma64(uint32_t pref, uint32_t offset)
{
    uint32_t id = pref>>5;
    uint64_t ret;
    pref -= id<<5; 
    BUFFER_CHECK
    ret = *(uint64_t *)&dma_info[id][pref].buffer[offset];
    if (dma_trace)
      fprintf(stderr, "%s: %d [%d:%d] = %llx\n", __FUNCTION__, id, pref, offset, (long long)ret);
    return ret;
}

extern "C" void simDma_initfd(uint32_t aid, uint32_t fd)
{
    uint32_t id = aid >> 16;
    uint32_t pref = aid & 0xffff;
    if (dma_trace)
      fprintf(stderr, "%s: id=%d pref=%d fd=%d\n", __FUNCTION__, id, pref, fd);
    assert(pref < MAX_DMA_IDS);
    dma_info[id][pref].fd = fd;
    assert(dma_info[id][pref].size_accum == 0);
}
extern "C" void simDma_init(uint32_t id, uint32_t pref, uint32_t size)
{
    if (dma_trace)
      fprintf(stderr, "simDma_init: id=%d pref=%d, size=%08x size_accum=%08x\n", id, pref, size, dma_info[id][pref].size_accum);
    assert(pref < MAX_DMA_IDS);
    dma_info[id][pref].size_accum += size;
    if(size == 0){
      if (dma_trace)
          fprintf(stderr, "%s: id=%d pref=%d fd=%d\n", __FUNCTION__, id, pref, dma_info[id][pref].fd);
      dma_info[id][pref].buffer = (unsigned char *)mmap(0,
          dma_info[id][pref].size_accum, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, dma_info[id][pref].fd, 0);
      if (dma_info[id][pref].buffer == MAP_FAILED) {
	fprintf(stderr, "simDma_init Error: mmap failed fd %x buffer %p size %x errno %d\n", dma_info[id][pref].fd, dma_info[id][pref].buffer, size, errno);
	exit(-1);
      }
      dma_info[id][pref].buffer_len = dma_info[id][pref].size_accum;
    }
    if (dma_trace)
      fprintf(stderr, "simDma_init: done\n");
}

extern "C" void simDma_idreturn(uint32_t aid)
{
    uint32_t id = aid >> 16;
    uint32_t pref = aid & 0xffff;
    if (dma_trace)
      fprintf(stderr, "simDma_idreturn: aid=%08x id=%d pref=%d size=%08x\n", aid, id, pref, dma_info[id][pref].size_accum);
    assert(pref < MAX_DMA_IDS);
    int unmapped = munmap(dma_info[id][pref].buffer, dma_info[id][pref].size_accum);
    if (unmapped != 0)
      fprintf(stderr, "%s: failed to unmap id=%d pref=%d fd=%d\n", __FUNCTION__, id, pref, dma_info[id][pref].fd);
    memset(&dma_info[id][pref], 0, sizeof(dma_info[id][pref]));
}
