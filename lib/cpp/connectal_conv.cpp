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
#include "ConvIndication.h"
#include "ConvRequest.h"
#include "dmaManager.h"
#include "connectal_conv.h"

#define COUNTER_INTERVAL 100000
static ConvRequestProxy *convRequest;
static DmaManager *dma;
static sem_t outputp_sem;

class ConvIndication : public ConvIndicationWrapper
{
    ParamStruct *param;
public:
    void outputp(uint32_t addr, float v) {
        if (param->elementSize_ == sizeof(float)) {
            printf("heard an conv: [%x] = %f/%x; ", addr, v, *(uint32_t *)&v);
            printf(" current F[%p]=%f\n", param->basePtr + addr, *(float *)(param->basePtr + addr));
            *(float *)(param->basePtr + addr) = v;
        }
        else {
            printf("heard an conv: [%x] = %f/%x; ", addr, v, *(uint32_t *)&v);
            printf(" current D[%p]=%f", param->basePtr + addr, *(double *)(param->basePtr + addr));
            printf("/%lx\n", *(uint64_t *)(param->basePtr + addr));
            *(double *)(param->basePtr + addr) = v;
        }
	//convRequest->say2(v, 2*v);
        sem_post(&outputp_sem);
    }
    ConvIndication(unsigned int id, ParamStruct *p) : ConvIndicationWrapper(id), param(p) {}
};
static ConvIndication *indication;

static void forward_kernel_hardware(ParamStruct *param, uint32_t p_limit,
     uint32_t q_limit, float temp, uint32_t bpx, uint32_t wpx, uint32_t outputp)
{
    static int once = 1;
    if (once) {
        once = 0;
printf("[%s:%d] create proxy\n", __FUNCTION__, __LINE__);
        indication = new ConvIndication(IfcNames_ConvIndicationH2S, param);
        convRequest = new ConvRequestProxy(IfcNames_ConvRequestS2H);
        dma = platformInit();
    }
    if (param->objectId_ == -1) {
        param->objectId_ = dma->reference(param->portalFd_);
        ConnectalParamType hparam;
printf("[%s:%d] element %d\n", __FUNCTION__, __LINE__, param->elementSize_);
        hparam.bottom_hw = param->conv_in_height_ * param->conv_in_width_ * param->elementSize_;
        hparam.kernel_hw = param->kernel_h_ * param->kernel_w_ * param->elementSize_;
        hparam.in_group_size = param->conv_in_channels_ / param->group_;
        hparam.baseSize = param->elementSize_;
        hparam.conv_in_width = param->conv_in_width_ * param->elementSize_;
        hparam.kernel_w = param->kernel_w_ * param->elementSize_;
        hparam.objectId = param->objectId_;
        convRequest->init(hparam);
    }
#define MIN_XFER 8
    int len = q_limit* param->elementSize_;
    int alen = ((len + MIN_XFER - 1) / MIN_XFER) * MIN_XFER;
    convRequest->forward_kernel(p_limit, alen, alen != len, temp, bpx, wpx, outputp);
//printf("[%s:%d] before wait q_limit %d\n", __FUNCTION__, __LINE__, q_limit);
    sem_wait(&outputp_sem);
}

#define MIN(A,B) (((int)(A) < (int)(B)) ? (A) : (B))
#define MAX(A,B) (((int)(A) > (int)(B)) ? (A) : (B))
template <typename Dtype>
void forward_kernel(const ParamType<Dtype> *param, int p_limit, int q_limit, Dtype temp, CPtr bpx, CPtr wpx, CPtr outputp, int trace)
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
        float foo = *CACCESS(bp) * *CACCESS(wp);
        temp += foo;
        //if (trace) {
//printf("[%s:%d] b[%lx] %x/%f w[%lx] %x/%f q_limit %d foo %x\n", __FUNCTION__, __LINE__, bp, *(uint32_t *)CACCESS(bp), *CACCESS(bp), wp, *(uint32_t *)CACCESS(wp), *CACCESS(wp), q_limit, *(uint32_t *)&foo);
        //}
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
//if (trace)
//printf("[%s:%d] result [%lx;%p]=%f\n", __FUNCTION__, __LINE__, outputp, param->basePtr + outputp, (double)temp);
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
  static int counter = 0;
  // For each input, ...
  CPtr bottom_data = bottom[0];
  CPtr top_data = top[0];
  for (int imageind_unused = 0; imageind_unused < bottom_size; ++imageind_unused) {
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
              int run_hardware = (counter-- <= 0);
              int p_limit = MIN(param->kernel_h_ - param->pad_h_, conv_in_height_ - y * stride_h_);
              int q_limit = MIN(param->kernel_w_ - param->pad_w_, conv_in_width_ - x * stride_w_);
              forward_kernel<Dtype>(this, p_limit, q_limit, bias_val, bpx, wp_item, outputp, run_hardware);
              if (run_hardware) {
//printf("[%s:%d] result [%lx;%p]=%f\n", __FUNCTION__, __LINE__, outputp, param->basePtr + outputp, (double)*CACCESS(outputp));
                  forward_kernel_hardware(this, p_limit, q_limit, bias_val, bpx, wp_item, outputp);
//printf("[%s:%d] result [%lx;%p]=%f\n", __FUNCTION__, __LINE__, outputp, param->basePtr + outputp, (double)*CACCESS(outputp));
                  counter = COUNTER_INTERVAL;
              }
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
  for (int j = 0; j < param->num_output_ * sizeof(Dtype); j += sizeof(Dtype)) {
    Dtype temp = 0;
    for (int i = 0; i < output_hw; i += sizeof(Dtype)) {
      temp += *CACCESS(tptr) * *CACCESS(param->bias_multiplier_ + i);
      tptr += sizeof(Dtype);
    }
    *CACCESS(param->bias_diff + j) += temp;
  }
}
template <typename Dtype>
void backward_kernel(const ParamType<Dtype> *param, int pad_x, int pad_y, int gchan, int wchan, Dtype chain_grad, CPtr bottom_bp, CPtr bottom_diff_bp)
{
  int p_start = MAX(0, pad_y);
  int p_limit = MIN(param->kernel_h_ * sizeof(Dtype), param->conv_in_height_ * sizeof(Dtype) + pad_y);
  int q_start = MAX(0, pad_x);
  int q_limit = MIN(param->kernel_w_ * sizeof(Dtype), param->conv_in_width_ * sizeof(Dtype) + pad_x);
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
  memset(CACCESS(zero_region), 0, zero_region_len);
  // For all images
  CPtr toff = top_diff[0];
  CPtr bottom_ptr = bottom[0];
  CPtr bottom_diff_ptr = bottom_diff[0];
  for (int imageind_unused = 0; imageind_unused < top_size; ++imageind_unused) {
    int gbase = 0;
    for (int n = 0; n < num_; ++n) {
      // Bias gradient, if necessary.
      if (bias_diff)
        backward_bias<Dtype>(this, toff);
      int wbase = 0;
      for (int g = 0; g < group_; ++g) {
        int wchan = wbase;
        for (int outindex = 0; outindex < out_group_size; ++outindex) {
          int gchan = gbase;
          for (int cchan = 0; cchan < in_group_size; ++cchan) {
            for (int y = 0; y <= usable_height; y += stride_h_){
              for (int x = 0; x <= usable_width; x += stride_w_) {
                Dtype chain_grad = *CACCESS(toff + ((y * (usable_width + stride_w_) / stride_h_ + x) / stride_w_) * sizeof(Dtype));
                int pad_x = (pad_w_ - x) * sizeof(Dtype);
                int pad_y = (pad_h_ - y) * sizeof(Dtype);
                if (chain_grad != 0.0)
                    backward_kernel<Dtype>(this, pad_x, pad_y,
                     gchan - pad_y * conv_in_width_ - pad_x, wchan, chain_grad, bottom_ptr, bottom_diff_ptr);
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
    bottom_ptr += num_ * in_group_size * bottom_hw;
    bottom_diff_ptr += num_ * in_group_size * bottom_hw;
  }
}

extern "C" void *alloc_connectal_conv(int size)
{
    if (size == sizeof(float))
        return new ParamType<float>(size);
    else
        return new ParamType<double>(size);
}
extern "C" void *alloc_portalMem(size_t size, int cached, int *fdptr)
{
    int fd = portalAlloc(size, cached);
    if (fdptr)
        *fdptr = fd;
    return portalMmap(fd, size);
}
//int portalCacheFlush(int fd, void *__p, long size, int flush)
