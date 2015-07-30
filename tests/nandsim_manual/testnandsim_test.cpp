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
#include "dmaManager.h"
#include "NandCfgIndication.h"
#include "NandCfgRequest.h"

int srcAlloc, nandAlloc;
unsigned int *srcBuffer = 0;
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
    fprintf(stderr, "NandCfg::readDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void writeDone(uint32_t v){
    fprintf(stderr, "NandCfg::writeDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void eraseDone(uint32_t v){
    fprintf(stderr, "NandCfg::eraseDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void configureNandDone(){
    fprintf(stderr, "NandCfg::configureNandDone\n");
    sem_post(&sem);
  }

  NandCfgIndication(int id) : NandCfgIndicationWrapper(id) {
    sem_init(&sem, 0, 0);
  }
  void wait() {
    fprintf(stderr, "NandCfg::wait for semaphore\n");
    sem_wait(&sem);
  }
private:
  sem_t sem;
};

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;
  NandCfgRequestProxy *device = 0;
  NandCfgIndication *deviceIndication = 0;

  fprintf(stderr, "chamdoo-test\n");
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new NandCfgRequestProxy(IfcNames_NandCfgRequestS2H);
  deviceIndication = new NandCfgIndication(IfcNames_NandCfgIndicationH2S);
  DmaManager *dma = platformInit();

  fprintf(stderr, "Main::allocating memory...\n");

  srcAlloc = portalAlloc(numBytes, 0);
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, numBytes);
  fprintf(stderr, "fd=%d, srcBuffer=%p\n", srcAlloc, srcBuffer);

  for (unsigned int i = 0; i < numBytes/sizeof(srcBuffer[0]); i++)
    srcBuffer[i] = srcGen++;
    
  portalCacheFlush(srcAlloc, srcBuffer, numBytes, 1);
  fprintf(stderr, "Main::flush and invalidate complete\n");
  sleep(1);

  unsigned int ref_srcAlloc = dma->reference(srcAlloc);

  nandAlloc = portalAlloc(nandBytes, 0);
  int ref_nandAlloc = dma->reference(nandAlloc);
  fprintf(stderr, "NAND alloc fd=%d ref=%d\n", nandAlloc, ref_nandAlloc);
  device->configureNand(ref_nandAlloc, nandBytes);
  deviceIndication->wait();

  /* do tests */
  unsigned long loop = 0;
  unsigned long match = 0, mismatch = 0;
  while (loop < nandBytes) {
	  unsigned int i;
	  for (i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
		  srcBuffer[i] = loop+i;
	  }

	  fprintf(stderr, "Main::starting write ref=%d, len=%08lx (%lu)\n", ref_srcAlloc, (long)numBytes, loop);
	  device->startWrite(ref_srcAlloc, 0, loop, numBytes, 16);
	  deviceIndication->wait();

	  loop+=numBytes;
  }

  loop = 0;
  while (loop < nandBytes) {
	  unsigned int i;
	  fprintf(stderr, "Main::starting read %08lx (%lu)\n", (long)numBytes, loop);
	  device->startRead(ref_srcAlloc, 0, loop, numBytes, 16);
	  deviceIndication->wait();

	  for (i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
		  if (srcBuffer[i] != loop+i) {
			  fprintf(stderr, "Main::mismatch [%08lx] != [%08lx]\n", (long)loop+i, (long)srcBuffer[i]);
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
}
