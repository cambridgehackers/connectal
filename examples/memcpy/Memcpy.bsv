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

import Vector::*;
import FIFOF::*;
import FIFO::*;
import BRAMFIFO::*;
import GetPut::*;
import ClientServer::*;

import ConnectalMemory::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import Pipe::*;

interface MemcpyRequest;
   method Action startCopy(Bit#(32) wrPointer, Bit#(32) rdPointer, Bit#(32) numWords, Bit#(32) burstLen, Bit#(32) iterCnt);
endinterface

interface MemcpyIndication;
   method Action started;
   method Action done;
endinterface

interface Memcpy;
   interface MemcpyRequest request;
   interface Vector#(1, MemReadClient#(64)) dmaReadClient;
   interface Vector#(1, MemWriteClient#(64)) dmaWriteClient;
endinterface


// NOTE: this test doesn't rely on mkDma[Read|Write]Buffer to ensure that
//       speculative read/write requests are not unsafely issued.  As a 
//       result this must be enforced manually (mdk)

module mkMemcpy#(MemcpyIndication indication)(Memcpy);

   MemreadEngine#(64,1)  re <- mkMemreadEngine;
   MemwriteEngine#(64,1) we <- mkMemwriteEngine;

   Reg#(Bit#(32))        rdIterCnt <- mkReg(0);
   Reg#(Bit#(32))        wrIterCnt <- mkReg(0);
   Reg#(Bit#(32))            rdCnt <- mkReg(0);
   Reg#(Bit#(32))            wrCnt <- mkReg(0);
   Reg#(SGLId)      rdPointer <- mkReg(0);
   Reg#(SGLId)      wrPointer <- mkReg(0);
   Reg#(Bit#(32))         burstLen <- mkReg(0);
   Reg#(Bit#(32))         numWords <- mkReg(0);
   
   FIFOF#(Bit#(64))    buffer <- mkSizedBRAMFIFOF(16);
   Reg#(Bit#(32))    rdBuffer <- mkReg(32);
   Reg#(Bit#(32))    wrBuffer <- mkReg(0); 
   
   rule start_read(rdIterCnt > 0 && rdBuffer >= burstLen);
      //$display("start_read %d", rdCnt);
      re.readServers[0].request.put(MemengineCmd{sglId:rdPointer, base:extend(rdCnt*4), len:(burstLen*4), burstLen:truncate(burstLen*4)});
      rdBuffer <= rdBuffer-burstLen;
      if(rdCnt+burstLen >= numWords) begin
	 rdCnt <= 0;
	 rdIterCnt <= rdIterCnt-1;
      end
      else begin
	 rdCnt <= rdCnt+burstLen;
      end
   endrule

   rule start_write(wrIterCnt > 0 && wrBuffer >= burstLen);
      //$display("                    start_write %d", wrCnt);
      we.writeServers[0].request.put(MemengineCmd{sglId:wrPointer, base:extend(wrCnt*4), len:burstLen*4, burstLen:truncate(burstLen*4)});
      wrBuffer <= wrBuffer-burstLen;
      if(wrCnt+burstLen >= numWords) begin
	 wrCnt <= 0;
	 wrIterCnt <= wrIterCnt-1;
      end
      else begin
	 wrCnt <= wrCnt+burstLen;
      end
   endrule
   
   rule read_finish;
      //$display("read_finish %d", rdIterCnt);
      let rv0 <- re.readServers[0].response.get;
   endrule

   rule write_finish;
      //$display("                    write_finish %d", wrIterCnt);
      let rv1 <- we.writeServers[0].response.get;
      if(wrIterCnt==0)
	 indication.done;
   endrule
   
   rule fill_buffer;
      let v <- toGet(re.dataPipes[0]).get;
      buffer.enq(v);
      wrBuffer <= wrBuffer+2;
      //$display("fill_buffer %h", rdFifo.first);
   endrule
   
   rule drain_buffer;
      let v <- toGet(buffer).get();
      we.dataPipes[0].enq(v);
      rdBuffer <= rdBuffer+2;
      //$display("                    drain_buffer %h", buffer.first);
   endrule

   interface MemcpyRequest request;
   method Action startCopy(Bit#(32) wp, Bit#(32) rp, Bit#(32) nw, Bit#(32) bl, Bit#(32) ic);
      $display("startCopy wrPointer=%d rdPointer=%d numWords=%h burstLen=%d iterCnt=%d", wp, rp, nw, bl, ic);
      indication.started;
      // initialized
      wrPointer <= wp;
      rdPointer <= rp;
      numWords  <= nw;
      wrIterCnt <= ic;
      rdIterCnt <= ic;
      burstLen  <= bl;
   endmethod
   endinterface
   interface MemReadClient dmaReadClient = cons(re.dmaClient, nil);
   interface MemWriteClient dmaWriteClient = cons(we.dmaClient, nil);
endmodule
