
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

#include <MmRequestProxy.h>
#include <MmIndicationWrapper.h>
#include <MmDebugIndicationWrapper.h>
#include <MmDebugRequestProxy.h>
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
#include "mnist.h"

static int verbose = 0;

class SigmoidIndication;
class MmIndication;
class MmDebugIndication;

RbmRequestProxy *rbmdevice = 0;
MmRequestProxy *mmdevice = 0;
MmDebugRequestProxy *mmdebug = 0;
SigmoidIndication *sigmoidindication = 0;
SigmoidRequestProxy *sigmoiddevice = 0;
TimerRequestProxy *timerdevice = 0;
MmIndication *mmdeviceIndication = 0;
MmDebugIndication *mmDebugIndication = 0;
TimerIndication *timerdeviceIndication = 0;
DmaConfigProxy *dma = 0;
DmaIndicationWrapper *dmaIndication = 0;

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
    sleep(2);
    if (dma) {
      dma->getStateDbg(ChannelType_Read);
    }
    if (mmdebug) {
      fprintf(stderr, "Calling mmdebug->debug()\n");
      mmdebug->debug();
    }
  }
  return 0;
}

int main(int argc, const char **argv)
{
  unsigned int srcGen = 0;

  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  mmdevice = new MmRequestProxy(IfcNames_MmRequestPortal);
  mmdebug = new MmDebugRequestProxy(IfcNames_MmDebugRequestPortal);
  mmdeviceIndication = new MmIndication(IfcNames_MmIndicationPortal);
  mmDebugIndication = new MmDebugIndication(IfcNames_MmDebugIndicationPortal);
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

#define LARGE_MAT
#ifdef LARGE_MAT
  int matrixSize = 32;
  if (argc > 1)
    matrixSize = strtoul(argv[1], 0, 0);
  cv::Mat m1 = (cv::Mat_<float>(matrixSize,matrixSize) <<
		11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,
		21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,
		31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,
		41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,
		11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,
		21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,
		31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,
		41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,
		11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,
		21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,
		31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,
		41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,
		11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,11,12,13,14,15,16,17,18,
		21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,21,22,23,24,25,26,27,28,
		31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,31,32,33,34,35,36,37,38,
		41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48,41,42,43,44,45,46,47,48
		);
  cv::Mat m2 = (cv::Mat_<float>(matrixSize,matrixSize) <<
		51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,
		61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,
		71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,
		81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,
		51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,
		61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,
		71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,
		81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,
		51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,
		61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,
		71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,
		81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,
		51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,51,62,53,54,55,56,57,58,
		61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,61,62,63,64,65,66,67,68,
		71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,71,72,73,74,75,76,77,78,
		81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88,81,82,83,84,85,86,87,88
		);
#else
  cv::Mat m1 = (cv::Mat_<float>(4,8) <<
		11,12,13,14,15,16,17,18,
		21,22,23,24,25,26,27,28,
		31,32,33,34,35,36,37,38,
		41,42,43,44,45,46,47,48
		);
  cv::Mat m2 = (cv::Mat_<float>(4,8) <<
		51,62,53,54,55,56,57,58,
		61,62,63,64,65,66,67,68,
		71,72,73,74,75,76,77,78,
		81,82,83,84,85,86,87,88
		);
#endif
  PortalMat pm1(m1);
  PortalMat pm2(m2);
  PortalMat pm3;
  //dumpMat<float>("pm1", "%5.1f", pm1);
  //dumpMat<float>("pm2", "%5.1f", pm2);
  start_timer(0);
  pm3.multf(pm1, pm2,mmdeviceIndication);
  uint64_t hw_cycles = lap_timer(0); 
  uint64_t read_beats = dma->show_mem_stats(ChannelType_Read);
  uint64_t write_beats = dma->show_mem_stats(ChannelType_Write);
  float read_util = (float)read_beats/(float)mmdeviceIndication->ccnt;
  float write_util = (float)write_beats/(float)mmdeviceIndication->ccnt;
  fprintf(stderr, "memory read beats %ld utilization (beats/cycle): %f\n", read_beats, read_util);
  fprintf(stderr, "memory write beats %ld utilization (beats/cycle): %f\n", write_beats, write_util);

  cv::Mat  m3 = pm1 * pm2.t();
  if (0) {
    dumpMat<float>("pm1 * pm2", "%5.1f", pm3);
    dumpMat<float>("m1 * m2", "%5.1f", m3);
  }
  bool eq = std::equal(m3.begin<float>(), m3.end<float>(), pm3.begin<float>());
  dumpMat<float>("diff", "%5.1f", pm3);
  fprintf(stderr, "eq=%d\n", eq);
  //device->finish();
  exit(!eq);
}
