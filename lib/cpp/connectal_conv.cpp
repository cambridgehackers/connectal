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
#include "portal.h"
#include "connectal_conv.h"

#define MIN(A,B) (((int)(A) < (int)(B)) ? (A) : (B))
#define MAX(A,B) (((int)(A) > (int)(B)) ? (A) : (B))
template <typename Dtype>
void forward_kernel(const ParamType<Dtype> *param, int p_limit, int q_limit, Dtype temp, CPtr bpx, CPtr wpx, CPtr outputp)
{
  int bottom_hw = param->conv_in_height_ * param->conv_in_width_ * sizeof(Dtype);
  int kernel_hw = param->kernel_h_ * param->kernel_w_ * sizeof(Dtype);
  int in_group_size = param->conv_in_channels_ / param->group_;
  // for each 'in_group', add contribution into convolution
  for (int k = 0; k < in_group_size; k++) {
    CPtr bpk = bpx, wpk = wpx;
    // Calculate single 2D filter convolution
    for (int p = 0; p < p_limit; p++) {
      CPtr bp = bpk, wp = wpk;
      for (int q = 0; q < q_limit; q++) {
        temp += *CACCESS(bp) * *CACCESS(wp);
        bp += sizeof(Dtype);
        wp += sizeof(Dtype);
      }
      bpk += param->conv_in_width_ * sizeof(Dtype);
      wpk += param->kernel_w_ * sizeof(Dtype);
    }
    bpx += bottom_hw;
    wpx += kernel_hw;
  }
  // Write convolution result into output (image, channel, y, x)
  *CACCESS(outputp) = temp;
}
template <typename Dtype>
void ParamType<Dtype>::forward_process(void)
{
ParamType<Dtype> *param = this;
  int out_group_size = conv_out_channels_ / group_;
  int in_group_size = conv_in_channels_ / group_;
  int bottom_hw = in_group_size * conv_in_height_ * conv_in_width_ * sizeof(Dtype);
  int kernel_hw = in_group_size * kernel_h_ * kernel_w_ * sizeof(Dtype);
  int output_hw = out_group_size * height_out_ * width_out_ * sizeof(Dtype);
  // For each input, ...
  for (int imageind = 0; imageind < bottom_size; ++imageind) {
    CPtr bottom_data = bottom[imageind];
    CPtr top_data = top[imageind];
      // Convolution
    // For each image in input batch
    for (int nunused = 0; nunused < num_; ++nunused) {
      CPtr biasptr = bias;
      // if group_ > 1, restrict connectivity to a subset of inputs
      CPtr wp_base = weight;
      for (int g = 0; g < group_; ++g) {
        CPtr outputp = top_data;
        CPtr wp_item = wp_base;
        // for each 'out_group', calculate convolution over input data
        for (int ounused = 0; ounused < out_group_size; ounused++) {
          CPtr bpg = bottom_data;
          const Dtype bias_val = bias ? *CACCESS(biasptr) : 0;
          if (bias)
              biasptr += sizeof(Dtype);
          // Scan over source 2D input data
          for (int y = 0; y < height_out_; y++) {
            CPtr bpx = bpg;
            for (int x = 0; x < width_out_; x++) {
              int p_limit = MIN(param->kernel_h_ - param->pad_h_, conv_in_height_ - y * stride_h_);
              int q_limit = MIN(param->kernel_w_ - param->pad_w_, conv_in_width_ - x * stride_w_);
              forward_kernel<Dtype>(this, p_limit, q_limit, bias_val, bpx, wp_item, outputp);
              outputp += sizeof(Dtype);
              bpx += stride_w_ * sizeof(Dtype);
            }
            bpg += conv_in_width_ * stride_h_ * sizeof(Dtype);
          }
          wp_item += kernel_hw;
        }
        bottom_data += bottom_hw;
        top_data += output_hw;
        wp_base += weight_offset_ * sizeof(Dtype);
      }
    }
  }
}
template <typename Dtype>
void backward_bias(const ParamType<Dtype> *param, CPtr tptr)
{
  int output_hw = param->height_out_ * param->width_out_ * sizeof(Dtype);
  for (int j = 0; j < param->num_output_ * sizeof(Dtype); j += sizeof(Dtype))
    for (int i = 0; i < output_hw; i += sizeof(Dtype)) {
      *CACCESS(param->bias_diff + j) += *CACCESS(tptr) * *CACCESS(param->bias_multiplier_ + i);
      tptr += sizeof(Dtype);
    }
}
template <typename Dtype>
void backward_kernel(const ParamType<Dtype> *param, int p_start, int p_limit, int q_start, int q_limit, int gchan, int wchan, Dtype chain_grad, CPtr bottom_bp, CPtr bottom_diff_bp)
{
  for (int p = p_start; p < p_limit; p += sizeof(Dtype)) {
    for (int q = q_start; q < q_limit; q += sizeof(Dtype)) {
      int belement = gchan + p * param->conv_in_width_ + q;
      int welement = wchan + p * param->kernel_w_ + q;
      // gradient w.r.t. weight. Note that we will accumulate diffs.
      if (param->weight_diff)
        *CACCESS(param->weight_diff + welement) += *CACCESS(bottom_bp + belement) * chain_grad;
      // gradient w.r.t. bottom data, if necessary.
      if (bottom_diff_bp)
        *CACCESS(bottom_diff_bp + belement) += *CACCESS(param->weight + welement) * chain_grad;
    }
  }
}
template <typename Dtype>
void ParamType<Dtype>::backward_process(void)
{
ParamType<Dtype> *param = this;
  int out_group_size = conv_out_channels_ / group_;
  int in_group_size = conv_in_channels_ / group_;
  int bottom_hw = conv_in_height_ * conv_in_width_ * sizeof(Dtype);
  int kernel_hw = kernel_h_ * kernel_w_ * sizeof(Dtype);
  int output_hw = height_out_ * width_out_ * sizeof(Dtype);
  int usable_height = conv_in_height_ + 2 * pad_h_ - kernel_h_;
  int usable_width = conv_in_width_ + 2 * pad_w_ - kernel_w_;
  if (weight_diff)
    memset(CACCESS(weight_diff), 0, weight_diff_count);
  if (bias_diff)
    memset(CACCESS(bias_diff), 0, num_output_ * sizeof(Dtype));
  // zero out gradient wrt bottom data, we're about to fill it
  for (int imageind = 0; imageind < top_size; ++imageind)
    if (bottom_diff[imageind])
      memset(CACCESS(bottom_diff[imageind]), 0, num_ * conv_in_channels_ * bottom_hw);
  // For all images
  for (int imageind = 0; imageind < top_size; ++imageind) {
    CPtr top_diff_bp = top_diff[imageind];
    if (!weight_diff && !bottom_diff[imageind])
      continue;
    int gbase = 0;
    int toff = 0;
    for (int n = 0; n < num_; ++n) {
      // Bias gradient, if necessary.
      if (bias_diff)
        backward_bias<Dtype>(this, top_diff_bp + toff);
      int wbase = 0;
      for (int g = 0; g < group_; ++g) {
        int wchan = wbase;
        for (int outindex = 0; outindex < out_group_size; ++outindex) {
          int gchan = gbase;
          for (int cchan = 0; cchan < in_group_size; ++cchan) {
            for (int y = 0; y <= usable_height; y += stride_h_){
              for (int x = 0; x <= usable_width; x += stride_w_) {
                Dtype chain_grad = *CACCESS(top_diff_bp + toff + ((y * (usable_width + stride_w_) / stride_h_ + x) / stride_w_) * sizeof(Dtype));
                int pad_x = (pad_w_ - x) * sizeof(Dtype);
                int pad_y = (pad_h_ - y) * sizeof(Dtype);
                int p_start = MAX(0, pad_y);
                int p_limit = MIN(param->kernel_h_ * sizeof(Dtype), param->conv_in_height_ * sizeof(Dtype) + pad_y);
                int q_start = MAX(0, pad_x);
                int q_limit = MIN(param->kernel_w_ * sizeof(Dtype), param->conv_in_width_ * sizeof(Dtype) + pad_x);
                if (chain_grad != 0.0)
                    backward_kernel<Dtype>(this, p_start, p_limit, q_start, q_limit,
                     gchan - pad_y * conv_in_width_ - pad_x, wchan, chain_grad, bottom[imageind], bottom_diff[imageind]);
              }
            }
            wchan += kernel_hw;
            gchan += bottom_hw;
          }
          toff += output_hw;
        }
        gbase += in_group_size * bottom_hw;
        wbase += weight_offset_ * sizeof(Dtype);
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
extern "C" void *alloc_portalMem(size_t size, int cached, int *fdptr)
{
    int fd = portalAlloc(size, cached);
    if (fdptr)
        *fdptr = fd;
    return portalMmap(fd, size);
}
//int portalCacheFlush(int fd, void *__p, long size, int flush)
