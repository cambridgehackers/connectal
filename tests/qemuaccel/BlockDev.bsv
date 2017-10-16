// Copyright (c) 2016 Connectal Project

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

typedef enum { BlockDevRead, BlockDevWrite } BlockDevOp deriving (Bits,Eq,FShow);

import BuildVector::*;
import ClientServer::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;

import ConnectalConfig::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import Pipe::*;

interface PortPair#(type ifc1, type ifc2);
   interface ifc1 port1;
   interface ifc2 port2;
endinterface
function PortPair#(ifc1, ifc2) portPair(ifc1 p1, ifc2 p2);
   return (interface PortPair#(ifc1,ifc2);
	      interface port1 = p1;
	      interface port2 = p2;
	   endinterface);
endfunction

interface BlockDevRequest;
   method Action transfer(BlockDevOp op, Bit#(32) dramaddr, Bit#(32) offset, Bit#(32) size, Bit#(32) tag);
endinterface

interface BlockDevResponse;
   method Action transferDone(Bit#(32) tag);
endinterface

typedef struct {
   BlockDevOp op;
   Bit#(32) dramaddr;
   Bit#(32) offset;
   Bit#(32) size;
   Bit#(32) tag;
   } BlockDevTransfer deriving (Bits,Eq,FShow);

typedef Client#(BlockDevTransfer,Bit#(32)) BlockDevClient;

interface BlockDev;
   interface BlockDevRequest request;
   interface BlockDevClient client;
endinterface

typedef 1 CmdQDepth;

module mkBlockDev#(BlockDevResponse ind)(BlockDev);
   FIFOF#(BlockDevTransfer) requestFifo <- mkFIFOF();
   FIFOF#(Bit#(32))        responseFifo <- mkFIFOF();

   rule rl_response;
      let response <- toGet(responseFifo).get();
      ind.transferDone(response);
   endrule

   interface BlockDevRequest request;
      method Action transfer(BlockDevOp op, Bit#(32) dramaddr, Bit#(32) offset, Bit#(32) size, Bit#(32) tag);
	 requestFifo.enq(BlockDevTransfer { op: op, dramaddr: dramaddr, offset: offset, size: size, tag: tag });
      endmethod
   endinterface
   interface Client client;
      interface Get request = toGet(requestFifo);
      interface Put response = toPut(responseFifo);
   endinterface
endmodule
