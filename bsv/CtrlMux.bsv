
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
import GetPutF::*;

import AxiMasterSlave::*;
import Portal::*;
import Directory::*;


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

module mkAxiSlaveMux#(Directory#(aw,_a,_b,_c) dir,
		      Vector#(numPortals,Portal#(aw,_a,_b,_c)) portals) (Axi3Slave#(_a,_b,_c))

   provisos(Add#(1,numPortals,numInputs),
	    Add#(1,numInputs,numIfcs),
	    Add#(nz, TLog#(numIfcs), 4));
   
   Axi3Slave#(_a,_b,_c) out_of_range <- mkAxi3SlaveOutOfRange;
   Vector#(numIfcs, Axi3Slave#(_a,_b,_c)) ifcs = append(cons(dir.portalIfc.ctrl,map(getCtrl, portals)),cons(out_of_range, nil));
   Vector#(numIfcs,FIFOF#(Bit#(_c))) req_aw_fifos <- replicateM(mkSizedFIFOF(1));
   
   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TAdd#(3,aw));

   function Bit#(4) psel(Bit#(_a) a);
      return a[port_sel_high:port_sel_low];
   endfunction
   
   function Maybe#(Bit#(TLog#(numIfcs))) xxx(Integer x, GetF#(t) y);
      return (y.notEmpty) ? tagged Valid fromInteger(x) : tagged Invalid;
   endfunction
   
   function Maybe#(Bit#(TLog#(numIfcs))) yyy(Maybe#(Bit#(TLog#(numIfcs))) x, Maybe#(Bit#(TLog#(numIfcs))) y);
      return isValid(x) ? x : y;
   endfunction
   
   function Maybe#(Bit#(TLog#(numIfcs))) zzz(Bit#(_c) r, Integer x, FIFOF#(Bit#(_c)) y);
      return y.notEmpty ? (y.first == r ? tagged Valid fromInteger(x) : tagged Invalid) : tagged Invalid; 
   endfunction
   
   let next_resp_read_idx = fold(yyy, zipWith(xxx, genVector, map(get_resp_read,ifcs)));
   let next_resp_b_idx    = fold(yyy, zipWith(xxx, genVector, map(get_resp_b,   ifcs)));
   
   function Bit#(TLog#(numIfcs)) write_idx(Bit#(_c) r);
      return fromMaybe(?, fold(yyy, zipWith(zzz(r), genVector, req_aw_fifos)));
   endfunction

   interface Put req_aw;
      method Action put(Axi3WriteRequest#(_a,_c) req);
	 Bit#(TLog#(numIfcs)) wsv = truncate(psel(req.address));
	 if (wsv > fromInteger(valueOf(numInputs)))
	    wsv = fromInteger(valueOf(numInputs));
	 ifcs[wsv].req_aw.put(req);
	 if (wsv > 0)
	    dir.writeEvent <= ?;
	 req_aw_fifos[wsv].enq(req.id);
      endmethod
   endinterface
   interface Put resp_write;
      method Action put(Axi3WriteData#(_b,_c) wdata);
	 ifcs[write_idx(wdata.id)].resp_write.put(wdata);
      endmethod
   endinterface
   interface GetF resp_b;
      method ActionValue#(Axi3WriteResponse#(_c)) get() if (next_resp_b_idx matches tagged Valid .idx);
	 let rv <- ifcs[idx].resp_b.get();
	 req_aw_fifos[idx].deq;
	 return rv;
      endmethod
      method Bool notEmpty();
	 return isValid(next_resp_b_idx);
      endmethod
   endinterface
   interface Put req_ar;
      method Action put(Axi3ReadRequest#(_a,_c) req);
	 Bit#(TLog#(numIfcs)) rsv = truncate(psel(req.address)); 
	 if (rsv > fromInteger(valueOf(numInputs)))
	    rsv = fromInteger(valueOf(numInputs));
	 ifcs[rsv].req_ar.put(req);
	 if (rsv > 0)
	    dir.readEvent <= ?;
      endmethod
   endinterface
   interface GetF resp_read;
      method ActionValue#(Axi3ReadResponse#(_b,_c)) get() if (next_resp_read_idx matches tagged Valid .idx);
	 let rv <- ifcs[idx].resp_read.get();
	 return rv;
      endmethod
      method Bool notEmpty();
	 return isValid(next_resp_read_idx);
      endmethod
   endinterface
   
endmodule
