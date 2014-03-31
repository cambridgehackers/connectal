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

module mkHirschB#(BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strA, BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strB, BRAMServer#(Bit#(lIndexWidth), Bit#(16)) matL)(MCSAlgorithm)
         provisos(Add#(0, 7, strIndexWidth),
	       Add#(0, 14, lIndexWidth));


    Reg#(Bit#(7)) aLenReg <- mkReg(0);
  Reg#(Bit#(7)) bLenReg <- mkReg(0);
  Reg#(Bit#(14)) rLenReg <- mkReg(0);
  Reg#(Bit#(7)) ii <- mkReg(0);
  Reg#(Bit#(7)) jj <- mkReg(0);
   Reg#(Bit#(8)) aData <- mkReg(0);
   Reg#(Bit#(8)) bData <- mkReg(0);
   Reg#(Bit#(16)) k1j <- mkReg(0);
   Reg#(Bit#(16)) k1jm1 <- mkReg(0);
  Reg#(Bit#(16)) k0j <- mkReg(0);
  Reg#(Bit#(16)) k0jm1 <- mkReg(0);

  Stmt hirschB =
   seq
      $display("hirschB running ");
      /* initialize two rows of temporary storage */
      for (jj <= 0; jj < aLenReg; jj <= jj + 1)
	 seq
	    matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {0,jj}, datain: 0});
	    matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {1,jj}, datain: 0});
	 endseq
      /* Loop through string a */
      for (ii <= 1; ii <= aLenReg; ii <= ii + 1)
	 seq
	    //$display("hirschB ii = %d", ii);
	    /* Copy L[1] to L[0].  could pingpong instead, or unroll loop */
	    /* L[1] is stored in matL[0] and L[0] is stored in matL[1] so that the result is in the right place at the end */
	    for (jj <= 0; jj <= bLenReg; jj <= jj + 1)
	       seq
		  matL.request.put(BRAMRequest{write: False, responseOnWrite: False, address: {0,jj}, datain: 0});
		  action
		     let ta <- matL.response.get();
		     matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {1,jj}, datain: ta});
		  endaction
	       endseq
	    /* initialize pipelining */
	    k0j <= 0;
	    k1j <= 0;
	    /* Loop through string B */
	    for (jj <= 1; jj <= bLenReg; jj <= jj + 1)
	       seq
		  action
		     /* Read a[i] and b[j] */
		     strA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ii-1, datain: 0});
		     strB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: jj-1, datain: 0});
		     k0jm1 <= k0j;  /* pipeline from previous cycle */
		     k1jm1 <= k1j;
		     /* start read of k0j */
		     matL.request.put(BRAMRequest{write: False, responseOnWrite: False, address: {1,jj}, datain: 0});
		  endaction
		  action
		     let ta <- strA.response.get();
		     let tb <- strB.response.get();
		     let tk <- matL.response.get();
		     aData <= ta;
		     bData <= tb;
		     k0j <= tk;
		  endaction
		  /* $display("hirschB ii %d jj %d A %d B %d", ii, jj, aData, bData);	*/
		  if (aData == bData)
		     action
			k1j <= k0jm1 + 1;
			/*$display("   EQ L[%d][%d] = %d", ii, jj, ta+1); */
		     endaction
		  else
		     action
			let tmax = max(k0j,k1jm1);
			//$display("     L[%d][%d] = %d = max(%d, %d)", ii, jj, tmax, k0j, k1jm1);
			k1j <= tmax;
		     endaction
		  matL.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {0,jj}, datain: k1j});
		  
	       endseq
	 endseq
   endseq;

   FSM hB <- mkFSM(hirschB);
   
   method Action setupA(Bit#(7) strLen);
      aLenReg <= strLen;
   endmethod
   
   method Action setupB(Bit#(7) strLen);
      bLenReg <= strLen;
   endmethod

   interface FSM fsm = hB;

endmodule
