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
   Reg#(Char) aData <- mkReg(0);
   Reg#(Char) bData <- mkReg(0);
   Reg#(Bit#(16)) lim1jm1 <- mkReg(0);
   Reg#(Bit#(16)) lim1j <- mkReg(0);
   Reg#(Bit#(16)) lijm1 <- mkReg(0);
   BRAM2Port#(StringIdx, Char) strA  <- mkBRAM2Server(defaultValue);
   BRAM2Port#(StringIdx, Char) strB <- mkBRAM2Server(defaultValue);
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

   Stmt maxQuadratic =
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
      for (ii<= 0; ii < aLenReg; ii <= ii + 1)
	 seq
	    matL.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {ii,0}, datain: 0});
	    endseq
      for (ii<= 0; ii < aLenReg; ii <= ii + 1)
	 seq
	    matL.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {0,ii}, datain: 0});
	 endseq
      for (ii<= 1; ii <= aLenReg; ii <= ii + 1)
	 for (jj<= 1; jj <= bLenReg; jj <= jj + 1)
	    seq
	       strA.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ii-1, datain: 0});
	       strB.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: jj-1, datain: 0});
	       action
		  let ta <- strA.portA.response.get();
		  let tb <- strB.portA.response.get();
		  aData <= ta;
		  bData <= tb;
	       endaction
	       if (aData == bData)
		  seq
		     matL.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: {ii-1,jj-1}, datain: 0});
		     action
			let temp <- matL.portA.response.get();
			lim1jm1 <= temp;
		     endaction
		     matL.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {ii,jj}, datain: lim1jm1+1});
		     
		  endseq
	       else
		  seq
		     matL.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: {ii,jj-1}, datain: 0});
		     action
			let tlijm1 <- matL.portA.response.get();
			lijm1 <= tlijm1;
		     endaction
		     matL.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: {ii-1,jj}, datain: 0});
		     action
			let tlim1j <- matL.portA.response.get();
			lim1j <= tlim1j;
		     endaction
			matL.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: {ii,jj}, datain: max(lijm1,lim1j)});
		  endseq
	    endseq
      matL.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: {aLenReg, bLenReg}, datain: 0});
      action
	 let result <- matL.portA.response.get();
	 indication.searchResult(zeroExtend(unpack(result)));
      endaction
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

   mkAutoFSM(maxQuadratic);
   
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

   method Action start();
   endmethod

endmodule
