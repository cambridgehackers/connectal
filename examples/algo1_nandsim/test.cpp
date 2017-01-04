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
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/mman.h>
#include <assert.h>
#include <mp.h>
#include <semaphore.h>
#include "dmaManager.h"
#include "MMURequest.h"
#include "MMUIndication.h"
#include "MemServerRequest.h"
#include "MemServerIndication.h"
#include "StrstrIndication.h"
#include "StrstrRequest.h"

static int trace_memory = 1;
extern "C" {
#include "drivers/portalmem/portalmem.h"
#include "userReference.h"
}

#include "nandsim.h"
#include "strstr.h"

class MMUIndicationNandSim : public MMUIndicationWrapper
{
  DmaManager *portalMemory;
  sem_t sem;
 public:
  int sglId;

  MMUIndicationNandSim(DmaManager *pm, unsigned int  id, int tile=DEFAULT_TILE) : MMUIndicationWrapper(id,tile), portalMemory(pm) {
    sem_init(&sem, 0, 0);
  }
  void wait() {
    sem_wait(&sem);
  }

  virtual void configResp(uint32_t pointer){
    fprintf(stderr, "MMUIndication::configResp: %x\n", pointer);
    portalMemory->confResp(pointer);
  }
  virtual void error (uint32_t code, uint32_t pointer, uint64_t offset, uint64_t extra) {
    fprintf(stderr, "MMUIndication::error(code=0x%x, pointer=0x%x, offset=0x%"PRIx64" extra=-0x%"PRIx64"\n", code, pointer, offset, extra);
    //if (--mmu_error_limit < 0)
        exit(-1);
  }
  virtual void idResponse(uint32_t sglId){
    fprintf(stderr, "MMUIndication::idResponse: %x\n", sglId);
    if (portalMemory)
      portalMemory->sglIdResp(sglId);
    this->sglId = sglId;
    sem_post(&sem);
  }
};

class MemServerIndicationNandSim : public MemServerIndicationWrapper
{
  MemServerRequestProxy *memServerRequestProxy;
  sem_t mtSem;
  uint64_t mtCnt;
  void init(){
    if (sem_init(&mtSem, 0, 0))
      PORTAL_PRINTF("MemServerIndication::init failed to init mtSem\n");
  }
 public:
  MemServerIndicationNandSim(unsigned int  id, int tile=DEFAULT_TILE) : MemServerIndicationWrapper(id,tile), memServerRequestProxy(NULL) {init();}
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

extern int initNandSim(DmaManager *hostDma);

int main(int argc, const char **argv)
{
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  DmaManager *hostDma = platformInit();
  MMURequestProxy *nandsimMMU = new MMURequestProxy(IfcNames_MMURequestS2H);
  DmaManager *nandsimDma = new DmaManager(nandsimMMU);

  StrstrRequestProxy *strstrRequest = new StrstrRequestProxy(IfcNames_StrstrRequestS2H);
  StrstrIndication *strstrIndication = new StrstrIndication(IfcNames_StrstrIndicationH2S);
  
  MMUIndicationNandSim nandsimMMUIndication(nandsimDma,IfcNames_MMUIndicationH2S);
  MemServerIndicationNandSim nandsimMemServerIndication(IfcNames_MemServerIndicationH2S);

  fprintf(stderr, "Initializing nandSim...\n");
  int haystack_len = initNandSim(hostDma);
  int haystack_base = 0;
  fprintf(stderr, "haystack_base=%d haystack_len=%d\n", haystack_base, haystack_len);

  fprintf(stderr, "Main::allocating memory...\n");

  // allocate memory for strstr data
  int needleAlloc = portalAlloc(numBytes, 0);
  int mpNextAlloc = portalAlloc(numBytes, 0);
  int ref_needleAlloc = hostDma->reference(needleAlloc);
  int ref_mpNextAlloc = hostDma->reference(mpNextAlloc);

  fprintf(stderr, "%s:%d %08x %08x\n", __FUNCTION__, __LINE__, ref_needleAlloc, ref_mpNextAlloc);

  char *needle = (char *)portalMmap(needleAlloc, numBytes);
  int *mpNext = (int *)portalMmap(mpNextAlloc, numBytes);

  const char *needle_text = "ababab";
  int needle_len = strlen(needle_text);
  strncpy(needle, needle_text, needle_len);
  compute_MP_next(needle, mpNext, needle_len);

  portalCacheFlush(needleAlloc, needle, numBytes, 1);
  portalCacheFlush(mpNextAlloc, mpNext, numBytes, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  // request the next sglist identifier from the sglistMMU hardware module
  // which is used by the mem server accessing flash memory.
  int id = 0;
  fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
  if (1) {
      MMURequest_idRequest(nandsimDma->priv.sglDevice, 0);
      sem_wait(&nandsimDma->priv.sglIdSem);
      id = nandsimDma->priv.sglId;
  } else {
      nandsimMMU->idRequest(0);
      nandsimMMUIndication.wait();
      id = nandsimMMUIndication.sglId;
  }

  fprintf(stderr, "[%s:%d] id=%d\n", __FUNCTION__, __LINE__, id);
  // pairs of ('offset','size') pointing to space in nandsim memory
  // this is unsafe.  To do it properly, we should get this list from
  // nandsim_exe or from the kernel driver.  This code here might overrun
  // the backing store allocated by nandsim_exe.
  RegionRef region[] = {{0, 0x100000}, {0x100000, 0x100000}};
  fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
  int ref_haystackInNandMemory = send_reference_to_portal(nandsimDma->priv.sglDevice, sizeof(region)/sizeof(region[0]), region, id);
  sem_wait(&(nandsimDma->priv.confSem));
  fprintf(stderr, "[%s:%d] %08x\n", __FUNCTION__, __LINE__, ref_haystackInNandMemory);

  // at this point, ref_needleAlloc and ref_mpNextAlloc are valid sgListIds for use by 
  // the host memory dma hardware, and ref_haystackInNandMemory is a valid sgListId for
  // use by the nandsim dma hardware

  fprintf(stderr, "about to setup device %d %d\n", ref_needleAlloc, ref_mpNextAlloc);
  strstrRequest->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
  fprintf(stderr, "about to invoke search %d\n", ref_haystackInNandMemory);
  strstrRequest->search(ref_haystackInNandMemory, haystack_len);
  strstrIndication->wait();  

  fprintf(stderr, "algo1_nandsim: Done %d\n",  (strstrIndication->match_cnt==3));
  sleep(2);
  exit(!(strstrIndication->match_cnt==3));
}
