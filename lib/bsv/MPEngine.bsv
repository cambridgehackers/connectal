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

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;
import BRAM::*;
import Gearbox::*;
import Connectable::*;

import MemUtils::*;
import AxiMasterSlave::*;
import MemTypes::*;
import Dma2BRAM::*;
import Pipe::*;

interface MPEngine#(numeric type busWidth);
   method Action setup(Bit#(32) needlePointer, Bit#(32) mpNextPointer, Bit#(32) needle_len);
   method Action search(Bit#(32) haystackPointer, Bit#(32) haystack_len, Bit#(32) haystack_base);
   method ActionValue#(Bool) finishSetup;
   method ActionValue#(Bool) finishSearch;
   interface Get#(Int#(32)) loc;
endinterface

typedef Bit#(8) Char;
typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 1024 MaxNeedleLen;
typedef TLog#(MaxNeedleLen) NeedleIdxWidth;
typedef Bit#(NeedleIdxWidth) NeedleIdx;

typedef enum {Idle, Ready, Run} Stage deriving (Eq, Bits);

module mkMPEngine#(Vector#(3,MemreadServer#(busWidth)) readers)(MPEngine#(busWidth))
   
   provisos(Add#(a__, 8, busWidth),
	    Div#(busWidth,8,nc),
	    Mul#(nc,8,busWidth),
	    Add#(1, b__, nc),
	    Add#(c__, 32, busWidth),
	    Add#(1, d__, TDiv#(busWidth, 32)),
	    Mul#(TDiv#(busWidth, 32), 32, busWidth),
	    Add#(e__, TLog#(nc), 32),
	    Add#(f__, TLog#(TDiv#(busWidth, 32)), 32));
   
   
   FIFOF#(void) compf <- mkFIFOF;
   FIFOF#(void) conff <- mkFIFOF; 
   FIFOF#(Int#(32)) locf <- mkFIFOF;
		   
   MemreadServer#(busWidth) haystackReader = readers[0];
   MemreadServer#(busWidth) mpReader = readers[1];
   MemreadServer#(busWidth) needleReader = readers[2];
   
   let verbose = False;
   let debug = False;

   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   BRAM2Port#(NeedleIdx, Char) needle  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(NeedleIdx, Bit#(32)) mpNext <- mkBRAM2Server(defaultValue);
   Gearbox#(nc,1,Char) haystack <- mkNto1Gearbox(clk,rst,clk,rst);
   
   Reg#(Stage)    stage <- mkReg(Idle);
   Reg#(Bit#(32)) needleLenReg <- mkReg(0);
   Reg#(Bit#(32)) haystackLenReg <- mkReg(0);
   Reg#(Bit#(32)) haystackBase <- mkReg(0);
   Reg#(Bit#(32)) jReg <- mkReg(0); // offset in haystack
   Reg#(Bit#(32)) iReg <- mkReg(0); // offset in needle
   Reg#(Bit#(2))  epochReg <- mkReg(0);

   BRAMWriter#(NeedleIdxWidth,busWidth) n2b <- mkBRAMWriter(0, needle.portB, needleReader.cmdServer, needleReader.dataPipe);
   BRAMWriter#(NeedleIdxWidth,busWidth) mp2b <- mkBRAMWriter(1, mpNext.portB, mpReader.cmdServer, mpReader.dataPipe);

   FIFOF#(Tuple2#(Bit#(2),Bit#(32))) efifo <- mkSizedFIFOF(2);

   rule finish_setup;
      if (verbose) $display("mkMPEngine::finish_setup");
      let x <- n2b.finish;
      let y <- mp2b.finish;
      stage <= Ready;
      conff.enq(?);
   endrule
      
   rule haystackResp;
      if (debug) $display("mkMPEngine::haystackResp");
      let rv <- toGet(haystackReader.dataPipe).get;
      haystack.enq(unpack(rv));
   endrule
   
   rule haystackDrain(stage != Run);
      if (debug) $display("mkMPEngine::haystackDrain");
      haystack.deq;
   endrule
   
   rule bramDrain(stage != Run);
      if (debug) $display("mkMPEngine::mpNextDrain");
      let x <- mpNext.portA.response.get;
      let y <- needle.portA.response.get;
      efifo.deq;
   endrule

   rule matchNeedleReq(stage == Run);
      if (debug) $display("mkMPEngine::matchNeedleReq %d %d", epochReg, iReg);
      needle.portA.request.put(BRAMRequest{write:False, address: truncate(iReg-1), datain:?, responseOnWrite:?});
      mpNext.portA.request.put(BRAMRequest{write:False, address: truncate(iReg), datain:?, responseOnWrite:?});
      efifo.enq(tuple2(epochReg,iReg));
      iReg <= iReg+1;
   endrule
         
   rule matchNeedleResp(stage == Run);
      let nv <- needle.portA.response.get;
      let mp <- mpNext.portA.response.get;
      let epoch = tpl_1(efifo.first);
      efifo.deq;
      if (debug) $display("mkMPEngine::matchNeedleResp %d %d", epochReg, epoch);
      if (epoch == epochReg) begin
	 let n = haystackLenReg;
	 let m = needleLenReg;
	 let hv = haystack.first;
	 let i = tpl_2(efifo.first);
	 let j = jReg;
	 if (debug) $display("mkMPEngine::feck %d %d %d %d %x %x", n, m, i, j, hv[0], nv);
	 if (j > n) begin
	    // jReg points to the end of the haystack; we are done
	    stage <= Ready;
	    if (debug) $display("mkMPEngine::end of search %d", j);
	 end
	 else if (i==m+1) begin
	    // iReg points to the end of the needle; we have a match
	    if (debug) $display("mkMPEngine::string match %d", j);
	    locf.enq(unpack(haystackBase+j-i));
	    epochReg <= epochReg + 1;
	    iReg <= 1;
	 end
	 else if ((i>0) && (nv != hv[0])) begin
	    // mismatch betwen head of haystack and head of needle; rewind iReg
	    if (debug) $display("mkMPEngine::char mismatch %d %d MP_Next[i]=%d", i, j, mp);
	    epochReg <= epochReg + 1;
	    iReg <= mp;
	 end
	 else begin
	    // match between head of needle and head of haystack; increment haystack
	    if (debug) $display("mkMPEngine::char match %d %d", i, j);
	    jReg <= j+1;
	    haystack.deq;
	 end
      end
      else begin
	 if (debug) $display("mkMPEngine::discard");
	 noAction;
      end
   endrule
   
   rule finish;
      let rv <- haystackReader.cmdServer.response.get;
      compf.enq(?);
   endrule

   method Action setup(Bit#(32) needle_pointer, Bit#(32) mpNext_pointer, Bit#(32) needle_len);
      needleLenReg <= extend(needle_len);
      n2b.start(needle_pointer, 0, 0, pack(truncate(needle_len)));
      mp2b.start(mpNext_pointer, 0, 0, pack(truncate(needle_len)));
   endmethod

   method Action search(Bit#(32) haystack_pointer, Bit#(32) haystack_len, Bit#(32) haystack_base) if (stage == Ready && !efifo.notEmpty && !haystack.notEmpty);
      haystackLenReg <= extend(haystack_len);
      haystackBase <= extend(haystack_base);
      stage <= Run;
      iReg <= 1;
      jReg <= 1;
      epochReg <= 0;
      Bit#(32) haystack_len_ds = haystack_len+fromInteger(valueOf(nc)-1);
      Bit#(TLog#(nc)) zeros = 0;
      Bit#(32) haystack_len_bytes = {zeros,haystack_len_ds[31:valueOf(TLog#(nc))]} * fromInteger(valueOf(nc));
      if (verbose) $display("mkMPEngine::search %d %d %d",  haystack_pointer, haystack_base, haystack_len_bytes);
      haystackReader.cmdServer.request.put(MemengineCmd{pointer:haystack_pointer, base:extend(haystack_base), len:haystack_len_bytes, burstLen:16*fromInteger(valueOf(nc))});
   endmethod
   method ActionValue#(Bool) finishSetup;
      conff.deq;
      return True;
   endmethod
   method ActionValue#(Bool) finishSearch if (!locf.notEmpty);
      compf.deq;
      return True;
   endmethod
   interface Get loc = toGet(locf);
endmodule
