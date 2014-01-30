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

import FIFO::*;
import SpecialFIFOs::*;
import GetPutF::*;
import Vector::*;
import BRAM::*;
import Gearbox::*;

import AxiMasterSlave::*;
import Dma::*;
import DmaUtils::*;

/*
 * Implementation of:
 *    MP algorithm on pages 7-11 from "Pattern Matching Algorithms" by
 *       Alberto Apostolico, Zvi Galil, 1997
 *
 *    procedure MP(x, t: string; m, n: integer);
 *    begin
 *        i := 1; j := 1;
 *        while j <= n do begin
 *            while (i = m + 1) or (i > 0 and x[i] != t[j]) do j := MP_next[i];
 *            i := i + 1; j := j + 1;
 *            if i = m + 1 then writeln('x occurs in t at position ', j - i + 1);
 *        end;
 *    end;
 *    
 *    procedure Compute_borders(x: string; m: integer);
 *    begin
 *        Border[0] := -1;
 *        for i := 1 to m do begin
 *            j := Boarder[i - 1];
 *            while j >= 0 and x[i] != x[j + 1] do j := Boarder[j];
 *            Border[i] := j + 1;
 *        end;
 *    end;
 *    
 *    procedure Compute_mp_next(x: string; m: integer);
 *    begin
 *        MP_next[i] := 0; j := 0;
 *        for i := 1 to m do begin
 *            { at this point, we have j = MP_next[i] }
 *            while j > 0 and x[i] != x[j] do j := MP_next[j];
 *            j := j + 1;
 *            MP_next[i + 1] := j;
 *        end;
 *    end;
 *
 */

interface StrstrRequest;
   method Action search(Bit#(32) needleHandle, Bit#(32) haystackHandle, Bit#(32) mpNextHandle, Bit#(32) needle_len, Bit#(32) haystack_len);
endinterface

interface StrstrIndication;
   method Action searchResult(Int#(32) v);
endinterface

typedef Bit#(8) Char;
typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 1024 MaxNeedleLen;
typedef Bit#(TLog#(MaxNeedleLen)) NeedleIdx;

typedef enum {Idle, Init, Run} Stage deriving (Eq, Bits);

module mkStrstrRequest#(StrstrIndication indication,
			DmaReadServer#(busWidth)   haystack_read_chan,
			DmaReadServer#(busWidth)     needle_read_chan,
			DmaReadServer#(busWidth)    mp_next_read_chan )(StrstrRequest)
   
   provisos(Add#(a__, 8, busWidth),
	    Div#(busWidth,8,nc),
	    Mul#(nc,8,busWidth),
	    Add#(1, b__, nc),
	    Add#(c__, 32, busWidth),
	    Add#(1, d__, TDiv#(busWidth, 32)),
	    Mul#(TDiv#(busWidth, 32), 32, busWidth));
   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   BRAM2Port#(NeedleIdx, Char) needle  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(NeedleIdx, Bit#(32)) mpNext <- mkBRAM2Server(defaultValue);
   Gearbox#(nc,1,Char) haystack <- mkNto1Gearbox(clk,rst,clk,rst);
   
   Reg#(Stage) stage <- mkReg(Idle);
   Reg#(Bit#(32)) needleLenReg <- mkReg(0);
   Reg#(Bit#(32)) haystackLenReg <- mkReg(0);
   Reg#(Bit#(32)) iReg <- mkReg(0);
   Reg#(Bit#(32)) jReg <- mkReg(0);
   Reg#(DmaPointer) haystackHandle <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) haystackPtr <- mkReg(0);
   
   DmaReadServer2BRAM#(NeedleIdx) n2b <- mkDmaReadServer2BRAM(needle_read_chan, needle.portB);
   DmaReadServer2BRAM#(NeedleIdx) mp2b <- mkDmaReadServer2BRAM(mp_next_read_chan, mpNext.portB);

   Reg#(Bit#(2)) epochReg <- mkReg(0);
   FIFO#(Tuple2#(Bit#(2),Bit#(32))) efifo <- mkSizedFIFO(2);
   Reg#(Bit#(32)) cycle <- mkReg(0);
   
   rule start (stage == Init);
      let x <- n2b.finished;
      let y <- mp2b.finished;
      stage <= Run;
      iReg <= 1;
      jReg <= 1;
   endrule

   (* descending_urgency = "mp2b_load, n2b_load, matchNeedleResp, matchNeedleReq" *)
   
   rule haystackReq (stage == Run);
      haystack_read_chan.readReq.put(DmaRequest {handle: haystackHandle, address: haystackPtr, burstLen: 1, tag: 0});
      haystackPtr <= haystackPtr + fromInteger(valueOf(nc));
   endrule
   
   rule haystackResp;
      let rv <- haystack_read_chan.readData.get;
      Vector#(nc,Char) pv = unpack(rv.data);
      haystack.enq(pv);
   endrule

   rule haystackDrain(stage != Run);
      haystack.deq;
   endrule
 
   rule matchNeedleReq(stage == Run);
      needle.portA.request.put(BRAMRequest{write:False, address:truncate(iReg-1)});
      mpNext.portA.request.put(BRAMRequest{write:False, address:truncate(iReg)});
      efifo.enq(tuple2(epochReg,iReg));
      iReg <= iReg+1;
      //$display("matchNeedleReq %d %d", epochReg, iReg);
   endrule
   
   rule hb (stage==Run);
      //$display("cycle %h **************************", cycle);
      cycle <= cycle+1;
   endrule
   
   rule matchNeedleResp(stage == Run);
      let nv <- needle.portA.response.get;
      let mp <- mpNext.portA.response.get;
      let epoch = tpl_1(efifo.first);
      efifo.deq;
      if (epoch == epochReg) begin
	 let n = haystackLenReg;
	 let m = needleLenReg;
	 let hv = haystack.first;
	 let i = tpl_2(efifo.first);
	 let j = jReg;
	 if (j > n) begin
	    indication.searchResult(-1);
	    stage <= Idle;
	 end
	 else if (i==m+1) begin
	    //$display("string match %d", j);
	    indication.searchResult(unpack(j-i));
	    epochReg <= epochReg+1;
	    iReg <= 1;
	 end
	 else if ((i==m+1) || ((i>0) && (nv != hv[0]))) begin
	    epochReg <= epochReg + 1;
	    iReg <= mp;
	    //$display("char mismatch %d %d MP_Next[i]=%d", i, j, mp);
	 end
	 else begin
	    //$display("   char match %d %d", i, j);
	    jReg <= j+1;
	    haystack.deq;
	 end
      end
   endrule
   
   method Action search(Bit#(32) needle_handle, Bit#(32) haystack_handle, Bit#(32) mpNext_handle, 
			Bit#(32) needle_len, Bit#(32) haystack_len) if (stage == Idle);

      $display("search %h %h", needle_len, haystack_len);
      needleLenReg <= needle_len;
      haystackLenReg <= haystack_len;
      n2b.start(needle_handle, pack(truncate(needle_len)));
      mp2b.start(mpNext_handle, pack(truncate(needle_len)));
      haystackHandle <= haystack_handle;
      stage <= Init;
      
   endmethod
endmodule
