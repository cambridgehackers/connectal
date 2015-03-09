// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import StmtFSM::*;
import BRAM::*;
import GotohB::*;
import StackReg::*;

interface SWAlgorithm;
   method Action setupA (Bit#(14) start, Bit#(14) length);
   method Action setupB (Bit#(14) start, Bit#(14) length);
   method Bit#(14) result();
   interface FSM fsm;
endinterface


/* frame arguments */
typedef struct {
   Bit#(14) aStart;
   Bit#(14) bStart;
   Bit#(14) aLen;
   Bit#(14) bLen;
   Bit#(16) tb; /* tb, te only need to be 1 bit, to represent 0 or g */
   Bit#(16) te;
   } CArgs deriving(Bits);

typedef struct {
   Bit#(14) midi;
   Bit#(14) minj;
   Bit#(2) mintype;
   } CVars deriving(Bits);

typedef enum {GCSIdle, GCS1, GCS2, GCS3, GCS4, GCS5, GCS6, 
   GCSComplete} GCState deriving (Bits, Eq);

module mkGotohC#(
   BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strA, 
   BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strB, 
   GotohAlgorithm cgotohB0,  
   GotohAlgorithm cgotohB1, 
   BRAMServer#(Bit#(lIndexWidth), Bit#(16)) cc, 
   BRAMServer#(Bit#(lIndexWidth), Bit#(16)) dd, 
   BRAMServer#(Bit#(lIndexWidth), Bit#(16)) rr, 
   BRAMServer#(Bit#(lIndexWidth), Bit#(16)) ss)(SWAlgorithm)
   provisos(Add#(0, 14, strIndexWidth),
	    Add#(0, 14, lIndexWidth));

   Bit#(16) initialH = 1;
   Bit#(16) initialG = 4;
      /* pc, args, vars */
   StackReg#(128, GCState, CArgs, CVars) fr <- mkStackReg(128, GCSIdle);

   Reg#(Bit#(14)) aStartReg <- mkReg(0);
   Reg#(Bit#(14)) bStartReg <- mkReg(0);
   Reg#(Bit#(14)) rStartReg <- mkReg(0);
   Reg#(Bit#(14)) aLenReg <- mkReg(0);
   Reg#(Bit#(14)) bLenReg <- mkReg(0);
   Reg#(Bit#(14)) ii <- mkReg(0);
   Reg#(Bit#(14)) jj <- mkReg(0);
   Reg#(Bit#(8)) aData <- mkReg(0);
   Reg#(Bit#(8)) bData <- mkReg(0);
   Reg#(Bit#(14)) outcounter <- mkReg(0);
   Reg#(Bit#(16)) alt1 <- mkReg(0);
   Reg#(Bit#(16)) alt2 <- mkReg(0);
   Reg#(Bit#(16)) minsofar <- mkReg(0);
   Reg#(Bit#(1)) minfound <- mkReg(0);

/*
 * GotohC(Astart, Alen, Bstart, Blen, tb, te, output fifo)
 * implicit A storage, B storage
 * 
 */
   function Bit#(16) gap (Bit#(16) i);
      
      if (i == 0) gap = 0;
      else gap = (initialG + (initialH * i));
      endfunction: gap
   
  // This FSM searches string B looking for the first char of string A
   Stmt gotohC2Stmt =
   seq
      $display("gotohC2Stmt running ");
      // read A[0]
      strA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: fr.args.aStart, datain: ?});
      action
	 let tmp <- strA.response.get();
	 aData <= tmp;
      endaction
      alt1 <= min(fr.args.tb, fr.args.te) + initialH + gap(zeroExtend(fr.args.bLen));
      minsofar <= alt1;
      fr.vars <= CVars{midi: 0, minj: 1, mintype: 1};
      // scan B
      for (jj <= 1; jj <= fr.args.bLen; jj <= jj + 1)
	 seq
	    strB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: fr.args.bStart + jj - 1, datain: ?});
	    action
	       let tmp <- strB.response.get();
	       bData <= tmp;
	    endaction
	    if (aData == bData)
	       alt2 <= 0;
	    else
	       alt2 <= 2;
	    alt2 <= alt2 + gap(zeroExtend(jj - 1)) + gap(zeroExtend(fr.args.bLen - jj));
	    if (min(alt1, alt2) < minsofar)
	       par
		  minsofar <= min(alt1, alt2);
		  fr.vars <= CVars{midi: 0, minj: jj, mintype: 1};
	       endpar
	 endseq
      if (fr.vars.minj > 1)
	 $display("delete B[%d] through B[%d]",
	    fr.args.bStart, fr.args.bStart + fr.vars.minj - 1);
      $display("convert A[%d] (%s) to B[%d] (%s)",
	       fr.args.aStart, aData, fr.args.bStart + fr.vars.minj - 1, bData);
      if (fr.vars.minj < fr.args.bLen)
	 $display("delete B[%d] through B[%d]",
		  fr.args.bStart + fr.vars.minj, fr.args.bStart + fr.args.bLen - 1);
      $display("notes fr.vars.minj %f fr.args.bLen %d",
	 fr.vars.minj, fr.args.bLen);
      fr.doreturn();
   endseq;

   FSM gC2fsm <- mkFSM(gotohC2Stmt);
   
   // AlgC step 1, 2, and 3
   rule gc1 (fr.pc == GCS1);
      $display("GCS1 aStart %d aLen %d bStart %d bLen %d", 
	 fr.args.aStart, fr.args.aLen, fr.args.bStart, fr.args.bLen);
      if (fr.args.bLen == 0)
	 begin
	    if (fr.args.aLen > 0)
	       $display("delete A[%d] through A[%d]", 
		  fr.args.aStart, fr.args.aStart + fr.args.aLen - 1);
	    fr.doreturn();
	 end
     else if (fr.args.aLen == 0)
	begin
	   $display("insert B[%d] through B[%d]",
	      fr.args.bStart, fr.args.bStart + fr.args.bLen - 1);
	end
     else if (fr.args.aLen == 1)
	begin
	   gC2fsm.start();
	   fr.nextpc(GCS2);
	end
     else
	action
	   let midi = fr.args.aLen >> 1;
	   fr.vars.midi <= midi;
	   cgotohB1.setupA(fr.args.aStart, midi);
	   cgotohB1.setupB(fr.args.bStart, fr.args.bLen);
	   cgotohB1.setupG(fr.args.tb);
	   cgotohB0.setupA(fr.args.aStart+midi, fr.args.aLen - midi);
	   cgotohB0.setupB(fr.args.bStart, fr.args.bLen);
	   cgotohB0.setupG(fr.args.te);
	   cgotohB0.fsm.start();
	   cgotohB1.fsm.start();
	   fr.nextpc(GCS3);
	endaction
   endrule
   
   // This FSM searches the results of the two calls to GotohB
   Stmt gotohC4Stmt =
   seq
      $display ("gotohC4A stmt running");
      action
	 minfound <= 0;
	 minsofar <= 0;
	 fr.vars.minj <= 0;
      endaction
      for (jj <= 0; jj <= fr.args.bLen; jj <= jj + 1)
	 seq
	    action
	       cc.request.put(BRAMRequest{write: False, responseOnWrite: False, address: zeroExtend(jj), datain: ?});
	       rr.request.put(BRAMRequest{write: False, responseOnWrite: False, address: zeroExtend(fr.args.bLen - jj), datain: ?});
	       dd.request.put(BRAMRequest{write: False, responseOnWrite: False, address: zeroExtend(jj), datain: ?});
	       ss.request.put(BRAMRequest{write: False, responseOnWrite: False, address: zeroExtend(fr.args.bLen - jj), datain: ?});
	    endaction
	    action
	       let tc <- cc.response.get();
	       let td <- dd.response.get();
	       let tr <- rr.response.get();
	       let ts <- ss.response.get();
	       let t1 = tc + tr;
	       let t2 = td + ts - initialG;
	       $display(" j %d cc %d dd %d rr %d ss %d",
		  jj, tc, td, tr, ts);
	       if ((minfound == 0) || (t1 < minsofar) || (t2 < minsofar))
		  action
		     if (t1 < t2)
			action
			   fr.vars <= CVars{midi: fr.vars.midi, minj: jj, mintype: 1};
			   minsofar <= t1;
			endaction
		     else
			action
			   fr.vars <= CVars{midi: fr.vars.midi, minj: jj, mintype: 2};
			   minsofar <= t2;
			endaction
		  endaction
	       minfound <= 1;
	    endaction
	 endseq
      $display ("midi %d minj %d fr.vars.mintype %d", 
	 fr.vars.midi, fr.vars.minj, fr.vars.mintype);
      if (fr.vars.mintype == 1)
	 action
	    fr.docall(GCS1, GCS5, CArgs {aStart: fr.args.aStart, aLen: fr.vars.midi, bStart: fr.args.bStart, bLen: fr.vars.minj, tb: fr.args.tb, te: initialG}, fr.vars);
	 endaction
      else /* fr.vars.mintype == 2 */
	 action
	    fr.docall(GCS1, GCS5, CArgs {aStart: fr.args.aStart, aLen: fr.vars.midi - 1, bStart: fr.args.bStart, bLen: fr.vars.minj, tb: fr.args.tb, te: 0}, fr.vars);
	 endaction
   endseq;

   FSM gc4fsm <- mkFSM(gotohC4Stmt);
   
   rule gc3 (fr.pc == GCS3 && cgotohB0.fsm.done() && cgotohB1.fsm.done());
      //$display("HSC3");
      gc4fsm.start();
      fr.nextpc(GCS4);
   endrule
   
   rule gc5 (fr.pc == GCS5);
      $display("GCC5 aStart %d aLen %d bStart %d bLen %d midi %d maj %d",
	 fr.args.aStart, fr.args.aLen, fr.args.bStart, fr.args.bLen,
	 fr.vars.midi, fr.vars.minj);
      if (fr.vars.mintype == 1)
	 action
	    fr.docall(GCS1, GCS6, CArgs{aStart: fr.args.aStart + fr.vars.midi, aLen: fr.args.aLen - fr.vars.midi, bStart: fr.args.bStart + fr.vars.minj, bLen: fr.args.bLen - fr.vars.minj, tb: initialG, te: fr.args.te}, fr.vars);
	 endaction
      else
	 action
	    $display("delete A[%d] and A[%d]",
	       fr.args.aStart + fr.vars.midi,
	       fr.args.aStart + fr.vars.midi + 1);
	    fr.docall(GCS1, GCS6, CArgs{aStart: fr.args.aStart + fr.vars.midi + 1, aLen: fr.args.aLen - fr.vars.midi- 1, bStart: fr.args.bStart + fr.vars.minj, bLen: fr.args.bLen - fr.vars.minj, tb: 0, te: fr.args.te}, fr.vars);
	 endaction
   endrule
   
   rule gc6 (fr.pc == GCS6);
      $display("GSC6");
      fr.doreturn();
   endrule

   rule hccomplete (fr.pc == GCSComplete);
      $display("GSCComplete, result size %d", outcounter);
      fr.nextpc(GCSIdle);
   endrule
   
   method Action setupA(Bit#(14) start, Bit#(14) length);
      $display("GotohC setupA %d %d", start, length);
      aStartReg <= start;
      aLenReg <= length;
   endmethod
   
   method Action setupB(Bit#(14) start, Bit#(14) length);
      $display("GotohC setupB %d %d", start, length);
      bStartReg <= start;
      bLenReg <= length;
   endmethod

   method Bit#(14) result();
      return(outcounter);
   endmethod

   
   interface FSM fsm;
      method Action start();
         $display("GotohC running aLen %d bLen %d", aLenReg, bLenReg);
	 fr.docall(GCS1, GCSComplete, CArgs{aStart: 0, aLen: aLenReg,
	    bStart: 0, bLen: bLenReg, tb: initialG, te: initialG}, CVars {midi: 0, minj: 0, mintype: 1});
      endmethod
      method Bool done();
	 return(fr.pc == GCSIdle);
      endmethod
      method Action waitTillDone();
      endmethod
      method Action abort();
      endmethod
   endinterface: fsm

endmodule
