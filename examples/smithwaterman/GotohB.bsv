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

interface GotohAlgorithm;
   method Action setupA (Bit#(14) start, Bit#(14) length);
   method Action setupB (Bit#(14) start, Bit#(14) length);
   method Action setupG (Bit#(16) g);
   method Action setupCC (Bit#(14) start);
   method Action setupDD (Bit#(14) start);
   method Bit#(14) result();
   interface FSM fsm;
endinterface


module mkGotohB#(BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strA, BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strB, BRAMServer#(Bit#(lIndexWidth), Bit#(16)) matCC, BRAMServer#(Bit#(lIndexWidth), Bit#(16)) matDD, int dir)(GotohAlgorithm)
         provisos(Add#(0, 14, strIndexWidth),
	       Add#(0, 14, lIndexWidth));


   Bit#(16) initialH = 1;
   Bit#(16) initialG = 4;
   Reg#(Bit#(14)) aStartReg <- mkReg(0);
   Reg#(Bit#(14)) bStartReg <- mkReg(0);
   Reg#(Bit#(14)) ccStartReg <- mkReg(0);
   Reg#(Bit#(14)) ddStartReg <- mkReg(0);
   Reg#(Bit#(14)) aLenReg <- mkReg(0);
   Reg#(Bit#(14)) bLenReg <- mkReg(0);
   Reg#(Bit#(14)) ii <- mkReg(0);
   Reg#(Bit#(14)) jj <- mkReg(0);
   Reg#(Bit#(8)) aData <- mkReg(0);
   Reg#(Bit#(8)) bData <- mkReg(0);
   Reg#(Bit#(16)) vd <- mkReg(0);
   Reg#(Bit#(16)) vc <- mkReg(0);
   Reg#(Bit#(16)) ve <- mkReg(0);
   Reg#(Bit#(16)) vs <- mkReg(0);
   Reg#(Bit#(16)) vt <- mkReg(0);
   Reg#(Bit#(16)) ccData <- mkReg(0);
   Reg#(Bit#(16)) ddData <- mkReg(0);
   Reg#(Bit#(16)) wdata <- mkReg(0);
   Reg#(Bit#(16)) argt <- mkReg(0);
   
  Stmt gotohB =
   seq
      $display("gotohB running %d %d %d %d dir %d",
	 aStartReg, aLenReg, bStartReg, bLenReg, dir);
      
      /* initialize arrays */
      vt <= initialG + initialH;
      jj<= 1;
      while (jj <= bLenReg)
	 seq
	    action
	       matCC.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ccStartReg + zeroExtend(jj), datain: vt});
	       matDD.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ddStartReg + zeroExtend(jj), datain: vt + initialG});
	       vt <= vt + initialH;
	       jj <= jj + 1;
	    endaction
	 endseq
      action
	 ve <= 0;
	 vc <= 0;
	 vs <= 0;
	 matCC.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ccStartReg, datain: 0});
	 matDD.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ddStartReg, datain: 0});
      endaction
      
      
      vt <= argt; /* Use passed-in value here */
      /* Loop through string a */
      ii <= 1;
      while (ii <= aLenReg)
	 seq
	    $display("gotohB ii = %d", ii);
	    /* read string A */
	    action
	       let idx = ?;
	       if (dir == 1)
		  idx = aStartReg + ii - 1;  // 0 to aLen - 1
	       else
		  idx = aStartReg + aLenReg - ii;  // aLen-1 downto 0
	       strA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: idx, datain: ?});
	    endaction
	    action
	       let tmp <- strA.response.get(); /* read a[i] */
	       aData <= tmp;
	    endaction
	    /* s = CC[0] */
	    matCC.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ccStartReg + 0, datain: ?});
       	    action
	       let tmp <- matCC.response.get();
	       vs <= tmp;
	    endaction
	    
	    action
	       let newt = vt + initialH;
	       vc <= newt;   /* c = t + i * h */
	       vt <= newt;
	       matCC.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ccStartReg + 0, datain: newt}); /* CC[0] = c */
	       matDD.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ddStartReg + 0, datain: newt}); /* DD[0] = CC[0] */
	       ve <= newt + initialG;
	       jj <= 1;
	    endaction


	    /* Loop through string B */
	    while (jj <= bLenReg)
	       seq
		  $display("gotohB jj = %d", jj);
		  ve <= min (ve, vc + initialG) + initialH;
		  /* read CC[j] and DD[j] */
		  matCC.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ccStartReg + jj, datain: ?});
		  matDD.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ddStartReg + jj, datain: ?});
		  action
		     let tmpcc <- matCC.response.get();
		     let tmpdd <- matDD.response.get();
		     ccData <= tmpcc;
		     ddData <= tmpdd;
		  endaction
		  /* read bData */
		  action
		     let idx = ?;
		     if (dir == 1)
			idx = bStartReg + jj - 1;  /* b[0] tp b[m-1] */
		     else
			idx = bStartReg + bLenReg - jj; /* b[m-1] downto b[0] */
		     strB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: idx, datain: ?});
		  endaction
		  action
		     let tmp <- strB.response.get();
		     bData <= tmp;
		  endaction
		  if (aData == bData)
		     wdata <= 0;
		  else
		     wdata <= 2;
		  
		  action
		     let newdd = min(ddData, ccData + initialG) + initialH;
		     matDD.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ddStartReg + jj, datain: newdd});
		     vc <= min(newdd, min(ve, vs + wdata));
		  endaction
		  vs <= ccData;
		  matCC.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ccStartReg + jj, datain: vc});
		  jj <= jj + 1;
	       endseq
	    ii <= ii + 1;
	 endseq
   endseq;

   FSM hB <- mkFSM(gotohB);
   
   method Action setupA(Bit#(14) start, Bit#(14) length);
      aStartReg <= start;
      aLenReg <= length;
   endmethod
   
   method Action setupB(Bit#(14) start, Bit#(14) length);
      bStartReg <= start;
      bLenReg <= length;
   endmethod

   method Action setupG(Bit#(16) g);
      argt <= g;
   endmethod

   method Action setupCC(Bit#(14) start);
      ccStartReg <= start;
   endmethod

   method Action setupDD(Bit#(14) start);
      ddStartReg <= start;
   endmethod

   method Bit#(14) result();
      return(zeroExtend(bLenReg));
   endmethod
   
   interface FSM fsm = hB;

endmodule
