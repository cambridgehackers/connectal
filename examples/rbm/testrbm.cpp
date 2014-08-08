
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

#ifdef MATRIX_NT
#include "MmRequestNTProxy.h"
MmRequestNTProxy *mmdevice = 0;
#else
#ifdef MATRIX_TN
#include "MmRequestTNProxy.h"
MmRequestTNProxy *mmdevice = 0;
#endif
#endif
DmaManager *dma = 0;
DmaConfigProxy *dmap = 0;
DmaIndicationWrapper *dmaIndication = 0;
MmIndication *mmdeviceIndication = 0;
SigmoidIndication *sigmoidindication = 0;
SigmoidRequestProxy *sigmoiddevice = 0;
RbmIndication *rbmDeviceIndication = 0;
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
      dmap->getStateDbg(ChannelType_Read);
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
#ifdef MATRIX_NT
  mmdevice = new MmRequestNTProxy(IfcNames_MmRequestPortal);
#else
#ifdef MATRIX_TN
  mmdevice = new MmRequestTNProxy(IfcNames_MmRequestPortal);
#endif
#endif
  rbmdevice = new RbmRequestProxy(IfcNames_RbmRequestPortal);
  rbmDeviceIndication = new RbmIndication(IfcNames_RbmIndicationPortal);
  mmdeviceIndication = new MmIndication(IfcNames_MmIndicationPortal);
  sigmoiddevice = new SigmoidRequestProxy(IfcNames_SigmoidRequestPortal);
  sigmoidindication = new SigmoidIndication(IfcNames_SigmoidIndicationPortal);
  timerdevice = new TimerRequestProxy(IfcNames_TimerRequestPortal);
  timerdeviceIndication = new TimerIndication(IfcNames_TimerIndicationPortal);

  dmap = new DmaConfigProxy(IfcNames_DmaConfigPortal);
  dma = new DmaManager(dmap);
  dmaIndication = new DmaIndication(dma, IfcNames_DmaIndicationPortal);

  if(sem_init(&mul_sem, 1, 0)){
    fprintf(stderr, "failed to init mul_sem\n");
    return -1;
  }

  portalExec_start();

  pthread_t dbgtid;
  fprintf(stderr, "creating debug thread\n");
  if(pthread_create(&dbgtid, NULL,  dbgThread, NULL)){
   fprintf(stderr, "error creating debug thread\n");
   exit(1);
  }

  matAllocator = new PortalMatAllocator(dmap, dma);
  configureSigmoidTable(rbmdevice, rbmDeviceIndication);
  int rv = 0;

  if (1) {
    cv::Mat m1 = (cv::Mat_<float>(4,8) <<
		  11,12,13,14,15,16,17,18,
		  21,22,23,24,25,26,27,28,
		  31,32,33,34,35,36,37,38,
		  41,42,43,44,45,46,47,48
		  );
    cv::Mat m2 = (cv::Mat_<float>(8,4) <<
		  51,62,53,54,
		  55,56,57,58,
		  61,62,63,64,
		  65,66,67,68,
		  71,72,73,74,
		  75,76,77,78,
		  81,82,83,84,
		  85,86,87,88
		  );
    cv::Mat m4 = (cv::Mat_<float>(8,4) <<
		  0.80,0.80,0.80,0.80,
		  0.80,0.80,0.80,0.80,
		  0.80,0.80,0.80,0.80,
		  0.80,0.80,0.80,0.80,
		  0.50,0.50,0.50,0.50,
		  0.50,0.50,0.50,0.50,
		  0.50,0.50,0.50,0.50,
		  0.50,0.50,0.50,0.50
		  );
#ifdef MATRIX_TN
    RbmMat pm1(m1.t());
    RbmMat pm2(m2);
#else
#ifdef MATRIX_NT
    RbmMat pm1(m1);
    RbmMat pm2(m2.t());
#endif
#endif
    
    RbmMat pm4(m4);
    RbmMat pm3;
    pm3.create(m1.rows, m2.cols, CV_32F);
    cv::Mat  m3 = m1 * m2;

    pm3.multf(pm1, pm2, mmdeviceIndication);
    pm3.multf(pm1, pm2, mmdeviceIndication);

    dumpMat<float>("pm1", "%5.1f", pm1);
    dumpMat<float>("pm2", "%5.1f", pm2);
    dumpMat<float>("pm1 * pm2", "%5.1f", pm3);

    bool eq = pm3.compare(m3);
    fprintf(stderr, "XXXXXXXXXXXXXXXXXXXXXX eq=%d\n", eq);

    pm3.sigmoid(pm4);
    dumpMat<float>("pm4", "%1.6f", pm4);
    dumpMat<float>("sigmoid", "%1.6f", pm3);

    rv = !eq;
  } else {
    RBM rbm(dma);
    rbm.run();
  }

  rbmdevice->finish();
  exit(rv);
}
