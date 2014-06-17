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

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include <portal.h>
#include "DmaConfigProxy.h"
#include "RbmRequestProxy.h"
#include "RbmIndicationWrapper.h"
#include "MmRequestProxy.h"
#include "MmIndicationWrapper.h"
#include "MmDebugIndicationWrapper.h"
#include "SigmoidRequestProxy.h"
#include "SigmoidIndicationWrapper.h"
#include "TimerRequestProxy.h"
#include "TimerIndicationWrapper.h"

class SigmoidIndication;

extern RbmRequestProxy *rbmdevice;
extern MmRequestProxy *mmdevice;
extern SigmoidRequestProxy *sigmoiddevice;
extern SigmoidIndication *sigmoidindication;
extern TimerRequestProxy *timerdevice;
extern sem_t mul_sem;

class PortalMatAllocator : public cv::MatAllocator {
public:
 PortalMatAllocator(DmaConfigProxy *dma) : numarrays(1), dma(dma) {}
  virtual ~PortalMatAllocator() {}
  virtual void allocate(int dims, const int* sizes, int type, int*& refcount,
			uchar*& datastart, uchar*& data, size_t* step);
  virtual void deallocate(int* refcount, uchar* datastart, uchar* data);
  int reference(int* refcount, uchar* datastart, uchar* data);
private:
  PortalAlloc *portalAlloc[128];
  int numarrays;
  DmaConfigProxy *dma;
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
  bool copy(cv::Mat &other);
  bool copy(cv::MatExpr other);
  bool transpose(cv::Mat &other);
  bool compare(Mat &other, const char *file=0, int line=0, float epsilon=0.0001, Mat *pm = 0);

  /*!
   * Multiplies a * b-transpose
   */
  void multf(PortalMat &a, PortalMat &b_transpose, MmIndication *mmind = NULL);
  void sigmoid(PortalMat &a);
  void hiddenStates(PortalMat &a);
  void hiddenStates2(PortalMat &a, PortalMat &rand);
  // weights += learningRate * (pos_associations - neg_associations) / num_examples;
  void updateWeights(PortalMat &posAssociations, PortalMat &negAssociations, float learningRateOverNumExamples);
  void sumOfErrorSquared(PortalMat &pred);
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
    sem_post(&mul_sem);
    fprintf(stderr, "mmfDone cycles=%ld\n", cycles);
  }
};

class MmDebugIndication : public MmDebugIndicationWrapper {
//wrapperClass
public:
 MmDebugIndication(int id, PortalPoller *poller = 0) : MmDebugIndicationWrapper(id, poller) {};
  virtual ~MmDebugIndication() {};

  void started() {
    fprintf(stderr, "mm.started()\n");
  }
  virtual void startSourceAndSink ( const unsigned int startA, const unsigned int startC, const int jint ) {
    fprintf(stderr, "mm.startSourceAndSink startA=%6d startC=%06d jint=%d\n", startA, startC, jint);
  }
  virtual void debug ( uint32_t aNotEmpty, uint32_t bNotEmpty, uint32_t macCount, uint32_t mmtilesANE, uint32_t mmtilesBNE, uint64_t chans) {
    fprintf(stderr, "mmdebug aNotEmpty=%x bNotEmpty=%x macCount=%d ane=%x bne=%x chans="PRIu64"\n", aNotEmpty, bNotEmpty, macCount, mmtilesANE, mmtilesBNE, chans);
  }

};

class SigmoidIndication : public SigmoidIndicationWrapper
{
public:
 SigmoidIndication(int id) : SigmoidIndicationWrapper(id) {
  }
  virtual ~SigmoidIndication() {}
  virtual void sigmoidDone() {
    fprintf(stderr, "sigmoidDone\n");
    sem_post(&mul_sem);
  }
  virtual void sigmoidTableUpdated(uint32_t addr) {
    sem_post(&mul_sem);
  }
  uint32_t sigmoidTableSize() { return sigmoidTableSize_; }
  virtual void sigmoidTableSize(uint32_t size) {
    fprintf(stderr, "sigmoidTableSize %d\n", size);
    sigmoidTableSize_ = size;
    sem_post(&mul_sem);
  }
 private:
  uint32_t sigmoidTableSize_;
};

class TimerIndication : public TimerIndicationWrapper
{
public:
 TimerIndication(int id) : TimerIndicationWrapper(id) {
  }
  virtual ~TimerIndication() {}
  virtual void elapsedCycles(uint64_t cycles, uint64_t idleCycles) {
    fprintf(stderr, "elapsedCycles %zd idle %zd idle %f\n", cycles, idleCycles, (double)idleCycles / (double)cycles);
  }
};
class RbmIndication : public RbmIndicationWrapper
{
public:
 RbmIndication(int id) : RbmIndicationWrapper(id) {
  }
  virtual ~RbmIndication() {}
  virtual void bramMmfDone() {
    //fprintf(stderr, "bramMmfDone\n");
    sem_post(&mul_sem);
  }
  virtual void toBramDone() {
    //fprintf(stderr, "toBramDone\n");
    sem_post(&mul_sem);
  }
  virtual void fromBramDone() {
    //fprintf(stderr, "fromBramDone\n");
    sem_post(&mul_sem);
  }
  virtual void statesDone() {
    //fprintf(stderr, "statesDone\n");
    sem_post(&mul_sem);
  }
  virtual void statesDone2() {
    //fprintf(stderr, "statesDone2\n");
    sem_post(&mul_sem);
  }
  virtual void updateWeightsDone() {
    //fprintf(stderr, "updateWeightsDone\n");
    sem_post(&mul_sem);
  }
  virtual void sumOfErrorSquared(uint32_t x) {
    //fprintf(stderr, "sumOfErrorSquared error=%f\n", *(float *)&x);
    sem_post(&mul_sem);
  }
  virtual void dbg(uint32_t a, uint32_t b, uint32_t c, uint32_t d) {
    fprintf(stderr, "rbm dbg a=%x b=%x c=%x d=%x\n", a, b, c, d);
  }
};

float sigmoid(float x);
void configureSigmoidTable(RbmRequestProxy *device, RbmIndication *indication);

template<typename T>
  void dumpMat(const char *prefix, const char *fmt, const cv::Mat &mat);
void dumpMatf(const char *prefix, const char *fmt, const cv::Mat &mat);

#endif // _PORTALMAT_H_

