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
//import Vector::*;
import BRAM::*;
//import Gearbox::*;
import Connectable::*;
import MCSAlgorithm::*;

//import AxiMasterSlave::*;
import Dma::*;
import DmaUtils::*;
import Dma2BRAM::*;

// algorithm
import HirschA::*;
import HirschB::*;


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
   method Action setupA(Bit#(32) strPointer, Bit#(32) strLen);
   method Action setupB(Bit#(32) strPointer, Bit#(32) strLen);
   method Action fetch(Bit#(32) strPointer, Bit#(32) dest, Bit#(32) src, Bit#(32) strLen);
   method Action start(Bit#(32) alg);
endinterface

interface MaxcommonsubseqIndication;
   method Action searchResult(Int#(32) v);
   method Action setupAComplete(); 
   method Action setupBComplete(); 
   method Action fetchComplete(); 
endinterface

typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 128 MaxStringLen;
typedef 16384 MaxFetchLen;
typedef TLog#(MaxStringLen) StringIdxWidth;
typedef Bit#(StringIdxWidth) StringIdx;
typedef TLog#(MaxFetchLen) LIdxWidth;
typedef Bit#(LIdxWidth) LIdx;

module mkMaxcommonsubseqRequest#(MaxcommonsubseqIndication indication,
			DmaReadServer#(busWidth)   setupA_read_server,
			DmaReadServer#(busWidth)   setupB_read_server,
			DmaWriteServer#(busWidth)   fetch_write_server )(MaxcommonsubseqRequest)
   
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

   
  Reg#(Bit#(7)) aLenReg <- mkReg(0);
  Reg#(Bit#(7)) bLenReg <- mkReg(0);
  Reg#(Bit#(14)) rLenReg <- mkReg(0);
  Reg#(Bit#(7)) ii <- mkReg(0);
  Reg#(Bit#(7)) jj <- mkReg(0);
   Reg#(Bit#(8)) aData <- mkReg(0);
   Reg#(Bit#(8)) bData <- mkReg(0);
   Reg#(Bit#(16)) lim1jm1 <- mkReg(0);
   Reg#(Bit#(16)) lim1j <- mkReg(0);
   Reg#(Bit#(16)) lijm1 <- mkReg(0);
   BRAM2Port#(StringIdx, Bit#(8)) strA  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(StringIdx, Bit#(8)) strB <- mkBRAM2Server(defaultValue);
   BRAM2Port#(LIdx, Bit#(16)) matL <- mkBRAM2Server(defaultValue);

   BRAMReadClient#(StringIdxWidth,busWidth) n2a <- mkBRAMReadClient(strA.portB);
   mkConnection(n2a.dmaClient, setupA_read_server);
   BRAMReadClient#(StringIdxWidth,busWidth) n2b <- mkBRAMReadClient(strB.portB);
   mkConnection(n2b.dmaClient, setupB_read_server);
   BRAMWriteClient#(LIdxWidth, busWidth) l2n <- mkBRAMWriteClient(matL.portB);
   mkConnection(l2n.dmaClient, fetch_write_server);

   FIFOF#(void) aReady <- mkFIFOF;
   FIFOF#(void) bReady <- mkFIFOF;
   FIFOF#(void) mReady <- mkFIFOF;

   Reg#(Bool) hirschARunning <- mkReg(False);
   Reg#(Bool) hirschBRunning <- mkReg(False);

   MCSAlgorithm hirschA <- mkHirschA(strA.portA, strB.portA, matL.portA);
   MCSAlgorithm hirschB <- mkHirschB(strA.portA, strB.portA, matL.portA, 1);
   
   // create BRAM Write client for matL

   rule finish_setupA;
      $display("finish setupA");
      let x <- n2a.finish;
      aReady.enq(?);
      indication.setupAComplete();
   endrule

   rule finish_setupB;
      $display("finish setupB");
      let x <- n2b.finish;
      bReady.enq(?);
      indication.setupBComplete();
   endrule

   rule finish_fetch;
      $display("finish fetch");
      let x <- l2n.finish;
      indication.fetchComplete();
   endrule

   rule hirschA_completion (hirschARunning && hirschA.fsm.done);
      hirschARunning <= False;
      indication.searchResult(22);
      endrule
   
   rule hirschB_completion (hirschBRunning && hirschB.fsm.done);
      hirschBRunning <= False;
      indication.searchResult(23);
      endrule
   
   
   method Action setupA(Bit#(32) strPointer, Bit#(32) strLen);
      aLenReg <= truncate(strLen);
      $display("setupA %h %d", strPointer, strLen);
      n2a.start(strPointer, 0, 0, pack(truncate(strLen-1)));
   endmethod

   method Action setupB(Bit#(32) strPointer, Bit#(32) strLen);
      bLenReg <= truncate(strLen);
      $display("setupB %h %d", strPointer, strLen);
      n2b.start(strPointer, 0, 0, pack(truncate(strLen-1)));
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
	       hirschA.setupA(0, aLenReg);
	       hirschA.setupB(0, bLenReg);
	       hirschA.setupL(0);
	       hirschA.fsm.start();
	       hirschARunning <= True;
	       end
	 1: begin
	       hirschB.setupA(0, aLenReg);
	       hirschB.setupB(0, bLenReg);
	       hirschB.fsm.start();
	       hirschB.setupL(0);
	       hirschBRunning <= True;
	       end
//	 2: hirschC.start();
      endcase
   endmethod

endmodule
