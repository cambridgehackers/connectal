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
import ClientServer::*;
import GetPut::*;
import ConnectalMemTypes::*;
import MemWriteEngine::*;
import Pipe::*;
import ConnectalConfig::*;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) burstLen);
endinterface

interface MemwriteIndication;
   method Action writeDone(Bit#(32) v);
endinterface

interface Memwrite;
   interface MemwriteRequest request;
   interface Vector#(1,MemWriteClient#(DataBusWidth)) dmaClient;
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);
   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))       numWords <- mkReg(0);
   Reg#(Bit#(32))       burstLen <- mkReg(0);
   Reg#(Bit#(32))         srcGens <- mkReg(0);
   Reg#(Bool)              doOnce <- mkReg(False);
   MemWriteEngine#(DataBusWidth,DataBusWidth,2,1)    we <- mkMemWriteEngine;

   rule start if (doOnce);
         we.writeServers[0].request.put(MemengineCmd{sglId:pointer, base:0, len:truncate(numWords), burstLen:truncate(burstLen)});
         $display("start");
         doOnce <= False;
   endrule
   rule finish;
         $display("finish");
         let rv <- we.writeServers[0].done.get;
         indication.writeDone(0);
   endrule
   rule src if (numWords != 0);
         let v = {srcGens+1,srcGens};
         we.writeServers[0].data.enq(v);
         srcGens <= srcGens+2;
         numWords <= numWords - 8;
   endrule

   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) wp, Bit#(32) nw, Bit#(32) bl);
          $display("startWrite pointer=%d numWords=%h burstLen=%d", pointer, nw, bl);
          pointer <= wp;
          numWords  <= nw;
          burstLen  <= bl;
          doOnce <= True;
       endmethod
   endinterface
   interface MemWriteClient dmaClient = cons(we.dmaClient,nil);
endmodule

