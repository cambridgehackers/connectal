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
#include <fstream>
#include <iostream>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/mman.h>
#include <assert.h>
#include <mp.h>
#include "dmaManager.h"
#include "StrstrIndication.h"
#include "StrstrRequest.h"
#include "MMURequest.h"
#include "MMUIndication.h"
#include "MemServerRequest.h"
#include "MemServerIndication.h"

static int trace_memory = 1;
extern "C" {
#include "sys/ioctl.h"
#include "drivers/portalmem/portalmem.h"
#include "sock_utils.h"
#include "userReference.h"
}

#include "nandsim.h"
#include "strstr.h"

class MMUIndication : public MMUIndicationWrapper
{
  DmaManager *portalMemory;
 public:
  MMUIndication(DmaManager *pm, unsigned int  id, int tile=DEFAULT_TILE) : MMUIndicationWrapper(id,tile), portalMemory(pm) {}
  MMUIndication(DmaManager *pm, unsigned int  id, PortalTransportFunctions *item, void *param) : MMUIndicationWrapper(id, item, param), portalMemory(pm) {}
  virtual void configResp(uint32_t pointer){
    fprintf(stderr, "MMUIndication::configResp: %x\n", pointer);
    portalMemory->confResp(pointer);
  }
  virtual void error (uint32_t code, uint32_t pointer, uint64_t offset, uint64_t extra) {
    fprintf(stderr, "MMUIndication::error(code=0x%x:%s, pointer=0x%x, offset=0x%"PRIx64" extra=0x%"PRIx64"\n", code, dmaErrors[code], pointer, offset, extra);
    if (--mmu_error_limit < 0)
        exit(-1);
  }
  virtual void idResponse(uint32_t sglId){
    portalMemory->sglIdResp(sglId);
  }
};

class MemServerIndication : public MemServerIndicationWrapper
{
  MemServerRequestProxy *memServerRequestProxy;
  sem_t mtSem;
  uint64_t mtCnt;
  void init(){
    if (sem_init(&mtSem, 0, 0))
      PORTAL_PRINTF("MemServerIndication::init failed to init mtSem\n");
  }
 public:
  MemServerIndication(unsigned int  id, int tile=DEFAULT_TILE) : MemServerIndicationWrapper(id,tile), memServerRequestProxy(NULL) {init();}
  MemServerIndication(MemServerRequestProxy *p, unsigned int  id, int tile=DEFAULT_TILE) : MemServerIndicationWrapper(id,tile), memServerRequestProxy(p) {init();}
  virtual void addrResponse(uint64_t physAddr){
    fprintf(stderr, "DmaIndication::addrResponse(physAddr=%"PRIx64")\n", physAddr);
  }
  virtual void reportStateDbg(const DmaDbgRec rec){
    fprintf(stderr, "MemServerIndication::reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void reportMemoryTraffic(uint64_t words){
    //fprintf(stderr, "reportMemoryTraffic: words=%"PRIx64"\n", words);
    mtCnt = words;
    sem_post(&mtSem);
  }
  virtual void error (uint32_t code, uint32_t pointer, uint64_t offset, uint64_t extra) {
    fprintf(stderr, "MemServerIndication::error(code=%x, pointer=%x, offset=%"PRIx64" extra=%"PRIx64"\n", code, pointer, offset, extra);
    if (--mem_error_limit < 0)
      exit(-1);
  }
  uint64_t receiveMemoryTraffic(){
    sem_wait(&mtSem);
    return mtCnt; 
  }
  uint64_t getMemoryTraffic(const ChannelType rc){
    assert(memServerRequestProxy);
    memServerRequestProxy->memoryTraffic(rc);
    return receiveMemoryTraffic();
  }
};

size_t numBytes = 1 << 10;

int main(int argc, const char **argv)
{
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);
  DmaManager *hostDma = platformInit();
  MMURequestProxy *nandsimMMURequest = new MMURequestProxy(IfcNames_NandMMURequestS2H);
  DmaManager *nandsimDma = new DmaManager(nandsimMMURequest);
  MMUIndication nandsimMMUIndication(nandsimDma,IfcNames_NandMMUIndicationH2S);

  StrstrRequestProxy *strstrRequest = new StrstrRequestProxy(IfcNames_AlgoRequestS2H);
  StrstrIndication *strstrIndication = new StrstrIndication(IfcNames_AlgoIndicationH2S);
  
  MemServerIndication hostMemServerIndication(IfcNames_MemServerIndicationH2S);
  MemServerIndication nandsimMemServerIndication(IfcNames_NandMemServerIndicationH2S);

  fprintf(stderr, "Main::allocating memory...\n");

  // allocate memory for strstr data
  int needleAlloc = portalAlloc(numBytes, 0);
  int mpNextAlloc = portalAlloc(numBytes, 0);
  int ref_needleAlloc = hostDma->reference(needleAlloc);
  int ref_mpNextAlloc = hostDma->reference(mpNextAlloc);

  fprintf(stderr, "%08x %08x\n", ref_needleAlloc, ref_mpNextAlloc);

  char *needle = (char *)portalMmap(needleAlloc, numBytes);
  int *mpNext = (int *)portalMmap(mpNextAlloc, numBytes);

  const char *needle_text = "ababab";
  int needle_len = strlen(needle_text);
  strncpy(needle, needle_text, needle_len);
  compute_MP_next(needle, mpNext, needle_len);

  // fprintf(stderr, "mpNext=[");
  // for(int i= 0; i <= needle_len; i++) 
  //   fprintf(stderr, "%d ", mpNext[i]);
  // fprintf(stderr, "]\nneedle=[");
  // for(int i= 0; i < needle_len; i++) 
  //   fprintf(stderr, "%d ", needle[i]);
  // fprintf(stderr, "]\n");

  portalCacheFlush(needleAlloc, needle, numBytes, 1);
  portalCacheFlush(mpNextAlloc, mpNext, numBytes, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");

 // fprintf(stderr, "Main::waiting to connect to nandsim_exe\n");
 // wait_for_connect_nandsim_exe();
 // fprintf(stderr, "Main::connected to nandsim_exe\n");
  // base of haystack in "flash" memory
  // this is read from nandsim_exe, but could also come from kernel driver
  //int haystack_base = read_from_nandsim_exe();
  //int haystack_len  = read_from_nandsim_exe();
  int haystack_len  = 0x100;

  // request the next sglist identifier from the sglistMMU hardware module
  // which is used by the mem server accessing flash memory.
  int id = 0;
  MMURequest_idRequest(nandsimDma->priv.sglDevice, 0);
  sem_wait(&nandsimDma->priv.sglIdSem);
  id = nandsimDma->priv.sglId;
  // pairs of ('offset','size') pointing to space in nandsim memory
  // this is unsafe.  To do it properly, we should get this list from
  // nandsim_exe or from the kernel driver.  This code here might overrun
  // the backing store allocated by nandsim_exe.
 // RegionRef region[] = {{0, 0x100000}, {0x100000, 0x100000}};
  RegionRef region[] = {{0x100000, 0x100000}};
  printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  int ref_haystackInNandMemory = send_reference_to_portal(nandsimDma->priv.sglDevice, sizeof(region)/sizeof(region[0]), region, id);
  sem_wait(&(nandsimDma->priv.confSem));
  fprintf(stderr, "%08x\n", ref_haystackInNandMemory);

  // at this point, ref_needleAlloc and ref_mpNextAlloc are valid sgListIds for use by 
  // the host memory dma hardware, and ref_haystackInNandMemory is a valid sgListId for
  // use by the nandsim dma hardware

  fprintf(stderr, "about to setup device %d %d\n", ref_needleAlloc, ref_mpNextAlloc);
  strstrRequest->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
  fprintf(stderr, "about to invoke search %d\n", ref_haystackInNandMemory);
  strstrRequest->search(ref_haystackInNandMemory, haystack_len);
  strstrIndication->wait();  
  fprintf(stderr, "algo1_flashmodel: Done\n");
  sleep(2);

  exit(!(strstrIndication->match_cnt==3));
}
