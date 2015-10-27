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
import ConnectalConfig::*;
import FIFOF::*;
import Vector::*;
import MemTypes::*;
import Pipe::*;
import Portal::*;
import HostInterface::*;

typedef enum {
   BpHeader,
   BpMessage
   } CnocPortalState deriving (Bits,Eq);

interface PortalMsgRequest;
   method Bit#(SlaveDataBusWidth) id();
   interface PipeIn#(Bit#(32)) message;
endinterface

interface PortalMsgIndication;
   method Bit#(SlaveDataBusWidth) id();
   interface PipeOut#(Bit#(32)) message;
endinterface

interface CnocTop#(numeric type numRequests, numeric type numIndications,
		   numeric type addrWidth, numeric type dataWidth, type pins, numeric type numMasters
		   );
   interface Vector#(numRequests, PortalMsgRequest) requests;
   interface Vector#(numIndications, PortalMsgIndication) indications;
   interface Vector#(NumReadClients,MemReadClient#(DataBusWidth)) readers;
   interface Vector#(NumWriteClients,MemWriteClient#(DataBusWidth)) writers;
   interface pins pins;
endinterface

module mkPortalMsgRequest#(Bit#(SlaveDataBusWidth) portalId, Vector#(numRequests, PipeIn#(Bit#(32))) portal)(PortalMsgRequest);
   Reg#(Bit#(8)) messageWordsReg <- mkReg(0);
   Reg#(Bit#(8)) methodIdReg <- mkReg(0);
   Reg#(CnocPortalState) bpState <- mkReg(BpHeader);
   FIFOF#(Bit#(32)) fifoMsgSink <- mkFIFOF();
   Bool verbose = False;

   rule receiveMessageHeader if (bpState == BpHeader);
      let hdr = fifoMsgSink.first();
      fifoMsgSink.deq();
      let methodId = hdr[23:16];
      Bit#(8) messageWords = hdr[7:0] - 1;
      if (messageWords == 0)
          messageWords = 1;
      methodIdReg <= methodId;
      if (verbose)
	 $display("receiveMessageHeader portal=%d hdr=%x methodId=%x messageWords=%d", portalId, hdr, methodId, messageWords);
      messageWordsReg <= messageWords;
      if (messageWords != 0)
	 bpState <= BpMessage;
   endrule
   rule receiveMessage if (bpState == BpMessage);
      let data = fifoMsgSink.first();
      fifoMsgSink.deq();
      if (verbose)
	 $display("receiveMessage portal=%d id=%d data=%x messageWords=%d", portalId, methodIdReg, data, messageWordsReg);
      portal[methodIdReg].enq(data);
      messageWordsReg <= messageWordsReg - 1;
      if (messageWordsReg == 1)
	 bpState <= BpHeader;
   endrule
   method Bit#(SlaveDataBusWidth) id();
       return portalId;
   endmethod
   interface message = toPipeIn(fifoMsgSink);
endmodule

module mkPortalMsgIndication#(Bit#(SlaveDataBusWidth) portalId, Vector#(numIndications, PipeOut#(Bit#(32))) portal, PortalSize messageSize)(PortalMsgIndication);
   Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
   Reg#(Bit#(8)) methodIdReg <- mkReg(0);
   Reg#(CnocPortalState) bpState <- mkReg(BpHeader);
   Vector#(numIndications, Bool) readyBits = map(pipeOutNotEmpty, portal);
   Bool      interruptStatus = False;
   Bit#(8)  readyChannel = -1;
   FIFOF#(Bit#(32)) fifoMsgSource <- mkFIFOF();
   function Bool pipeOutNotEmpty(PipeOut#(a) po); return po.notEmpty(); endfunction
   let verbose = False;

   for (Integer i = valueOf(numIndications) - 1; i >= 0; i = i - 1) begin
      if (readyBits[i]) begin
         interruptStatus = True;
         readyChannel = fromInteger(i);
      end
   end

   rule sendHeader if (bpState == BpHeader && interruptStatus);
      Bit#(16) messageBits = messageSize.size(extend(readyChannel));
      Bit#(16) roundup = messageBits[4:0] == 0 ? 0 : 1;
      Bit#(16) numWords = (messageBits >> 5) + roundup;
      Bit#(32) hdr = extend(readyChannel) << 16 | extend(numWords+1);
      if (verbose) $display("sendHeader portal=%d hdr=%h messageBits=%d numWords=%d", portalId, hdr, messageBits, numWords);
      messageWordsReg <= numWords;
      methodIdReg <= readyChannel;
      fifoMsgSource.enq(hdr);
      bpState <= BpMessage;
   endrule
   rule sendMessage if (bpState == BpMessage);
      messageWordsReg <= messageWordsReg - 1;
      let v = portal[methodIdReg].first;
      portal[methodIdReg].deq();
      fifoMsgSource.enq(v);
      if (verbose) $display("sendMessage portal=%d id=%d data=%h messageWords=%d", portalId, methodIdReg, v, messageWordsReg);
      if (messageWordsReg == 1) begin
	 bpState <= BpHeader;
      end
   endrule
   method Bit#(SlaveDataBusWidth) id();
      return portalId;
   endmethod
   interface message = toPipeOut(fifoMsgSource);
endmodule
