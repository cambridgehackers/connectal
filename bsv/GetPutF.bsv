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

import GetPut::*;
import Connectable::*;
import FIFOF::*;
import FIFOLevel::*;
import BRAMFIFOFLevel::*;

import PCIE :: *; // ConnectableWithClocks
import Clocks :: *;

interface GetF#(type a);
   method ActionValue#(a) get();
   method Bool notEmpty();
endinterface

interface PutF#(type a);
   method Action put(a v);
   method Bool notFull();
endinterface

instance ToGet#(GetF#(b), b);
   function Get#(b) toGet(GetF#(b) getf);
      return (interface Get;
	      method get = getf.get;
	      endinterface);
   endfunction
endinstance

instance ToPut#(PutF#(b), b);
   function Put#(b) toPut(PutF#(b) putf);
      return (interface Put;
	      method put = putf.put;
	      endinterface);
   endfunction
endinstance

instance Connectable#(GetF#(a), Put#(a));
   module mkConnection#(GetF#(a) source, Put#(a) sink)(Empty);
      rule connectGetPutF;
	 let v <- source.get();
	 sink.put(v);
      endrule
   endmodule
endinstance

instance Connectable#(GetF#(a), PutF#(a));
   module mkConnection#(GetF#(a) source, PutF#(a) sink)(Empty);
      rule connectGetPutF;
	 let v <- source.get();
	 sink.put(v);
      endrule
   endmodule
endinstance

typeclass ToGetF#(type a, type b);
   function GetF#(b) toGetF(a x);
endtypeclass
typeclass ToPutF#(type a, type b);
   function PutF#(b) toPutF(a x);
endtypeclass

instance ToGetF#(FIFOF#(b), b);
   function GetF#(b) toGetF(FIFOF#(b) fifof);
      return (interface GetF;
	      method ActionValue#(b) get();
	         fifof.deq();
	      return fifof.first();
	      endmethod
	      method Bool notEmpty();
		 return fifof.notEmpty();
	      endmethod
	 endinterface);
   endfunction
endinstance

instance ToPutF#(FIFOF#(b), b);
   function PutF#(b) toPutF(FIFOF#(b) fifof);
      return (interface PutF;
	      method Action put(b x);
	         fifof.enq(x);
	      endmethod
	      method Bool notFull();
		 return fifof.notFull();
	      endmethod
	 endinterface);
   endfunction
endinstance

instance ToGetF#(FIFOLevelIfc#(b,d), b);
   function GetF#(b) toGetF(FIFOLevelIfc#(b,d) fifof);
      return (interface GetF;
	      method ActionValue#(b) get();
	         fifof.deq();
	      return fifof.first();
	      endmethod
	 method Bool notEmpty();
	    return fifof.notEmpty();
	 endmethod
	 endinterface);
   endfunction
endinstance

instance ToPutF#(FIFOLevelIfc#(b,d), b);
   function PutF#(b) toPutF(FIFOLevelIfc#(b,d) fifof);
      return (interface PutF;
	      method Action put(b x);
	         fifof.enq(x);
	      endmethod
	      method Bool notFull();
		 return fifof.notFull();
	      endmethod
	 endinterface);
   endfunction
endinstance

instance ToGetF#(FIFOFLevel#(b,d), b);
   function GetF#(b) toGetF(FIFOFLevel#(b,d) fifof);
      return (interface GetF;
	      method ActionValue#(b) get();
	         fifof.fifo.deq();
	      return fifof.fifo.first();
	      endmethod
	 method Bool notEmpty();
	    return fifof.fifo.notEmpty();
	 endmethod
	 endinterface);
   endfunction
endinstance

instance ToPutF#(FIFOFLevel#(b,d), b);
   function PutF#(b) toPutF(FIFOFLevel#(b,d) fifof);
      return (interface PutF;
	      method Action put(b x);
	         fifof.fifo.enq(x);
	      endmethod
	      method Bool notFull();
		 return fifof.fifo.notFull();
	      endmethod
	 endinterface);
   endfunction
endinstance

typeclass RegToWriteOnly#(type a);
   function WriteOnly#(a) regToWriteOnly(Reg#(a) x);
endtypeclass

instance RegToWriteOnly#(a);
   function WriteOnly#(a) regToWriteOnly(Reg#(a) x);
      return (interface WriteOnly;
		 method Action _write(a v);
		    x._write(v);
		 endmethod
	      endinterface);
   endfunction
endinstance

instance ConnectableWithClocks#(GetF#(a), PutF#(a)) provisos (Bits#(a, awidth));
   module mkConnectionWithClocks#(GetF#(a) in, PutF#(a) out,
                                  Clock inClock, Reset inReset,
                                  Clock outClock, Reset outReset)(Empty) provisos (Bits#(a, awidth));
       SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(1, inClock, inReset, outClock);
       rule doGet;
           let v <- in.get();
	   synchronizer.enq(v);
       endrule
       rule doPut;
           let v = synchronizer.first;
	   synchronizer.deq;
	   out.put(v);
       endrule
   endmodule: mkConnectionWithClocks
endinstance: ConnectableWithClocks

instance ConnectableWithClocks#(GetF#(a), Put#(a)) provisos (Bits#(a, awidth));
   module mkConnectionWithClocks#(GetF#(a) in, Put#(a) out,
                                  Clock inClock, Reset inReset,
                                  Clock outClock, Reset outReset)(Empty) provisos (Bits#(a, awidth));
       SyncFIFOIfc#(a) synchronizer <- mkSyncFIFO(1, inClock, inReset, outClock);
       rule doGet;
           let v <- in.get();
	   synchronizer.enq(v);
       endrule
       rule doPut;
           let v = synchronizer.first;
	   synchronizer.deq;
	   out.put(v);
       endrule
   endmodule: mkConnectionWithClocks
endinstance: ConnectableWithClocks
