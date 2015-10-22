
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

#ifdef MATRIX_NT
#include "MmRequestNT.h"
MmRequestNTProxy *mmdevice = 0;
#else
#ifdef MATRIX_TN
#include "MmRequestTN.h"
MmRequestTNProxy *mmdevice = 0;
#endif
#endif
#include <MmIndication.h>
#include <dmaManager.h>
#include <errno.h>
#include <math.h> // frexp(), fabs()
#include <assert.h>
#include "portalmat.h"

static int verbose = 0;

#ifdef CUDA_PERF_TEST
void cuda_test();
long int cuda_mm(cv::Mat& src1, cv::Mat& src2, cv::Mat& dst);
#endif


void *dbgThread(void *)
{
  while (1) {
    sleep(2);
    mmdevice->debug();
  }
  return 0;
}

bool compare(cv::Mat& m1, cv::Mat& m2, float epsilon)
{
  bool rv = (m1.rows == m2.rows);
  rv &= (m1.cols == m2.cols);
  for(int i = 0; i < m1.rows; i++){
    for(int j = 0; j < m1.cols; j++) {
      float err = fabs(m1.at<float>(i,j)-m2.at<float>(i,j))/m1.at<float>(i,j);
      bool pass = (epsilon > err);
      if (verbose && !pass) fprintf(stderr, "%f %f\n", m1.at<float>(i,j), m2.at<float>(i,j));
      rv &= pass;
    }
  }
  return rv;
}

int main(int argc, const char **argv)
{
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
  bool sane = 1;
#define LARGE_MAT
#ifdef LARGE_MAT
#ifdef SIMULATION
  int A = 64;
  int B = 256;
#else
  int A = 256;
  int B = 2048;
#endif
  if (argc > 1) {
    B = strtoul(argv[1], 0, 0);
    A = 2*B;
  }
  srand(A*B);
  cv::Mat m1(A,B,CV_32F);
  cv::Mat m2(B,A,CV_32F);
  for(int a = 0; a < A; a++){
    for(int b = 0; b < B; b++){
      float v = (float)(rand() % 10);
      m2.at<float>(b,a) = (A*B)+v;
      m1.at<float>(a,b) = v;
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

#ifndef CUDA_PERF_TEST
#ifdef MATRIX_NT
  mmdevice = new MmRequestNTProxy(IfcNames_MmRequestNTS2H);
#else
#ifdef MATRIX_TN
  mmdevice = new MmRequestTNProxy(IfcNames_MmRequestTNS2H);
#endif
#endif
  MmIndication *mmdeviceIndication = new MmIndication(IfcNames_MmIndicationH2S);
  //TimerRequestProxy *timerdevice = new TimerRequestProxy(IfcNames_TimerRequestPortalS2H);
  TimerIndication timerdeviceIndication(IfcNames_TimerIndicationH2S);
    DmaManager *dma = platformInit();

  if(sem_init(&mul_sem, 1, 0)){
    fprintf(stderr, "failed to init mul_sem\n");
    return -1;
  }

  long req_freq = 100000000;
  long freq = 0;
  setClockFrequency(0, req_freq, &freq);
  fprintf(stderr, "Requested FCLK[0]=%ld actually %ld\n", req_freq, freq);

  matAllocator = new PortalMatAllocator(dma);
  FILE *octave_file = fopen("foo.m", "w");

  fprintf(stderr, "OpenCV matmul\n");
  portalTimerStart(0);
  cv::Mat  m3 = m1 * m2;
  //uint64_t opencv_hw_cycles = portalTimerLap(0);

  PortalMat tm3;
  fprintf(stderr, "Naive matmul\n");
  portalTimerStart(0);
  tm3.naive_mul(m1,m2, octave_file);
  //uint64_t naive_hw_cycles = portalTimerLap(0);

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

#ifdef MATRIX_TN
  fprintf(stderr, "pm1t\n");
  PortalMat pm1t(m1.t());
  fprintf(stderr, "pm2\n");
  PortalMat pm2(m2);
  pm1t.reference();
  pm2.reference();
#else
#ifdef MATRIX_NT
  fprintf(stderr, "pm1\n");
  PortalMat pm1(m1);
  fprintf(stderr, "pm2t\n");
  PortalMat pm2t(m2.t());
  pm1.reference();
  pm2t.reference();
#endif
#endif
  PortalMat pm3;
  pm3.create(m1.rows, m2.cols, CV_32F);
  pm3.reference();

  // we invoke .reference on the matrices in advance 
  // in order to avoid counting the elapsed time for
  // performance analysis.  This is not strictly necessary
  // as all the portalmat methods make sure a valid 
  // reference is available before invoking the hardware

  pthread_t dbgtid;
  fprintf(stderr, "creating debug thread\n");

  if(pthread_create(&dbgtid, NULL,  dbgThread, NULL)){
   fprintf(stderr, "error creating debug thread\n");
   exit(1);
  }

  fprintf(stderr, "HW matmul\n");
  portalTimerStart(0);
#ifdef MATRIX_TN
  pm3.multf(pm1t, pm2, mmdeviceIndication);
#else
#ifdef MATRIX_NT
  pm3.multf(pm1, pm2t, mmdeviceIndication);
#endif
#endif
#if 0
  //uint64_t hw_cycles = portalTimerLap(0); 
  uint64_t read_beats = hostMemServerIndication.getMemoryTraffic(ChannelType_Read);
  uint64_t write_beats = hostMemServerIndication.getMemoryTraffic(ChannelType_Write);
  float read_util = (float)read_beats/(float)mmdeviceIndication->ccnt;
  float write_util = (float)write_beats/(float)mmdeviceIndication->ccnt;
  float read_bw = read_util * N_VALUE * 4 * (float)freq / 1.0e9;
  float write_bw = write_util * N_VALUE * 4 * (float)freq / 1.0e9;
  float macs = m1.rows * m2.rows * m2.cols;
  fprintf(stderr, "Bus frequency %f MHz\n", (float)freq / 1.0e6);
  fprintf(stderr, "memory read  beats %f utilization %f (beats/cycle), bandwidth %f (GB/s)\n", (float)read_beats, read_util, read_bw);
  fprintf(stderr, "memory write beats %f utilization %f (beats/cycle), bandwidth %f (GB/s)\n", (float)write_beats, write_util, write_bw);
  fprintf(stderr, "Throughput %f macs/cycle %f GFLOP/s\n",
	  (float)macs / (float)mmdeviceIndication->ccnt,
	  2.0 * (float)macs / (float)mmdeviceIndication->ccnt * freq / 1.0e9);
  fprintf(stderr, "Time %f cycles, opencv matmul %f cycles (speedup %f), naive matmul %f cycles (speedup %f)\n",
	  (float)mmdeviceIndication->ccnt,
	  (float)opencv_hw_cycles, (float)opencv_hw_cycles/(float)mmdeviceIndication->ccnt,
	  (float)naive_hw_cycles, (float)naive_hw_cycles/(float)mmdeviceIndication->ccnt);
#endif

  if (0) {
    dumpMat<float>("pm3", "%5.1f", pm3);
    dumpMat<float>(" m3", "%5.1f", m3);
  }
  bool eq = pm3.compare(m3);
#else // CUDA_PERF_TEST
  cv::Mat cm3(m1.rows,m2.cols, CV_32F);
  cuda_mm(m1, m2, cm3);
  cv::Mat  m3 = m1 * m2;
  bool eq = compare(m3, cm3, 0.01);
#endif // CUDA_PERF_TEST
  fprintf(stderr, "XXXXXXXXXXXXXXXXXXXXXXXXXX eq=%d\n", eq);
  return(!(eq&&sane));
}

