
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <RbmRequestProxy.h>
#include <RbmIndicationWrapper.h>
#include <DmaConfigProxy.h>
#include <GeneratedTypes.h>
//#include <DmaIndicationWrapper.h>
#include <StdDmaIndication.h>
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>
#include <errno.h>
#include <math.h> // frexp(), fabs()
#include <assert.h>
#include "portalmat.h"
#include "rbm.h"
#include "mnist.h"

static int verbose = 0;

class RbmIndication;

DmaConfigProxy *dma = 0;
DmaIndicationWrapper *dmaIndication = 0;
MmIndication *mmdeviceIndication = 0;
MmRequestProxy *mmdevice = 0;
SigmoidIndication *sigmoidindication = 0;
SigmoidRequestProxy *sigmoiddevice = 0;
RbmIndication *deviceIndication = 0;
RbmRequestProxy *rbmdevice = 0;
TimerIndication *timerdeviceIndication = 0;
TimerRequestProxy *timerdevice = 0;

long dotprod = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (int i = 0; i < (len > 64 ? 64 : len) ; i++) {
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
	if (i % 4 == 3)
	  fprintf(stderr, " ");
    }
    fprintf(stderr, "\n");
}

void *dbgThread(void *)
{
  while (1) {
    sleep(1);
    if (dma) {
      dma->getStateDbg(ChannelType_Read);
      rbmdevice->dbg();
      sleep(5);
    }
  }
  return 0;
}

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  rbmdevice = new RbmRequestProxy(IfcNames_RbmRequestPortal);
  deviceIndication = new RbmIndication(IfcNames_RbmIndicationPortal);
  mmdevice = new MmRequestProxy(IfcNames_MmRequestPortal);
  mmdeviceIndication = new MmIndication(IfcNames_MmIndicationPortal);
  sigmoiddevice = new SigmoidRequestProxy(IfcNames_SigmoidRequestPortal);
  sigmoidindication = new SigmoidIndication(IfcNames_SigmoidIndicationPortal);
  timerdevice = new TimerRequestProxy(IfcNames_TimerRequestPortal);
  timerdeviceIndication = new TimerIndication(IfcNames_TimerIndicationPortal);

  dma = new DmaConfigProxy(IfcNames_DmaConfigPortal);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndicationPortal);

  if(sem_init(&mul_sem, 1, 0)){
    fprintf(stderr, "failed to init mul_sem\n");
    return -1;
  }

  pthread_t tid;
  fprintf(stderr, "creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
   fprintf(stderr, "error creating exec thread\n");
   exit(1);
  }

  pthread_t dbgtid;
  fprintf(stderr, "creating debug thread\n");
  if(pthread_create(&dbgtid, NULL,  dbgThread, NULL)){
   fprintf(stderr, "error creating debug thread\n");
   exit(1);
  }

  matAllocator = new PortalMatAllocator(dma);

  configureSigmoidTable(rbmdevice, deviceIndication);

  if (1) {
    cv::Mat m1 = (cv::Mat_<float>(4,6) <<
		  1,2,3,4,5,6,
		  4,5,6,7,8,9,
		  7,8,9,10,11,12,
		  10,11,12,13,14,15);
    cv::Mat m2 = (cv::Mat_<float>(4,6) <<
		  11,12,13,14,15,16,
		  16,17,18,19,20,21,
		  21,22,23,24,25,26,
		  24,25,26,27,28,29);
    PortalMat pm1(m1);
    PortalMat pm2(m2);
    PortalMat pm3;
    dumpMat<float>("pm1", "%5.1f", pm1);
    dumpMat<float>("pm2", "%5.1f", pm2);
    pm3.sigmoid(pm1);
    dumpMat<float>("sigmoid", "%5.1f", pm3);
    pm3.multf(pm1, pm2);
    pm3.multf(pm1, pm2);
    dumpMat<float>("pm1 * pm2", "%5.1f", pm3);
  } else {
    RBM rbm(dma);
    rbm.run();
  }

  rbmdevice->finish();
  exit(0);
}
