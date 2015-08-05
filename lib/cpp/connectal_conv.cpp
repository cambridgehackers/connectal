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
#include "connectal_conv.h"

//#define PERFSTAT
#define NUM_EVENTS 4
static void perfpinit(void)
{
#ifdef PERFSTAT
  static int once = 1;
  int event[NUM_EVENTS] = {PAPI_TOT_INS, PAPI_TOT_CYC, PAPI_BR_MSP, PAPI_L1_DCM };
  if (once) {
    once = 0;
    /* Start counting events */
    if (PAPI_start_counters(event, NUM_EVENTS) != PAPI_OK) {
        fprintf(stderr, "PAPI_start_counters - FAILED\n");
        exit(1);
    }
  }
#endif
}
static void perfread(long long *perfvalues)
{
#ifdef PERFSTAT
    if (PAPI_read_counters(perfvalues, NUM_EVENTS) != PAPI_OK) {
        fprintf(stderr, "PAPI_read_counters - FAILED\n");
        exit(1);
    }
#endif
}
#ifdef PERFSTAT
static void perfperf(long long *perfvalues, const char *name)
{
    printf("%s: Total instructions: %6lld;", name, perfvalues[0]);
    printf("Total cycles: %6lld;", perfvalues[1]);
    printf("Instr per cycle: %2.3f;", (double)perfvalues[0] / (double) perfvalues[1]);
    printf("Branches mispredicted: %6lld;", perfvalues[2]);
    printf("L1 Cache misses: %6lld\n", perfvalues[3]);
}
#endif

#define MIN(A,B) (((A) < (B)) ? (A) : (B))
#define MAX(A,B) (((A) > (B)) ? (A) : (B))
template <typename Dtype>
void ParamType<Dtype>::forward_process(void)
{
  perfpinit();
  long long perfvalues1[NUM_EVENTS];
  int bottom_hw = conv_in_height_ * conv_in_width_;
  int kernel_hw = kernel_h_ * kernel_w_;
  int out_group_size = conv_out_channels_ / group_;
  int in_group_size = conv_in_channels_ / group_;
  // For each input, ...
  for (int i = 0; i < bottom_size; ++i) {
    const Dtype* bottom_data = bottom[i];
    Dtype* top_data = top[i];
      // Convolution
    // For each image in input batch
    for (int nunused = 0; nunused < num_; ++nunused) {
      const Dtype *biasptr = bias;
      // if group_ > 1, restrict connectivity to a subset of inputs
      for (int g = 0; g < group_; ++g) {
        Dtype *outputp = top_data;
        const Dtype *wp_base = &weight[g * weight_offset_];
        // for each 'out_group', calculate convolution over input data
        for (int ounused = 0; ounused < out_group_size; ounused++) {
          const Dtype *bpg = bottom_data;
          const Dtype bias_val = bias ? *biasptr++ : 0;
          // Scan over source 2D input data
          for (int y = 0; y < height_out_; y++) {
            int p_limit = MIN(kernel_h_ - pad_h_, conv_in_height_ - y * stride_h_);
            const Dtype *bpy = bpg;
            for (int x = 0; x < width_out_; x++) {
              int q_limit = MIN(kernel_w_ - pad_w_, conv_in_width_ - x * stride_w_);
              Dtype temp = bias_val;
              const Dtype *bpx = bpy, *wpx = wp_base;
              // for each 'in_group', add contribution into convolution
              for (int k = 0; k < in_group_size; k++) {
                const Dtype *bpk = bpx, *wpk = wpx;
                // Calculate single 2D filter convolution
                for (int p = 0; p < p_limit; p++) {
                  const Dtype *bp = bpk, *wp = wpk;
                  for (int q = 0; q < q_limit; q++)
                    temp += *bp++ * *wp++;
                  bpk += conv_in_width_;
                  wpk += kernel_w_;
                }
                bpx += bottom_hw;
                wpx += kernel_hw;
              }
              // Write convolution result into output (image, channel, y, x)
              *outputp++ = temp;
              bpy += stride_w_;
            }
            bpg += conv_in_width_ * stride_h_;
          }
          wp_base += in_group_size * kernel_hw;
          perfread(perfvalues1);
        }
        bottom_data += in_group_size * bottom_hw;
        top_data += output_offset_;
      }
    }
  }
#ifdef PERFSTAT
  static int jcacount = 0;
  if (jcacount++ > 300 && jcacount < 310)
    perfperf(perfvalues1, "forward");
#endif
}
template <typename Dtype>
void ParamType<Dtype>::backward_process(void)
{
  perfpinit();
  long long perfvalues2[NUM_EVENTS];
  int bottom_hw = conv_in_height_ * conv_in_width_;
  int kernel_hw = kernel_h_ * kernel_w_;
  int out_group_size = conv_out_channels_ / group_;
  int in_group_size = conv_in_channels_ / group_;
  int usable_height = conv_in_height_ + 2 * pad_h_ - kernel_h_;
  int usable_width = conv_in_width_ + 2 * pad_w_ - kernel_w_;
  if (weight_diff)
    memset(weight_diff, 0, weight_diff_count);
  if (bias_diff)
    memset(bias_diff, 0, bias_diff_count);
  // For all images
  for (int i = 0; i < top_size; ++i) {
    for (int n = 0; n < num_; ++n) {
      int boff = n * conv_in_channels_ * bottom_hw;
      const Dtype *top_diff_bp = top_diff[i]
          + n * conv_out_channels_ * conv_out_spatial_dim_;
      const Dtype *bottom_bp = bottom[i] + boff;
      Dtype *bottom_diff_bp = NULL;
      // Bias gradient, if necessary.
      if (bias_diff) {
        const Dtype *tptr = top_diff_bp;
        for (int j = 0; j < num_output_; j++)
          for (int i = 0; i < conv_out_spatial_dim_; i++)
            bias_diff[j] += *tptr++ * bias_multiplier_[i];
      }
      if (propagate_down[i]) {
        bottom_diff_bp =  bottom_diff[i] + boff;
      }
      if (weight_diff || bottom_diff_bp) {
        for (int g = 0; g < group_; ++g) {
          for (int cchan = 0; cchan < in_group_size; ++cchan) {
            int gchan = (g * in_group_size + cchan) * bottom_hw;
            // zero out gradient wrt bottom data, we're about to fill it
            if (bottom_diff_bp)
              memset(&bottom_diff_bp[gchan], 0, bottom_hw * sizeof(Dtype));
            for (int outindex = 0; outindex < out_group_size; ++outindex) {
              int wchan = g * weight_offset_ + (cchan + outindex * in_group_size) * kernel_hw;
              const Dtype *topdptr = &top_diff_bp[g * output_offset_ + outindex * conv_out_spatial_dim_];
              for (int y = 0; y <= usable_height; y += stride_h_){
                for (int x = 0; x <= usable_width; x += stride_w_) {
                  Dtype chain_grad = topdptr[(y * (usable_width + stride_w_) / stride_h_ + x) / stride_w_ ];
                  int pad_y = pad_h_ - y;
                  int pad_x = pad_w_ - x;
                  int p_start = MAX(0, pad_y);
                  int p_limit = MIN(kernel_h_, conv_in_height_ + pad_y);
                  int q_start = MAX(0, pad_x);
                  int q_limit = MIN(kernel_w_, conv_in_width_ + pad_x);
                  int bbase = gchan - pad_y * conv_in_width_ - pad_x;
                  if (chain_grad != 0.0)
                  for (int p = p_start; p < p_limit; ++p) {
                    for (int q = q_start; q < q_limit; ++q) {
                      int belement = bbase + p * conv_in_width_ + q;
                      int welement = wchan + p * kernel_w_ + q;
                      // gradient w.r.t. weight. Note that we will accumulate diffs.
                      if (weight_diff)
                        weight_diff[welement] += bottom_bp[belement] * chain_grad;
                      // gradient w.r.t. bottom data, if necessary.
                      if (bottom_diff_bp)
                        bottom_diff_bp[belement] += weight[welement] * chain_grad;
                    }
                  }
                }
              }
              perfread(perfvalues2);
            }
#ifdef PERFSTAT
            static int jcacount = 0;
            if (jcacount++ > 300) {
                perfperf(perfvalues2, "second");
                exit(-1);
            }
#endif
          }
        }
      }
    }
  }
}

extern "C" void *alloc_connectal_conv(int size)
{
    if (size == sizeof(float)) {
        ParamType<float> *param = new ParamType<float>;
printf("[%s:%d] float param %p\n", __FUNCTION__, __LINE__, param);
        return param;
    }
    else {
        ParamType<double> *param = new ParamType<double>;
printf("[%s:%d] double param %p\n", __FUNCTION__, __LINE__, param);
        return param;
    }
}
