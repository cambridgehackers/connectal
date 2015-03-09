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

module mkHirschB#(BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strA, BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strB, BRAMServer#(Bit#(lIndexWidth), Bit#(16)) matL, int dir)(MCSAlgorithm)
         provisos(Add#(0, 14, strIndexWidth),
	       Add#(0, 14, lIndexWidth));


   Reg#(Bit#(14)) aStartReg <- mkReg(0);
   Reg#(Bit#(14)) bStartReg <- mkReg(0);
   Reg#(Bit#(14)) rStartReg <- mkReg(0);
   Reg#(Bit#(14)) aLenReg <- mkReg(0);
   Reg#(Bit#(14)) bLenReg <- mkReg(0);
   Reg#(Bit#(14)) ii <- mkReg(0);
   Reg#(Bit#(14)) jj <- mkReg(0);
   Reg#(Bit#(8)) aData <- mkReg(0);
   Reg#(Bit#(8)) bData <- mkReg(0);
   Reg#(Bit#(16)) k1j <- mkReg(0);
   Reg#(Bit#(16)) k1jm1 <- mkReg(0);
   Reg#(Bit#(16)) k0j <- mkReg(0);
   Reg#(Bit#(16)) k0jm1 <- mkReg(0);
   BRAM1Port#(Bit#(lIndexWidth), Bit#(16)) k0  <- mkBRAM1Server(defaultValue);

/* The original algorithm B uses two vectors K0 and K1 to store two rows of the full L
 * matrix from algoritm A.  For any particular iteration, K[0][j-1] K[0][j]
 * and K[1][j-1] are used to compute K[1][j]
 * 
 * Each cycle, K[1] is copied to K[0], and then a new K[1] is computed.  First, the
 * the previous K[0][j] is copied to K[0][j-1] and the previous K[1][j] is copied to
 * K[1][j-1].  Then a new K[1][j] is computed.
 * 
 * In the revised version, a single vector is used, plus auxiliary registers.
 * First the old K[0][j] auxiliary is copied to K[0][j-1] and the K[1][j] auxiliary
 * is copied to K[1][j-1].  Then K[0][j] is read. Then K[1][j] is computed <and written> to
 * K[0][j].  When the row is finished, K[0] is effectively K[1]
 *  
 */
   
  Stmt hirschB =
   seq
      jj <= 17;  // one cycle delay to permit the control registers to get set
      //$display("hirschB running %d %d %d %d dir %d",
	// aStartReg, aLenReg, bStartReg, bLenReg, dir);
      /* initialize K1 (stored in lMat) of temporary storage */
      for (jj <= 0; jj <= bLenReg; jj <= jj + 1)
	 seq
	    matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: rStartReg + zeroExtend(jj), datain: 0});
	 endseq
      /* Loop through string a */
      for (ii <= 1; ii <= aLenReg; ii <= ii + 1)
	 seq
	    //$display("hirschB ii = %d", ii);
	    par
	       /* initialize pipelining */
	       jj <= 1;
	       k0j <= 0;
	       k1j <= 0;
	       action
		  let idx = ?;
		  if (dir == 1)
		     idx = aStartReg + ii - 1;  // 0 to aLen - 1
		  else
		     idx = aStartReg + aLenReg - ii;  // aLen-1 downto 0
		  strA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: idx, datain: ?});
	       endaction
	       /* Read b[j] */
	       action
		  let idx = ?;
		  if (dir == 1)
		     idx = bStartReg;
		  else
		     idx = bStartReg + bLenReg - 1;
		  strB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: idx, datain: ?});
	       endaction
	       /* start read of k0j */
	       matL.request.put(BRAMRequest{write: False, responseOnWrite: False, address: rStartReg + 1, datain: ?});
	    endpar
	    action
	       let ta <- strA.response.get(); /* read a[i] */
	       aData <= ta;
	    endaction

	    /* Loop through string B */
	    while (jj <= bLenReg)
	       seq
		  //$display("hirschB jj = %d", jj);
		  action
		     let tb <- strB.response.get();
		     let tk <- matL.response.get();
		     k0jm1 <= k0j;  /* pipeline from previous cycle */
		     k1jm1 <= k1j;
		     bData <= tb;   /* read b[j] from bram */
		     k0j <= tk;     /* read k[0][j] from bram */
		     matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: rStartReg + zeroExtend(jj-1), datain: k1j});
		  endaction
		  //$display("hirschB ii %d jj %d A %h B %h k1j", ii, jj, aData, bData, k1j);
		  action
		     let tmp = ?;
		     /* Read b[j] */
		     /* if backwards B[bStartReg + bLenReg - jj] */
		     action
			let idx = ?;
			if (dir == 1)
			   idx = bStartReg + jj;
			else
			   idx = bStartReg + bLenReg - jj - 1;
			strB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: idx, datain: ?});
		     endaction
		     if (aData == bData)
			tmp = k0jm1 + 1;
		     else
		        tmp = max(k0j,k1jm1);
		     k1j <= tmp;
		     jj <= jj + 1;
		     /* start read of k0j */
		     matL.request.put(BRAMRequest{write: False, responseOnWrite: False, address: rStartReg + zeroExtend(jj+1), datain: ?});
		  endaction
		  //$display("     L[%d][%d] = %d ", ii, jj, k1j);
	       endseq
	    action
	       let tb <- strB.response.get();
	       let tk <- matL.response.get();
	       matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: rStartReg + zeroExtend(jj-1), datain: k1j});
	    endaction
	 endseq
   endseq;

   FSM hB <- mkFSM(hirschB);
   
   method Action setupA(Bit#(14) start, Bit#(14) length);
      aStartReg <= start;
      aLenReg <= length;
   endmethod
   
   method Action setupB(Bit#(14) start, Bit#(14) length);
      bStartReg <= start;
      bLenReg <= length;
   endmethod

   method Action setupL(Bit#(14) start);
      rStartReg <= start;
   endmethod

   method Bit#(14) result();
      return(zeroExtend(bLenReg));
   endmethod
   
   interface FSM fsm = hB;

endmodule
