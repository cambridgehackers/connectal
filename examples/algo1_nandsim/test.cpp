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
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <semaphore.h>
#include <ctime>
#include <monkit.h>
#include <mp.h>

#include "StdDmaIndication.h"
#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "NandSimIndicationWrapper.h"
#include "NandSimRequestProxy.h"
#include "StrstrIndicationWrapper.h"
#include "StrstrRequestProxy.h"

static int trace_memory = 1;
extern "C" {
#include "sys/ioctl.h"
#include "portalmem.h"
#include "sock_utils.h"
#include "dmaManager.h"
#include "userReference.h"
}

size_t numBytes = 1 << 12;
#ifndef BOARD_bluesim
size_t nandBytes = 1 << 24;
#else
size_t nandBytes = 1 << 14;
#endif

class NandSimIndication : public NandSimIndicationWrapper
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

  NandSimIndication(int id) : NandSimIndicationWrapper(id) {
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
  unsigned int srcGen = 0;
  NandSimRequestProxy *nandsimRequest = 0;
  DmaConfigProxy *dmaConfig = 0;
  NandSimIndication *nandsimIndication = 0;
  DmaIndication *dmaIndication = 0;

  StrstrRequestProxy *strstrRequest = 0;
  DmaConfigProxy *nandsimDmaConfig = 0;
  StrstrIndication *strstrIndication = 0;
  DmaIndication *nandsimDmaIndication = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  nandsimRequest = new NandSimRequestProxy(IfcNames_NandSimRequest);
  dmaConfig = new DmaConfigProxy(IfcNames_DmaConfig);
  DmaManager *dma = new DmaManager(dmaConfig);
  nandsimIndication = new NandSimIndication(IfcNames_NandSimIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);


  strstrRequest = new StrstrRequestProxy(IfcNames_AlgoRequest);
  nandsimDmaConfig = new DmaConfigProxy(IfcNames_NandsimDmaConfig);
  strstrIndication = new StrstrIndication(IfcNames_AlgoIndication);
  DmaManager *nandsimDma = new DmaManager(nandsimDmaConfig);
  nandsimDmaIndication = new DmaIndication(nandsimDma,IfcNames_NandsimDmaIndication);

  portalExec_start();
  fprintf(stderr, "Main::allocating memory...\n");

  // allocate memory for strstr data
  int haystackAlloc = portalAlloc(numBytes);
  int needleAlloc = portalAlloc(numBytes);
  int mpNextAlloc = portalAlloc(numBytes);
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  int ref_haystackAlloc = dma->reference(haystackAlloc);
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  int ref_needleAlloc = dma->reference(needleAlloc);
  int ref_mpNextAlloc = dma->reference(mpNextAlloc);
  char *needle = (char *)portalMmap(needleAlloc, numBytes);
  char *haystack = (char *)portalMmap(haystackAlloc, numBytes);
  int *mpNext = (int *)portalMmap(mpNextAlloc, numBytes);

  // allocate memory buffer for nandsim to use as backing store
  int nandBacking = portalAlloc(nandBytes);
  int ref_nandBacking = dma->reference(nandBacking);

  // give the nandsim a pointer to its backing store
  nandsimRequest->configureNand(ref_nandBacking, nandBytes);
  nandsimIndication->wait();

  // write a pattern into the scratch memory and flush
  const char *needle_text = "ababab";
  const char *haystack_text = "acabcabacababacababababababcacabcabacababacabababc";
  int needle_len = strlen(needle_text);
  int haystack_len = strlen(haystack_text);
  strncpy(needle, needle_text, needle_len);
  strncpy(haystack, haystack_text, haystack_len);
  compute_MP_next(needle, mpNext, needle_len);
  portalDCacheFlushInval(needleAlloc, numBytes, needle);
  portalDCacheFlushInval(mpNextAlloc, numBytes, mpNext);
  portalDCacheFlushInval(haystackAlloc, numBytes, haystack);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  // write the contents of haystack into "flash" memory
  nandsimRequest->startWrite(ref_haystackAlloc, 0, 0, numBytes, 16);
  nandsimIndication->wait();

  int id = nandsimDma->priv.handle++;
  // pairs of ('offset','size') poinging to space in nandsim memory
  // this is unsafe.  We should check that the we aren't overflowing 
  // 'nandBytes', the size of the nandSimulator backing store
  RegionRef region[] = {{0, 0x100000}, {0x100000, 0x100000}};
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
  int ref_haystackInNandMemory = send_reference_to_portal(nandsimDma->priv.device, sizeof(region)/sizeof(region[0]), region, id);
  sem_wait(&(nandsimDma->priv.confSem));

  fprintf(stderr, "about to setup device %d %d\n", ref_needleAlloc, ref_mpNextAlloc);
  strstrRequest->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
  strstrIndication->wait();
  fprintf(stderr, "about to invoke search %d\n", ref_haystackInNandMemory);
  strstrRequest->search(ref_haystackInNandMemory, haystack_len, 1);
  strstrIndication->wait();  
  exit(!(strstrIndication->match_cnt==3));
}
