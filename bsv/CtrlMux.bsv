
// Copyright (c) 2012 Nokia, Inc.
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


import Vector::*;
import GetPut::*;
import FIFOF::*;
import SpecialFIFOs::*;
import FIFO::*;

import Portal::*;
import Directory::*;
import Dma::*;

module mkInterruptMux#(Vector#(numPortals,ReadOnly#(Bool)) inputs) (ReadOnly#(Bool))
   provisos(Add#(nz, TLog#(numPortals), 4),
	    Add#(1, a__, numPortals));
   
   function Bool my_read(ReadOnly#(Bool) x);
      return x._read;
   endfunction
   
   function Bool my_or(Bool a, Bool b);
      return a || b;
   endfunction
   
   method Bool _read;
      return fold(my_or,map(my_read,inputs));
   endmethod

endmodule

module mkSlaveMux#(Directory#(aw,addrWidth,dataWidth) dir,
		   Vector#(numPortals,Portal#(addrWidth,dataWidth)) portals) (MemSlave#(addrWidth,dataWidth))
   provisos(Add#(1,numPortals,numIfcs),
	    Add#(nz, TLog#(numIfcs), 4));
   
   Vector#(numIfcs, MemSlave#(addrWidth,dataWidth)) ifcs = cons(dir.portalIfc.slave,map(getSlave, portals));
   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TAdd#(3,aw));
   function Bit#(4) psel(Bit#(addrWidth) a);
      return a[port_sel_high:port_sel_low];
   endfunction
   
   FIFO#(MemRequest#(addrWidth)) req_ars <- mkSizedFIFO(1);
   FIFO#(void) req_ar_fifo <- mkSizedFIFO(1);
   Reg#(Bit#(TLog#(numIfcs))) rs <- mkReg(0);

   FIFO#(MemRequest#(addrWidth)) req_aws <- mkSizedFIFO(1);
   FIFO#(void) req_aw_fifo <- mkSizedFIFO(1);
   Reg#(Bit#(TLog#(numIfcs))) ws <- mkReg(0);
   
   rule req_aw;
      let req <- toGet(req_aws).get;
      ifcs[ws].write_server.writeReq.put(req);
   endrule
      
   rule req_ar;
      let req <- toGet(req_ars).get;
      ifcs[rs].read_server.readReq.put(req);
   endrule
      
   interface MemWriteServer write_server;
      interface Put writeReq;
	 method Action put(MemRequest#(addrWidth) req);
	    ws <= truncate(psel(req.addr));
	    req_aws.enq(req);
	    req_aw_fifo.enq(?);
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(ObjectData#(dataWidth) wdata);
	    ifcs[ws].write_server.writeData.put(wdata);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(6)) get();
	    let rv <- ifcs[ws].write_server.writeDone.get();
	    req_aw_fifo.deq;
	    return rv;
	 endmethod
      endinterface
   endinterface
   interface MemReadServer read_server;
      interface Put readReq;
	 method Action put(MemRequest#(addrWidth) req);
	    rs <= truncate(psel(req.addr)); 
	    req_ars.enq(req);
	    req_ar_fifo.enq(?);
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(ObjectData#(dataWidth)) get();
	    let rv <- ifcs[rs].read_server.readData.get();
	    req_ar_fifo.deq;
	    return rv;
	 endmethod
      endinterface
   endinterface
   
endmodule

