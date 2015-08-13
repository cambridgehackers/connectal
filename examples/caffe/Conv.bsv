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
import FloatingPoint::*;
import FIFO::*;
import Vector::*;
import StmtFSM::*;

typedef struct {
    Bit#(32) bottom_hw;
    Bit#(32) kernel_hw;
    Bit#(32) in_group_size;
    Bit#(32) baseSize;
    Bit#(32) conv_in_width;
    Bit#(32) kernel_w;
} ConnectalParamType  deriving (Eq,Bits);

interface ConvIndication;
    method Action outputp(Float v);
endinterface

interface ConvRequest;
    method Action init(ConnectalParamType param);
    method Action forward_kernel(Bit#(32) p_limit, Bit#(32) q_limit, Float temp, Bit#(32) bpx, Bit#(32) wpx, Bit#(32) outputp);
endinterface

interface Conv;
    interface ConvRequest request;
endinterface

module mkConv#(ConvIndication indication)(Conv);
    Reg#(ConnectalParamType) param <- mkReg(unpack(0));
    Reg#(Bit#(32)) p_limit <- mkReg(0);
    Reg#(Bit#(32)) q_limit <- mkReg(0);
    Reg#(Float)    temp <- mkReg(0);
    Reg#(Bit#(32)) bpx <- mkReg(0);
    Reg#(Bit#(32)) wpx <- mkReg(0);
    Reg#(Bit#(32)) outputp <- mkReg(0);
    Reg#(Bit#(32)) k <- mkReg(0);
    Reg#(Bit#(32)) p <- mkReg(0);
    Reg#(Bit#(32)) q <- mkReg(0);
    Reg#(Bit#(32)) bpk <- mkReg(0);
    Reg#(Bit#(32)) wpk <- mkReg(0);
    Reg#(Bit#(32)) bp <- mkReg(0);
    Reg#(Bit#(32)) wp <- mkReg(0);

    FSM fsm <- mkFSM(seq
        // for each 'in_group', add contribution into convolution
        for ( k <= 0; k < param.in_group_size; k <= k + 1) seq
            bpk <= bpx;
            wpk <= wpx;
            // Calculate single 2D filter convolution
            for ( p <= 0; p < p_limit; p <= p + 1) seq
                bp <= bpk;
                wp <= wpk;
                for ( q <= 0; q < q_limit; q <= q + 1) seq
         //         temp += *CACCESS(bp) * *CACCESS(wp);
                    bp <= bp + param.baseSize;
                    wp <= wp + param.baseSize;
                endseq
                bpk <= bpk + param.conv_in_width;
                wpk <= wpk + param.kernel_w;
            endseq
            bpx <= bpx + param.bottom_hw;
            wpx <= wpx + param.kernel_hw;
        endseq
        // Write convolution result into output (image, channel, y, x)
        //  *CACCESS(outputp) = temp;
        endseq);

   interface ConvRequest request;
       method Action init(ConnectalParamType aparam);
           param <= aparam;
       endmethod
       method Action forward_kernel(Bit#(32) ap_limit, Bit#(32) aq_limit, Float atemp, Bit#(32) abpx, Bit#(32) awpx, Bit#(32) aoutputp);
           p_limit <= ap_limit;
           q_limit <= aq_limit;
           temp <= atemp;
           bpx <= abpx;
           wpx <= awpx;
           outputp <= aoutputp;
           fsm.start();
       endmethod
   endinterface

//void backward_bias(const ParamType<Dtype> *param, CPtr tptr)
//{
//  int output_hw = param->height_out_ * param->width_out_ * sizeof(Dtype);
//  for (int j = 0; j < param->num_output_ * sizeof(Dtype); j += sizeof(Dtype)) {
//    Dtype temp = 0;
//    for (int i = 0; i < output_hw; i += sizeof(Dtype)) {
//      temp += *CACCESS(tptr) * *CACCESS(param->bias_multiplier_ + i);
//      tptr += sizeof(Dtype);
//    }
//    *CACCESS(param->bias_diff + j) += temp;
//  }
//}

//void backward_kernel(const ParamType<Dtype> *param, int pad_x, int pad_y, int gchan, int wchan, Dtype chain_grad, CPtr bottom_bp, CPtr bottom_diff_bp)
//{
//  int p_start = MAX(0, pad_y);
//  int p_limit = MIN(param->kernel_h_ * sizeof(Dtype), param->conv_in_height_ * sizeof(Dtype) + pad_y);
//  int q_start = MAX(0, pad_x);
//  int q_limit = MIN(param->kernel_w_ * sizeof(Dtype), param->conv_in_width_ * sizeof(Dtype) + pad_x);
//  for (int p = p_start; p < p_limit; p += sizeof(Dtype)) {
//    for (int q = q_start; q < q_limit; q += sizeof(Dtype)) {
//      int belement = gchan + p * param->conv_in_width_ + q;
//      int welement = wchan + p * param->kernel_w_ + q;
//      // gradient w.r.t. weight. Note that we will accumulate diffs.
//      if (param->weight_diff)
//        *CACCESS(param->weight_diff + welement) += *CACCESS(bottom_bp + belement) * chain_grad;
//      // gradient w.r.t. bottom data, if necessary.
//      if (bottom_diff_bp)
//        *CACCESS(bottom_diff_bp + belement) += *CACCESS(param->weight + welement) * chain_grad;
//    }
//  }
//}
endmodule
