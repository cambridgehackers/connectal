// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import CtrlMux::*;

import MIFO::*;
import Pipe::*;
import Portal::*;
import MemTypes::*;
import AddressGenerator::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import ConnectalMemory::*;

typedef struct {
    Bit#(1) select;
    Bit#(6) tag;
} ReadReqInfo deriving (Bits);

interface PortalCtrlMemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemSlave#(addrWidth, dataWidth) memSlave;
   interface ReadOnly#(Bool) interrupt;
   interface WriteOnly#(Bool) top;
endinterface

module mkPortalCtrlMemSlave#(Bit#(dataWidth) ifcId, 
			     Vector#(numIndications, PipeOut#(Bit#(dataWidth))) indicationPipes)(PortalCtrlMemSlave#(addrWidth, dataWidth))
   provisos( Add#(a__, 1, dataWidth)
	    ,Div#(dataWidth, 8, b__)
	    ,Bits#(MemData#(dataWidth), c__)
	    ,Add#(d__, dataWidth, TMul#(dataWidth, 2))
	    );
   
   AddressGenerator#(addrWidth,dataWidth) ctrlReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(addrWidth,dataWidth) ctrlWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(MemData#(dataWidth))        ctrlWriteDataFifo <- mkFIFO();
   FIFO#(Bit#(MemTagSize))        ctrlWriteDoneFifo <- mkFIFO();
   Reg#(Bool) topR <- mkReg(True);

   function Bool pipeOutNotEmpty(PipeOut#(a) po); return po.notEmpty(); endfunction
   Vector#(numIndications, Bool) readyBits = map(pipeOutNotEmpty, indicationPipes);
   
   Reg#(Bool) interruptEnableReg <- mkReg(False);
   Bool      interruptStatus = False;
   Reg#(Bit#(TMul#(dataWidth,2))) cycle_count <- mkReg(0);
   Reg#(Bit#(dataWidth))    snapshot <- mkReg(0);
   
   Bit#(dataWidth)  readyChannel = -1;
   for (Integer i = 0; i < valueOf(numIndications); i = i + 1) begin
      if (readyBits[i]) begin
         interruptStatus = True;
         readyChannel = fromInteger(i);
      end
   end
   
   rule count;
      cycle_count <= cycle_count+1;
   endrule
   
   rule writeDataRule;
      let d <- toGet(ctrlWriteDataFifo).get();
      let b <- ctrlWriteAddrGenerator.addrBeat.get();
      //$display("mkCtrl.writeData addr=%h data=%h last=%d", b.addr, d.data, b.last);
      let v = d.data;
      let addr = b.addr;
      if (addr == 'h000)
	 noAction;
      if (addr == 'h004)
	 interruptEnableReg <= v[0] == 1'd1;
      if (b.last)
	 ctrlWriteDoneFifo.enq(b.tag);
   endrule

   interface PhysMemSlave memSlave;
      interface PhysMemReadServer read_server;
	 interface Put readReq = ctrlReadAddrGenerator.request;
	 interface Get readData;
	    method ActionValue#(MemData#(dataWidth)) get();
	       let b <- ctrlReadAddrGenerator.addrBeat.get();
	       let addr = b.addr;
	       let v = 'h05a05a0;
	       if (addr == 'h000)
		  v = interruptStatus ? 1 : 0;
	       if (addr == 'h004)
		  v = interruptEnableReg ? 1 : 0;
	       if (addr == 'h008)
		  v = 7;
               if (addr == 'h00C) begin
		  if (interruptStatus)
		     v = readyChannel+1;
		  else 
		     v = 0;
               end
	       if (addr == 'h010)
		  v = ifcId;
	       if (addr == 'h014)
		  v = extend(pack(topR));
	       if (addr == 'h018) begin
		  snapshot <= truncate(cycle_count);
		  v = truncate(cycle_count>>valueOf(dataWidth));
	       end
	       if (addr == 'h01C)
		  v = snapshot;
	       //$display("mkCtrl.readData addr=%h data=%h", b.addr, v);
	       return MemData { data: v, tag: b.tag, last: b.last };
	    endmethod
	 endinterface
      endinterface: read_server
      interface PhysMemWriteServer write_server; 
	 interface Put writeReq = ctrlWriteAddrGenerator.request;
	 interface Put writeData;
	    method Action put(MemData#(dataWidth) d);
	       ctrlWriteDataFifo.enq(d);
	    endmethod
	 endinterface
	 interface Get writeDone;
	    method ActionValue#(Bit#(MemTagSize)) get();
	       let tag <- toGet(ctrlWriteDoneFifo).get();
	       return tag;
	    endmethod
	 endinterface
      endinterface: write_server
   endinterface: memSlave
   interface ReadOnly interrupt;
      method Bool _read();
	 return interruptStatus && interruptEnableReg;
      endmethod
   endinterface
   interface WriteOnly top;
      method Action _write(Bool v);
	 topR <= v;
      endmethod
   endinterface
endmodule   

module mkPipeInMemSlave#(PipeIn#(Bit#(dataWidth)) methodPipe)(PhysMemSlave#(addrWidth, dataWidth))
   provisos (Add#(1,a__,dataWidth));

   AddressGenerator#(addrWidth,dataWidth) fifoReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(addrWidth,dataWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(MemTagSize))        fifoWriteDoneFifo <- mkFIFO();

   interface PhysMemReadServer read_server;
      interface Put readReq = fifoReadAddrGenerator.request;
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let b <- fifoReadAddrGenerator.addrBeat.get();
	    let v = 0;
	    if (b.addr[7:0] == 4)
	       v = extend(pack(methodPipe.notFull()));
	    return MemData { data: v, tag: b.tag, last: b.last };
	 endmethod
      endinterface
   endinterface
   interface PhysMemWriteServer write_server; 
      interface Put writeReq = fifoWriteAddrGenerator.request;
      interface Put writeData;
	 method Action put((MemData#(dataWidth)) d);
	    let b <- fifoWriteAddrGenerator.addrBeat.get();
	    //$display("mkPipeInMemSlave.writeData.put addr=%h data=%h", b.addr, d.data);
	    if (b.last)
	       fifoWriteDoneFifo.enq(b.tag);
	    methodPipe.enq(d.data);
	    // this used to be where we triggered putFailed
	 endmethod
      endinterface
      interface Get writeDone = toGet(fifoWriteDoneFifo);
   endinterface
endmodule

module mkPipeOutMemSlave#(PipeOut#(Bit#(dataWidth)) methodPipe)(PhysMemSlave#(addrWidth, dataWidth))
   provisos (Add#(1,a__,dataWidth));
   AddressGenerator#(addrWidth,dataWidth) fifoReadAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(addrWidth,dataWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(MemTagSize))                  fifoWriteDoneFifo <- mkFIFO();
   FIFO#(MemData#(dataWidth))                   fifoReadDataFifo <- mkFIFO();
   rule readDataRule;
      let b <- fifoReadAddrGenerator.addrBeat.get();
      let v = 0;
      if (b.addr[7:0] == 0)
	 v <- toGet(methodPipe).get();
      else if (b.addr[7:0] == 4)
	 v = extend(pack(methodPipe.notEmpty()));
      //$display("mkPipeOutMemSlave.readData.get addr=%h data=%h", b.addr, data);
      fifoReadDataFifo.enq(MemData { data: v, tag: b.tag, last: b.last });
   endrule

   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(addrWidth) req);
	    fifoReadAddrGenerator.request.put(req);
	    if (!methodPipe.notEmpty())
	       $display("***\n\n mkPipeOutMemSlave.read_server.underflow! \n\n****");
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let d <- toGet(fifoReadDataFifo).get();
	    return d;
	 endmethod
      endinterface
   endinterface
   interface PhysMemWriteServer write_server; 
      interface Put writeReq = fifoWriteAddrGenerator.request;
      interface Put writeData;
	 method Action put((MemData#(dataWidth)) d);
	    let b <- fifoWriteAddrGenerator.addrBeat.get();
	    //$display("mkPipeOutMemSlave.writeData.put addr=%h data=%h", b.addr, d.data);
	    if (b.last)
	       fifoWriteDoneFifo.enq(b.tag);
	 endmethod
      endinterface
      interface Get writeDone = toGet(fifoWriteDoneFifo);
   endinterface
endmodule

module mkMemPortal#(Bit#(slaveDataWidth) ifcId,
		    PipePortal#(numRequests, numIndications, slaveDataWidth) portal)(MemPortal#(slaveAddrWidth, slaveDataWidth))
   provisos ( Add#(1, i__, slaveDataWidth)
	     ,Add#(c__, 8, slaveAddrWidth)
	     ,Add#(d__, 1, c__)
	     ,Add#(a__, TLog#(TAdd#(1, TAdd#(numRequests, numIndications))), c__)
	     ,Add#(b__, slaveDataWidth, TMul#(slaveDataWidth, 2))
	     );

   Vector#(numRequests,    PipeIn#(Bit#(slaveDataWidth)))     requestPipes = portal.requests;
   Vector#(numIndications, PipeOut#(Bit#(slaveDataWidth))) indicationPipes = portal.indications;
   Vector#(numRequests,    PhysMemSlave#(8, slaveDataWidth))    requestMemSlaves <- mapM(mkPipeInMemSlave, requestPipes);
   Vector#(numIndications, PhysMemSlave#(8, slaveDataWidth)) indicationMemSlaves <- mapM(mkPipeOutMemSlave, indicationPipes);
   
   PortalCtrlMemSlave#(8,slaveDataWidth) ctrlPort <- mkPortalCtrlMemSlave(ifcId, indicationPipes);
   PhysMemSlave#(slaveAddrWidth,slaveDataWidth) memslave  <- mkMemSlaveMux(cons(ctrlPort.memSlave,append(requestMemSlaves, indicationMemSlaves)));
   interface PhysMemSlave slave = memslave;
   interface ReadOnly interrupt = ctrlPort.interrupt;
   interface WriteOnly top = ctrlPort.top;
endmodule

typedef enum {
   Idle,
   HeadRequested,
   TailRequested,
   RequestMessage,
   MessageHeaderRequested,
   MessageRequested,
   UpdateTail,
   Waiting,
   Stop
   } SharedMemoryPortalState deriving (Bits,Eq);

module mkSharedMemoryPortal#(PipePortal#(numRequests, numIndications, 32) portal)(SharedMemoryPortal#(64));

   MemreadEngineV#(64,2,2) readEngine <- mkMemreadEngine();
   MemwriteEngineV#(64,2,2) writeEngine <- mkMemwriteEngine();

   Bool verbose = True;

   Reg#(Bit#(32)) sglIdReg <- mkReg(0);
   Reg#(Bool)     readyReg   <- mkReg(False);

   if (valueOf(numRequests) > 0) begin
      // read the head and tail pointers, if they are different, then read a request
      Reg#(Bit#(32)) reqLimitReg <- mkReg(0);
      Reg#(Bit#(32)) reqHeadReg <- mkReg(0);
      Reg#(Bit#(32)) reqTailReg <- mkReg(0);
      Reg#(Bit#(16)) wordCountReg <- mkReg(0);
      Reg#(Bit#(16)) messageWordsReg <- mkReg(0);
      Reg#(Bit#(16)) methodIdReg <- mkReg(0);
      Reg#(SharedMemoryPortalState) reqState <- mkReg(Idle);

      rule updateReqHeadTail if (reqState == Idle && readyReg);
	 $display("updateReqHeadTail");
	 readEngine.readServers[0].request.put(MemengineCmd { sglId: sglIdReg,
							     base: 0,
							     burstLen: 16,
							     len: 16
							     });
	 reqState <= HeadRequested;
      endrule

      rule receiveReqHeadTail if (reqState == HeadRequested || reqState == TailRequested);
	 let data <- toGet(readEngine.dataPipes[0]).get();
	 let w0 = data[31:0];
	 let w1 = data[63:32];
	 let head = reqHeadReg;
	 let tail = reqTailReg;
	 if (reqState == HeadRequested) begin
	    reqLimitReg <= w0;
	    reqHeadReg <= w1;
	    head = w1;
	    reqState <= TailRequested;
	 end
	 else begin
	    if (reqTailReg == 0) begin
	       tail = w0;
	       reqTailReg <= tail;
	    end
	    if (tail != reqHeadReg)
	       reqState <= RequestMessage;
	    else
	       reqState <= Idle;
	 end
	 if (head != tail || verbose || True)
	    $display("receiveReqHeadTail state=%d w0=%x w1=%x head=%d tail=%d limit=%d", reqState, w0, w1, head, tail, reqLimitReg);
      endrule

      rule requestMessage if (reqState == RequestMessage);
	 Bit#(32) wordCount = reqHeadReg - reqTailReg;
	 if ((reqTailReg & 1) == 1) begin
	    $display("WARNING requestMessage: reqTail=%d is odd.", reqTailReg);
	 end
	 let tail = reqTailReg + wordCount;
	 if (reqHeadReg < reqTailReg) begin
	    $display("requestMessage wrapped: head=%d tail=%d", reqHeadReg, reqTailReg);
	    wordCount = reqLimitReg - reqTailReg;
	    tail = 4;
	 end
	 if (verbose) $display("requestMessage id=%d tail=%h head=%h wordCount=%d", sglIdReg, reqTailReg, reqHeadReg, wordCount);

	 reqTailReg <= tail;
	 wordCountReg <= truncate(wordCount);
	 readEngine.readServers[0].request.put(MemengineCmd {sglId: sglIdReg,
							     base: extend(reqTailReg << 2),
							     burstLen: 16,
							     len: wordCount << 2
							     });
	 reqState <= MessageHeaderRequested;
      endrule

      MIFO#(4,1,4,Bit#(32)) readMifo <- mkMIFO();
      rule demuxwords if (readMifo.enqReady());
	 let data <- toGet(readEngine.dataPipes[0]).get();
	 Vector#(2,Bit#(32)) dvec = unpack(data);
	 let enqCount = 2;
	 Vector#(4,Bit#(32)) dvec4;
	 dvec4[0] = dvec[0];
	 dvec4[1] = dvec[1];
	 dvec4[2] = 0;
	 dvec4[3] = 0;
	 readMifo.enq(enqCount, dvec4);
      endrule

      rule receiveMessageHeader if (reqState == MessageHeaderRequested);
	 let vec <- toGet(readMifo).get();
	 let hdr = vec[0];
	 let methodId = hdr[31:16];
	 let messageWords = hdr[15:0];
	 methodIdReg <= methodId;
	 if (verbose)
	    $display("receiveMessageHeader hdr=%x methodId=%x messageWords=%d wordCount=%d", hdr, methodId, messageWords, wordCountReg);
	 wordCountReg <= wordCountReg - 1;
	 messageWordsReg <= messageWords - 1;
	 if (wordCountReg <= messageWords)
	    reqState <= UpdateTail;
	 else if (messageWords == 1)
	    reqState <= MessageHeaderRequested;
	 else
	    reqState <= MessageRequested;
      endrule

      //GearBox(Bit#(64),Bit#(32)) gb <- mkNto1Gearbox(defaultClock,defaultReset,defaultClock,defaultReset);
      rule receiveMessage if (reqState == MessageRequested);
	 let vec <- toGet(readMifo).get();
	 let data = vec[0];
	 $display("receiveMessage data=%x messageWords=%d wordCount=%d", data, messageWordsReg, wordCountReg);
	 if (methodIdReg != 16'hFFFF)
	    portal.requests[methodIdReg].enq(data);

	 messageWordsReg <= messageWordsReg - 1;
	 wordCountReg <= wordCountReg - 1;
	 if (messageWordsReg == 1)
	    reqState <= MessageHeaderRequested;
	 else if (wordCountReg <= 1)
	    reqState <= UpdateTail;
      endrule

      rule updateTail if (reqState == UpdateTail);
	 $display("updateTail: tail=%d", reqTailReg);
	 // update the tail pointer
	 writeEngine.writeServers[0].request.put(MemengineCmd {sglId: sglIdReg,
							       base: 8,
							       len: 8,
							       burstLen: 8
							       });
	 writeEngine.dataPipes[0].enq(extend(reqTailReg));
	 reqState <= Waiting;
      endrule
      rule waiting if (reqState == Waiting);
	 let done <- writeEngine.writeServers[0].response.get();
	 $display("done waiting for write");
	 reqState <= Idle;
      endrule

      rule consumeResponse;
	 let response <- readEngine.readServers[0].response.get();
      endrule

   end
   if (valueOf(numIndications) > 0) begin
   end
   interface SharedMemoryPortalConfig cfg;
      method Action setSglId(Bit#(32) id);
	 $display("setSglId id=%d", id);
	 sglIdReg <= id;
	 readyReg <= True;
      endmethod
   endinterface
   interface MemReadClient  readClient = readEngine.dmaClient;
   interface MemWriteClient writeClient = writeEngine.dmaClient;
   interface ReadOnly interrupt;
   endinterface
endmodule
