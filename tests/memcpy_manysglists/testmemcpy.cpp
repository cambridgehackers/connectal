/* Copyright (c) 2013 Quanta Research Cambridge, Inc
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
#include <monkit.h>
#include "dmaManager.h"
#include "MemcpyIndication.h"
#include "MemcpyRequest.h"

sem_t done_sem;
int srcAlloc;
int dstAlloc;
unsigned int *srcBuffer = 0;
unsigned int *dstBuffer = 0;
int numWords = 16 << 2;
size_t alloc_sz = numWords*sizeof(unsigned int);
bool memcmp_fail = false;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (unsigned int i = 0; i < len ; i++) {
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
	if (i % 32 == 31)
	  fprintf(stderr, "\n");
    }
    fprintf(stderr, "\n");
}

class MemcpyIndication : public MemcpyIndicationWrapper
{

public:
  MemcpyIndication(unsigned int id) : MemcpyIndicationWrapper(id){}

  virtual void started(){
    fprintf(stderr, "started\n");
  }
  virtual void done() {
    sem_post(&done_sem);
    fprintf(stderr, "done\n");
    memcmp_fail = memcmp(srcBuffer, dstBuffer, alloc_sz);
    //dump("xxx ", (char*)dstBuffer, alloc_sz);
  }
};

int do_copy(int srcAlloc, int sgl_config_request_id, int sgl_config_indication_id)
{
  MemcpyRequestProxy *device = new MemcpyRequestProxy(IfcNames_MemcpyRequest);
  MemcpyIndication deviceIndication(IfcNames_MemcpyIndication);
    DmaManager *dma = platformInit();
  //MMURequestProxy *dmap = new MMURequestProxy(sgl_config_request_id);
  //MMUIndication *hostMMUIndication = new MMUIndication(dma, sgl_config_indication_id);

  fprintf(stderr, "Main::allocating memory...\n");

  size_t dstBytes = alloc_sz;
  size_t srcBytes = dstBytes;
  bool first = false;

  int dstAlloc = portalAlloc(dstBytes, 0);
  if(!srcAlloc) {
    srcAlloc = portalAlloc(srcBytes, 0);
    first = true;
  }

  int ref_dstAlloc = dma->reference(dstAlloc);
  int ref_srcAlloc = dma->reference(srcAlloc);

  srcBuffer = (unsigned int *)portalMmap(srcAlloc, srcBytes);
  dstBuffer = (unsigned int *)portalMmap(dstAlloc, dstBytes);

  
  for (int i = 0; i < numWords; i++){
    if (first) srcBuffer[i] = i;
    dstBuffer[i] = 0x5a5abeef;
  }

  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  portalCacheFlush(dstAlloc, dstBuffer, alloc_sz, 1);

  device->startCopy(ref_dstAlloc, ref_srcAlloc, numWords, 16, 1);
  sem_wait(&done_sem);

  return dstAlloc;
}

int main(int argc, const char **argv)
{
  if(sem_init(&done_sem, 1, 0)){
    fprintf(stderr, "failed to init done_sem\n");
    exit(1);
  }

  bool memcmp_fails[4] = {false, false, false, false};

  int dst_ref0 = do_copy(0,        IfcNames_MMU0ConfigRequest, IfcNames_MMU0ConfigIndication);
  memcmp_fails[0] = memcmp_fail;
  int dst_ref1 = do_copy(dst_ref0, IfcNames_MMU1ConfigRequest, IfcNames_MMU1ConfigIndication);
  memcmp_fails[1] = memcmp_fail;
  do_copy(dst_ref1, IfcNames_MMU2ConfigRequest, IfcNames_MMU2ConfigIndication);
  memcmp_fails[2] = memcmp_fail;
  int dst_ref3 = do_copy(dst_ref3, IfcNames_MMU3ConfigRequest, IfcNames_MMU3ConfigIndication);
  memcmp_fails[3] = memcmp_fail;

  fprintf(stderr, "memcpy_manysglists: Done %d %d %d %d\n", memcmp_fails[0], memcmp_fails[1], memcmp_fails[2], memcmp_fails[3]);
  sleep(2);

  exit(memcmp_fails[0] | memcmp_fails[1] | memcmp_fails[2] | memcmp_fails[3] );
}
