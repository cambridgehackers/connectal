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
import MCSAlgorithm::*;
import ConnectalMemTypes::*;
import DmaUtils::*;
import Dma2BRAM::*;

// algorithm
import HirschA::*;
import HirschB::*;
import HirschC::*;


/* This module solves the maximum common subsequence problem.
 * It finds the longest subsequence of characters present in both input strings
 * the subsequence does not have to be contiguous and the characters can have different locations
 * and offsets in the two strings, just so long as they occur in the same order
 *
 *  To initialize, load string A with request setupA, and wait for indication setup complete
 * Then load string B with request setupB, and wait for indication setup complete
 * To start the unit, signal start, and wait for searchResult, which will tell you the length
 * To retreive the result, use fetch and wait for fetchComplete
 */

/* First pass implements Hirschberg Algorithm A and the fetch call returns the L matrix
 */
interface MaxcommonsubseqRequest;
   method Action setupA(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
   method Action setupB(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
   method Action fetch(Bit#(32) strPointer, Bit#(32) dest, Bit#(32) src, Bit#(32) strLen);
   method Action start(Bit#(32) alg);
endinterface

interface MaxcommonsubseqIndication;
   method Action searchResult(Bit#(32) v);
   method Action setupAComplete(); 
   method Action setupBComplete(); 
   method Action fetchComplete(); 
endinterface

typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 16384 MaxStringLen;
typedef 16384 MaxFetchLen;
typedef TLog#(MaxStringLen) StringIdxWidth;
typedef Bit#(StringIdxWidth) StringIdx;
typedef TLog#(MaxFetchLen) LIdxWidth;
typedef Bit#(LIdxWidth) LIdx;

module mkMaxcommonsubseqRequest#(MaxcommonsubseqIndication indication,
			MemReadServer#(busWidth)   setupA_read_server,
			MemReadServer#(busWidth)   setupB_read_server,
			MemWriteServer#(busWidth)   fetch_write_server )(MaxcommonsubseqRequest)
   
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
            Add#(1, h__, busWidth),
            Add#(TDiv#(busWidth, 16), g__, TMul#(2, TDiv#(busWidth, 16))));

   
  Reg#(Bit#(14)) aLenReg <- mkReg(0);
  Reg#(Bit#(14)) bLenReg <- mkReg(0);
  Reg#(Bit#(14)) rLenReg <- mkReg(0);
   BRAM2Port#(StringIdx, Bit#(8)) strA  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(StringIdx, Bit#(8)) strB <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) matL0 <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) matL1 <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) matL <- mkBRAM2Server(defaultValue);

   BRAMReadClient#(StringIdxWidth,busWidth) n2a <- mkBRAMReadClient(strA.portB);
   mkConnection(n2a.dmaClient, setupA_read_server);
   BRAMReadClient#(StringIdxWidth,busWidth) n2b <- mkBRAMReadClient(strB.portB);
   mkConnection(n2b.dmaClient, setupB_read_server);
   BRAMWriteClient#(LIdxWidth, busWidth) l2n <- mkBRAMWriteClient(matL.portB);
   mkConnection(l2n.dmaClient, fetch_write_server);


   Reg#(Bool) hirschARunning <- mkReg(False);
   Reg#(Bool) hirschB0Running <- mkReg(False);
   Reg#(Bool) hirschB1Running <- mkReg(False);
   Reg#(Bool) hirschCRunning <- mkReg(False);

   MCSAlgorithm hirschA <- mkHirschA(strA.portA, strB.portA, matL.portA);
   MCSAlgorithm hirschB1 <- mkHirschB(strA.portA, strB.portA, matL.portA, 1);
   MCSAlgorithm hirschB0 <- mkHirschB(strA.portA, strB.portA, matL.portA, 0);
   MCSAlgorithm chirschB1 <- mkHirschB(strA.portA, strB.portA, matL0.portA, 1);
   MCSAlgorithm chirschB0 <- mkHirschB(strA.portA, strB.portA, matL1.portA, 0);
   MCSAlgorithm hirschC <- mkHirschC(strA.portA, strB.portA, matL.portA, chirschB0, chirschB1, matL0.portB, matL1.portB);
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

   rule finish_fetch;
      $display("finish fetch");
      let x <- l2n.finish;
      indication.fetchComplete();
   endrule

   rule hirschA_completion (hirschARunning && hirschA.fsm.done);
      hirschARunning <= False;
      indication.searchResult(pack(zeroExtend(hirschA.result())));
      endrule
   
   rule hirschB0_completion (hirschB0Running && hirschB0.fsm.done);
      hirschB0Running <= False;
      indication.searchResult(pack(zeroExtend(hirschB0.result())));
      endrule
   
   rule hirschB1_completion (hirschB1Running && hirschB1.fsm.done);
      hirschB1Running <= False;
      indication.searchResult(pack(zeroExtend(hirschB1.result())));
      endrule
   
   rule hirschC_completion (hirschCRunning && hirschC.fsm.done);
      hirschCRunning <= False;
      indication.searchResult(pack(zeroExtend(hirschC.result())));
      endrule
   
   
   method Action setupA(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
      aLenReg <= truncate(strLen);
      $display("setupA %h %h %d", strPointer, strOffset, strLen);
      n2a.start(strPointer, 0, pack(truncate(strOffset)), pack(truncate(strOffset + strLen-1)));
      hirschA.setupA(truncate(strOffset), pack(truncate(strLen)));
      hirschB0.setupA(truncate(strOffset), pack(truncate(strLen)));
      hirschB1.setupA(truncate(strOffset), pack(truncate(strLen)));
      hirschC.setupA(truncate(strOffset), pack(truncate(strLen)));
   endmethod

   method Action setupB(Bit#(32) strPointer, Bit#(32) strOffset, Bit#(32) strLen);
      bLenReg <= truncate(strLen);
      $display("setupB %h %h %d", strPointer, strOffset, strLen);
      n2b.start(strPointer, 0, pack(truncate(strOffset)), pack(truncate(strOffset + strLen-1)));
      hirschA.setupB(truncate(strOffset), pack(truncate(strLen)));
      hirschB0.setupB(truncate(strOffset), pack(truncate(strLen)));
      hirschB1.setupB(truncate(strOffset), pack(truncate(strLen)));
      hirschC.setupB(truncate(strOffset), pack(truncate(strLen)));
   endmethod
   
   method Action fetch(Bit#(32) strPointer, Bit#(32) dest, Bit#(32) src, Bit#(32) strLen);
      //rLenReg <= truncate(strLen);
      $display("fetch %h %h %h %h", strPointer, dest, src, strLen);
      let bram_start_idx = pack(truncate(src));
      let bram_finish_idx = bram_start_idx+pack(truncate(strLen-1));
      l2n.start(strPointer, zeroExtend(dest), bram_start_idx, bram_finish_idx);
   endmethod

   method Action start(Bit#(32) alg);
      $display ("start %d", alg);
      case (alg) 
	 0: begin
	       hirschA.setupL(0);
	       hirschA.fsm.start();
	       hirschARunning <= True;
	    end
	 1: begin
	       hirschB1.fsm.start();
	       hirschB1.setupL(0);
	       hirschB1Running <= True;
	    end
	 2: begin
	       hirschB0.fsm.start();
	       hirschB0.setupL(0);
	       hirschB0Running <= True;
	    end
	 3: begin
	       hirschC.setupL(0);
	       hirschC.fsm.start();
	       hirschCRunning <= True;
	    end
      endcase
   endmethod

endmodule
