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


import BRAM::*;
import FIFO::*;
import Vector::*;
import Gearbox::*;
import FIFOF::*;
import SpecialFIFOs::*;

import BRAMFIFOFLevel::*;
import GetPut::*;
import MemTypes::*;

interface MemReader#(numeric type dataWidth);
   interface ObjectReadServer #(dataWidth) readServer;
   interface ObjectReadClient#(dataWidth) readClient;
endinterface

module mkMemReader(MemReader#(dataWidth))
   provisos(Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));

   FIFOF#(ObjectData#(dataWidth))  readBuffer <- mkFIFOF;
   FIFOF#(ObjectRequest)       reqOutstanding <- mkFIFOF;

   interface ObjectReadServer readServer;
      interface Put readReq = toPut(reqOutstanding);
      interface Get readData = toGet(readBuffer);
   endinterface
   interface ObjectReadClient readClient;
      interface Get readReq = toGet(reqOutstanding);
      interface Put readData = toPut(readBuffer);
   endinterface
endmodule


interface MemWriter#(numeric type dataWidth);
   interface ObjectWriteServer#(dataWidth) writeServer;
   interface ObjectWriteClient#(dataWidth) writeClient;
endinterface


module mkMemWriter(MemWriter#(dataWidth))
   provisos(Div#(dataWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,dataWidth),
	    Log#(dataWidthBytes,beatShift));

   FIFOF#(ObjectData#(dataWidth)) writeBuffer <- mkFIFOF;
   FIFOF#(ObjectRequest)        reqOutstanding <- mkFIFOF;
   FIFOF#(Bit#(6))                        doneTags <- mkFIFOF();

   interface ObjectWriteServer writeServer;
      interface Put writeReq = toPut(reqOutstanding);
      interface Put writeData = toPut(writeBuffer);
      interface Get writeDone = toGet(doneTags);
   endinterface
   interface ObjectWriteClient writeClient;
      interface Get writeReq = toGet(reqOutstanding);
      interface Get writeData = toGet(writeBuffer);
      interface Put writeDone = toPut(doneTags);
   endinterface

endmodule
   

interface MemengineCmdBuf#(numeric type numServers, numeric type cmdQDepth);
   method Action enq(Bit#(TLog#(numServers)) idx, MemengineCmd cmd);
   method Action first_req(Bit#(TLog#(numServers)) idx);
   method ActionValue#(MemengineCmd) first_resp();
   method Action deq(Bit#(TLog#(numServers)) idx);
   method Action upd(Bit#(TLog#(numServers)) idx, MemengineCmd cmd);
endinterface


module mkMemengineCmdBuf(MemengineCmdBuf#(numServers,cmdQDepth))
   provisos(Mul#(cmdQDepth,numServers,cmdBuffSz),
	    Log#(cmdBuffSz, cmdBuffAddrSz),
	    Add#(a__, TLog#(numServers), TAdd#(1, cmdBuffAddrSz)));
   
   function Bit#(cmdBuffAddrSz) hf(Integer i) = fromInteger(i*valueOf(cmdQDepth));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) head <- mapM(mkReg, genWith(hf));
   Vector#(numServers, Reg#(Bit#(cmdBuffAddrSz))) tail <- mapM(mkReg, genWith(hf));
   BRAM2Port#(Bit#(cmdBuffAddrSz),MemengineCmd)    cmdBuf <- mkBRAM2Server(defaultValue);
   let cmd_q_depth = fromInteger(valueOf(cmdQDepth));

      
   method Action enq(Bit#(TLog#(numServers)) idx, MemengineCmd cmd);
      cmdBuf.portB.request.put(BRAMRequest{write:True, responseOnWrite:False, address:tail[idx], datain:cmd});
      Bit#(TAdd#(1,cmdBuffAddrSz)) nt = extend(tail[idx])+1;
      Bit#(TAdd#(1,cmdBuffAddrSz)) li = (extend(idx)+1)*cmd_q_depth;
      Bit#(TAdd#(1,cmdBuffAddrSz)) rs = (extend(idx)+0)*cmd_q_depth;
      if (nt >= li) 
	 nt = rs;
      tail[idx] <= truncate(nt);
   endmethod

   method Action first_req(Bit#(TLog#(numServers)) idx);
      cmdBuf.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:head[idx], datain:?});
   endmethod
   
   method ActionValue#(MemengineCmd) first_resp();
      let cmd <- cmdBuf.portA.response.get;
      return cmd;
   endmethod

   method Action deq(Bit#(TLog#(numServers)) idx);
      Bit#(TAdd#(1,cmdBuffAddrSz)) nt = extend(head[idx])+1;
      Bit#(TAdd#(1,cmdBuffAddrSz)) li = (extend(idx)+1)*cmd_q_depth;
      Bit#(TAdd#(1,cmdBuffAddrSz)) rs = (extend(idx)+0)*cmd_q_depth;
      if (nt >= li) 
	 nt = rs;
      head[idx] <= truncate(nt);
   endmethod

   method Action upd(Bit#(TLog#(numServers)) idx, MemengineCmd cmd);
      cmdBuf.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:head[idx], datain:cmd});
   endmethod

endmodule

