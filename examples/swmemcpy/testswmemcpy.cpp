/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "portal.h"
#include "dmaManager.h"
#include "sock_utils.h"

int numWords = 16;
size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

class TestPM : public ConnectalMemory
{
public:
  virtual void sglist(uint32_t off, uint64_t addr, uint32_t len) {}
  virtual void paref(uint32_t off, uint32_t ref) {}
  TestPM() : ConnectalMemory(){}
};

void* child(void* prd_sock)
{
  int fd;
  int rd_sock = *((int*)prd_sock);
  sock_fd_read(rd_sock, &fd);

  unsigned int *dstBuffer = (unsigned int *)DmaManager_mmap(fd, alloc_sz);
  //fprintf(stderr, "child::mmap %08x\n", dstBuffer);  

  unsigned int sg = 0;
  bool mismatch = false;
  for (int i = 0; i < numWords; i++){
    mismatch |= (dstBuffer[i] != sg++);
    fprintf(stderr, "%08x, %08x\n", dstBuffer[i], sg-1);
  }
  fprintf(stderr, "child::writeDone mismatch=%d\n", mismatch);
  munmap(dstBuffer, alloc_sz);
  close(fd);
  return NULL;
}


void* parent(void* pwr_sock)
{
  int wr_sock = *((int*)pwr_sock);
  int dstAlloc;
  unsigned int *dstBuffer = 0;
  unsigned int *dba = 0;
  class TestPM *pm = new TestPM();
  
  fprintf(stderr, "parent::allocating memory...\n");
  dstAlloc = pm->alloc(alloc_sz);
  dstBuffer = (unsigned int *)DmaManager_mmap(dstAlloc.header.fd, alloc_sz);
  fprintf(stderr, "parent::mmap %p\n", dstBuffer);  

  for (int i = 0; i < numWords; i++){
    dstBuffer[i] = i;
  }
  
  pm->dCacheFlushInval(dstAlloc, alloc_sz, dstBuffer);
  fprintf(stderr, "parent::flush and invalidate complete\n");

  int rc = ioctl(pm->pa_fd, PA_DEBUG_PK, &dstAlloc);
  fprintf(stderr, "parent::debug ioctl complete (%d)\n",rc);

  dba = (unsigned int *)DmaManager_mmap(dstAlloc.header.fd, alloc_sz);
  fprintf(stderr, "parent::mmap %p\n", dba);  

  unsigned int sg = 0;
  bool mismatch = false;
  for (int i = 0; i < numWords; i++){
    mismatch |= (dba[i] != sg++);
    fprintf(stderr, "%08x, %08x\n", dba[i], dstBuffer[i]);
  }
  fprintf(stderr, "parent::writeDone mismatch=%d\n", mismatch);

  sock_fd_write(wr_sock, NULL, 0, dstAlloc.header.fd);
  munmap(dstBuffer, alloc_sz);
  close(dstAlloc.header.fd);
  return NULL;
}

int main(int argc, const char **argv)
{
  int sv[2];
  int pid;

  if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sv) < 0) {
    perror("socketpair");
    exit(1);
  }
    
  switch ((pid = fork())) {
  case 0:
    close(sv[0]);
    child(&sv[1]);
    break;
  case -1:
    perror("fork");
    exit(1);
  default:
    close(sv[1]);
    parent(&sv[0]);
    break;
  }
}
