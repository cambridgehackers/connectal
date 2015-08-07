// Copyright (c) 2015 The Connectal Project

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
#include <string.h>
#include <cblas.h>
#include "connectal_conv.h"

template <typename Dtype>
void ParamType<Dtype>::im2col_cpu(const Dtype* data_im) {
  int height_col = (conv_in_height_ + 2 * pad_h_ - kernel_h_) / stride_h_ + 1;
  int width_col = (conv_in_width_ + 2 * pad_w_ - kernel_w_) / stride_w_ + 1;
  int channels_col = conv_in_channels_ * kernel_h_ * kernel_w_;
  for (int c = 0; c < channels_col; ++c) {
    int w_offset = c % kernel_w_;
    int h_offset = (c / kernel_w_) % kernel_h_;
    int c_im = c / kernel_h_ / kernel_w_;
    for (int h = 0; h < height_col; ++h) {
      for (int w = 0; w < width_col; ++w) {
        int h_pad = h * stride_h_ - pad_h_ + h_offset;
        int w_pad = w * stride_w_ - pad_w_ + w_offset;
        if (h_pad >= 0 && h_pad < conv_in_height_ && w_pad >= 0 && w_pad < conv_in_width_)
          col_buffer_[(c * height_col + h) * width_col + w] =
            data_im[(c_im * conv_in_height_ + h_pad) * conv_in_width_ + w_pad];
        else
          col_buffer_[(c * height_col + h) * width_col + w] = 0;
      }
    }
  }
}

template <typename Dtype> void caffe_cpu_gemm(const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const int M, const int N, const int K, const Dtype* A, const Dtype* B, const Dtype beta, Dtype* C); 
template<> void caffe_cpu_gemm<float>(const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const int M, const int N, const int K, const float* A, const float* B, const float beta, float* C) {
  cblas_sgemm(CblasRowMajor, TransA, TransB, M, N, K, 1., A, (TransA == CblasNoTrans) ? K : M, B, (TransB == CblasNoTrans) ? N : K, beta, C, N);
}

template<> void caffe_cpu_gemm<double>(const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB, const int M, const int N, const int K, const double* A, const double* B, const double beta, double* C) {
  cblas_dgemm(CblasRowMajor, TransA, TransB, M, N, K, 1., A, (TransA == CblasNoTrans) ? K : M, B, (TransB == CblasNoTrans) ? N : K, beta, C, N);
}

template <typename Dtype>
void ParamType<Dtype>::forward_process(void)
{
  // For each input, ...
  for (int i = 0; i < bottom_size; ++i) {
    const Dtype* bottom_data = bottom[i];
    Dtype* top_data = top[i];
      // Convolution
    // For each image in input batch
    for (int n = 0; n < num_; ++n) {
      int kernel_dim_ = conv_in_channels_ * kernel_h_ * kernel_w_;
      const Dtype* col_buff = bottom_data + bottom_mult * n;
      if (!is_1x1_) {
        im2col_cpu(col_buff);
        col_buff = col_buffer_;
      }
      for (int g = 0; g < group_; ++g) {
        caffe_cpu_gemm<Dtype>(CblasNoTrans, CblasNoTrans, conv_out_channels_/group_, conv_out_spatial_dim_, kernel_dim_ / group_,
            weight + weight_offset_ * g, col_buff + col_offset_ * g,
            (Dtype)0., top_data + top_mult * n + output_offset_ * g);
      }
      // Bias
      if (bias) {
        caffe_cpu_gemm<Dtype>(CblasNoTrans, CblasNoTrans, num_output_, height_out_ * width_out_, 1,
            bias, bias_multiplier_,
            (Dtype)1., top_data + top_mult * n);
      }
    }
  }
}

template <typename Dtype> void caffe_cpu_gemv(const int M, const int N, const Dtype* A, const Dtype* x, Dtype* y);
template <> void caffe_cpu_gemv<float>(const int M, const int N, const float* A, const float* x, float* y) {
  cblas_sgemv(CblasRowMajor, CblasNoTrans, M, N, 1., A, N, x, 1, 1., y, 1);
}
template <> void caffe_cpu_gemv<double>(const int M, const int N, const double* A, const double* x, double* y) {
  cblas_dgemv(CblasRowMajor, CblasNoTrans, M, N, 1., A, N, x, 1, 1., y, 1);
}
template <typename Dtype>
void ParamType<Dtype>::backward_process(void)
{
  if (weight_diff)
    memset(weight_diff, 0, weight_diff_count);
  if (bias_diff)
    memset(bias_diff, 0, bias_diff_count);
  // For all images
  for (int i = 0; i < top_size; ++i) {
    int kernel_dim_ = conv_in_channels_ * kernel_h_ * kernel_w_;
    // Bias gradient, if necessary.
    if (bias && this->param_propagate_down_[1]) {
      for (int n = 0; n < num_; ++n) {
        caffe_cpu_gemv<Dtype>(num_output_, height_out_ * width_out_, top_diff[i] + top_mult * n, bias_multiplier_, bias_diff);
      }
    }
    if (this->param_propagate_down_[0] || propagate_down[i]) {
      for (int n = 0; n < num_; ++n) {
        // gradient w.r.t. weight. Note that we will accumulate diffs.
        if (this->param_propagate_down_[0]) {
          const Dtype* col_buff = bottom[i] + bottom_mult * n;
          if (!is_1x1_) {
            im2col_cpu(col_buff);
            col_buff = col_buffer_;
          }
          for (int g = 0; g < group_; ++g) {
            caffe_cpu_gemm<Dtype>(CblasNoTrans, CblasTrans, conv_out_channels_ / group_,
                kernel_dim_ / group_, conv_out_spatial_dim_,
                top_diff[i] + top_mult * n + output_offset_ * g, col_buff + col_offset_ * g,
                (Dtype)1., weight_diff + weight_offset_ * g);
          }
        }
        // gradient w.r.t. bottom data, if necessary.
        if (propagate_down[i]) {
          Dtype* col_buff = col_buffer_;
          if (is_1x1_)
            col_buff = bottom_diff[i] + bottom_mult * n;
          for (int g = 0; g < group_; ++g) {
            caffe_cpu_gemm<Dtype>(CblasTrans, CblasNoTrans, kernel_dim_ / group_,
                conv_out_spatial_dim_, conv_out_channels_ / group_,
                weight + weight_offset_ * g, top_diff[i] + top_mult * n + output_offset_ * g,
                (Dtype)0., col_buff + col_offset_ * g);
          }
          if (!is_1x1_) {
            Dtype *data_im = bottom_diff[i] + bottom_mult * n;
            memset(data_im, 0, sizeof(Dtype) * conv_in_height_ * conv_in_width_ * conv_in_channels_);
            int height_col = (conv_in_height_ + 2 * pad_h_ - kernel_h_) / stride_h_ + 1;
            int width_col = (conv_in_width_ + 2 * pad_w_ - kernel_w_) / stride_w_ + 1;
            int channels_col = conv_in_channels_ * kernel_h_ * kernel_w_;
            for (int c = 0; c < channels_col; ++c) {
              int w_offset = c % kernel_w_;
              int h_offset = (c / kernel_w_) % kernel_h_;
              int c_im = c / kernel_h_ / kernel_w_;
              for (int h = 0; h < height_col; ++h) {
                for (int w = 0; w < width_col; ++w) {
                  int h_pad = h * stride_h_ - pad_h_ + h_offset;
                  int w_pad = w * stride_w_ - pad_w_ + w_offset;
                  if (h_pad >= 0 && h_pad < conv_in_height_ && w_pad >= 0 && w_pad < conv_in_width_)
                    data_im[(c_im * conv_in_height_ + h_pad) * conv_in_width_ + w_pad] +=
                        col_buff[(c * height_col + h) * width_col + w];
                }
              }
            }
          }
        }
      }
    }
  }
}

extern "C" void *alloc_connectal_conv(int size)
{
    if (size == sizeof(float))
        return new ParamType<float>;
    else
        return new ParamType<double>;
}
