
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


#include <stdio.h>
#include <sys/time.h>
#include <opencv2/gpu/gpu.hpp>


void cuda_test()
{

  struct timeval tv0;
  struct timeval tv1;
  struct timezone tz; 

  int A = 100;
  int B = 100;

  cv::Mat src1(A,B,CV_32F);
  cv::Mat src2(A,B,CV_32F);
  cv::Mat src3(A,B,CV_32F);
  cv::Mat dst(A,B,CV_32F);

  cv::gpu::GpuMat d_src1, d_src2, d_src3, d_dst;
  
  for(int a = 0; a < A; a++){
    for(int b = 0; b < B; b++){
      src1.at<float>(a,b) = a*b;
      src2.at<float>(a,b) = a*b;
      src3.at<float>(a,b) = 0;
      dst.at<float>(a,b)  = 0;
    }
  }

  cv::gemm(src1, src2, 1.0, src3, 1.0, dst);

  assert(!gettimeofday(&tv0, &tz));
  cv::gemm(src1, src2, 1.0, src3, 1.0, dst);
  assert(!gettimeofday(&tv1, &tz));

  fprintf(stderr, "cpu time: %d (usec)\n", tv1.tv_usec-tv0.tv_usec);

  d_src1.upload(src1);
  d_src2.upload(src2);
  d_src3.upload(src3);
  
  cv::gpu::gemm(d_src1, d_src2, 1.0, d_src3, 1.0, d_dst);
  
  assert(!gettimeofday(&tv0, &tz));
  cv::gpu::gemm(d_src1, d_src2, 1.0, d_src3, 1.0, d_dst);
  assert(!gettimeofday(&tv1, &tz));

  fprintf(stderr, "gpu time: %d (usec)\n", tv1.tv_usec-tv0.tv_usec);
}

long int cuda_mm(cv::Mat& src1, cv::Mat& src2, cv::Mat& dst)
{

  struct timeval tv0;
  struct timeval tv1;
  struct timezone tz; 

  cv::Mat src3 = cv::Mat::zeros(src1.rows,src2.cols,CV_32F);
  cv::gpu::GpuMat d_src1, d_src2, d_src3, d_dst;
  
  d_src1.upload(src1);
  d_src2.upload(src2);
  d_src3.upload(src3);
  d_dst.upload(dst);
  
  cv::gpu::gemm(d_src1, d_src2, 1.0, d_src3, 1.0, d_dst);
  
  assert(!gettimeofday(&tv0, &tz));
  cv::gpu::gemm(d_src1, d_src2, 1.0, d_src3, 1.0, d_dst);
  assert(!gettimeofday(&tv1, &tz));

  d_dst.download(dst);

  long int rv = tv1.tv_usec-tv0.tv_usec;
  fprintf(stderr, "gpu time: %d (usec)\n", rv);
  return rv;
}


