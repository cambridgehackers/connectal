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
#include "NandCfgIndication.h"
#include "NandCfgRequest.h"
#include "StrstrIndication.h"
#include "StrstrRequest.h"

static int trace_memory = 1;
extern "C" {
#include "sys/ioctl.h"
#include "drivers/portalmem/portalmem.h"
#include "sock_utils.h"
#include "userReference.h"
}

size_t numBytes = 1 << 12;
#ifndef BOARD_bluesim
size_t nandBytes = 1 << 24;
#else
size_t nandBytes = 1 << 14;
#endif

class NandCfgIndication : public NandCfgIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(uint32_t v){
    fprintf(stderr, "NandSim::readDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void writeDone(uint32_t v){
    fprintf(stderr, "NandSim::writeDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void eraseDone(uint32_t v){
    fprintf(stderr, "NandSim::eraseDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void configureNandDone(){
    fprintf(stderr, "NandSim::configureNandDone\n");
    sem_post(&sem);
  }

  NandCfgIndication(int id) : NandCfgIndicationWrapper(id) {
    sem_init(&sem, 0, 0);
  }
  void wait() {
    fprintf(stderr, "NandSim::wait for semaphore\n");
    sem_wait(&sem);
  }
private:
  sem_t sem;
};

class StrstrIndication : public StrstrIndicationWrapper
{
public:
  StrstrIndication(unsigned int id) : StrstrIndicationWrapper(id){
    sem_init(&sem, 0, 0);
    match_cnt = 0;
  };
  virtual void setupComplete() {
    fprintf(stderr, "Strstr::setupComplete\n");
    sem_post(&sem);
  }
  virtual void searchResult (int v){
    fprintf(stderr, "searchResult = %d\n", v);
    if (v == -1)
      sem_post(&sem);
    else 
      match_cnt++;
  }
  void wait() {
    fprintf(stderr, "Strstr::wait for semaphore\n");
    sem_wait(&sem);
  }
  int match_cnt;
private:
  sem_t sem;
};




int main(int argc, const char **argv)
{
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);
  DmaManager *dma = platformInit();
  MMURequestProxy *nandMMURequest = new MMURequestProxy(IfcNames_NandMMURequest);
  DmaManager *nandsimDma = new DmaManager(nandMMURequest);
  MMUIndication *nandMMUIndication = new MMUIndication(nandsimDma,IfcNames_NandMMUIndication);

  StrstrRequestProxy *strstrRequest = new StrstrRequestProxy(IfcNames_AlgoRequest);
  StrstrIndication *strstrIndication = new StrstrIndication(IfcNames_AlgoIndication);

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

  // base of haystack in "flash" memory
  // this is read from nandsim_exe, but could also come from kernel driver
  int haystack_base = 0;
  int haystack_len  = 64;

  // request the next sglist identifier from the sglistMMU hardware module
  // which is used by the mem server accessing flash memory.
  int id = 0;
  MMURequest_idRequest(nandsimDma->priv.sglDevice, -1);
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

  // at this point, ref_needleAlloc and ref_mpNextAlloc are valid sgListIds for use by 
  // the host memory dma hardware, and ref_haystackInNandMemory is a valid sgListId for
  // use by the nandsim dma hardware

  fprintf(stderr, "about to setup device %d %d\n", ref_needleAlloc, ref_mpNextAlloc);
  strstrRequest->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
  strstrIndication->wait();

  fprintf(stderr, "about to invoke search %d\n", ref_haystackInNandMemory);
  strstrRequest->search(ref_haystackInNandMemory, haystack_len);
  strstrIndication->wait();  

  exit(!(strstrIndication->match_cnt==3));
}
