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
import CtrlMux::*;

import Pipe::*;
import Portal::*;
import MemTypes::*;
import AddressGenerator::*;

typedef struct {
    Bit#(1) select;
    Bit#(6) tag;
} ReadReqInfo deriving (Bits);

interface PortalCtrlMemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface MemSlave#(addrWidth, dataWidth) memSlave;
   interface ReadOnly#(Bool) interrupt;
endinterface

module mkPortalCtrlMemSlave#(Vector#(numIndications, PipeOut#(Bit#(dataWidth))) indicationPipes)(PortalCtrlMemSlave#(addrWidth, dataWidth));
   AddressGenerator#(addrWidth,dataWidth) ctrlReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(addrWidth,dataWidth) ctrlWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(MemData#(dataWidth))        ctrlWriteDataFifo <- mkFIFO();
   FIFO#(Bit#(ObjectTagSize))        ctrlWriteDoneFifo <- mkFIFO();

    // indication-specific state
    Reg#(Bit#(dataWidth)) underflowReadCountReg <- mkReg(0);
    Reg#(Bit#(dataWidth)) outOfRangeReadCountReg <- mkReg(0);
    Reg#(Bit#(dataWidth)) outOfRangeWriteCount <- mkReg(0);
    function Bool pipeOutNotEmpty(PipeOut#(a) po); return po.notEmpty(); endfunction
    Vector#(numIndications, Bool) readyBits = map(pipeOutNotEmpty, indicationPipes);

    Reg#(Bool) interruptEnableReg <- mkReg(False);
    Bool      interruptStatus = False;

    Bit#(dataWidth)  readyChannel = -1;
    for (Integer i = 0; i < valueOf(numIndications); i = i + 1) begin
        if (readyBits[i]) begin
           interruptStatus = True;
           readyChannel = fromInteger(i);
        end
    end

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

   interface MemSlave memSlave;
      interface MemReadServer read_server;
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
	       if (addr == 'h00C)
		  v = underflowReadCountReg;
	       if (addr == 'h010)
		  v = outOfRangeReadCountReg;
	       if (addr == 'h014)
		  v = outOfRangeWriteCount;
               if (addr == 'h018) begin
		  if (interruptStatus)
		     v = readyChannel+1;
		  else 
		     v = 0;
               end
	       //$display("mkCtrl.readData addr=%h data=%h", b.addr, v);
	       return MemData { data: v, tag: b.tag, last: b.last };
	    endmethod
	 endinterface
      endinterface: read_server
      interface MemWriteServer write_server; 
	 interface Put writeReq = ctrlWriteAddrGenerator.request;
	 interface Put writeData;
	    method Action put(MemData#(dataWidth) d);
	       ctrlWriteDataFifo.enq(d);
	    endmethod
	 endinterface
	 interface Get writeDone;
	    method ActionValue#(Bit#(ObjectTagSize)) get();
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
endmodule   

module mkPipeInMemSlave#(PipeIn#(Bit#(dataWidth)) methodPipe)(MemSlave#(addrWidth, dataWidth))
   provisos (Add#(1,a__,dataWidth));

   AddressGenerator#(addrWidth,dataWidth) fifoReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(addrWidth,dataWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(ObjectTagSize))        fifoWriteDoneFifo <- mkFIFO();
   FIFO#(Bool)                           putFailedFifo <- mkFIFO();

   interface MemReadServer read_server;
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
   interface MemWriteServer write_server; 
      interface Put writeReq = fifoWriteAddrGenerator.request;
      interface Put writeData;
	 method Action put((MemData#(dataWidth)) d);
	    let b <- fifoWriteAddrGenerator.addrBeat.get();
	    //$display("mkPipeInMemSlave.writeData.put addr=%h data=%h", b.addr, d.data);
	    if (b.last)
	       fifoWriteDoneFifo.enq(b.tag);
	    if (methodPipe.notFull()) begin
	       // FIXME: handle putFailed
	       methodPipe.enq(d.data);
	    end
	 endmethod
      endinterface
      interface Get writeDone = toGet(fifoWriteDoneFifo);
   endinterface
endmodule

module mkPipeOutMemSlave#(PipeOut#(Bit#(dataWidth)) methodPipe)(MemSlave#(addrWidth, dataWidth))
   provisos (Add#(1,a__,dataWidth));
   AddressGenerator#(addrWidth,dataWidth) fifoReadAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(addrWidth,dataWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(ObjectTagSize))                  fifoWriteDoneFifo <- mkFIFO();
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

   interface MemReadServer read_server;
      interface Put readReq;
	 method Action put(MemRequest#(addrWidth) req);
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
   interface MemWriteServer write_server; 
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

module mkMemPortal#(Portal#(numRequests, numIndications, slaveDataWidth) portal)(MemPortal#(slaveAddrWidth, slaveDataWidth))
   provisos (Add#(1, i__, slaveDataWidth),
	     Add#(c__, 8, slaveAddrWidth),
	     Add#(d__, 1, c__),
	     Max#(numIndications,1,numIndicationsToMux),
	     Add#(a__, TLog#(TAdd#(1, TAdd#(numRequests, numIndicationsToMux))), c__),
	     Add#(numIndicationsToMux, b__, TAdd#(numIndications, 1))
	     );

   PipeIn#(Bit#(slaveDataWidth)) guardRequestPipe =
      (interface PipeIn#(Bit#(slaveDataWidth));
	  method Action enq(Bit#(slaveDataWidth) v) if (False); endmethod
	  method Bool notFull(); return False; endmethod
       endinterface);
   Vector#(1, PipeIn#(Bit#(slaveDataWidth))) guardRequestPipes = replicate(guardRequestPipe);

   FIFOF#(Bit#(slaveDataWidth)) putFailedIndicationFifo <- mkFIFOF();
   PipeOut#(Bit#(slaveDataWidth)) putFailedIndicationPipe = toPipeOut(putFailedIndicationFifo);

   Vector#(numRequests,         PipeIn#(Bit#(slaveDataWidth)))     requestPipes = take(portal.requests);
   Vector#(numIndicationsToMux, PipeOut#(Bit#(slaveDataWidth))) indicationPipes = take(append(portal.indications, cons(putFailedIndicationPipe, nil)));
   Vector#(numRequests,         MemSlave#(8, slaveDataWidth))    requestMemSlaves <- mapM(mkPipeInMemSlave, requestPipes);
   Vector#(numIndicationsToMux, MemSlave#(8, slaveDataWidth)) indicationMemSlaves <- mapM(mkPipeOutMemSlave, indicationPipes);

   PortalCtrlMemSlave#(8,slaveDataWidth) ctrlPort <- mkPortalCtrlMemSlave(indicationPipes);

   MemSlave#(slaveAddrWidth,slaveDataWidth) memslave  <- mkMemSlaveMux(cons(ctrlPort.memSlave,
									    append(requestMemSlaves, indicationMemSlaves)));

   method ifcId   = portal.ifcId;
   method ifcType = portal.ifcType;

   interface MemSlave slave = memslave;
   interface ReadOnly interrupt = ctrlPort.interrupt;
endmodule
