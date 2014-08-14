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
#include "dmaSendFd.h"
}

int scratchAlloc, nandAlloc;
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
private:
  sem_t sem;
  int match_cnt;
};


int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;
  NandSimRequestProxy *nandsimRequest = 0;
  DmaConfigProxy *dmaConfig = 0;
  NandSimIndication *nandsimIndication = 0;
  DmaIndication *dmaIndication = 0;

  StrstrRequestProxy *strstrRequest = 0;
  DmaConfigProxy *strstrDmaConfig = 0;
  StrstrIndication *strstrIndication = 0;
  DmaIndication *strstrDmaIndication = 0;

  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  nandsimRequest = new NandSimRequestProxy(IfcNames_NandSimRequest);
  dmaConfig = new DmaConfigProxy(IfcNames_DmaConfig);
  DmaManager *dma = new DmaManager(dmaConfig);
  nandsimIndication = new NandSimIndication(IfcNames_NandSimIndication);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);


  strstrRequest = new StrstrRequestProxy(IfcNames_StrstrRequest);
  strstrDmaConfig = new DmaConfigProxy(IfcNames_StrstrDmaConfig);
  strstrIndication = new StrstrIndication(IfcNames_StrstrIndication);
  DmaManager *strstrDma = new DmaManager(strstrDmaConfig);
  strstrDmaIndication = new DmaIndication(strstrDma,IfcNames_StrstrDmaIndication);

  portalExec_start();

  fprintf(stderr, "Main::allocating memory...\n");

  // allocate scratch memory for program to write character strings
  scratchAlloc = portalAlloc(numBytes);
  unsigned int ref_scratchAlloc = dma->reference(scratchAlloc);

  // allocate memory buffer for nandsim to use as backing store
  nandAlloc = portalAlloc(nandBytes);
  int ref_nandAlloc = dma->reference(nandAlloc);

  // give the nandsim a pointer to its backing store
  nandsimRequest->configureNand(ref_nandAlloc, nandBytes);
  nandsimIndication->wait();

  // write a pattern into the scratch memory and flush
  unsigned int *srcBuffer = (unsigned int *)portalMmap(scratchAlloc, numBytes);
  for (int i = 0; i < numBytes/sizeof(srcBuffer[0]); i++)
    srcBuffer[i] = srcGen++;
  portalDCacheFlushInval(scratchAlloc, numBytes, srcBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  // write the contents of scratch into "flash" memory
  nandsimRequest->startWrite(ref_scratchAlloc, 0, 0, numBytes, 16);
  nandsimIndication->wait();

  // this is a temporary hack.  We are inlining the pertinant lines from DmaManager_reference
  // for this to work, NANDSIMHACK must be defined.  What this does is send an SGList of the size 
  // scratchAlloc to strstrDMA starting at offset 0 in the nandsim backing store.
  int id = strstrDma->priv.handle++;
  int ref_nandMemory = send_fd_to_portal(strstrDma->priv.device, scratchAlloc, id, global_pa_fd);
  sem_wait(&(strstrDma->priv.confSem));  

  exit(0);
}
