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

#ifndef __CONNECTAL_CONV_H__
#define __CONNECTAL_CONV_H__
#include <stdlib.h>
#include <dlfcn.h>

template <typename Dtype>
class ParamType {
public:
    const Dtype* weight;
    const Dtype* bias;
    const Dtype **bottom;
    Dtype **top;
    const Dtype *bias_multiplier_;
    Dtype **bottom_diff;
    const Dtype **top_diff;
    Dtype *weight_diff;
    Dtype *bias_diff;
    int top_size;
    int bottom_size;
    int weight_diff_count;
    int bias_diff_count;
    int num_;
    int num_output_;
    int group_;
    int height_out_, width_out_;
    int kernel_h_, kernel_w_;
    int conv_in_height_, conv_in_width_;
    int conv_in_channels_, conv_out_channels_;
    int conv_out_spatial_dim_;
    int weight_offset_;
    int output_offset_;
    int pad_h_, pad_w_;
    int stride_h_, stride_w_;
    const bool *propagate_down;
    // legacy support
    Dtype* col_buffer_;
    int is_1x1_;
    int col_offset_;
    int bottom_mult, top_mult;
    int param_propagate_down_[2];
    ParamType(): weight(NULL), bias(NULL), bottom(NULL), top(NULL),
        bias_multiplier_(NULL), bottom_diff(NULL), top_diff(NULL),
        weight_diff(NULL), bias_diff(NULL),
        top_size(0), bottom_size(0), weight_diff_count(0), bias_diff_count(0),
        num_(0), num_output_(0), group_(0), height_out_(0), width_out_(0),
        kernel_h_(0), kernel_w_(0), conv_in_height_(0), conv_in_width_(0),
        conv_in_channels_(0), conv_out_channels_(0), conv_out_spatial_dim_(0),
        weight_offset_(0), output_offset_(0), pad_h_(0), pad_w_(0),
        stride_h_(0), stride_w_(0), propagate_down(NULL)
        // legacy
        , col_buffer_(NULL), is_1x1_(0), col_offset_(0), bottom_mult(0), top_mult(0)
        //, param_propagate_down_[0](0), param_propagate_down_[1](0)
        { }
    virtual void forward_process(void);
    virtual void backward_process(void);
    void im2col_cpu(const Dtype* data_im);
};
typedef void *(*ALLOCFN)(int size);
void *init_connectal_conv_library(int size)
{
    static void *handle;
    static ALLOCFN creatme;
    if (!handle) {
        char *libname = getenv("CONNECTAL_CONV_LIBRARY");
        if (!libname) {
            printf("%s: The environment variable CONNECTAL_CONV_LIBRARY must contain the filename of the shared library for connectal conv support\n", __FUNCTION__);
            exit(-1);
        }
        printf("%s: libname is %s\n", __FUNCTION__, libname);
        handle = dlopen(libname, RTLD_NOW);
        if (handle)
            creatme = (ALLOCFN)dlsym(handle,"alloc_connectal_conv");
        else {
           printf("%s: dlopen(%s) failed, %s", __FUNCTION__, libname, dlerror());
           exit(-1);
        }
        if (!creatme) {
           printf("%s: dlsym('alloc_connectal_conv') failed, %s", __FUNCTION__, dlerror());
           exit(-1);
        }
    }
    return creatme(size);
}
#endif // __CONNECTAL_CONV_H__
