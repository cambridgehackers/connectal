
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

#include <unistd.h>
#include "portalmat.h"
#include <StdDmaIndication.h>

PortalMatAllocator *matAllocator = 0;
sem_t mul_sem;

void PortalMatAllocator::allocate(int dims, const int* sizes, int type, int*& refcount,
				  uchar*& datastart, uchar*& data, size_t* step)
{
  size_t arraysize = step[0]*sizes[0];
  size_t totalsize = cv::alignSize(arraysize+3*sizeof(int), 4096);
  int arraynum = numarrays++;
  dma->alloc(totalsize, &portalAlloc[arraynum]);

  data = datastart = (uchar*)(unsigned int *)mmap(0, totalsize, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, portalAlloc[arraynum]->header.fd, 0);
  refcount = (int*)(data + arraysize);
  int *parraynum = refcount+1;
  *parraynum = arraynum;
  int *pref = refcount+2;
  *pref = 0;
  *refcount = 1;
  fprintf(stderr, "PortalMatAllocator::allocate   datastart=%p arraynum=%d size=%ld\n",
	  datastart, arraynum, totalsize);
}

void PortalMatAllocator::deallocate(int* refcount, uchar* datastart, uchar* data)
{
  int *parraynum = refcount+1;
  int *pref = refcount+2;
  int arraynum = *parraynum;
  int ref = *pref;
  size_t size = portalAlloc[arraynum]->header.size;
  fprintf(stderr, "PortalMatAllocator::deallocate datastart=%p arraynum=%d size=%ld\n",
	  datastart, arraynum, size);
  munmap(datastart, size);
  close(portalAlloc[arraynum]->header.fd);
}

int PortalMatAllocator::reference(int* refcount, uchar* datastart, uchar* data)
{
  int *parraynum = refcount+1;
  int *pref = refcount+2;
  int arraynum = *parraynum;
  int ref = *pref;
  //fprintf(stderr, "PortalMatAllocator::reference datastart=%p arraynum=%d ref=%d\n", datastart, arraynum, ref);
  if (!ref) {
    //fprintf(stderr, "Calling dma->reference arraynum=%d\n", arraynum);
    ref = dma->reference(portalAlloc[arraynum]);
    *pref = ref;
  }
  return ref;
}

PortalMat::PortalMat()
    : cv::Mat() 
{
    allocator = matAllocator;
    fprintf(stderr, "PortalMat::PortalMat() this=%p datastart=%p\n", this, datastart);
}

PortalMat::PortalMat(int rows, int cols, int type)
    : cv::Mat()
{
    allocator = matAllocator;
    create(rows, cols, type);
    fprintf(stderr, "PortalMat::PortalMat(rows,cols) this=%p datastart=%p\n", this, datastart);
}

PortalMat::PortalMat(int rows, int cols, int type, const cv::Scalar& s)
    : cv::Mat()
{
    allocator = matAllocator;
    create(rows, cols, type);
    *(cv::Mat*)this = s;
    fprintf(stderr, "PortalMat::PortalMat(Scalar&) this=%p datastart=%p\n", this, datastart);
}

PortalMat::PortalMat(const PortalMat &m)
  : Mat()
{
    allocator = matAllocator;
    create(m.rows, m.cols, CV_32F);
    //*(cv::Mat*)this = m;
    for (int i = 0; i < m.rows; i++)
	for (int j = 0; j < m.cols; j++) {
	    this->at<float>(i,j) = m.at<float>(i,j);
	}
    fprintf(stderr, "PortalMat::PortalMat(PortalMat&) this=%p datastart=%p\n", this, datastart);
}

PortalMat::PortalMat(const cv::Mat &m)
    : Mat()
{
    allocator = matAllocator;
    create(m.rows, m.cols, CV_32F);
    //*(cv::Mat*)this = m;
    for (int i = 0; i < m.rows; i++)
	for (int j = 0; j < m.cols; j++) {
	    this->at<float>(i,j) = m.at<float>(i,j);
	}
    fprintf(stderr, "PortalMat::PortalMat(Mat&) this=%p datastart=%p\n", this, datastart);
}

PortalMat::~PortalMat() {}

PortalMat& PortalMat::operator = (const cv::MatExpr& expr)
{
    *(cv::Mat*)this = expr;
    fprintf(stderr, "PortalMat::operator=(MatExpr&) this=%p datastart=%p\n", this, datastart);
}

PortalMat& PortalMat::operator = (const cv::Mat& o)
{
    *(cv::Mat*)this = o;
    fprintf(stderr, "PortalMat::operator=(Mat&) this=%p datastart=%p\n", this, datastart);
}

int PortalMat::reference()
{
    int ref = 0;
    //fprintf(stderr, "PortalMat::reference this=%p datastart=%p\n", this, datastart);
    ref = matAllocator->reference(refcount, datastart, data);
    return ref;
}

bool PortalMat::copy(cv::Mat &other)
{
    create(other.rows, other.cols, CV_32F);
    for (int i = 0; i < rows; i++) {
	for (int j = 0; j < cols; j++) {
	    at<float>(i, j) = other.at<float>(i, j);
	}
    }
    return true;
}

bool PortalMat::copy(cv::MatExpr other)
{
    cv::Mat m(other);
    create(m.rows, m.cols, CV_32F);
    for (int i = 0; i < rows; i++) {
	for (int j = 0; j < cols; j++) {
	    at<float>(i, j) = m.at<float>(i, j);
	}
    }
    return true;
}

bool PortalMat::transpose(cv::Mat &other)
{
    create(other.cols, other.rows, CV_32F);
    for (int i = 0; i < rows; i++) {
	for (int j = 0; j < cols; j++) {
	    at<float>(i, j) = other.at<float>(j, i);
	}
    }
    return true;
}

bool PortalMat::compare(Mat &other, const char *file, int line, float epsilon, Mat *pm)
{
    if (0)
	fprintf(stderr, "PortalMat.compare rows=%d cols=%d other.rows=%d other.cols=%d\n",
		rows, cols, other.rows, other.cols);

    if (rows != other.rows || cols != other.cols) {
	fprintf(stderr, "PortalMat.compare dimension mismatch rows=%d cols=%d other.rows=%d other.cols=%d\n",
		rows, cols, other.rows, other.cols);
	return false;
    }
    for (int i = 0; i < rows; i++) {
	for (int j = 0; j < cols; j++) {
	    float v = at<float>(i, j);
	    float ov = other.at<float>(i, j);
	    if (fabs(v - ov) > epsilon) {
		if (file)
		    fprintf(stderr, "%s:%d: ", file, line);
		fprintf(stderr, "mismatch[%d,%d] expected %f got %f error=%f", i, j, v, ov, fabs(v - ov));
		if (pm) {
		    float pmv = pm->at<float>(i,j);
		    fprintf(stderr, " pm[%d,%d]=%f %08x", i, j, pmv, *(int*)&pmv);
		}
		fprintf(stderr, "\n");
		//return false;
	    }
	}
    }
    return true;
}

/*!
 * Multiplies a * b-transpose
 */
void PortalMat::multf(PortalMat &a, PortalMat &b_transpose,  MmIndication *mmind)
{
    if (a.cols != b_transpose.cols) {
	fprintf(stderr, "Mismatched matrices: a.rows=%d a.cols=%d b.rows=%d b.cols=%d\n", a.rows, a.cols, b_transpose.rows, b_transpose.cols);
	return;
    }
    create(a.rows, b_transpose.rows, CV_32F);
    fprintf(stderr, "mult: ref=%d rows=%d cols=%d a.ref=%d a.rows=%d a.cols=%d b.ref=%d b.rows=%d b.cols=%d\n",
	    reference(), rows, cols,
	    a.reference(), a.rows, a.cols,
	    b_transpose.reference(), b_transpose.rows, b_transpose.cols);
    fprintf(stderr, "device->mmf\n");
    mmdevice->mmf(a.reference(), a.rows, a.cols,
		  b_transpose.reference(), b_transpose.rows, b_transpose.cols,
		  reference());
    sem_wait(&mul_sem);
    if(mmind) {
      int macs = a.rows*a.cols*b_transpose.rows;
      fprintf(stderr, "macs %d cycles %f macs/cycle: %f\n", macs, (float)mmind->ccnt, ((float)macs)/((float)mmind->ccnt));
    }
}

void PortalMat::sigmoid(PortalMat &a)
{
    create(a.rows, a.cols, CV_32F);
    fprintf(stderr, "sigmoid: a.ref=%d a.rows=%d a.cols=%d\n", a.reference(), a.rows, a.cols);
    reference();
    //fprintf(stderr, "sigmoiddevice->sigmoid\n");
    sigmoiddevice->sigmoid(a.reference(), 0, reference(), 0, a.rows*a.cols);
    sem_wait(&mul_sem);
}

void PortalMat::hiddenStates(PortalMat &a)
{
    create(a.rows, a.cols, CV_32F);
    fprintf(stderr, "hiddenStates: a.ref=%d a.rows=%d a.cols=%d\n", a.reference(), a.rows, a.cols);
    reference();
    //fprintf(stderr, "sigmoiddevice->computeStates\n");
    rbmdevice->computeStates(a.reference(), 0, reference(), 0, a.rows*a.cols);
    sem_wait(&mul_sem);
}

void PortalMat::hiddenStates2(PortalMat &a, PortalMat &rand)
{
    create(a.rows, a.cols, CV_32F);
    fprintf(stderr, "hiddenStates2: a.ref=%d a.rows=%d a.cols=%d\n", a.reference(), a.rows, a.cols);
    rand.reference();
    reference();
    //fprintf(stderr, "rbmdevice->computeStates2 ptr=%d randPtr=%d\n", a.reference(), rand.reference());
    rbmdevice->computeStates2(a.reference(), 0, rand.reference(), 0, reference(), 0, a.rows*a.cols);
    sem_wait(&mul_sem);
}

// weights += learningRate * (pos_associations - neg_associations) / num_examples;
void PortalMat::updateWeights(PortalMat &posAssociations, PortalMat &negAssociations, float learningRateOverNumExamples)
{
    fprintf(stderr, "rbmdevice->updateWeights pa.ref=%d na.ref=%d\n", posAssociations.reference(), negAssociations.reference());
    rbmdevice->updateWeights(posAssociations.reference(), negAssociations.reference(), reference(), rows*cols, *(int*)&learningRateOverNumExamples);
    sem_wait(&mul_sem);
}

void PortalMat::sumOfErrorSquared(PortalMat &pred)
{
    if (rows != pred.rows || cols != pred.cols) {
	fprintf(stderr, "Mismatched data and pred: data.rows=%d data.cols=%d  pred.rows=%d pred.cols=%d\n",
		rows, cols, pred.rows, pred.cols);
	return;
    }
    rbmdevice->sumOfErrorSquared(reference(), pred.reference(), rows*cols);
    sem_wait(&mul_sem);
}

float sigmoid(float x)
{
  if (x < -8.0)
    x = -8.0;
  if (x > 8.0)
    x = 8.0;
  return 1 / (1 + expf(-x));
}

void configureSigmoidTable(RbmRequestProxy *device, RbmIndication *indication)
{
  sigmoiddevice->sigmoidTableSize();
  sem_wait(&mul_sem);

  int num_entries = sigmoidindication->sigmoidTableSize();
  int addrsize = log((double)num_entries) / log(2.0);

  float range = 16.0;
  float lowest_angle = - range/2.0;
  double fincr = (float)num_entries / range;
  double fscale = num_entries / range;
  fprintf(stderr, "configureSigmoidTable: num_entries=%d addrsize=%d fscale=%f fincr=%f\n", num_entries, addrsize, fscale, fincr);

  PortalMat sigmoidTable;
  // each entry consists of [-angle, sigmoid(angle), derivative, 0]
  sigmoidTable.create(1, 4*num_entries, CV_32F);

  // v = (index-num_entries/2) / fscale
  // index = v * fscale + num_entries/2

  float fxscale = fscale;
  float fxllimit = (float)lowest_angle;
  float fxulimit = (float)-lowest_angle;
  fprintf(stderr, "configureSigmoidTable num_entries=%d rscale=%f %x llimit=%f %x rlimit=%f %x\n",
	  num_entries, fxscale, *(int*)&fxscale, fxllimit, *(int*)&fxllimit, fxulimit, *(int*)&fxulimit);
  sigmoiddevice->setSigmoidLimits(*(int*)&fxscale, *(int*)&fxllimit, *(int*)&fxulimit);

  int incr = 1;
  fprintf(stderr, "filling sigmoid table pointer=%x\n", sigmoidTable.reference());
  for (int ai = 0; ai < num_entries; ai += incr) {
    float angle = (ai - num_entries / 2) / fscale;
    int index = (int)(angle*fscale);
    float s = sigmoid(angle);
    //fprintf(stderr, "ai=%d angle=%f entry_angle=%f sigmoid=%f\n", ai, angle, angle * fscale + num_entries/2, s);
    sigmoidTable.at<float>(0, 4*ai+0) = -angle;
    sigmoidTable.at<float>(0, 4*ai+1) = s;
    if (ai == num_entries-1) {
      sigmoidTable.at<float>(0, 4*ai+2) = 0;
    } else if (ai > 0) {
      float angle_prev = (ai - 1 - num_entries/2) / fscale;
      float s_prev = sigmoidTable.at<float>(0,4*(ai-1)+1);
      float dangle = angle - angle_prev;
      float ds = s - s_prev;
      float slope = ds / dangle;
      //fprintf(stderr, "angle=%f angle_prev=%f s=%f s_prev=%f ds=%f dangle=%f slope=%f\n", angle, angle_prev, s, s_prev, ds, dangle, slope);
      sigmoidTable.at<float>(0, 4*ai+2) = slope;
    }
    sigmoidTable.at<float>(0, 4*ai+3) = 0;
  }
  fprintf(stderr, "updating sigmoid table pointer=%x\n", sigmoidTable.reference());
  sigmoiddevice->updateSigmoidTable(sigmoidTable.reference(), 0, num_entries);
  sem_wait(&mul_sem);
  fprintf(stderr, "sigmoid table updated\n");
}

template<typename T>
void dumpMat(const char *prefix, const char *fmt, const cv::Mat &mat)
{
  fprintf(stderr, "%s: rows=%d cols=%d mat=%p\n", prefix, mat.rows, mat.cols, &mat);
  for (int i = 0; i < mat.rows; i++) {
    fprintf(stderr, "%s: %03d:", prefix, i);
    for (int j = 0; j < mat.cols; j++) {
      fprintf(stderr, " ");
      fprintf(stderr, fmt, mat.at<T>(i, j));
    }
    fprintf(stderr, "\n");
  }
}
template void dumpMat<float>(const char *prefix, const char *fmt, const cv::Mat &mat);
