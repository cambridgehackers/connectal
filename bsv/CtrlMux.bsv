
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
import RegFileA::*;

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
		   Vector#(numPortals,Portal#(addrWidth,dataWidth)) portals) (PhysicalDmaSlave#(addrWidth,dataWidth))
   provisos(Add#(1,numPortals,numInputs),
	    Add#(1,numInputs,numIfcs),
	    Add#(nz, TLog#(numIfcs), 4));
   
   PhysicalDmaSlave#(addrWidth,dataWidth) out_of_range <- mkPhysicalDmaSlaveOutOfRange;
   Vector#(numIfcs, PhysicalDmaSlave#(addrWidth,dataWidth)) ifcs = append(cons(dir.portalIfc.slave,map(getSlave, portals)),cons(out_of_range, nil));
   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TAdd#(3,aw));
   function Bit#(4) psel(Bit#(addrWidth) a);
      return a[port_sel_high:port_sel_low];
   endfunction
   
   FIFO#(void) req_ar_fifo <- mkSizedFIFO(1);
   Reg#(Bit#(TLog#(numIfcs))) rs <- mkReg(0);
   
   FIFO#(void) req_aw_fifo <- mkSizedFIFO(1);
   Reg#(Bit#(TLog#(numIfcs))) ws <- mkReg(0);
   
   interface PhysicalWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysicalRequest#(addrWidth) req);
	    Bit#(TLog#(numIfcs)) wsv = truncate(psel(req.paddr));
	    if (wsv > fromInteger(valueOf(numInputs)))
	       wsv = fromInteger(valueOf(numInputs));
	    ifcs[wsv].write_server.writeReq.put(req);
	    ws <= wsv;
	    req_aw_fifo.enq(?);
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(DmaData#(dataWidth) wdata);
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
   interface PhysicalReadServer read_server;
      interface Put readReq;
	 method Action put(PhysicalRequest#(addrWidth) req);
	    Bit#(TLog#(numIfcs)) rsv = truncate(psel(req.paddr)); 
	    if (rsv > fromInteger(valueOf(numInputs)))
	       rsv = fromInteger(valueOf(numInputs));
	    ifcs[rsv].read_server.readReq.put(req);
	    req_ar_fifo.enq(?);
	    rs <= rsv;
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(DmaData#(dataWidth)) get();
	    let rv <- ifcs[rs].read_server.readData.get();
	    req_ar_fifo.deq;
	    return rv;
	 endmethod
      endinterface
   endinterface
   
endmodule

