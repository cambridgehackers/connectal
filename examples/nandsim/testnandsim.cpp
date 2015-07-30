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
#include <fcntl.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include "dmaManager.h"
#include "NandCfgIndication.h"
#include "NandCfgRequest.h"
#include "nandsim.h"

static int trace_memory = 1;
extern "C" {
#include "userReference.h"
}

using namespace std;

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

int main(int argc, const char **argv)
{

#ifndef BOARD_bluesim
  size_t nandBytes = 1 << 12;
#else
  size_t nandBytes = 1 << 18;
#endif

  fprintf(stderr, "testnandsim::%s %s\n", __DATE__, __TIME__);

  DmaManager *hostDma = platformInit();
  NandCfgRequestProxy *nandcfgRequest = new NandCfgRequestProxy(IfcNames_NandCfgRequestS2H);
  NandCfgIndication *nandcfgIndication = new NandCfgIndication(IfcNames_NandCfgIndicationH2S);

  int nandAlloc = portalAlloc(nandBytes, 0);
  fprintf(stderr, "testnandsim::nandAlloc=%d\n", nandAlloc);
  int ref_nandAlloc = hostDma->reference(nandAlloc);
  fprintf(stderr, "ref_nandAlloc=%d\n", ref_nandAlloc);
  fprintf(stderr, "testnandsim::NAND alloc fd=%d ref=%d\n", nandAlloc, ref_nandAlloc);
  nandcfgRequest->configureNand(ref_nandAlloc, nandBytes);
  nandcfgIndication->wait();

#ifndef ALGO_NANDSIM
  if (argc == 1) {

    fprintf(stderr, "testnandsim::allocating memory...\n");
    size_t srcBytes = nandBytes>>2;
    int srcAlloc = portalAlloc(srcBytes, 0);
    unsigned int *srcBuffer = (unsigned int *)portalMmap(srcAlloc, srcBytes);
    unsigned int ref_srcAlloc = hostDma->reference(srcAlloc);
    fprintf(stderr, "testnandsim::fd=%d, srcBuffer=%p\n", srcAlloc, srcBuffer);

    /* do tests */
    fprintf(stderr, "testnandsim::chamdoo-test\n");
    unsigned long loop = 0;
    unsigned long match = 0, mismatch = 0;

    while (loop < nandBytes) {

      fprintf(stderr, "testnandsim::starting write ref=%d, len=%08zx (%lu)\n", ref_srcAlloc, srcBytes, loop);
      for (unsigned int i = 0; i < srcBytes/sizeof(srcBuffer[0]); i++) {
	srcBuffer[i] = loop+i;
      }
      portalCacheFlush(srcAlloc, srcBuffer, srcBytes, 1);
      nandcfgRequest->startWrite(ref_srcAlloc, 0, loop, srcBytes, 16);
      nandcfgIndication->wait();
      loop+=srcBytes;
    }
    fprintf(stderr, "testnandsim:: write phase complete\n");
    loop = 0;
    while (loop < nandBytes) {
      fprintf(stderr, "testnandsim::starting read %08zx (%lu)\n", srcBytes, loop);

      for (unsigned int i = 0; i < srcBytes/sizeof(srcBuffer[0]); i++) {
	srcBuffer[i] = 5;
      }

      portalCacheFlush(srcAlloc, srcBuffer, srcBytes, 1);
      nandcfgRequest->startRead(ref_srcAlloc, 0, loop, srcBytes, 16);
      nandcfgIndication->wait();
      
      for (unsigned int i = 0; i < srcBytes/sizeof(srcBuffer[0]); i++) {
	if (srcBuffer[i] != loop+i) {
	  fprintf(stderr, "testnandsim::mismatch [%08ld] != [%08d] (%d,%zu)\n", loop+i, srcBuffer[i], i, srcBytes/sizeof(srcBuffer[0]));
	  mismatch++;
	} else {
	  match++;
	}
      }
      
      loop+=srcBytes;
    }
    /* end */
    
    //uint64_t beats_r = hostDma->show_mem_stats(ChannelType_Read);
    //uint64_t beats_w = hostDma->show_mem_stats(ChannelType_Write);

    fprintf(stderr, "testnandsim::Summary: match=%lu mismatch:%lu (%lu) (%f percent)\n", match, mismatch, match+mismatch, (float)mismatch/(float)(match+mismatch)*100.0);
    //fprintf(stderr, "(%"PRIx64", %"PRIx64")\n", beats_r, beats_w);
    
    return (mismatch > 0);
  } else
#endif
  {

    // else we were invoked by alg1_nandsim
    const char *filename = "../test.bin";
    fprintf(stderr, "testnandsim::opening %s\n", filename);
    // open up the text file and read it into an allocated memory buffer
    int dataFile = open(filename, O_RDONLY);
    off_t data_len = lseek(dataFile, 0, SEEK_END);
    data_len = data_len & ~15; // because we are using a burst length of 16
    lseek(dataFile, 0, SEEK_SET);

    int dataAlloc = portalAlloc(data_len, 0);
    int ref_dataAlloc = hostDma->reference(dataAlloc);
    char *data = (char *)portalMmap(dataAlloc, data_len);
    ssize_t read_len = read(dataFile, data, data_len); 
    if(read_len != data_len) {
      fprintf(stderr, "testnandsim::error reading %s %ld %ld\n", filename, (long)data_len, (long) read_len);
      exit(-1);
    }

    // write the contents of data into "flash" memory
    portalCacheFlush(ref_dataAlloc, data, data_len, 1);
    fprintf(stderr, "testnandsim::invoking write %08x %08lx\n", ref_dataAlloc, (long)data_len);
    nandcfgRequest->startWrite(ref_dataAlloc, 0, 0, data_len, 16);
    nandcfgIndication->wait();

    fprintf(stderr, "testnandsim::connecting to algo_exe...\n");
    connect_to_algo_exe();
    fprintf(stderr, "testnandsim::connected to algo_exe\n");

    // send the offset and length (in nandsim) of the text
    write_to_algo_exe(0);
    write_to_algo_exe(data_len);
    printf("[%s:%d] sleep, waiting for search\n", __FUNCTION__, __LINE__);
    sleep(200);
    printf("[%s:%d] now closing down\n", __FUNCTION__, __LINE__);
  }
}
