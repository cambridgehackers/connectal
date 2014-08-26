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

#include "StdDmaIndication.h"
#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "NandSimIndicationWrapper.h"
#include "NandSimRequestProxy.h"

static int trace_memory = 1;
extern "C" {
#include "userReference.h"
}

using namespace std;

int srcAlloc, nandAlloc;
unsigned int *srcBuffer = 0;
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

static int sockfd = -1;
#define SOCK_NAME "socket_for_nandsim"
void connect_to_algo_exe(void)
{
  int connect_attempts = 0;

  if (sockfd != -1)
    return;
  if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s (%s) socket error %s\n",__FUNCTION__, SOCK_NAME, strerror(errno));
    exit(1);
  }

  //fprintf(stderr, "%s (%s) trying to connect...\n",__FUNCTION__, SOCK_NAME);
  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, SOCK_NAME);
  while (connect(sockfd, (struct sockaddr *)&local, strlen(local.sun_path) + sizeof(local.sun_family)) == -1) {
    if(connect_attempts++ > 16){
      fprintf(stderr,"%s (%s) connect error %s\n",__FUNCTION__, SOCK_NAME, strerror(errno));
      exit(1);
    }
    //fprintf(stderr, "%s (%s) retrying connection\n",__FUNCTION__, SOCK_NAME);
    sleep(1);
  }
  fprintf(stderr, "%s (%s) connected\n",__FUNCTION__, SOCK_NAME);
}


void write_to_algo_exe(unsigned int x)
{
  if (send(sockfd, &x, sizeof(x), 0) == -1) {
    fprintf(stderr, "%s send error\n",__FUNCTION__);
    exit(1);
  }
}


int main(int argc, const char **argv)
{
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);
  unsigned int srcGen = 0;

  NandSimRequestProxy *nandsimRequest = 0;
  NandSimIndication *nandsimIndication = 0;

  DmaConfigProxy *dmaConfig = 0;
  DmaIndication *dmaIndication = 0;

  nandsimRequest = new NandSimRequestProxy(IfcNames_NandSimRequest);
  nandsimIndication = new NandSimIndication(IfcNames_NandSimIndication);

  dmaConfig = new DmaConfigProxy(IfcNames_DmaConfig);
  DmaManager *dma = new DmaManager(dmaConfig);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);

  fprintf(stderr, "Main::allocating memory...\n");

  srcAlloc = portalAlloc(numBytes);
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, numBytes);
  fprintf(stderr, "fd=%d, srcBuffer=%p\n", srcAlloc, srcBuffer);

  portalExec_start();

  for (int i = 0; i < numBytes/sizeof(srcBuffer[0]); i++)
    srcBuffer[i] = srcGen++;
    
  portalDCacheFlushInval(srcAlloc, numBytes, srcBuffer);
  fprintf(stderr, "Main::flush and invalidate complete\n");
  sleep(1);

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);

  nandAlloc = portalAlloc(nandBytes);
  int ref_nandAlloc = dma->reference(nandAlloc);
  fprintf(stderr, "NAND alloc fd=%d ref=%d\n", nandAlloc, ref_nandAlloc);
  nandsimRequest->configureNand(ref_nandAlloc, nandBytes);
  nandsimIndication->wait();

  bool sangwoo = true;
  if (sangwoo){
    fprintf(stderr, "sangwoo-test\n");

    for (int i = 0; i < numBytes/sizeof(srcBuffer[0]); i++)
      srcBuffer[i] = i;
    portalDCacheFlushInval(srcAlloc, numBytes, srcBuffer);

    nandsimRequest->startWrite(ref_srcAlloc, 0, 0, numBytes, 16);
    nandsimIndication->wait();

    unsigned int* nand_memory = (unsigned int*)portalMmap(nandAlloc,nandBytes);
    for (int i = 0; i < numBytes/sizeof(srcBuffer[0]); i++)
      if(nand_memory[i] != srcBuffer[i])
	fprintf(stderr, "ERROR: sangwoo-test %d %d (%d)\n", nand_memory[i], srcBuffer[i], i);
      
    fprintf(stderr, "sangwoo-test successful\n");
  } else if (argc == 1) {
    /* do tests */
    fprintf(stderr, "chamdoo-test\n");
    unsigned long loop = 0;
    unsigned long match = 0, mismatch = 0;
    while (loop < nandBytes) {
      int i;
      for (i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
	srcBuffer[i] = loop+i;
      }
      
      fprintf(stderr, "Main::starting write ref=%d, len=%08zx (%lu)\n", ref_srcAlloc, numBytes, loop);
      nandsimRequest->startWrite(ref_srcAlloc, 0, loop, numBytes, 16);
      nandsimIndication->wait();
      
      loop+=numBytes;
    }
    
    loop = 0;
    while (loop < nandBytes) {
      int i;
      fprintf(stderr, "Main::starting read %08zx (%lu)\n", numBytes, loop);
      nandsimRequest->startRead(ref_srcAlloc, 0, loop, numBytes, 16);
      nandsimIndication->wait();
      
      for (i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
	if (srcBuffer[i] != loop+i) {
	  fprintf(stderr, "Main::mismatch [%08ld] != [%08d]\n", loop+i, srcBuffer[i]);
	  mismatch++;
	} else {
	  match++;
	}
      }
      
      loop+=numBytes;
    }
    /* end */
    
    fprintf(stderr, "Main::Summary: match=%lu mismatch:%lu (%lu) (%f percent)\n", 
	    match, mismatch, match+mismatch, (float)mismatch/(float)(match+mismatch)*100.0);
    
    return (mismatch > 0);
  } else {
    // else we were invoked by alg1_nandsim
    string filename = "../haystack.txt";
    // open up the text file and read it into an allocated memory buffer
    ifstream dataFile(filename.c_str(), ios::in|ios::binary|ios::ate);
    streampos data_len = dataFile.tellg();
    int dataAlloc = portalAlloc(data_len);
    int ref_dataAlloc = dma->reference(dataAlloc);
    char *data = (char *)portalMmap(dataAlloc, data_len);
    if(!dataFile.read(data, data_len)){
      fprintf(stderr, "error reading %s %d\n", filename.c_str(), (int)data_len);
      exit(-1);
    }

    // write the contents of data into "flash" memory
    nandsimRequest->startWrite(ref_dataAlloc, 0, 0, data_len, 16);
    nandsimIndication->wait();

    // send the offset and length (in nandsim) of the text
    connect_to_algo_exe();
    write_to_algo_exe(0);
    write_to_algo_exe(data_len);
  }
}
