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
    void forward_process(void);
    void backward_process(void);
};
#include "connectal_conv.cpp"
#endif // __CONNECTAL_CONV_H__
