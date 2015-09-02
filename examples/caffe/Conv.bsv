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
import FShow::*;

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
    method Action forward_kernel(Bit#(32) p_limit, Bit#(32) q_limit, Bit#(1) skip, Float temp, Bit#(32) bpx, Bit#(32) wpx, Bit#(32) outputp);
endinterface

interface Conv;
    interface ConvRequest request;
    interface Vector#(1,MemReadClient#(DataBusWidth)) readDma;
    interface Vector#(1,MemWriteClient#(DataBusWidth)) writeDma;
endinterface

typedef struct {
    Float a;
    Float b;
} DotType deriving (Bits, Eq);

typedef struct {
    Bool  odd;
    Bool  last;
} LastType deriving (Bits, Eq);

interface DotProd;
    interface PipeIn#(DotType) inVal;
    interface PipeIn#(LastType) lastF;
    interface PipeOut#(void)   done;
    method Action init(Float atemp);
    method Float result();
endinterface

(* synthesize *)
module mkDotProd(DotProd);
    FIFOF#(DotType) dotFifo <- mkFIFOF;
    FIFOF#(LastType) lastFifo <- mkFIFOF;
    FIFOF#(void) innerDone <- mkFIFOF;
    FloatAlu adder <- mkFloatAdder(defaultValue);
    FloatAlu mul <- mkFloatMultiplier(defaultValue);
    Reg#(Float)    temp <- mkReg(0);

    rule dotrule;
        let v <- toGet(dotFifo).get;
$display("MUL %x %x", v.a, v.b);
        mul.request.put(tuple2(v.a, v.b));
    endrule

    rule addrule;
        match {.resp,.*} <- mul.response.get;
$display("ADD %x %x", resp, temp);
        adder.request.put(tuple2(resp,temp));
    endrule

    rule storerule;
        let v <- toGet(lastFifo).get;
        match {.resp,.*} <- adder.response.get;
        temp <= resp;                //ERROR -> not atomic
        if (v.last) begin
$display("RES %x", temp);
            innerDone.enq(?);
        end
    endrule
    interface inVal = toPipeIn(dotFifo);
    interface lastF = toPipeIn(lastFifo);
    interface done = toPipeOut(innerDone);
    method Action init(Float atemp);
$display("INIT %x", atemp);
        temp <= atemp;
    endmethod
    method Float result();
        return temp;
    endmethod
endmodule

interface WordFloat;
    method Action inVal(Bit#(DataBusWidth) vb, Bit#(DataBusWidth) vw, Bool odd, Bool last);
    method ActionValue#(DotType) outVal();
    method ActionValue#(LastType) outLast();
endinterface

(* synthesize *)
module mkWordFloat(WordFloat);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    Gearbox#(2, 1, Bit#(32)) lToSa <- mkNto1Gearbox(defaultClock, defaultReset, defaultClock, defaultReset);
    Gearbox#(2, 1, Bit#(32)) lToSb <- mkNto1Gearbox(defaultClock, defaultReset, defaultClock, defaultReset);
    Gearbox#(2, 1, LastType) lToLast <- mkNto1Gearbox(defaultClock, defaultReset, defaultClock, defaultReset);

    method Action inVal(Bit#(DataBusWidth) vb, Bit#(DataBusWidth) vw, Bool odd, Bool last);
        lToSa.enq(unpack(vb));
        lToSb.enq(unpack(vw));
        Vector#(2, LastType) vl;
        vl[0] = LastType{odd: odd, last: last && odd};
        vl[1] = LastType{odd: odd, last: last};
        lToLast.enq(vl);
    endmethod

    method ActionValue#(DotType) outVal();
        let vb <- toGet(lToSa).get;
        let vw <- toGet(lToSb).get;
        Float btemp = unpack(vb);
        Float wtemp = unpack(vw);
        $display("READRES32: b %x w %x", btemp, wtemp);
        $display("READRES32f: b w");
        $display(fshow(btemp));
        $display(fshow(wtemp));
        return DotType{a: btemp, b: wtemp};
    endmethod

    method ActionValue#(LastType) outLast();
        let v <- toGet(lToLast).get;
        return v;
    endmethod
endmodule

module mkConv#(ConvIndication indication)(Conv);
    DotProd dotp <- mkDotProd;
    WordFloat wf <- mkWordFloat;
    Reg#(ConnectalParamType) param <- mkReg(unpack(0));
    Reg#(Bit#(32)) p_limit <- mkReg(0);
    Reg#(Bit#(32)) q_limit <- mkReg(0);
    Reg#(Bit#(1)) skip <- mkReg(0);
    Reg#(Bit#(32)) bpx <- mkReg(0);
    Reg#(Bit#(32)) wpx <- mkReg(0);
    Reg#(Bit#(32)) outputp <- mkReg(0);
    Reg#(Bit#(32)) k <- mkReg(0);
    Reg#(Bit#(32)) p <- mkReg(0);
    Reg#(Bit#(32)) q <- mkReg(0);
    Reg#(Bit#(32)) bp <- mkReg(0);
    Reg#(Bit#(32)) wp <- mkReg(0);
    Reg#(Bool)     fsmRunning <- mkReg(False);
    MemreadEngine#(DataBusWidth,2,2) re <- mkMemreadEngine;
    MemwriteEngine#(DataBusWidth,2,1) wr <- mkMemwriteEngine;
    Reg#(Bit#(BurstLenSize)) burstLenInBytes <- mkReg(8);
    Reg#(Bit#(32)) waitFinish <- mkReg(0);
    Reg#(Bool) dtypeFloat <- mkReg(False);
    Reg#(Bool) dumpStart <- mkReg(False);
    Server#(Double,Float) d2fb <- mkDoubleToFloat;
    Server#(Double,Float) d2fw <- mkDoubleToFloat;

    rule readconv;
        let vb <- d2fb.response.get();
        let vw <- d2fw.response.get();
        $display("READRES64: %x %x", vb, vw);
        toPut(dotp.inVal).put(DotType{a: vb, b: vw});
    endrule

    rule readresd if (!dtypeFloat);
        let vb <- toGet(re.readServers[0].data).get;
        let vw <- toGet(re.readServers[1].data).get;
        Double btempd = unpack(vb.data);
        Double wtempd = unpack(vw.data);
        d2fb.request.put(btempd);
        d2fw.request.put(wtempd);
        $display("READRESX64: %x %x", vb.data, vw.data);
        $display("READRESX64f: %f %f", btempd, wtempd);
        toPut(dotp.lastF).put(LastType{odd: False, last: vb.last && waitFinish == 1});
        if (vb.last)
            waitFinish <= waitFinish - 1;
    endrule

    rule readresf if (dtypeFloat);
        let vb <- toGet(re.readServers[0].data).get;
        let vw <- toGet(re.readServers[1].data).get;
        $display("READRESX32: %x %x", vb.data, vw.data);
        let bdata = vb.data;
        if (vb.last) begin
            if (skip != 0)
                bdata = extend(bdata[31:0]);
            waitFinish <= waitFinish - 1;
        end
        wf.inVal(bdata, vw.data, False, vb.last && waitFinish == 1);
    endrule

    rule readgear;
        let vd <- toGet(wf.outVal).get;
        toPut(dotp.inVal).put(vd);
        let vf <- toGet(wf.outLast).get;
        toPut(dotp.lastF).put(vf);
    endrule

    FSM fsm <- mkFSM(seq
        // for each 'in_group', add contribution into convolution
        for ( k <= 0; k < param.in_group_size; k <= k + 1) seq
            bp <= bpx;
            wp <= wpx;
            // Calculate single 2D filter convolution
            for ( p <= 0; p < p_limit; p <= p + 1) seq
                $display("FSM: k %d p %d/%d q %d; bp %x, wp %x", k, p, p_limit, q_limit, bp, wp);
                re.readServers[0].request.put(MemengineCmd{sglId:param.objectId,
                    base:extend(bp), len:q_limit, burstLen:burstLenInBytes});
                re.readServers[1].request.put(MemengineCmd{sglId:param.objectId,
                    base:extend(wp), len:q_limit, burstLen:burstLenInBytes});
                waitFinish <= waitFinish + 1;
                bp <= bp + param.conv_in_width;
                wp <= wp + param.kernel_w;
            endseq
            bpx <= bpx + param.bottom_hw;
            wpx <= wpx + param.kernel_hw;
        endseq
        dotp.done.deq;
        // Write convolution result into output (image, channel, y, x)
        //  *CACCESS(outputp) = temp;
        indication.outputp(outputp, dotp.result());
        fsmRunning <= False;
        endseq);

   interface ConvRequest request;
       method Action init(ConnectalParamType aparam);
           $display("Conv:init");
           param <= aparam;
           dtypeFloat <= (aparam.baseSize == 4);
           if (!dumpStart) begin
              $dumpon;
              dumpStart <= True;
           end
       endmethod

       method Action forward_kernel(Bit#(32) ap_limit, Bit#(32) aq_limit, Bit#(1) askip, Float atemp, Bit#(32) abpx, Bit#(32) awpx, Bit#(32) aoutputp) if (!fsmRunning);
           $display("Conv:forward_kernel");
           p_limit <= ap_limit;
           q_limit <= aq_limit;
           skip <= askip;
           dotp.init(atemp);
           bpx <= extend(abpx);
           wpx <= extend(awpx);
           outputp <= aoutputp;
           fsm.start();
           fsmRunning <= True;
       endmethod
   endinterface
   interface readDma = cons(re.dmaClient, nil);
   interface writeDma = cons(wr.dmaClient, nil);

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
