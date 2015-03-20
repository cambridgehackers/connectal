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
import HostInterface::*;

typedef struct {
    Bit#(1) select;
    Bit#(6) tag;
} ReadReqInfo deriving (Bits);

interface PortalCtrlMemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemSlave#(addrWidth, dataWidth) memSlave;
   interface ReadOnly#(Bool) interrupt;
   interface WriteOnly#(Bit#(dataWidth)) num_portals;
endinterface


module mkPortalCtrlMemSlave#(Bit#(dataWidth) ifcId, 
			     Vector#(numIndications, PipeOut#(Bit#(dataWidth))) indicationPipes)
   (PortalCtrlMemSlave#(addrWidth, dataWidth))
   provisos( Add#(a__, 1, dataWidth)
	    ,Div#(dataWidth, 8, b__)
	    ,Bits#(MemData#(dataWidth), c__)
	    ,Add#(d__, dataWidth, TMul#(dataWidth, 2))
	    );
   
   AddressGenerator#(addrWidth,dataWidth) ctrlReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(addrWidth,dataWidth) ctrlWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(MemData#(dataWidth))        ctrlWriteDataFifo <- mkFIFO();
   FIFO#(Bit#(MemTagSize))        ctrlWriteDoneFifo <- mkFIFO();
   Reg#(Bit#(dataWidth)) num_portals_reg <- mkReg(0);

   function Bool pipeOutNotEmpty(PipeOut#(a) po); return po.notEmpty(); endfunction
   Vector#(numIndications, Bool) readyBits = map(pipeOutNotEmpty, indicationPipes);
   
   Reg#(Bool) interruptEnableReg <- mkReg(False);
   Bool      interruptStatus = False;
   Reg#(Bit#(TMul#(dataWidth,2))) cycle_count <- mkReg(0);
   Reg#(Bit#(dataWidth))    snapshot <- mkReg(0);
   
   Bit#(dataWidth)  readyChannel = -1;
   for (Integer i = valueOf(numIndications) - 1; i >= 0; i = i - 1) begin
      if (readyBits[i]) begin
         interruptStatus = True;
         readyChannel = fromInteger(i);
      end
   end
   
   rule count;
      cycle_count <= cycle_count+1;
   endrule
   let verbose = False;
   
   rule writeDataRule;
      let d <- toGet(ctrlWriteDataFifo).get();
      let b <- ctrlWriteAddrGenerator.addrBeat.get();
      if (verbose) $display("mkCtrl.writeData addr=%h data=%h last=%d", b.addr, d.data, b.last);
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
		  v = fromInteger(valueOf(NumberOfTiles));
               if (addr == 'h00C) begin
		  if (interruptStatus)
		     v = readyChannel+1;
		  else 
		     v = 0;
               end
	       if (addr == 'h010)
		  v = ifcId;
	       if (addr == 'h014)
		  v = num_portals_reg;
	       if (addr == 'h018) begin
		  snapshot <= truncate(cycle_count);
		  v = truncate(cycle_count>>valueOf(dataWidth));
	       end
	       if (addr == 'h01C)
		  v = snapshot;
	       if (verbose) $display("mkCtrl.readData addr=%h data=%h", b.addr, v);
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
   interface WriteOnly num_portals;
      method Action _write(Bit#(dataWidth) v);
	 num_portals_reg <= v;
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
	    if (b.addr == 4)
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
      if (b.addr == 0)
	 v <- toGet(methodPipe).get();
      else if (b.addr == 4)
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
	     ,Add#(c__, 5, slaveAddrWidth)
	     ,Add#(d__, 1, c__)
	     ,Add#(a__, TLog#(TAdd#(1, TAdd#(numRequests, numIndications))), c__)
	     ,Add#(b__, slaveDataWidth, TMul#(slaveDataWidth, 2))
	     );

   Vector#(numRequests,    PipeIn#(Bit#(slaveDataWidth)))     requestPipes = portal.requests;
   Vector#(numIndications, PipeOut#(Bit#(slaveDataWidth))) indicationPipes = portal.indications;
   Vector#(numRequests,    PhysMemSlave#(5, slaveDataWidth))    requestMemSlaves <- mapM(mkPipeInMemSlave, requestPipes);
   Vector#(numIndications, PhysMemSlave#(5, slaveDataWidth)) indicationMemSlaves <- mapM(mkPipeOutMemSlave, indicationPipes);
   
   PortalCtrlMemSlave#(5,slaveDataWidth) ctrlPort <- mkPortalCtrlMemSlave(ifcId, indicationPipes);
   PhysMemSlave#(slaveAddrWidth,slaveDataWidth) memslave  <- mkMemSlaveMux(cons(ctrlPort.memSlave,append(requestMemSlaves, indicationMemSlaves)));
   interface PhysMemSlave slave = memslave;
   interface ReadOnly interrupt = ctrlPort.interrupt;
   interface WriteOnly num_portals = ctrlPort.num_portals;
endmodule
