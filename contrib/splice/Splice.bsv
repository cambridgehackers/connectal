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
import BRAM::*;
import Connectable::*;
import ConnectalMemTypes::*;
import DmaUtils::*;
import Dma2BRAM::*;

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
interface SpliceRequest;
   method Action setupA(Bit#(32) strPointer, Bit#(32) strLen);
   method Action setupB(Bit#(32) strPointer, Bit#(32) strLen);
   method Action fetch(Bit#(32) strPointer, Bit#(32) strLen);
   method Action start();
endinterface

interface SpliceIndication;
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
typedef TLog#(MaxStringLen) StringIdx;
typedef TLog#(MaxFetchLen) LIdx;

module mkSpliceRequest#(SpliceIndication indication,
			MemReadServer#(busWidth)   setupA_read_server,
			MemReadServer#(busWidth)   setupB_read_server,
			MemWriteServer#(busWidth)   fetch_write_server )(SpliceRequest)
   
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

   
  Reg#(Bit#(32)) aLenReg <- mkReg(0);
  Reg#(Bit#(32)) bLenReg <- mkReg(0);
  Reg#(Bit#(32)) rLenReg <- mkReg(0);
  Reg#(Bit#(32)) ii <- mkReg(0);
   Reg#(Char) aData <- mkReg(0);
   Reg#(Char) bData <- mkReg(0);
   BRAM2Port#(Bit#(StringIdx), Char) strA  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(Bit#(StringIdx), Char) strB <- mkBRAM2Server(defaultValue);
   BRAM2Port#(Bit#(LIdx), Bit#(16)) matL <- mkBRAM2Server(defaultValue);

   BRAMReadClient#(StringIdx,busWidth) n2a <- mkBRAMReadClient(strA.portB);
   mkConnection(n2a.dmaClient, setupA_read_server);
   BRAMReadClient#(StringIdx,busWidth) n2b <- mkBRAMReadClient(strB.portB);
   mkConnection(n2b.dmaClient, setupB_read_server);
   BRAMWriteClient#(LIdx, busWidth) l2n <- mkBRAMWriteClient(matL.portB);
   mkConnection(l2n.dmaClient, fetch_write_server);

   FIFOF#(void) aReady <- mkFIFOF;
   FIFOF#(void) bReady <- mkFIFOF;
   FIFOF#(void) mReady <- mkFIFOF;
   Stmt splice =
   seq while(True)
   seq
      action
	 let ra <- aReady.deq();
	 $display("Splice A Ready");
      endaction
      action
	 let rb <- bReady.deq();
	 $display("Splice B Ready");
      endaction
      if (aLenReg > bLenReg)
	 rLenReg <= aLenReg;
      else
	 rLenReg <= bLenReg;
      for (ii <= 0; ii < rLenReg; ii <= ii + 1)
	 seq
	    $display("Splice ii %d ", ii);
	    strA.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: truncate(ii), datain: 0});
	    strB.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: truncate(ii), datain: 0});
	    action
	       let left <- strA.portA.response.get();
	       let right <- strB.portA.response.get();
	       aData <= left;
	       bData <= right;
	    endaction
	    $display("aData %h bData %h", aData, bData);
	    matL.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: truncate(ii), datain: {aData, bData}});
	 endseq
      indication.searchResult(unpack(rLenReg));
   endseq
   endseq;
   
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

   mkAutoFSM(splice);
   
   method Action setupA(Bit#(32) strPointer, Bit#(32) strLen);
      aLenReg <= strLen;
      $display("setupA %h %d", strPointer, strLen);
      n2a.start(strPointer, 0, 0, truncate(strLen - 1));
   endmethod

   method Action setupB(Bit#(32) strPointer, Bit#(32) strLen);
      bLenReg <= strLen;
      $display("setupB %h %d", strPointer, strLen);
      n2b.start(strPointer, 0, 0, truncate(strLen - 1));
   endmethod
   
   method Action fetch(Bit#(32) strPointer, Bit#(32) strLen);
      rLenReg <= strLen;
      $display("fetch %h %d", strPointer, strLen);
      l2n.start(strPointer, 0, 0, truncate(strLen - 1));
   endmethod

   method Action start();
   endmethod

endmodule
