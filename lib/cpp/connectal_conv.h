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
    //const 
    bool *propagate_down;
    ParamType(): weight(NULL), bias(NULL), bottom(NULL), top(NULL),
        bias_multiplier_(NULL), bottom_diff(NULL), top_diff(NULL),
        weight_diff(NULL), bias_diff(NULL),
        top_size(0), bottom_size(0), weight_diff_count(0), bias_diff_count(0),
        num_(0), num_output_(0), group_(0), height_out_(0), width_out_(0),
        kernel_h_(0), kernel_w_(0), conv_in_height_(0), conv_in_width_(0),
        conv_in_channels_(0), conv_out_channels_(0), conv_out_spatial_dim_(0),
        weight_offset_(0), output_offset_(0), pad_h_(0), pad_w_(0),
        stride_h_(0), stride_w_(0), propagate_down(NULL) { }
    virtual void forward_process(void);
    virtual void backward_process(void);
};
typedef void *(*ALLOCFN)(int size);
static void *handle;
static ALLOCFN creatme;
void *init_connectal_conv_library(int size)
{
printf("[%s:%d] load shared library for connectal_conv\n", __FUNCTION__, __LINE__);
    if (!handle) {
        char *libname = getenv("CONNECTAL_CONV_LIBRARY");
        printf("%s: libname is %s\n", __FUNCTION__, libname);
        handle = dlopen(libname, RTLD_NOW);
        if (!handle) {
           printf("The error is %s", dlerror());
        }
        creatme = (ALLOCFN)dlsym(handle,"alloc_connectal_conv");
        if (!creatme) {
           printf("The error is %s", dlerror());
        }
    }
    return creatme(size);
}
#endif // __CONNECTAL_CONV_H__
