// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

/*
 * Implementation of:
 *    MP algorithm on pages 7-11 from "Pattern Matching Algorithms" by
 *       Alberto Apostolico, Zvi Galil, 1997
 */

`include "ConnectalProjectConfig.bsv"
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;
import BRAM::*;
import Gearbox::*;
import Connectable::*;
import ConfigReg::*;
import StmtFSM::*;
import Probe::*;

import ConnectalMemUtils::*;
import ConnectalMemTypes::*;
import Dma2BRAM::*;
import Pipe::*;
import OldEHR::*;

interface MPEngine#(numeric type haystackBusWidth, numeric type configBusWidth);
   interface PipeIn#(Triplet#(Bit#(32))) setsearch;
   interface PipeOut#(Int#(32)) locdone;
endinterface

interface MPStreamEngine#(numeric type haystackBusWidth, numeric type configBusWidth);
   interface PipeIn#(MemDataF#(configBusWidth)) needle;
   interface PipeIn#(MemDataF#(configBusWidth)) mpNext;
   interface PipeIn#(MemDataF#(haystackBusWidth)) haystack;
   interface PipeOut#(Int#(32)) locdone;
   method Action clear();
   method Action start(Bit#(32) needleLen);
endinterface

typedef Bit#(8) Char;
typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 1024 MaxNeedleLen;
typedef TLog#(MaxNeedleLen) NeedleIdxWidth;
typedef Bit#(NeedleIdxWidth) NeedleIdx;

typedef enum {Config_needle, Config_mpNext, Initialized, Search} Stage deriving (Eq, Bits);



module mkMPEngine#(MemReadEngineServer#(haystackBusWidth) haystackReader,
		   MemReadEngineServer#(configBusWidth) configReader) (MPEngine#(haystackBusWidth,configBusWidth))

   provisos(Add#(a__, 8, haystackBusWidth),
	    Div#(haystackBusWidth,8,haystackBusBytes),
	    Mul#(haystackBusBytes,8,haystackBusWidth),
	    Add#(1, b__, haystackBusBytes),
	    Add#(c__, 32, haystackBusWidth),
	    Add#(1, d__, TDiv#(haystackBusWidth, 32)),
	    Mul#(TDiv#(haystackBusWidth, 32), 32, haystackBusWidth),
	    Add#(e__, TLog#(haystackBusBytes), 32),
	    Add#(f__, TLog#(TDiv#(haystackBusWidth, 32)), 32)
	    ,Mul#(TDiv#(configBusWidth, 8), 8, configBusWidth)
	    ,Add#(1, g__, TDiv#(configBusWidth, 8))
	    ,Add#(h__, TLog#(TDiv#(configBusWidth, 8)), 32)
	    ,Add#(i__, TLog#(TDiv#(configBusWidth, 32)), 32)
	    ,Add#(1, j__, TDiv#(configBusWidth, 32))
	    ,Mul#(TDiv#(configBusWidth, 32), 32, configBusWidth)
	    );
   


   
   FIFOF#(Int#(32)) locf <- mkFIFOF;
   FIFO#(Bool) conff <- mkSizedFIFO(1);
   
   let verbose = True;
   let debug = False;

   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   BRAM2Port#(NeedleIdx, Char) needle  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(NeedleIdx, Bit#(32)) mpNext <- mkBRAM2Server(defaultValue);
   Gearbox#(haystackBusBytes,1,Char) haystack <- mkNto1Gearbox(clk,rst,clk,rst);

   Reg#(Bit#(32)) cycleCnt <- mkReg(0);
   Reg#(Bit#(32)) lastHD <- mkReg(0);
   
   Reg#(Stage)    stage <- mkReg(Config_needle);
   Reg#(Bit#(32)) needleLenReg <- mkReg(0);
   Reg#(Bit#(32)) haystackLenReg <- mkReg(0);
   Reg#(Bit#(32)) haystackBase <- mkReg(0);
   Reg#(Bit#(32)) jReg <- mkReg(0); // offset in haystack
   Reg#(Bit#(32)) iReg <- mkReg(0); // offset in needle
   Reg#(Bit#(2))  epochReg <- mkReg(0);

   BRAMWriter#(NeedleIdxWidth,configBusWidth) n2b <- mkBRAMWriter(0, needle.portB, configReader);
   BRAMWriter#(NeedleIdxWidth,configBusWidth) mp2b <- mkBRAMWriter(1, mpNext.portB, configReader);

   FIFOF#(Tuple2#(Bit#(2),Bit#(32))) efifo <- mkSizedFIFOF(2);
   FIFOF#(Triplet#(Bit#(32))) ssfifo <- mkFIFOF;
   FIFO#(void) doneFifo <- mkFIFO;
   
   rule countCycles;
      if (debug) $display("******************************************** %d", cycleCnt);
      cycleCnt <= cycleCnt+1;
   endrule
   
   rule haystackResp;
      if (debug) $display("mkMPEngine::haystackResp");
      let rv <- toGet(haystackReader.data).get;
      haystack.enq(unpack(rv.data));
      if (rv.last)
         conff.deq;
   endrule
   
   rule haystackDrain(stage != Search);
      if (debug) $display("mkMPEngine::haystackDrain");
      haystack.deq;
   endrule
   
   rule bramDrain(stage != Search);
      if (debug) $display("mkMPEngine::mpNextDrain");
      let x <- mpNext.portA.response.get;
      let y <- needle.portA.response.get;
      efifo.deq;
   endrule
  
   
`define OPTIMIZE_MISMATCH
`ifdef OPTIMIZE_MISMATCH
   rule matchNeedleReq(stage == Search);
      if (debug) $display("mkMPEngine::matchNeedleReq %d %d", epochReg, iReg);
      needle.portA.request.put(BRAMRequest{write:False, address: truncate(iReg-1), datain:?, responseOnWrite:?});
      mpNext.portA.request.put(BRAMRequest{write:False, address: truncate(iReg), datain:?, responseOnWrite:?});
      efifo.enq(tuple2(epochReg,iReg));
      iReg <= 1;
   endrule
         
   rule matchNeedleResp(stage == Search);
      let nv <- needle.portA.response.get;
      let mp <- mpNext.portA.response.get;
      let epoch = tpl_1(efifo.first);
      efifo.deq;
      if (debug) $display("mkMPEngine::matchNeedleResp %d %d", epochReg, epoch);
      if (epoch == epochReg) begin
	 Bool deq_haystack = False;
	 let n = haystackLenReg;
	 let m = needleLenReg;
	 let hv = haystack.first;
	 let i = tpl_2(efifo.first);
	 let j = jReg;
	 if (debug) $display("mkMPEngine::feck %d %d %d %d %x %x", n, m, i, j, hv[0], nv);
	 if (j > n) begin
	    // jReg points to the end of the haystack; we are done
	    stage <= Config_needle;
	    if (debug) $display("mkMPEngine::end of search %d", j);
	    locf.enq(-1);
	 end
	 else if (i==m+1) begin
	    // iReg points to the end of the needle; we have a match
	    if (debug) $display("mkMPEngine::string match %d", j);
	    locf.enq(unpack(haystackBase+j-i));
	 end
	 else if (nv != hv[0]) begin
	    // mismatch betwen head of haystack and head of needle; rewind iReg
	    if (debug) $display("mkMPEngine::char mismatch %d %d MP_Next[i]=%d", i, j, mp);
	    if (mp == 0) begin
	       iReg <= 1;
	       jReg <= j+1;
	       deq_haystack = True;
	    end
	    else begin
	       epochReg <= epochReg + 1;
	       iReg <= mp;
	    end
	 end
	 else begin
	    // match between head of needle and head of haystack; increment haystack
	    if (debug) $display("mkMPEngine::char match(%d) %d %d", (nv == hv[0]), i, j);
	    deq_haystack = True;
	    jReg <= j+1;
	    epochReg <= epochReg + 1;
	    iReg <= i+1;
	 end
	 if (deq_haystack) begin
	    haystack.deq;
	    lastHD <= cycleCnt;
	    if (debug) $display("mkMPEngine:: deq haystack(%d)", cycleCnt-lastHD);
	 end
      end
      else begin
	 if (debug) $display("mkMPEngine::discard");
	 noAction;
      end
   endrule
`else
   rule matchNeedleReq(stage == Search);
      if (debug) $display("mkMPEngine::matchNeedleReq %d %d", epochReg, iReg);
      needle.portA.request.put(BRAMRequest{write:False, address: truncate(iReg-1), datain:?, responseOnWrite:?});
      mpNext.portA.request.put(BRAMRequest{write:False, address: truncate(iReg), datain:?, responseOnWrite:?});
      efifo.enq(tuple2(epochReg,iReg));
      iReg <= iReg+1;
   endrule
         
   rule matchNeedleResp(stage == Search);
      let nv <- needle.portA.response.get;
      let mp <- mpNext.portA.response.get;
      let epoch = tpl_1(efifo.first);
      efifo.deq;
      if (debug) $display("mkMPEngine::matchNeedleResp %d %d", epochReg, epoch);
      if (epoch == epochReg) begin
	 Bool deq_haystack = False;
	 let n = haystackLenReg;
	 let m = needleLenReg;
	 let hv = haystack.first;
	 let i = tpl_2(efifo.first);
	 let j = jReg;
	 if (debug) $display("mkMPEngine::feck %d %d %d %d %x %x", n, m, i, j, hv[0], nv);
	 if (j > n) begin
	    // jReg points to the end of the haystack; we are done
	    stage <= Config_needle;
	    if (debug) $display("mkMPEngine::end of search %d", j);
	 end
	 else if (i==m+1) begin
	    // iReg points to the end of the needle; we have a match
	    if (debug) $display("mkMPEngine::string match %d", j);
	    locf.enq(unpack(haystackBase+j-i));
	    epochReg <= epochReg + 1;
	    iReg <= 1;
	 end
	 else if (nv != hv[0]) begin
	    // mismatch betwen head of haystack and head of needle; rewind iReg
	    if (debug) $display("mkMPEngine::char mismatch %d %d MP_Next[i]=%d", i, j, mp);
	    epochReg <= epochReg + 1;
	    if (mp == 0) begin
	       iReg <= 1;
	       jReg <= j+1;
	       deq_haystack = True;
	    end
	    else begin
	       iReg <= mp;
	    end
	 end
	 else begin
	    // match between head of needle and head of haystack; increment haystack
	    if (debug) $display("mkMPEngine::char match(%d) %d %d", (nv == hv[0]), i, j);
	    deq_haystack = True;
	    jReg <= j+1;
	 end
	 if (deq_haystack) begin
	    haystack.deq;
	    lastHD <= cycleCnt;
	    if (debug) $display("mkMPEngine:: deq haystack(%d)", cycleCnt-lastHD);
	 end
      end
      else begin
	 if (debug) $display("mkMPEngine::discard");
	 noAction;
      end
   endrule
`endif 
  
   rule finish_setup_n2b;
      if (verbose) $display("mkMPEngine::finish_setup_n2b");
      let x <- n2b.finish;
      conff.deq;
      stage <= Config_mpNext;
   endrule

   rule finish_setup_mp2b;
      if (verbose) $display("mkMPEngine::finish_setup_mp2b");
      let y <- mp2b.finish;
      conff.deq;
      stage <= Initialized;
   endrule
      
   rule setup_needle (stage == Config_needle);
      conff.enq(True);
      match {.needle_sglId, .mpNext_sglId, .needle_len} = ssfifo.first;
      needleLenReg <= extend(needle_len);
      if (verbose) $display("mkMPEngine::setup_needle %d %d", needle_sglId, needle_len);
      n2b.start(needle_sglId, 0, 0, pack(truncate(needle_len)));
   endrule
   
   rule setup_mpNext (stage == Config_mpNext);
      conff.enq(True);
      match {.needle_sglId, .mpNext_sglId, .needle_len} = ssfifo.first;
      needleLenReg <= extend(needle_len);
      if (verbose) $display("mkMPEngine::setup_mpNext %d %d", mpNext_sglId, needle_len);
      mp2b.start(mpNext_sglId, 0, 0, pack(truncate(needle_len)));
      ssfifo.deq;
   endrule

   rule search (stage == Initialized && !efifo.notEmpty && !haystack.notEmpty);
      stage <= Search;
      conff.enq(True);
      match {.haystack_sglId, .haystack_len, .haystack_base} <- toGet(ssfifo).get;
      haystackLenReg <= extend(haystack_len);
      haystackBase <= extend(haystack_base);
      iReg <= 1;
      jReg <= 1;
      epochReg <= 0;
      Bit#(32) haystack_len_ds = haystack_len+fromInteger(valueOf(haystackBusBytes)-1);
      Bit#(TLog#(haystackBusBytes)) zeros = 0;
      Bit#(32) haystack_len_bytes = {zeros,haystack_len_ds[31:valueOf(TLog#(haystackBusBytes))]} * fromInteger(valueOf(haystackBusBytes));
      $display("haystack read offset=%d burstLen=%d", haystack_base, fromInteger(8*valueOf(haystackBusBytes)));
      haystackReader.request.put(MemengineCmd{sglId:haystack_sglId, base:extend(haystack_base), len:haystack_len_bytes, burstLen:fromInteger(8*valueOf(haystackBusBytes)), tag: 0});
      if (verbose) $display("mkMPEngine::search %d %d %d",  haystack_sglId, haystack_base, haystack_len_bytes);
   endrule
   
   interface PipeIn setsearch = toPipeIn(ssfifo);   
   interface PipeOut locdone = toPipeOut(locf);

endmodule

module mkMPStreamEngine(MPStreamEngine#(haystackBusWidth,configBusWidth))

   provisos(Add#(a__, 8, haystackBusWidth),
	    Div#(haystackBusWidth,8,haystackBusBytes),
	    Mul#(haystackBusBytes,8,haystackBusWidth),
	    Add#(1, b__, haystackBusBytes),
	    Add#(c__, 32, haystackBusWidth),
	    Add#(1, d__, TDiv#(haystackBusWidth, 32)),
	    Mul#(TDiv#(haystackBusWidth, 32), 32, haystackBusWidth),
	    Add#(e__, TLog#(haystackBusBytes), 32),
	    Add#(f__, TLog#(TDiv#(haystackBusWidth, 32)), 32)
	    ,Mul#(TDiv#(configBusWidth, 8), 8, configBusWidth)
	    ,Add#(1, g__, TDiv#(configBusWidth, 8))
	    ,Add#(h__, TLog#(TDiv#(configBusWidth, 8)), 32)
	    ,Add#(i__, TLog#(TDiv#(configBusWidth, 32)), 32)
	    ,Add#(1, j__, TDiv#(configBusWidth, 32))
	    ,Mul#(TDiv#(configBusWidth, 32), 32, configBusWidth)
	    );
   
   FIFOF#(Int#(32)) locf <- mkFIFOF;
   
   let verbose = True;
   let debug = True;

   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   BRAM2Port#(NeedleIdx, Char) needleBram  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(NeedleIdx, Bit#(32)) mpNextBram <- mkBRAM2Server(defaultValue);
   FIFOF#(MemDataF#(haystackBusWidth)) haystackFifo <- mkFIFOF();
   Gearbox#(haystackBusBytes,1,Char) haystackGb <- mkNto1Gearbox(clk,rst,clk,rst);

   Reg#(Bit#(32)) cycleCnt <- mkReg(0);
   Reg#(Bit#(32)) lastHD <- mkReg(0);
   
   Reg#(Stage)    stage <- mkReg(Initialized);
   Reg#(Bit#(32)) needleLenReg <- mkReg(0);
   Reg#(Bit#(32)) jReg <- mkReg(1); // offset in haystack
   Reg#(Bit#(32)) iReg <- mkReg(1); // offset in needle

   BRAMPipeIn#(NeedleIdxWidth,configBusWidth) n2b <- mkBRAMPipeIn(0, needleBram.portB);
   BRAMPipeIn#(NeedleIdxWidth,configBusWidth) mp2b <- mkBRAMPipeIn(1, mpNextBram.portB);

   FIFOF#(Tuple2#(Bit#(2),Bit#(32))) efifo <- mkSizedFIFOF(2);
   FIFO#(void) doneFifo <- mkFIFO;
   
   rule countCycles;
      //if (debug) $display("******************************************** %d", cycleCnt);
      cycleCnt <= cycleCnt+1;
   endrule
   
   rule haystackResp;
      let rv <- toGet(haystackFifo).get;
      if (debug) $display("mkMPEngine::haystackResp rv=%h", rv.data);
      haystackGb.enq(unpack(rv.data));
   endrule
   
   let x_i <- mkReg(0);
   let t_j <- mkReg(0);
   let m = needleLenReg;
   let i = iReg;
   let iReg_minus_1 <- mkReg(0);
   let matchFsm <- mkAutoFSM(seq
      while (stage != Search) seq
	 iReg <= 1;
      endseq
      action
	 iReg <= 1;
	 jReg <= 1;
	 let t = haystackGb.first[0]; haystackGb.deq();
	 t_j <= t;
         iReg_minus_1 <= iReg-1;
      endaction
      action
	 needleBram.portA.request.put(BRAMRequest{write:False, address: truncate(iReg_minus_1), datain:?, responseOnWrite:?});
      endaction
      action
	 let xNext <- needleBram.portA.response.get();
	 x_i <= xNext;
      endaction
      while (stage == Search) seq
	 $display("initial i=%d j=%d x_i=%h t_j=%h", iReg, jReg, x_i, t_j);
	 while ((i == m + 1) || (i > 0 && x_i != t_j)) seq
	    action
	       mpNextBram.portA.request.put(BRAMRequest{write:False, address: truncate(iReg), datain:?, responseOnWrite:?});
      	    endaction
	    action
	       Bit#(32) mpNext <- mpNextBram.portA.response.get();
	       let iNext = mpNext[15:0];
	       let xNext = mpNext[31:16];
	       iReg <= extend(iNext);
	       x_i <= truncate(xNext);
	       $display("i=%d iNext=%d m+1=%d x_i=%h t_j=%h mpNext=%h", i, iNext, m+1, xNext, t_j, mpNext);
	    endaction
	 endseq
	 action
	    iReg <= iReg + 1;
	    jReg <= jReg + 1;
	    needleBram.portA.request.put(BRAMRequest{write:False, address: truncate(iReg+1-1), datain:?, responseOnWrite:?});
	    let t = haystackGb.first[0]; haystackGb.deq();
	    t_j <= t;
      endaction
      action
	    if (t_j == 0) begin
	       $display("iReg=%d jReg=%d t==0 locf.enq(-1)", iReg-1, jReg-1, t_j);
	       locf.enq(-1); // this seems to be needed for the strstr example to terminate
	    end
	 endaction
	 action
	    let xNext <- needleBram.portA.response.get();
	    x_i <= xNext;
	    $display("step    i=%d j=%d x_i=%h t_j=%h", iReg, jReg, xNext, t_j);
	    if (iReg == m + 1) begin
	       $display("match at j=%d", jReg - iReg);
	       locf.enq(unpack(jReg - iReg));
	    end
	 endaction
      endseq // stage == Search
      endseq);
  
   interface PipeIn needle = n2b.pipe;
   interface PipeIn mpNext = mp2b.pipe;
   interface PipeIn haystack = toPipeIn(haystackFifo);
   interface PipeOut locdone = toPipeOut(locf);

   method Action clear();
      stage <= Initialized;
   endmethod
   method Action start(Bit#(32) needleLen);
      stage <= Search;
      jReg <= 1;
      iReg <= 1;
      needleLenReg <= needleLen;
   endmethod

endmodule
