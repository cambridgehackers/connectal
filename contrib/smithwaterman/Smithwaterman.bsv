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


import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import StmtFSM::*;
import BRAM::*;
import Connectable::*;
import ConnectalMemTypes::*;
import DmaUtils::*;
import Dma2BRAM::*;

// algorithm
import GotohB::*;
import GotohC::*;

interface SmithwatermanRequest;
   method Action setupA(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
   method Action setupB(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
   method Action start(Bit#(32) alg);
endinterface

interface SmithwatermanIndication;
   method Action searchResult(Bit#(32) v);
   method Action setupAComplete(); 
   method Action setupBComplete(); 
endinterface

typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 16384 MaxStringLen;
typedef 16384 MaxFetchLen;
typedef TLog#(MaxStringLen) StringIdxWidth;
typedef Bit#(StringIdxWidth) StringIdx;
typedef TLog#(MaxFetchLen) LIdxWidth;
typedef Bit#(LIdxWidth) LIdx;

module mkSmithwatermanRequest#(SmithwatermanIndication indication,
			MemReadServer#(busWidth)   setupA_read_server,
			MemReadServer#(busWidth)   setupB_read_server)(SmithwatermanRequest)
   
   provisos(Add#(a__, 8, busWidth),
	    Div#(busWidth,8,nc),
	    Mul#(nc,8,busWidth),
	    Add#(1, b__, nc),
	    Add#(c__, 32, busWidth),
	    Add#(1, d__, TDiv#(busWidth, 32)),
	    Mul#(TDiv#(busWidth, 32), 32, busWidth),
            Mul#(TDiv#(busWidth, 16), 16, busWidth),
            Add#(1, e__, TDiv#(busWidth, 16)),
            Add#(1, f__, TMul#(2, TDiv#(busWidth, 16))),
            Add#(TDiv#(busWidth, 16), g__, TMul#(2, TDiv#(busWidth, 16))));

   
  Reg#(Bit#(14)) aLenReg <- mkReg(0);
  Reg#(Bit#(14)) bLenReg <- mkReg(0);
  Reg#(Bit#(14)) rLenReg <- mkReg(0);
   BRAM2Port#(StringIdx, Bit#(8)) strA  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(StringIdx, Bit#(8)) strB <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) cc <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) dd <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) rr <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) ss <- mkBRAM2Server(defaultValue);

   BRAMReadClient#(StringIdxWidth,busWidth) n2a <- mkBRAMReadClient(strA.portB);
   mkConnection(n2a.dmaClient, setupA_read_server);
   BRAMReadClient#(StringIdxWidth,busWidth) n2b <- mkBRAMReadClient(strB.portB);
   mkConnection(n2b.dmaClient, setupB_read_server);

   
   Reg#(Bool) gotohCRunning <- mkReg(False);

   GotohAlgorithm cgotohB1 <- mkGotohB(strA.portA, strB.portA, cc.portA, dd.portA, 1);
   GotohAlgorithm cgotohB0 <- mkGotohB(strA.portA, strB.portA, rr.portA, ss.portA, 0);
   SWAlgorithm gotohC <- mkGotohC(strA.portA, strB.portA, cgotohB0, cgotohB1, cc.portB, dd.portB, rr.portB, ss.portB);
   // create BRAM Write client for matL

   rule finish_setupA;
      $display("finish setupA");
      let x <- n2a.finish;
      indication.setupAComplete();
   endrule

   rule finish_setupB;
      $display("finish setupB");
      let x <- n2b.finish;
      indication.setupBComplete();
   endrule

   rule gotohC_completion (gotohCRunning && gotohC.fsm.done);
      gotohCRunning <= False;
      indication.searchResult(pack(zeroExtend(gotohC.result())));
      endrule
   
   
   method Action setupA(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
      aLenReg <= truncate(strLen);
      $display("setupA %h %h %d", strPointer, strOffset, strLen);
      n2a.start(strPointer, 0, pack(truncate(strOffset)), pack(truncate(strOffset + strLen-1)));
      gotohC.setupA(truncate(strOffset), pack(truncate(strLen)));
   endmethod

   method Action setupB(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
      bLenReg <= truncate(strLen);
      $display("setupB %h %h %d", strPointer, strOffset, strLen);
      n2b.start(strPointer, 0, pack(truncate(strOffset)), pack(truncate(strOffset + strLen-1)));
      gotohC.setupB(truncate(strOffset), pack(truncate(strLen)));
   endmethod
   

   method Action start(Bit#(32) alg);
      $display ("start %d", alg);
      case (alg) 
	 3: begin
	       gotohC.fsm.start();
	       gotohCRunning <= True;
	    end
      endcase
   endmethod

endmodule
