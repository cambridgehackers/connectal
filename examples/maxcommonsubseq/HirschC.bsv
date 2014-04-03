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

module mkHirschC#(BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strA, BRAMServer#(Bit#(strIndexWidth), Bit#(8)) strB, BRAMServer#(Bit#(lIndexWidth), Bit#(16)) matL, int dir)(MCSAlgorithm)
         provisos(Add#(0, 7, strIndexWidth),
	       Add#(0, 14, lIndexWidth));


   Reg#(Bit#(7)) aStartReg <- mkReg(0);
   Reg#(Bit#(7)) bStartReg <- mkReg(0);
   Reg#(Bit#(14)) rStartReg <- mkReg(0);
   Reg#(Bit#(7)) aLenReg <- mkReg(0);
   Reg#(Bit#(7)) bLenReg <- mkReg(0);
   Reg#(Bit#(7)) ii <- mkReg(0);
   Reg#(Bit#(7)) jj <- mkReg(0);
   Reg#(Bit#(8)) aData <- mkReg(0);
   Reg#(Bit#(8)) bData <- mkReg(0);
   Reg#(Bit#(16)) k1j <- mkReg(0);
   Reg#(Bit#(16)) k1jm1 <- mkReg(0);
   Reg#(Bit#(16)) k0j <- mkReg(0);
   Reg#(Bit#(16)) k0jm1 <- mkReg(0);
   BRAM1Port#(Bit#(lIndexWidth), Bit#(16)) k0  <- mkBRAM1Server(defaultValue);

/*
 * HirschC(Astart, Alen, Bstart, Blen, output fifo)
 * implicit A storage, B storage
 * 
 */
  Stmt hirschC =
   seq
      $display("hirschC running ");

   endseq;

   FSM hC <- mkFSM(hirschC);
   
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

   
   interface FSM fsm = hC;

endmodule
