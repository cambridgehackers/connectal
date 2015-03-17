// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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


import FIFO::*;
import GetPut::*;
import SpecialFIFOs::*;
import MemTypes::*;


interface PhysMemConnector#(numeric type addrWidth, numeric type dataWidth);
   interface PhysMemSlave#(addrWidth,dataWidth) slave;
   interface PhysMemMaster#(addrWidth,dataWidth) master;
endinterface

interface MemwriteConnector#(numeric type dataWidth);
   interface MemWriteServer#(dataWidth) server;
   interface MemWriteClient#(dataWidth) client;
endinterface

interface MemreadConnector#(numeric type dataWidth);
   interface MemReadServer#(dataWidth) server;
   interface MemReadClient#(dataWidth) client;
endinterface

function PhysMemSlave#(aw,dw) getPhysMemConnectorSlave(PhysMemConnector#(aw,dw) s);
   return s.slave;
endfunction

// TODO: all the connectors could probably be conflated if we redefined MemRequest (mdk)

module mkMemwriteConnector(MemwriteConnector#(dataWidth));
   FIFO#(MemRequest) write_req <- mkBypassFIFO;
   FIFO#(MemData#(dataWidth)) write_data <- mkBypassFIFO;
   FIFO#(Bit#(MemTagSize))    write_done <- mkBypassFIFO;
   interface MemWriteServer server; 
      interface Put writeReq;
	 method Action put(MemRequest r);
	    write_req.enq(r);
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(dataWidth) d);
	    write_data.enq(d);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(MemTagSize)) get;
	    write_done.deq;
	    return write_done.first;
	 endmethod
      endinterface
   endinterface
   interface MemWriteClient client; 
      interface Get writeReq;
	 method ActionValue#(MemRequest) get;
	    write_req.deq;
	    return write_req.first;
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(dataWidth)) get;
	    write_data.deq;
	    return write_data.first;
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(MemTagSize) t);
	    write_done.enq(t);
	 endmethod
      endinterface
   endinterface
endmodule

module mkMemreadConnector(MemreadConnector#(dataWidth));
   FIFO#(MemRequest) read_req <- mkBypassFIFO;
   FIFO#(MemData#(dataWidth)) read_data <- mkBypassFIFO;
   interface MemReadServer server;
      interface Put readReq;
	 method Action put(MemRequest r);
	    read_req.enq(r);
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get;
	    read_data.deq;
	    return read_data.first;
	 endmethod
      endinterface
   endinterface
   interface MemReadClient client;
      interface Get readReq;
	 method ActionValue#(MemRequest) get;
	    read_req.deq;
	    return read_req.first;
	 endmethod
      endinterface
      interface Put readData;
	 method Action put(MemData#(dataWidth) d);
	    read_data.enq(d);
	 endmethod
      endinterface
   endinterface
endmodule

module mkPhysMemConnector(PhysMemConnector#(addrWidth,dataWidth));
   FIFO#(PhysMemRequest#(addrWidth)) read_req <- mkBypassFIFO;
   FIFO#(PhysMemRequest#(addrWidth)) write_req <- mkBypassFIFO;
   FIFO#(MemData#(dataWidth)) read_data <- mkBypassFIFO;
   FIFO#(MemData#(dataWidth)) write_data <- mkBypassFIFO;
   FIFO#(Bit#(MemTagSize))    write_done <- mkBypassFIFO;
   interface PhysMemSlave slave;
      interface PhysMemReadServer read_server;
	 interface Put readReq;
	    method Action put(PhysMemRequest#(addrWidth) r);
	       read_req.enq(r);
	    endmethod
	 endinterface
	 interface Get readData;
	    method ActionValue#(MemData#(dataWidth)) get;
	       read_data.deq;
	       return read_data.first;
	    endmethod
	 endinterface
      endinterface
      interface PhysMemWriteServer write_server; 
	 interface Put writeReq;
	    method Action put(PhysMemRequest#(addrWidth) r);
	       write_req.enq(r);
	    endmethod
	 endinterface
	 interface Put writeData;
	    method Action put(MemData#(dataWidth) d);
	       write_data.enq(d);
	    endmethod
	 endinterface
	 interface Get writeDone;
	    method ActionValue#(Bit#(MemTagSize)) get;
	       write_done.deq;
	       return write_done.first;
	    endmethod
	 endinterface
      endinterface
   endinterface
   interface PhysMemMaster master;
      interface PhysMemReadClient read_client;
	 interface Get readReq;
	    method ActionValue#(PhysMemRequest#(addrWidth)) get;
	       read_req.deq;
	       return read_req.first;
	    endmethod
	 endinterface
	 interface Put readData;
	    method Action put(MemData#(dataWidth) d);
	       read_data.enq(d);
	    endmethod
	 endinterface
      endinterface
      interface PhysMemWriteClient write_client; 
	 interface Get writeReq;
	    method ActionValue#(PhysMemRequest#(addrWidth)) get;
	       write_req.deq;
	       return write_req.first;
	    endmethod
	 endinterface
	 interface Get writeData;
	    method ActionValue#(MemData#(dataWidth)) get;
	       write_data.deq;
	       return write_data.first;
	    endmethod
	 endinterface
	 interface Put writeDone;
	    method Action put(Bit#(MemTagSize) t);
	       write_done.enq(t);
	    endmethod
	 endinterface
      endinterface
   endinterface
endmodule
	