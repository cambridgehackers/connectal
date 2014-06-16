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
   AddressGenerator#(addrWidth) ctrlReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(addrWidth) ctrlWriteAddrGenerator <- mkAddressGenerator();
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
	       let b <- ctrlWriteAddrGenerator.addrBeat.get();
	       $display("mkCtrl.writeData addr=%h data=%h last=%d", b.addr, d.data, b.last);
	       let v = d.data;
	       let addr = b.addr;
	       if (addr == 'h000)
		  noAction;
	       if (addr == 'h004)
		  interruptEnableReg <= v[0] == 1'd1;
	       if (b.last)
		  ctrlWriteDoneFifo.enq(b.tag);
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

module mkPipeInMemSlave#(PipeIn#(Bit#(dataWidth)) methodPipe)(MemSlave#(addrWidth, dataWidth));

   AddressGenerator#(addrWidth) fifoReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(addrWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(ObjectTagSize))        fifoWriteDoneFifo <- mkFIFO();
   FIFO#(Bool)                           putFailedFifo <- mkFIFO();

   interface MemReadServer read_server;
      interface Put readReq = fifoReadAddrGenerator.request;
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let b <- fifoReadAddrGenerator.addrBeat.get();
	    return MemData { data: 0, tag: b.tag, last: b.last };
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

module mkPipeOutMemSlave#(PipeOut#(Bit#(dataWidth)) methodPipe)(MemSlave#(addrWidth, dataWidth));
   AddressGenerator#(addrWidth) fifoReadAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(addrWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(ObjectTagSize))                  fifoWriteDoneFifo <- mkFIFO();
   interface MemReadServer read_server;
      interface Put readReq;
	 method Action put(MemRequest#(addrWidth) req);
	    fifoReadAddrGenerator.request.put(req);
	    if (!methodPipe.notEmpty())
	       $display("***\n\n underflow! \n\n****");
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let b <- fifoReadAddrGenerator.addrBeat.get();
	    let data <- toGet(methodPipe).get();
	    //$display("mkPipeOutMemSlave.readData.get addr=%h data=%h", b.addr, data);
	    return MemData { data: data, tag: b.tag, last: b.last };
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
   provisos (Add#(c__, 15, slaveAddrWidth),
	     Add#(d__, 1, c__),
	     Max#(numRequests,1,numRequestsToMux),
	     Max#(numIndications,1,numIndicationsToMux),

	     Add#(a__, TLog#(numRequestsToMux), 6),
	     Add#(b__, TLog#(numIndicationsToMux), 6),
	     Add#(numIndications, e__, numIndicationsToMux),
	     Add#(numRequests, f__, numRequestsToMux),
	     Add#(numIndicationsToMux, g__, TAdd#(numIndications, 1)),
	     Add#(numRequestsToMux, h__, TAdd#(numRequests, 1))
	     );

   PipeIn#(Bit#(slaveDataWidth)) guardRequestPipe =
      (interface PipeIn#(Bit#(slaveDataWidth));
	  method Action enq(Bit#(slaveDataWidth) v) if (False); endmethod
	  method Bool notFull(); return False; endmethod
       endinterface);
   FIFOF#(Bit#(slaveDataWidth)) putFailedIndicationFifo <- mkFIFOF();
   PipeOut#(Bit#(slaveDataWidth)) putFailedIndicationPipe = toPipeOut(putFailedIndicationFifo);

   Vector#(numRequestsToMux,    PipeIn#(Bit#(slaveDataWidth)))     requestPipes = take(append(portal.requests, cons(guardRequestPipe, nil)));
   Vector#(numIndicationsToMux, PipeOut#(Bit#(slaveDataWidth))) indicationPipes = take(append(portal.indications, cons(putFailedIndicationPipe, nil)));
   Vector#(numRequestsToMux,    MemSlave#(8, slaveDataWidth))    requestMemSlaves <- mapM(mkPipeInMemSlave, requestPipes);
   Vector#(numIndicationsToMux, MemSlave#(8, slaveDataWidth)) indicationMemSlaves <- mapM(mkPipeOutMemSlave, indicationPipes);

   MemSlave#(14,slaveDataWidth) requestFifoMemSlave    <- mkMemSlaveMux(requestMemSlaves);
   MemSlave#(14,slaveDataWidth) indicationFifoMemSlave <- mkMemSlaveMux(indicationMemSlaves);

   MemSlave#(14,slaveDataWidth)     requestCtrlMemSlave <- mkPipeInMemSlave(guardRequestPipe);
   PortalCtrlMemSlave#(14,slaveDataWidth) indicationCtrlPort <- mkPortalCtrlMemSlave(indicationPipes);

   MemSlave#(15,slaveDataWidth) requestMemSlave <- mkMemSlaveMux(cons(requestFifoMemSlave, cons(requestCtrlMemSlave, nil)));
   MemSlave#(15,slaveDataWidth) indicationMemSlave <- mkMemSlaveMux(cons(indicationFifoMemSlave, cons(indicationCtrlPort.memSlave, nil)));

   MemSlave#(slaveAddrWidth,slaveDataWidth) memslave  <- mkMemSlaveMux(cons(requestMemSlave, cons(indicationMemSlave, nil)));

   method ifcId   = portal.ifcId;
   method ifcType = portal.ifcType;

   interface MemSlave slave = memslave;
   interface ReadOnly interrupt = indicationCtrlPort.interrupt;
endmodule
