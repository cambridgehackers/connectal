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

interface MemreadRequest;
   method Action startRead(Bit#(32) numWords);
   method Action getStateDbg();   
endinterface

interface MemreadIndication;
   method Action started(Bit#(32) numWords);
   method Action rData(Bit#(64) v);
   method Action reportStateDbg(Bit#(32) streamRdCnt, Bit#(32) dataMismatch);
   method Action readReq(Bit#(32) v);
   method Action readDone(Bit#(32) dataMismatch);
endinterface

module mkMemreadRequest#(MemreadIndication indication,
			 ReadChan#(Bit#(64)) dma_stream_read_chan) (MemreadRequest);

   Reg#(Bit#(32)) streamRdCnt <- mkReg(0);
   Reg#(Bool)    dataMismatch <- mkReg(False);  
   Reg#(Bit#(32))      srcGen <- mkReg(0);
   Reg#(Bit#(40))      offset <- mkReg(0);

   rule consume;
      let v <- dma_stream_read_chan.readData.get;
      let misMatch0 = v[31:0] != srcGen;
      let misMatch1 = v[63:32] != srcGen+1;
      dataMismatch <= dataMismatch || misMatch0 || misMatch1;
      srcGen <= srcGen+2;
      // indication.rData(v);
   endrule
   
   rule readReq(streamRdCnt > 0);
      streamRdCnt <= streamRdCnt-16;
      dma_stream_read_chan.readReq.put(offset);
      offset <= offset + 1;
      if (streamRdCnt == 16)
	 indication.readDone(zeroExtend(pack(dataMismatch)));
      else if (streamRdCnt[5:0] == 6'b0)
	 indication.readReq(streamRdCnt);
   endrule

   method Action startRead(Bit#(32) numWords) if (streamRdCnt == 0);
      streamRdCnt <= numWords;
      indication.started(numWords);
   endmethod
   
   method Action getStateDbg();
      indication.reportStateDbg(streamRdCnt, dataMismatch ? 32'd1 : 32'd0);
   endmethod
   
endmodule