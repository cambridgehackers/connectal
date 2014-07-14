
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
DmaConfigProxy *dmap = 0;
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
    if (dmap) {
      dmap->getStateDbg(ChannelType_Read);
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

  dmap = new DmaConfigProxy(IfcNames_DmaConfigPortal);
  DmaManager *dma = new DmaManager(dmap);
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

  matAllocator = new PortalMatAllocator(dmap, dma);

#define LARGE_MAT
#ifdef LARGE_MAT
  int A = 32;
  int B = 512;
  if (argc > 1) {
    B = strtoul(argv[1], 0, 0);
    A = 2*B;
  }
  cv::Mat m1(A,B,CV_32F);
  cv::Mat m2(B,A,CV_32F);
  float v = 0;
  for(int a = 0; a < A; a++){
    for(int b = 0; b < B; b++){
      m2.at<float>(b,a) = (A*B)+v;
      m1.at<float>(a,b) = v;
      v++;
    }
  }
#else
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
#endif

  FILE *octave_file = fopen("foo.m", "w");

  start_timer(0);
  fprintf(stderr, "OpenCV matmul\n");
  cv::Mat  m3 = m1 * m2;
  uint64_t opencv_hw_cycles = lap_timer(0);

  PortalMat tm3;
  fprintf(stderr, "Naive matmul\n");
  start_timer(0);
  tm3.naive_mul(m1,m2, octave_file);
  uint64_t naive_hw_cycles = lap_timer(0);

  bool sane = 1;
  if (1) {
    fprintf(stderr, "DumpMat\n");
    dumpMatOctave<float>("m1",  "%10.5f", m1,  octave_file);
    dumpMatOctave<float>("m2",  "%10.5f", m2,  octave_file);
    dumpMatOctave<float>("m3",  "%10.5f", m3,  octave_file);
    dumpMatOctave<float>("tm3", "%10.5f", tm3, octave_file);
    fclose(octave_file);
    sane = tm3.compare(m3, 0, 0, 0.0001, 0, false);
    fprintf(stderr, "sane=%d\n", sane);
    fflush(stdout);
  }

  fprintf(stderr, "pm1\n");
  PortalMat pm1(m1);
  fprintf(stderr, "pm2t\n");
  PortalMat pm2t(m2.t());
  PortalMat pm3;
  fprintf(stderr, "HW matmul\n");
  start_timer(0);
  pm3.multf(pm1, pm2t, mmdeviceIndication);
  uint64_t hw_cycles = lap_timer(0); 
  uint64_t read_beats = dma->show_mem_stats(ChannelType_Read);
  uint64_t write_beats = dma->show_mem_stats(ChannelType_Write);
  float read_util = (float)read_beats/(float)mmdeviceIndication->ccnt;
  float write_util = (float)write_beats/(float)mmdeviceIndication->ccnt;
  fprintf(stderr, "memory read beats %lld utilization (beats/cycle): %f\n", read_beats, read_util);
  fprintf(stderr, "memory write beats %lld utilization (beats/cycle): %f\n", write_beats, write_util);
  fprintf(stderr, "opencv matmul %ld cycles (speedup %5.2ff), naive matmul %ld cycles (speedup %5.2f)\n",
	  opencv_hw_cycles, (float)opencv_hw_cycles/(float)hw_cycles,
	  naive_hw_cycles, (float)naive_hw_cycles/(float)hw_cycles);

  if (0) {
    dumpMat<float>("pm3", "%5.1f", pm3);
    dumpMat<float>(" m3", "%5.1f", m3);
  }
  //bool eq = std::equal(m3.begin<float>(), m3.end<float>(), pm3.begin<float>());
  bool eq = pm3.compare(pm3);
  fprintf(stderr, "eq=%d\n", eq);
  //device->finish();
  exit(!eq&&!sane);
}
