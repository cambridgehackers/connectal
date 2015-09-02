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
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import StmtFSM::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import HostInterface::*;
import FloatOps::*;
import Gearbox::*;
import GearboxGetPut::*;
import DefaultValue::*;
import Pipe::*;
import ClientServer::*;

typedef struct {
    Bit#(32) bottom_hw;
    Bit#(32) kernel_hw;
    Bit#(32) in_group_size;
    Bit#(32) baseSize;
    Bit#(32) conv_in_width;
    Bit#(32) kernel_w;
    Bit#(32) objectId;
} ConnectalParamType  deriving (Eq,Bits);

interface ConvIndication;
    method Action outputp(Bit#(32) addr, Float v);
endinterface

interface ConvRequest;
    method Action init(ConnectalParamType param);
    method Action forward_kernel(Bit#(32) ap_limit, Bit#(32) aq_limit, Bit#(1) askip, Float atemp, Bit#(32) abpx, Bit#(32) awpx, Bit#(32) aoutputp);
endinterface

interface Conv;
    interface ConvRequest request;
    interface Vector#(1,MemReadClient#(DataBusWidth)) readDma;
    interface Vector#(1,MemWriteClient#(DataBusWidth)) writeDma;
endinterface

typedef struct {
    Float a;
    Float b;
    Bool  last;
} DotType deriving (Bits, Eq);

interface DotProd;
    interface PipeIn#(DotType) sendPair;
    interface PipeOut#(void)   done;
    method Action init(Float atemp);
    method Float result();
endinterface

(* synthesize *)
module mkDotProd(DotProd);
    FIFOF#(DotType) dotFifo <- mkFIFOF;
    FIFOF#(Bool) lastFifo <- mkFIFOF1;
    FIFOF#(void) innerDone <- mkFIFOF;
    FloatAlu adder <- mkFloatAdder(defaultValue);
    FloatAlu mul <- mkFloatMultiplier(defaultValue);
    Reg#(Float)    temp <- mkReg(0);

    rule dotrule;
        let v <- toGet(dotFifo).get;
        mul.request.put(tuple2(v.a, v.b));
        toPut(lastFifo).put(v.last);
    endrule

    rule addrule;
        match {.resp,.*} <- mul.response.get;
        adder.request.put(tuple2(resp,temp));
    endrule

    rule storerule;
        let v <- toGet(lastFifo).get;
        match {.resp,.*} <- adder.response.get;
        temp <= resp;
        if (v)
            innerDone.enq(?);
    endrule
    interface sendPair = toPipeIn(dotFifo);
    interface done = toPipeOut(innerDone);
    method Action init(Float atemp);
        temp <= atemp;
    endmethod
    method Float result();
        return temp;
    endmethod
endmodule

interface GearFloat;
    method Action startConversion(Bit#(DataBusWidth) vb, Bit#(DataBusWidth) vw, Bool last);
    method ActionValue#(DotType) outVal();
endinterface

(* synthesize *)
module mkGearFloat(GearFloat);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    Gearbox#(2, 1, Bit#(32)) lToSa <- mkNto1Gearbox(defaultClock, defaultReset, defaultClock, defaultReset);
    Gearbox#(2, 1, Bit#(32)) lToSb <- mkNto1Gearbox(defaultClock, defaultReset, defaultClock, defaultReset);
    Gearbox#(2, 1, Bool) lToLast <- mkNto1Gearbox(defaultClock, defaultReset, defaultClock, defaultReset);

    method Action startConversion(Bit#(DataBusWidth) vb, Bit#(DataBusWidth) vw, Bool last);
        lToSa.enq(unpack(vb));
        lToSb.enq(unpack(vw));
        Vector#(2, Bool) vl = replicate(last);
        lToLast.enq(vl);
    endmethod

    method ActionValue#(DotType) outVal();
        let vb <- toGet(lToSa).get;
        let vw <- toGet(lToSb).get;
        let vl <- toGet(lToLast).get;
        return DotType{a: unpack(vb), b: unpack(vw), last: vl};
    endmethod
endmodule

module mkConv#(ConvIndication indication)(Conv);
    DotProd dotp <- mkDotProd;
    GearFloat gear <- mkGearFloat;
    Reg#(ConnectalParamType) param <- mkReg(unpack(0));
    Reg#(Bit#(32)) p_limit <- mkReg(0);
    Reg#(Bit#(32)) q_limit <- mkReg(0);
    Reg#(Bit#(1)) skip <- mkReg(0);
    Reg#(Bit#(32)) bpx <- mkReg(0);
    Reg#(Bit#(32)) wpx <- mkReg(0);
    Reg#(Bit#(32)) outputp <- mkReg(0);
    Reg#(Bit#(32)) k <- mkReg(0);
    Reg#(Bit#(32)) p <- mkReg(0);
    Reg#(Bit#(32)) bp <- mkReg(0);
    Reg#(Bit#(32)) wp <- mkReg(0);
    Reg#(Bool)     fsmRunning <- mkReg(False);
    MemreadEngine#(DataBusWidth,2,2) rEngine <- mkMemreadEngine;
    MemwriteEngine#(DataBusWidth,2,1) wEngine <- mkMemwriteEngine;
    Reg#(Bit#(BurstLenSize)) burstLenInBytes <- mkReg(8);
    Reg#(Bit#(32)) waitFinish <- mkReg(0);
    Reg#(Bool) dtypeFloat <- mkReg(False);
    Reg#(Bool) dumpStart <- mkReg(False);
    Server#(Double,Float) d2fb <- mkDoubleToFloat;
    Server#(Double,Float) d2fw <- mkDoubleToFloat;
    FIFOF#(Bool) dLast <- mkFIFOF;

    rule readconv;
        let vb <- d2fb.response.get();
        let vw <- d2fw.response.get();
        let vl <- toGet(dLast).get();
        toPut(dotp.sendPair).put(DotType{a: vb, b: vw, last: vl});
    endrule

    rule readresd if (!dtypeFloat);
        let vb <- toGet(rEngine.readServers[0].data).get;
        let vw <- toGet(rEngine.readServers[1].data).get;
        d2fb.request.put(unpack(vb.data));
        d2fw.request.put(unpack(vw.data));
        toPut(dLast).put(vb.last && waitFinish == 1);
        if (vb.last)
            waitFinish <= waitFinish - 1;
    endrule

    rule readresf if (dtypeFloat);
        let vb <- toGet(rEngine.readServers[0].data).get;
        let vw <- toGet(rEngine.readServers[1].data).get;
        let bdata = vb.data;
        if (vb.last) begin
            if (skip != 0)
                bdata = extend(bdata[31:0]);
            waitFinish <= waitFinish - 1;
        end
        gear.startConversion(bdata, vw.data, vb.last && waitFinish == 1);
    endrule

    rule readgear;
        let vd <- toGet(gear.outVal).get;
        toPut(dotp.sendPair).put(vd);
    endrule

    FSM fsm <- mkFSM(seq
        // for each 'in_group', add contribution into convolution
        for ( k <= 0; k < param.in_group_size; k <= k + 1) seq
            bp <= bpx;
            wp <= wpx;
            // Calculate single 2D filter convolution
            for ( p <= 0; p < p_limit; p <= p + 1) action
                rEngine.readServers[0].request.put(MemengineCmd{sglId:param.objectId,
                    base:extend(bp), len:q_limit, burstLen:burstLenInBytes});
                rEngine.readServers[1].request.put(MemengineCmd{sglId:param.objectId,
                    base:extend(wp), len:q_limit, burstLen:burstLenInBytes});
                waitFinish <= waitFinish + 1;
                bp <= bp + param.conv_in_width;
                wp <= wp + param.kernel_w;
            endaction
            bpx <= bpx + param.bottom_hw;
            wpx <= wpx + param.kernel_hw;
        endseq
        endseq);

    rule finishProcessing;
        dotp.done.deq;
        // Write convolution result into output (image, channel, y, x)
        //  *CACCESS(outputp) = temp;
        indication.outputp(outputp, dotp.result());
        fsmRunning <= False;
    endrule

    interface ConvRequest request;
        method Action init(ConnectalParamType aparam);
            param <= aparam;
            dtypeFloat <= (aparam.baseSize == 4);
            if (!dumpStart) begin
               //$dumpon;
               dumpStart <= True;
            end
        endmethod

        method Action forward_kernel(Bit#(32) ap_limit, Bit#(32) aq_limit, Bit#(1) askip, Float atemp, Bit#(32) abpx, Bit#(32) awpx, Bit#(32) aoutputp) if (!fsmRunning);
            p_limit <= ap_limit;
            q_limit <= aq_limit;
            skip <= askip;
            dotp.init(atemp);
            bpx <= extend(abpx);
            wpx <= extend(awpx);
            outputp <= aoutputp;
            fsmRunning <= True;
            fsm.start();
        endmethod
    endinterface
    interface readDma = cons(rEngine.dmaClient, nil);
    interface writeDma = cons(wEngine.dmaClient, nil);
endmodule

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
