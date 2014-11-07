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
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/mman.h>
#include <assert.h>
#include <mp.h>

#include "StdDmaIndication.h"
#include "MMURequest.h"
#include "GeneratedTypes.h" 
#include "NandSimIndication.h"
#include "NandSimRequest.h"
#include "StrstrIndication.h"
#include "StrstrRequest.h"

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



static int sockfd;
#define SOCK_NAME "socket_for_nandsim"
void wait_for_connect_nandsim_exe()
{
  int listening_socket;

  if ((listening_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s: socket error %s",__FUNCTION__, strerror(errno));
    exit(1);
  }

  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, SOCK_NAME);
  unlink(local.sun_path);
  int len = strlen(local.sun_path) + sizeof(local.sun_family);
  if (bind(listening_socket, (struct sockaddr *)&local, len) == -1) {
    fprintf(stderr, "%s[%d]: bind error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }

  if (listen(listening_socket, 5) == -1) {
    fprintf(stderr, "%s[%d]: listen error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  
  //fprintf(stderr, "%s[%d]: waiting for a connection...\n",__FUNCTION__, listening_socket);
  if ((sockfd = accept(listening_socket, NULL, NULL)) == -1) {
    fprintf(stderr, "%s[%d]: accept error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  remove(SOCK_NAME);  // we are connected now, so we can remove named socket
}

unsigned int read_from_nandsim_exe()
{
  unsigned int rv;
  if(recv(sockfd, &rv, sizeof(rv), 0) == -1){
    fprintf(stderr, "%s recv error\n",__FUNCTION__);
    exit(1);	  
  }
  return rv;
}

int main(int argc, const char **argv)
{
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  MMURequestProxy *hostMMURequest = new MMURequestProxy(IfcNames_AlgoMMURequest);
  DmaManager *hostDma = new DmaManager(hostMMURequest);
  MMUIndication *hostMMUIndication = new MMUIndication(hostDma, IfcNames_AlgoMMUIndication);

  MMURequestProxy *nandsimMMU0Request = new MMURequestProxy(IfcNames_NandsimMMU0Request);
  DmaManager *nandsimDma0 = new DmaManager(nandsimMMU0Request);
  MMUIndication *nandsimMMU0Indication = new MMUIndication(nandsimDma0,IfcNames_NandsimMMU0Indication);

  MMURequestProxy *nandsimMMU1Request = new MMURequestProxy(IfcNames_NandsimMMU1Request);
  DmaManager *nandsimDma1 = new DmaManager(nandsimMMU1Request);
  MMUIndication *nandsimMMU1Indication = new MMUIndication(nandsimDma1,IfcNames_NandsimMMU1Indication);

  StrstrRequestProxy *strstrRequest = new StrstrRequestProxy(IfcNames_AlgoRequest);
  StrstrIndication *strstrIndication = new StrstrIndication(IfcNames_AlgoIndication);

  MemServerIndication *hostMemServerIndication = new MemServerIndication(IfcNames_HostMemServerIndication);
  MemServerIndication *nandsimMemServer0Indication = new MemServerIndication(IfcNames_NandsimMemServer0Indication);
  MemServerIndication *nandsimMemServer1Indication = new MemServerIndication(IfcNames_NandsimMemServer1Indication);

  portalExec_start();
  fprintf(stderr, "Main::allocating memory...\n");

  // allocate memory for strstr data
  int needleAlloc = portalAlloc(numBytes);
  int mpNextAlloc = portalAlloc(numBytes);
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

  portalDCacheFlushInval(needleAlloc, numBytes, needle);
  portalDCacheFlushInval(mpNextAlloc, numBytes, mpNext);
  fprintf(stderr, "Main::flush and invalidate complete\n");

  fprintf(stderr, "Main::waiting to connect to nandsim_exe\n");
  wait_for_connect_nandsim_exe();
  fprintf(stderr, "Main::connected to nandsim_exe\n");
  // base of haystack in "flash" memory
  // this is read from nandsim_exe, but could also come from kernel driver
  int haystack_base = read_from_nandsim_exe();
  int haystack_len  = read_from_nandsim_exe();

  sleep(2);

  // request the next sglist identifier from the sglistMMU hardware module
  // which is used by the mem server accessing flash memory.
  int id0 = 0;
  MMURequest_idRequest(nandsimDma0->priv.sglDevice, -1);
  sem_wait(&nandsimDma0->priv.sglIdSem);
  id0 = nandsimDma0->priv.sglId;
  printf("[%s:%d] %08x\n", __FUNCTION__, __LINE__, id0);

  int id1 = 0;
  MMURequest_idRequest(nandsimDma1->priv.sglDevice, -1);
  sem_wait(&nandsimDma1->priv.sglIdSem);
  id1 = nandsimDma1->priv.sglId;
  printf("[%s:%d] %08x\n", __FUNCTION__, __LINE__, id1);

  // pairs of ('offset','size') pointing to space in nandsim memory
  // this is unsafe.  To do it properly, we should get this list from
  // nandsim_exe or from the kernel driver.  This code here might overrun
  // the backing store allocated by nandsim_exe.
  RegionRef region[] = {{0, 0x100000}, {0x100000, 0x100000}};
  int ref_haystackInNandMemory0 = send_reference_to_portal(nandsimDma0->priv.sglDevice, sizeof(region)/sizeof(region[0]), region, id0);
  int ref_haystackInNandMemory1 = send_reference_to_portal(nandsimDma1->priv.sglDevice, sizeof(region)/sizeof(region[0]), region, id1);
  sem_wait(&(nandsimDma0->priv.confSem));
  sem_wait(&(nandsimDma1->priv.confSem));
  fprintf(stderr, "%08x\n", ref_haystackInNandMemory0);
  fprintf(stderr, "%08x\n", ref_haystackInNandMemory1);

  assert(ref_haystackInNandMemory1==ref_haystackInNandMemory0);

  // at this point, ref_needleAlloc and ref_mpNextAlloc are valid sgListIds for use by 
  // the host memory dma hardware, and ref_haystackInNandMemory is a valid sgListId for
  // use by the nandsim dma hardware

  fprintf(stderr, "about to setup device %d %d\n", ref_needleAlloc, ref_mpNextAlloc);
  strstrRequest->setup(ref_needleAlloc, ref_mpNextAlloc, needle_len);
  fprintf(stderr, "about to invoke search %d\n", ref_haystackInNandMemory0);
  strstrRequest->search(ref_haystackInNandMemory0, haystack_len);
  strstrIndication->wait();  

  exit(!(strstrIndication->match_cnt==3));
}
