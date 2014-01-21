
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

import AxiClientServer::*;
import Portal::*;


module mkInterruptMux#(Vector#(numPortals,Portal#(aw,_a,_b,_c)) portals) (ReadOnly#(Bool))

   provisos(Add#(nz, TLog#(numPortals), 4),
	    Add#(1, a__, numPortals));
   
   Vector#(numPortals, ReadOnly#(Bool)) inputs = map(getInterrupt, portals);
   
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

module mkAxiSlaveMux#(Vector#(1,         Portal#(aw,_a,_b,_c)) directories, 
		      Vector#(numPortals,Portal#(aw,_a,_b,_c)) portals) (Axi3Server#(_a,_b,_c))

   provisos(Add#(1,numPortals,numInputs),
	    Add#(nz, TLog#(numInputs), 4));
   
   Vector#(1, Axi3Server#(_a,_b,_c)) d_slaves = map(getCtrl, directories);
   Vector#(numPortals, Axi3Server#(_a,_b,_c)) p_slaves = map(getCtrl, portals);
   Vector#(numInputs, Axi3Server#(_a,_b,_c)) inputs = append(d_slaves,p_slaves);
   
   Reg#(Bit#(TLog#(numInputs))) ws <- mkReg(0);
   Reg#(Bit#(TLog#(numInputs))) rs <- mkReg(0);

   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TAdd#(3,aw));
   function Bit#(4) psel(Bit#(_a) a);
      return a[port_sel_high:port_sel_low];
   endfunction
   
   interface Put req_aw;
      method Action put(Axi3WriteRequest#(_a,_c) req);
	 Bit#(TLog#(numInputs)) wsv = truncate(psel(req.address));
	 inputs[wsv].req_aw.put(req);
	 ws <= wsv;
      endmethod
   endinterface
   interface Put resp_write;
      method Action put(Axi3WriteData#(_b,_c) wdata);
	 inputs[ws].resp_write.put(wdata);
      endmethod
   endinterface
   interface Get resp_b;
      method ActionValue#(Axi3WriteResponse#(_c)) get();
	 let rv <- inputs[ws].resp_b.get();
	 return rv;
      endmethod
   endinterface
   interface Put req_ar;
      method Action put(Axi3ReadRequest#(_a,_c) req);
	 Bit#(TLog#(numInputs)) rsv = truncate(psel(req.address)); 
	 inputs[rsv].req_ar.put(req);
	 rs <= rsv;
      endmethod
   endinterface
   interface Get resp_read;
      method ActionValue#(Axi3ReadResponse#(_b,_c)) get();
	 let rv <- inputs[rs].resp_read.get();
	 return rv;
      endmethod
   endinterface
endmodule
