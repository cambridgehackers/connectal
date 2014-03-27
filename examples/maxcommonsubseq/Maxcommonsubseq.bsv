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
import FIFOF::*;
import SpecialFIFOs::*;
import GetPut::*;
import StmtFSM::*;
//import Vector::*;
import BRAM::*;
//import Gearbox::*;
import Connectable::*;

//import AxiMasterSlave::*;
import Dma::*;
import DmaUtils::*;
import Dma2BRAM::*;

// algorithm
import HirschA::*;
import Hirsch::*;

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
   method Action start();
endinterface

interface MaxcommonsubseqIndication;
   method Action searchResult(Int#(32) v);
   method Action setupAComplete(); 
   method Action setupBComplete(); 
   method Action fetchComplete(); 
endinterface

typedef Bit#(8) Char;
typedef Bit#(64) DWord;
typedef Bit#(32) Word;

typedef 128 MaxStringLen;
typedef 16384 MaxFetchLen;
typedef TLog#(MaxStringLen) StringIdxWidth;
typedef Bit#(StringIdxWidth) StringIdx;
typedef TLog#(MaxFetchLen) LIdxWidth;
typedef Bit#(LIdxWidth) LIdx;

   
   
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

   mkHirschA(strA.portA, strB.portA, matL.portA)
   mkFSM(hirschB);
   
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

   method Action start(int alg);
      case (alg) 
	 0: hirschA.start();
	 1: hirschB.start();
//	 2: hirschC.start();
	 default:
      endcase
   endmethod

endmodule
