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

import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;

import AxiMasterSlave::*;
import Dma::*;

interface MempokeRequest;
   method Action readWord(Bit#(32) pointer, Bit#(32) offset);
   method Action writeWord(Bit#(32) pointer, Bit#(32) offset, S0 data);
endinterface

interface MempokeIndication;
   method Action readWordResult(S0 v);
   method Action writeWordResult(S0 v);
endinterface

typedef struct{
   Bit#(32) a;
   Bit#(32) b;
   } S0 deriving (Eq,Bits);

module mkMempokeRequest#(MempokeIndication indication,
			 ObjectWriteServer#(64) dma_write_server,
			 ObjectReadServer#(64) dma_read_server) (MempokeRequest);
      
   rule writeRule;
      let v <- dma_write_server.writeDone.get;
      indication.writeWordResult(unpack(0));
   endrule

   rule readRule;
      let v <- dma_read_server.readData.get();
      indication.readWordResult(unpack(v.data));
   endrule
   
   method Action readWord(Bit#(32) pointer, Bit#(32) offset);
      dma_read_server.readReq.put(ObjectRequest{pointer:pointer, offset:extend(offset), burstLen:8, tag:0});
   endmethod
   
   method Action writeWord(Bit#(32) pointer, Bit#(32) offset, S0 data);
      dma_write_server.writeReq.put(ObjectRequest{pointer:pointer, offset:extend(offset), burstLen:8, tag:0});
      dma_write_server.writeData.put(ObjectData{data:pack(data),tag:0});
   endmethod         

endmodule