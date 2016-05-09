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
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/mman.h>
#include <assert.h>
#include "dmaManager.h"
#include "MMURequest.h"
#include "MMUIndication.h"
#include "NandCfgIndication.h"
#include "NandCfgRequest.h"
#include "RegexpIndication.h"
#include "RegexpRequest.h"

static int trace_memory = 1;
extern "C" {
#include "sys/ioctl.h"
#include "drivers/portalmem/portalmem.h"
#include "sock_utils.h"
#include "userReference.h"
}

#include "regexp_utils.h"
#include "nandsim.h"

class MMUIndicationNAND : public MMUIndicationWrapper
{
  DmaManager *portalMemory;
 public:
  MMUIndicationNAND(DmaManager *pm, unsigned int  id, int tile=DEFAULT_TILE) : MMUIndicationWrapper(id,tile), portalMemory(pm) {}
  MMUIndicationNAND(DmaManager *pm, unsigned int  id, PortalTransportFunctions *item, void *param) : MMUIndicationWrapper(id, item, param), portalMemory(pm) {}
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
    portalMemory->sglIdResp(sglId);
  }
};

size_t numBytes = 1 << 10;

int main(int argc, const char **argv)
{
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  //MMURequestProxy *hostMMURequest = new MMURequestProxy(IfcNames_MMURequestS2H);
  DmaManager *hostDma = platformInit();
  MMURequestProxy *nandsimMMURequest = new MMURequestProxy(IfcNames_NandMMURequestS2H);
  DmaManager *nandsimDma = new DmaManager(nandsimMMURequest);
  MMUIndicationNAND nandsimMMUIndication(nandsimDma,IfcNames_NandMMUIndicationH2S);

  RegexpRequestProxy *device = new RegexpRequestProxy(IfcNames_AlgoRequestS2H);
  RegexpIndication *deviceIndication = new RegexpIndication(IfcNames_AlgoIndicationH2S);
  
  //MemServerIndication hostMemServerIndication(IfcNames_MemServerIndicationH2S);
  //MemServerIndication nandsimMemServerIndication(IfcNames_NandMemServerIndicationH2S);

  haystack_dma = hostDma;
  //haystack_mmu = hostMMURequest;
  regexp = device;

  fprintf(stderr, "Main::allocating memory...\n");

  // this is hard-coded into the REParser.java
  assert(32 == MAX_NUM_STATES);
  assert(32 == MAX_NUM_CHARS);

  ////////////////////////////////////////////////////////////////////
  // 

  fprintf(stderr, "Main::waiting to connect to nandsim_exe\n");
  wait_for_connect_nandsim_exe();
  fprintf(stderr, "Main::connected to nandsim_exe\n");
  // base of haystack in "flash" memory
  // this is read from nandsim_exe, but could also come from kernel driver
  int haystack_base = read_from_nandsim_exe();
  int haystack_len  = read_from_nandsim_exe();
  (void) haystack_base;  // unused

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
  RegionRef region[] = {{0, 0x100000}, {0x100000, 0x100000}};
  printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  int ref_haystackInNandMemory = send_reference_to_portal(nandsimDma->priv.sglDevice, sizeof(region)/sizeof(region[0]), region, id);
  sem_wait(&(nandsimDma->priv.confSem));
  fprintf(stderr, "%08x\n", ref_haystackInNandMemory);

  // 
  ////////////////////////////////////////////////////////////////////

  if(1){
    P charMapP;
    P stateMapP;
    P stateTransitionsP;
    
    readfile("../jregexp.charMap", &charMapP);
    readfile("../jregexp.stateMap", &stateMapP);
    readfile("../jregexp.stateTransitions", &stateTransitionsP);

    portalCacheFlush(charMapP.alloc, charMapP.mem, charMapP.length, 1);
    portalCacheFlush(stateMapP.alloc, stateMapP.mem, stateMapP.length, 1);
    portalCacheFlush(stateTransitionsP.alloc, stateTransitionsP.mem, stateTransitionsP.length, 1);

    for(int i = 0; i < num_tests; i++){

      device->setup(charMapP.ref, charMapP.length);
      device->setup(stateMapP.ref, stateMapP.length);
      device->setup(stateTransitionsP.ref, stateTransitionsP.length);

      // for this test, we are just re-usng the same haystack which 
      // has been written to the nandsim backing store by nandsim_exe 

      if(i==0){
	readfile("test.bin", &haystackP[0]);
	sw_match_cnt = num_tests*sw_ref(&haystackP[0], &charMapP, &stateMapP, &stateTransitionsP);
      }

      sem_wait(&test_sem);
      int token = deviceIndication->token;

      assert(token < max_num_tokens);
      token_map[token] = i;
      fprintf(stderr, "Main::about to invoke search %08x %08x\n", ref_haystackInNandMemory, haystack_len);
      // Regexp uses a data-bus width of 8 bytes.  length must be a multiple of this dimension
      device->search(token, ref_haystackInNandMemory, haystack_len & ~((1<<3)-1));
    }

    sem_wait(&test_sem);
    close(charMapP.alloc);
    close(stateMapP.alloc);
    close(stateTransitionsP.alloc);
  }
  fprintf(stderr, "hw_match_cnt=%d, sw_match_cnt=%d\n", hw_match_cnt, sw_match_cnt);
  return (hw_match_cnt == sw_match_cnt ? 0 : -1);
}
