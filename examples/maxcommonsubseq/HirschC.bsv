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
import MCSAlgorithm::*;

/* frame arguments */
typedef struct {
   Bit#(7) aStart;
   Bit#(7) bStart;
   Bit#(7) aLen;
   Bit#(7) bLen;
   } CArgs deriving(Bits);

typedef struct {
   Bit#(7) midi;
   Bit#(7) maxj;
   } CVars deriving(Bits);

typedef enum {HCSIdle, HCS1, HCS2, HCSComplete} HCState deriving (Bits, Eq);

module mkHirschC#(BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strA, BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strB, BRAMServer#(Bit#(lIndexWidth), Bit#(16)) matL, MCSAlgorithm chirschB0,  MCSAlgorithm chirschB1, BRAMServer#(Bit#(lIndexWidth)) l0, BRAMServer#(Bit#(lIndexWidth)) l1)(MCSAlgorithm)
         provisos(Add#(0, 7, strIndexWidth),
	       Add#(0, 14, lIndexWidth));

      /* pc, args, vars */
   StackReg#(128, FSState, CArgs, CVars) fr <- mkStackReg(128, HCSIDLE);


   Reg#(Bit#(7)) aStartReg <- mkReg(0);
   Reg#(Bit#(7)) bStartReg <- mkReg(0);
   Reg#(Bit#(14)) rStartReg <- mkReg(0);
   Reg#(Bit#(7)) aLenReg <- mkReg(0);
   Reg#(Bit#(7)) bLenReg <- mkReg(0);
   Reg#(Bit#(7)) ii <- mkReg(0);
   Reg#(Bit#(7)) jj <- mkReg(0);
   Reg#(Bit#(8)) aData <- mkReg(0);
   Reg#(Bit#(8)) bData <- mkReg(0);
   Reg#(Bit#(14)) outcounter <- mkReg(0);

/*
 * HirschC(Astart, Alen, Bstart, Blen, output fifo)
 * implicit A storage, B storage
 * 
 */
   
  // This FSM searches string B looking for the first char of string A
   Stmt hirschC2stmt =
   seq
      $display("hirschC running ");
      // read A[0]
      strA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: fr.args.aStart, datain: ?});
      action
	 let tmp <- strA.response.get();
	 aData <= tmp;
      endaction
      // scan for it in B
      for (jj <= 0; jj < fr.args.bLen; jj <= jj + 1)
	 seq
	    strB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: bstart + jj, datain: ?});
	    action
	       let tmp <- strB.response.get();
	       bData <= tmp;
	    endaction
	    if (aData == bData)
	       seq
		  matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: outcounter, datain: aData});
		  outcounter <= outcounter + 1;
		  break;
	       endseq
	 endseq
      fr.nextpc(HCSComplete);
   endseq;

   FSM hC2fsm <- mkFSM(hirschC2Stmt);
   
   // AlgC step 1, 2, and 3
   rule hc1 (fr.pc == HCS1);
      $display("HCS1 aStart %d aLen %d bStart %d bLen %d", fr.args.aStart, fr.args.aLen, fr.args.bStart, fr.args.bLen);
      if (fr.args.bLen == 0)
	doreturn();
     else if (fr.args.aLen == 1)
	begin
	   hc2fsm.start();
	   fr.nextpc(HCS2);
	end
     else
	action
	   let midi = fr.aLen >> 1;
	   fr.vars.midi <= midi;
	   chirschB0.setupA(fr.args.aStart, midi);
	   chirschB0.setupB(fr.args.bStart, fr.args.bLen);
	   chirschB1.setupA(fr.args.aStart+midi, fr.args.aLen - midi);
	   chirschB1.setupB(fr.args.bStart, fr.args.bLen);
	   chirschB0.start();
	   chirschB1.start();
	   fr.nextPC(HCS3);
	endaction
   endrule
   
   // This FSM searches the results of the two calls to HirschB
   Stmt hirschC4Stmt =
   seq
      maxjvalue <= 0;
      for (jj <= 0; jj <= fr.args.bLen; jj <= jj + 1)
	 seq
	    l0.request.put(BRAMRequest{write: False, responseOnWrite: False, address: jj, datain: ?});
	    l1.request.put(BRAMRequest{write: False, responseOnWrite: False, address: fr.args.bLen - jj, datain: ?});
	    action
	       let t1 <- lo.response.get();
	       let t2 <- l1.response.get();
	       if ((t1 + t2) > maxjvalue)
		  action
		     maxjvalue <= t1 + t2;
		     fr.vars.maxj <= jj;
		  endaction
	    endaction
	 endseq
      
      fr.docall(HCS1, HCS5, CArgs {aStart: fr.args.aStart, aLen: fr.vars.midi, bStart: fr.args.bStart, bLen: fr.vars.maxj}, fr.vars);
   endseq

   FSM hc4fsm <- mkFSM(hirschC4Stmt);
   
   rule hc3 (fr.pc == HCS3 && chirschB0.done() && chirschB1.done);
      hc4fsm.start();
      fr.nextPC(HCS4);
   endrule
   
   rule hc5 (fr.pc == HCS5);
      fr.docall(HCS1, HCS6, CArgs{aStart: fr.args.aStart + fr.vars.midi, aLen: fr.args.aLen - fr.vars.midi, bStart: fr.args.bStart + fr.vars.maxj, bLen: fr.args.bLen - fr.vars.maxj}, fr.vars);
   endrule
   
   rule hc6 (fr.pc == HCS6);
      fr.doreturn();
   endrule
   
   method Action setupA(Bit#(7) start, Bit#(7) length);
      aStartReg <= start;
      aLenReg <= length;
   endmethod
   
   method Action setupB(Bit#(7) start, Bit#(7) length);
      bStartReg <= start;
      bLenReg <= length;
   endmethod

   method Action setupL(Bit#(14) start);
      rStartReg <= start;
   endmethod

   method Action start();
      docall(HCS1, HCSComplere, {aStart: 0, aLen: aLenReg,
	 bStart: 0, bLen: bLenReg}, {0, 0})
   endmethod
   
   interface FSM fsm = hC;

endmodule
