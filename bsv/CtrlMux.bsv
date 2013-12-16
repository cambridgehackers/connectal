
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

import AxiMasterSlave::*;
import Portal::*;


module mkInterruptMux#(Vector#(2,         Portal#(aw,_a,_b,_c,_d)) directories, 
		       Vector#(numPortals,Portal#(aw,_a,_b,_c,_d)) portals) (ReadOnly#(Bool))

   provisos(Add#(2,numPortals,numInputs),
	    Add#(nz, TLog#(numInputs), 4),
	    Add#(1, a__, numInputs));
   
   Vector#(2, ReadOnly#(Bool)) d_interrupts = map(getInterrupt, directories);
   Vector#(numPortals, ReadOnly#(Bool)) p_interrupts = map(getInterrupt, portals);
   Vector#(numInputs, ReadOnly#(Bool)) inputs = append(d_interrupts,p_interrupts);
   
   
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

module mkAxiSlaveMux#(Vector#(2,         Portal#(aw,_a,_b,_c,_d)) directories, 
		      Vector#(numPortals,Portal#(aw,_a,_b,_c,_d)) portals) (Axi3Slave#(_a,_b,_c,_d))

   provisos(Add#(2,numPortals,numInputs),
	    Add#(nz, TLog#(numInputs), 4));
   
   Vector#(2, Axi3Slave#(_a,_b,_c,_d)) d_slaves = map(getCtrl, directories);
   Vector#(numPortals, Axi3Slave#(_a,_b,_c,_d)) p_slaves = map(getCtrl, portals);
   Vector#(numInputs, Axi3Slave#(_a,_b,_c,_d)) inputs = append(d_slaves,p_slaves);
   
   Reg#(Bit#(TLog#(numInputs))) ws <- mkReg(0);
   Reg#(Bit#(TLog#(numInputs))) rs <- mkReg(0);

   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TAdd#(3,aw));
   function Bit#(4) psel(Bit#(_a) a);
      return a[port_sel_high:port_sel_low];
   endfunction
   
   interface Axi3SlaveWrite write;
      method Action writeAddr(Bit#(_a) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
			      Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache,
			      Bit#(_d) awid);
	 Bit#(TLog#(numInputs)) wsv = truncate(psel(addr));
	 inputs[wsv].write.writeAddr(addr,burstLen,burstWidth,burstType,burstProt,burstCache,awid);
	 ws <= wsv;
      endmethod
      method Action writeData(Bit#(_b) v, Bit#(_c) byteEnable, Bit#(1) last, Bit#(_d) wid);
	 inputs[ws].write.writeData(v,byteEnable,last,wid);
      endmethod
      method ActionValue#(Bit#(2)) writeResponse();
	 let rv <- inputs[ws].write.writeResponse;
	 return rv;
      endmethod
      method ActionValue#(Bit#(_d)) bid();
	 let rv <- inputs[ws].write.bid;
	 return rv;
      endmethod
   endinterface
   interface Axi3SlaveRead read;
      method Action readAddr(Bit#(_a) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
			     Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(_d) arid);
	 Bit#(TLog#(numInputs)) rsv = truncate(psel(addr)); 
	 inputs[rsv].read.readAddr(addr,burstLen,burstWidth,burstType,burstProt,burstCache,arid);
	 rs <= rsv;
      endmethod
      method Bit#(1) last();
	 return inputs[rs].read.last;
      endmethod
      method Bit#(_d) rid();
         return inputs[rs].read.rid;
      endmethod
      method ActionValue#(Bit#(_b)) readData();
	 let rv <- inputs[rs].read.readData;
	 return rv;
      endmethod
   endinterface
endmodule
