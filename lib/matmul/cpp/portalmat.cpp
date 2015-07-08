
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
#include "dmaManager.h"
#include "portalmat.h"

PortalMatAllocator *matAllocator = 0;
sem_t mul_sem;

void PortalMatAllocator::allocate(int dims, const int* sizes, int type, int*& refcount,
				  uchar*& datastart, uchar*& data, size_t* step)
{
  size_t arraysize = step[0]*sizes[0];
  size_t totalsize = cv::alignSize(arraysize, 4096);
  int arraynum = numarrays++;
  int fd = portalAlloc(totalsize, 0);
  struct arrayInfo *info = &arrayInfo[arraynum];
  info->fd = fd;
  info->refcount = 1;
  info->totalsize = totalsize;
  info->data = (uchar*)portalMmap(fd, totalsize);
  info->ref = 0;

  data = datastart = (uchar*)info->data;
  refcount = (int*)info;
  fprintf(stderr, "PortalMatAllocator::allocate   arraynum=%d arraysize=%ld totalsize=%ld datastart=%p refcount=%p end of data=%p\n",
	  arraynum, (long)arraysize, (long)totalsize, datastart, refcount, datastart+totalsize);
}

void PortalMatAllocator::deallocate(int* refcount, uchar* datastart, uchar* data)
{
  struct arrayInfo *info = (struct arrayInfo *)refcount;
  size_t totalsize = info->totalsize;
  fprintf(stderr, "PortalMatAllocator::deallocate datastart=%p size=%ld ref=%d\n",
	  datastart, (long)totalsize, info->ref);
  munmap(datastart, totalsize);
  dma->dereference(info->ref);
  close(info->fd);
  memset(info, 0, sizeof(struct arrayInfo));
}

int PortalMatAllocator::reference(int* refcount, uchar* datastart, uchar* data)
{
  struct arrayInfo *info = (struct arrayInfo *)refcount;
  int ref = info->ref;
  if (!ref) {
    ref = dma->reference(info->fd);
    info->ref = ref;
  }
  //fprintf(stderr, "PortalMatAllocator::reference returning %d\n", ref);
  return ref;
}

void PortalMatAllocator::cacheFlushInvalidate(int* refcount, uchar* datastart, uchar* data)
{
  struct arrayInfo *info = (struct arrayInfo *)refcount;
  portalCacheFlush(info->fd, datastart, info->totalsize, 1);
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
    return *this;
}

PortalMat& PortalMat::operator = (const cv::Mat& o)
{
    *(cv::Mat*)this = o;
    fprintf(stderr, "PortalMat::operator=(Mat&) this=%p datastart=%p\n", this, datastart);
    return *this;
}

int PortalMat::reference()
{
    int ref = 0;
    //fprintf(stderr, "PortalMat::reference this=%p datastart=%p\n", this, datastart);
    ref = matAllocator->reference(refcount, datastart, data);
    return ref;
}

void PortalMat::cacheFlushInvalidate()
{
    matAllocator->cacheFlushInvalidate(refcount, datastart, data);
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

bool PortalMat::compare(Mat &refMat, const char *file, int line, float epsilon, Mat *pm, bool verbose)
{
    if (0)
	fprintf(stderr, "PortalMat.compare rows=%d cols=%d refMat.rows=%d refMat.cols=%d\n",
		rows, cols, refMat.rows, refMat.cols);

    if (rows != refMat.rows || cols != refMat.cols) {
	fprintf(stderr, "PortalMat.compare dimension mismatch rows=%d cols=%d refMat.rows=%d refMat.cols=%d\n",
		rows, cols, refMat.rows, refMat.cols);
	return false;
    }
    bool rv = true;
    bool first = true;
    for (int i = 0; i < rows; i++) {
	for (int j = 0; j < cols; j++) {
	    float v = at<float>(i, j);
	    float refVal = refMat.at<float>(i, j);
	    float relativeError = fabs((v - refVal) / refVal);
	    if (relativeError > epsilon) {
	      if (verbose || first) {
		if (file)
		  fprintf(stderr, "%s:%d: ", file, line);
		fprintf(stderr, "mismatch[%d,%d] expected %f got %f error=%f)", i, j, refVal, v, relativeError);
		if (pm) {
		  float pmv = pm->at<float>(i,j);
		  fprintf(stderr, " pm[%d,%d]=%f %08x", i, j, pmv, *(int*)&pmv);
		}
		fprintf(stderr, "\n");
	      }
	      rv = false;
	      first = false;
	    }
	}
    }
    
    if (!rv) {
      if (file)
	fprintf(stderr, "%s:%d: ", file, line);
      fprintf(stderr, "PortalMat::compare detected a mismatch\n");
    }
    return rv;
}


void PortalMat::naive_mul(cv::Mat &a, cv::Mat &b, FILE *f)
{

  fprintf(stderr, "a:(%d x %d) b:(%d x %d)", a.rows, a.cols, b.rows, b.cols);
  assert(a.cols == b.rows);
  create(a.rows, b.cols, CV_32F);
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      double c = 0.0;
#ifndef __FOO
      bool last = (i==(rows-1) && j==(cols-1));
      if(last) fprintf(f, "c = 0.0;\n");
      for(int l = 0; l < a.cols; l++) {
	double x = (double)a.at<float>(i,l);
	double y = (double)b.at<float>(l,j);
	double p = x*y;
	if(last){
	  fprintf(f, "assert(c==%f);\n", c);
	}
      	c = c + p;
	if(last){
	  fprintf(f, "p = %f*%f;\n", x, y);
	  fprintf(f, "assert(p==%f);\n", p);
	  fprintf(f, "c = c + p;\n");
	  fprintf(f, "disp([c, %f])\n", c);
	  fprintf(f, "assert(c==%f)\n", c);
	}
      }
      at<float>(i, j) = (float)c;
      if (last) fprintf(f, "rez = %f;\n", c);
#else
      int K = 2;
      int gatherSz = 8/K;
      float c_ij[gatherSz];
      for(int k = 0; k < gatherSz; k++)
	c_ij[k] = 0.0;
      for(int l = 0; l < a.cols; l+=gatherSz)
	for(int k = 0; k < gatherSz; k++)
	  c_ij[k] += a.at<float>(i,l+k) * b.at<float>(l+k,j);
      for(int k = 0; k < gatherSz; k++)
	c += c_ij[k];
      at<float>(i, j) = c;
#endif
    }
  }
}


#ifdef MATRIX_NT
void PortalMat::multf(PortalMat &a, PortalMat &b_transpose,  MmIndication *mmind)
{
    create(a.rows, b_transpose.rows, CV_32F);
    cacheFlushInvalidate();
    if (a.cols != b_transpose.cols) {
	fprintf(stderr, "Mismatched matrices: a.rows=%d a.cols=%d b.rows=%d b.cols=%d\n", a.rows, a.cols, b_transpose.rows, b_transpose.cols);
	return;
    }
    long aref = a.reference();
    long bref = b_transpose.reference();
    long cref = reference();
    if (0)
    fprintf(stderr, "mult: ref=%d rows=%d cols=%d a.ref=%d a.rows=%d a.cols=%d b.ref=%d b.rows=%d b.cols=%d\n",
	    cref, rows, cols,
	    aref, a.rows, a.cols,
	    bref, b_transpose.rows, b_transpose.cols);
    mmdevice->mmf(aref, a.rows, a.cols,
		  bref, b_transpose.rows, b_transpose.cols,
		  cref,
		  a.rows*a.cols, a.cols*J_VALUE,
		  b_transpose.rows*b_transpose.cols, b_transpose.cols*K_VALUE,
		  a.rows*b_transpose.rows, b_transpose.rows*J_VALUE);

    sem_wait(&mul_sem);
    if(mmind) {
      int macs = a.rows*a.cols*b_transpose.rows;
      if (0)
	fprintf(stderr, "macs %d cycles %f lap_timer %f macs/cycle: %f\n", macs, (float)mmind->ccnt, (float)portalTimerLap(0), ((float)macs)/((float)mmind->ccnt));
    }
}


#else
#ifdef MATRIX_TN
void PortalMat::multf(PortalMat &a_transpose, PortalMat &b,  MmIndication *mmind)
{
    create(a_transpose.cols, b.cols, CV_32F);
    cacheFlushInvalidate();

    if (a_transpose.rows != b.rows) {
	fprintf(stderr, "Mismatched matrices: a.rows=%d a.cols=%d b.rows=%d b.cols=%d\n", a_transpose.rows, a_transpose.cols, b.rows, b.cols);
	return;
    }
    long aref = a_transpose.reference();
    long bref = b.reference();
    long cref = reference();
    fprintf(stderr, "mult: ref=%ld rows=%d cols=%d a.ref=%ld a.rows=%d a.cols=%d b.ref=%ld b.rows=%d b.cols=%d\n",
	    cref, rows, cols,
	    aref, a_transpose.rows, a_transpose.cols,
	    bref, b.rows, b.cols);
    mmdevice->mmf(aref, a_transpose.rows, a_transpose.cols,
		  bref, b.rows, b.cols,
		  cref,
		  a_transpose.rows*a_transpose.cols, a_transpose.cols*J_VALUE,
		  a_transpose.rows*b.cols, b.cols*J_VALUE,
		  a_transpose.cols*b.cols, b.rows*b.cols);
    sem_wait(&mul_sem);
    if(mmind) {
      int macs = a_transpose.rows*a_transpose.cols*b.rows;
      if (0)
	fprintf(stderr, "macs %d cycles %f lap_timer %f macs/cycle: %f\n", macs, (float)mmind->ccnt, (float)portalTimerLap(0), ((float)macs)/((float)mmind->ccnt));
    }
}

#endif
#endif


template<typename T>
void dumpMatF(const char *prefix, const char *fmt, const cv::Mat &mat, FILE *ofile)
{
  fprintf(ofile, "%s: rows=%d cols=%d mat=%p\n", prefix, mat.rows, mat.cols, &mat);
  for (int i = 0; i < mat.rows; i++) {
    fprintf(ofile, "%s: %03d:", prefix, i);
    for (int j = 0; j < mat.cols; j++) {
      fprintf(ofile, " ");
      fprintf(ofile, fmt, mat.at<T>(i, j));
    }
    fprintf(ofile, "\n");
  }
}
template void dumpMatF<float>(const char *prefix, const char *fmt, const cv::Mat &mat, FILE *ofile);

template<typename T>
void dumpMatOctave(const char *name, const char *fmt, const cv::Mat &mat, FILE *ofile)
{
  fprintf(ofile, "%s=[", name);
  for (int i = 0; i < mat.rows; i++) {
    for (int j = 0; j < mat.cols; j++) {
      fprintf(ofile, " ");
      fprintf(ofile, fmt, mat.at<T>(i, j));
      if(j+1 < mat.cols)
	fprintf(ofile, ",");
    }
    if(i+1 < mat.rows)
      fprintf(ofile, ";");
  }
  fprintf(ofile,"];\n");
}
template void dumpMatOctave<float>(const char *name, const char *fmt, const cv::Mat &mat, FILE *ofile);

template<typename T>
void dumpMat(const char *prefix, const char *fmt, const cv::Mat &mat)
{
  dumpMatF<T>(prefix,fmt,mat,stderr);
}
template void dumpMat<float>(const char *prefix, const char *fmt, const cv::Mat &mat);
template void dumpMat<int>(const char *prefix, const char *fmt, const cv::Mat &mat);
template void dumpMat<unsigned char>(const char *prefix, const char *fmt, const cv::Mat &mat);

void dynamicRange(cv::Mat mat, int *pmin_exp, int *pmax_exp, float *pmin_val, float *pmax_val)
{
  int min_exp = 0;
  int max_exp = 0;
  float min_val = 0.0;
  float max_val = 0.0;
  
  for (int i = 0; i < mat.rows; i++) {
    for (int j = 0; j < mat.cols; j++) {
      float f = mat.at<float>(i,j);
      int exp = 0;
      //float mantissa = frexpf(f, &exp);
      min_val = std::min<float>(min_val, f);
      max_val = std::max<float>(max_val, f);
      min_exp = std::min<int>(min_exp, exp);
      max_exp = std::max<int>(max_exp, exp);
    }
  }
  if (pmin_exp)
    *pmin_exp = min_exp;
  if (pmax_exp)
    *pmax_exp = max_exp;
  if (pmin_val)
    *pmin_val = min_val;
  if (pmax_val)
    *pmax_val = max_val;
}
