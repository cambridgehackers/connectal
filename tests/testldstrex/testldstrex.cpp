// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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
//#include <stdio.h>
//#include <sys/mman.h>
//#include <string.h>
//#include <stdlib.h>
//#include <unistd.h>
//#include <semaphore.h>
//#include <pthread.h>
//#include <errno.h>
//#include <math.h> // frexp(), fabs()
//#include <assert.h>
//#include <stdio.h>
//#include <errno.h>
#include <ext/atomicity.h>
#include "portal.h"
#define CV_XADD __gnu_cxx::__exchange_and_add

int main(int argc, const char **argv)
{
  int totalsize = 4096;
  int fd = portalAlloc(totalsize, 0);
  if (fd < 0) {
    fprintf(stderr, "memory alloc failed\n");
    exit(-1);
  }
  fprintf(stderr, "allocated %d bytes, fd=%d\n", totalsize, fd);
  int *mem = (int*)portalMmap(fd, totalsize);
  *mem = 1;
  fprintf(stderr, "Before CV_XADD: mem=%p *mem=%d\n", mem, *mem);
  CV_XADD(mem, -1);
  fprintf(stderr, "Before CV_XADD: *mem=%d\n", *mem);
  exit(0);
}
