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

#ifndef _PORTALMAT_H_
#define _PORTALMAT_H_

#include <opencv2/core/core.hpp>
#include <semaphore.h>
#include <stdio.h>
#include <sys/mman.h>

#include <portal.h>
#include "dmaManager.h"
#include "MemServerRequest.h"
#include "MMURequest.h"

#ifdef MATRIX_NT
#include "MmRequestNT.h"
extern MmRequestNTProxy *mmdevice;
#else
#ifdef MATRIX_TN
#include "MmRequestTN.h"
extern MmRequestTNProxy *mmdevice;
#endif
#endif
 
#include "MmIndication.h"
#include "TimerRequest.h"
#include "TimerIndication.h"

extern TimerRequestProxy *timerdevice;
extern sem_t mul_sem;

class PortalMatAllocator : public cv::MatAllocator {
public:
  PortalMatAllocator(DmaManager *dma) : numarrays(1), dma(dma) {}
  virtual ~PortalMatAllocator() {}
  virtual void allocate(int dims, const int* sizes, int type, int*& refcount,
			uchar*& datastart, uchar*& data, size_t* step);
  virtual void deallocate(int* refcount, uchar* datastart, uchar* data);
  int reference(int* refcount, uchar* datastart, uchar* data);
  void cacheFlushInvalidate(int* refcount, uchar* datastart, uchar* data);
private:
  struct arrayInfo {
    // refcount goes first
    int refcount;
    int fd;
    uchar *data;
    size_t totalsize;
    int ref;
  } arrayInfo[128];
  int numarrays;
  DmaManager *dma;
};

extern PortalMatAllocator *matAllocator;
class MmIndication;

class PortalMat : public cv::Mat {
public:
  PortalMat();
  PortalMat(int rows, int cols, int type);
  PortalMat(int rows, int cols, int type, const cv::Scalar& s);
  PortalMat(const PortalMat &m);
  PortalMat(const cv::Mat &m);
  ~PortalMat();
  PortalMat& operator = (const cv::MatExpr& expr);
  PortalMat& operator = (const cv::Mat& o);
  int reference();
  void cacheFlushInvalidate();
  bool copy(cv::Mat &other);
  bool copy(cv::MatExpr other);
  bool transpose(cv::Mat &other);
  bool compare(Mat &other, const char *file=0, int line=0, float epsilon=0.01, Mat *pm = 0, bool verbose = false);
  void naive_mul(cv::Mat &a, cv::Mat &b, FILE *f);
  void multf(PortalMat &a, PortalMat &b_transpose, MmIndication *mmind = NULL);
};

class MmIndication : public MmIndicationWrapper
{
public:
  uint64_t ccnt;
 MmIndication(int id) : MmIndicationWrapper(id) {
    ccnt = 0;
  }
  virtual ~MmIndication() {}
  virtual void mmfDone(uint64_t cycles) {
    ccnt = cycles;
    fprintf(stderr, "mmfDone cycles=%ld\n", (long)cycles);
    sem_post(&mul_sem);
  }
  void dpsVal(uint32_t v) {
    fprintf(stderr, "dpsVal v=%x %f\n", v, *(float *)&v);
    sem_post(&mul_sem);
  }
  void started() {
    fprintf(stderr, "mm.started:\n");
  }
  virtual void startSourceAndSink ( const unsigned int startA, const unsigned int startC, const int jint ) {
    fprintf(stderr, "mm.startSourceAndSink: startA=%6d startC=%06d jint=%d\n", startA, startC, jint);
  }
  virtual void debug ( uint32_t macCount) {
    fprintf(stderr, "mm.debug: macCount=%d\n", macCount);
  }
};

class TimerIndication : public TimerIndicationWrapper
{
public:
 TimerIndication(int id) : TimerIndicationWrapper(id) {
  }
  virtual ~TimerIndication() {}
  virtual void elapsedCycles(uint64_t cycles, uint64_t idleCycles) {
    fprintf(stderr, "elapsedCycles %lld idle %lld idle %f\n", (long long)cycles, (long long)idleCycles, (double)idleCycles / (double)cycles);
  }
};

template<typename T>
  void dumpMat(const char *prefix, const char *fmt, const cv::Mat &mat);

template<typename T>
  void dumpMatF(const char *prefix, const char *fmt, const cv::Mat &mat, FILE *ofile);

template<typename T>
  void dumpMatOctave(const char *name, const char *fmt, const cv::Mat &mat, FILE *ofile);

void dynamicRange(cv::Mat mat, int *pmin_exp, int *pmax_exp, float *pmin_val=0, float *pmax_val=0);

#endif // _PORTALMAT_H_

