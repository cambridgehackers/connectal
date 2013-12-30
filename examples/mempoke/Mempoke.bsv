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

import AxiClientServer::*;
import AxiRDMA::*;
import BsimRDMA::*;
import PortalMemory::*;
import PortalRMemory::*;

interface MempokeRequest;
   method Action readWord(Bit#(32) handle, Bit#(40) addr);
   method Action writeWord(Bit#(32) handle, Bit#(40) addr, S0 data);
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
			 DMAWriteServer#(64) dma_write_server,
			 DMAReadServer#(64) dma_read_server) (MempokeRequest);
      
   rule writeRule;
      let v <- dma_write_server.writeDone.get;
      indication.writeWordResult(unpack(0));
   endrule

   rule readRule;
      let v <- dma_read_server.readData.get();
      indication.readWordResult(unpack(v.data));
   endrule
   
   method Action readWord(Bit#(32) handle, Bit#(40) addr);
      dma_read_server.readReq.put(DMAAddressRequest{handle:handle, address:addr, burstLen:1, tag:0});
   endmethod
   
   method Action writeWord(Bit#(32) handle, Bit#(40) addr, S0 data);
      dma_write_server.writeReq.put(DMAAddressRequest{handle:handle, address:addr, burstLen:1, tag:0});
      dma_write_server.writeData.put(DMAData{data:pack(data),tag:0});
   endmethod         

endmodule