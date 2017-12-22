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

import FIFOF::*;
import FIFO::*;
import GetPut::*;
import GetPutWithClocks::*;
import Connectable::*;
import RegFile::*;


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

typedef struct {
   Bit#(addrWidth) address;
   Bit#(4) len;
   Bit#(3) size; // assume matches bus width of Axi3Master
   Bit#(2) burst;  // drive with 2'b01
   Bit#(3) prot; // drive with 3'b000
   Bit#(4) cache; // drive with 4'b0011
   Bit#(idWidth) id;
   Bit#(2) lock;
   Bit#(4) qos;
} Axi3ReadRequest#(numeric type addrWidth, numeric type idWidth) deriving (Bits);

function Bit#(3) axiBusSize(Integer busWidth);
   if (busWidth == 16)
      return 3'b001;
   else if (busWidth == 32)
      return 3'b010;
   else if (busWidth == 64)
      return 3'b011;
   else if (busWidth == 128)
      return 3'b100;
   else if (busWidth == 256)
      return 3'b101;
   else if (busWidth == 512)
      return 3'b110;
   else if (busWidth == 1024)
      return 3'b111;
   else
      return 3'b000;
endfunction

typedef struct {
   Bit#(busWidth) data;
   Bit#(2) resp;
   Bit#(1) last;
   Bit#(idWidth) id;
} Axi3ReadResponse#(numeric type busWidth, numeric type idWidth) deriving (Bits);

typedef struct {
   Bit#(addrWidth) address;
   Bit#(4) len;
   Bit#(3) size; // assume matches bus width of Axi3Master
   Bit#(2) burst;  // drive with 2'b01
   Bit#(3) prot; // drive with 3'b000
   Bit#(4) cache; // drive with 4'b0011
   Bit#(idWidth) id;
   Bit#(2) lock;
   Bit#(4) qos;
} Axi3WriteRequest#(numeric type addrWidth, numeric type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(TDiv#(busWidth,8)) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi3WriteData#(numeric type busWidth, numeric type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) resp;
    Bit#(idWidth) id;
} Axi3WriteResponse#(numeric type idWidth) deriving (Bits);

function Get#(Axi3ReadResponse#(_b,_c)) get_resp_read(Axi3Slave#(_a,_b,_c) x);
   return x.resp_read;
endfunction

function Get#(Axi3WriteResponse#(_c)) get_resp_b(Axi3Slave#(_a,_b,_c) x);
   return x.resp_b;
endfunction

interface Axi3Master#(numeric type addrWidth, numeric type busWidth, numeric type idWidth);
   interface Get#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Put#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Get#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Get#(Axi3WriteData#(busWidth, idWidth)) resp_write;
   interface Put#(Axi3WriteResponse#(idWidth)) resp_b;
endinterface

interface Axi3Slave#(numeric type addrWidth, numeric type busWidth, numeric type idWidth);
   interface Put#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Get#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Put#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Put#(Axi3WriteData#(busWidth, idWidth)) resp_write;
   interface Get#(Axi3WriteResponse#(idWidth)) resp_b;
endinterface

function Put#(t) null_put();
   return (interface Put;
	      method Action put(t x) if (False);
		 noAction;
	      endmethod
	   endinterface);
endfunction

function Get#(t) null_get();
   return (interface Get;
	      method ActionValue#(t) get() if (False);
		 return ?;
	      endmethod
	   endinterface);
endfunction
      
function  Axi3Master#(addrWidth, busWidth, idWidth) null_axi_master();
   return (interface Axi3Master;
	      interface Get req_ar = null_get;
	      interface Put resp_read = null_put;
	      interface Get req_aw = null_get;
	      interface Get resp_write = null_get;
	      interface Put resp_b = null_put;
	   endinterface);
endfunction

instance Connectable#(Axi3Master#(addrWidth, busWidth,idWidth), Axi3Slave#(addrWidth, busWidth,idWidth));
   module mkConnection#(Axi3Master#(addrWidth, busWidth,idWidth) m, Axi3Slave#(addrWidth, busWidth,idWidth) s)(Empty);

      mkConnection(m.req_ar, s.req_ar);
      mkConnection(s.resp_read, m.resp_read);

      mkConnection(m.req_aw, s.req_aw);
      mkConnection(m.resp_write, s.resp_write);
      mkConnection(s.resp_b, m.resp_b);

   endmodule
endinstance


instance ConnectableWithClocks#(Axi3Master#(addrWidth, busWidth,idWidth), Axi3Slave#(addrWidth, busWidth,idWidth))
   provisos (ConnectableWithClocks#(Get#(Axi3ReadRequest#(addrWidth, idWidth)), Put#(Axi3ReadRequest#(addrWidth, idWidth)))
	     ,ConnectableWithClocks#(Get#(Axi3ReadResponse#(busWidth, idWidth)), Put#(Axi3ReadResponse#(busWidth, idWidth)))
	     ,ConnectableWithClocks#(Get#(Axi3WriteRequest#(addrWidth, idWidth)), Put#(Axi3WriteRequest#(addrWidth, idWidth)))
	     ,ConnectableWithClocks#(Get#(Axi3WriteData#(busWidth, idWidth)), Put#(Axi3WriteData#(busWidth, idWidth)))
	     ,ConnectableWithClocks#(Get#(Axi3WriteResponse#(idWidth)), Put#(Axi3WriteResponse#(idWidth)))
	     );

   module mkConnectionWithClocks2#(Axi3Master#(addrWidth, busWidth,idWidth) m, Axi3Slave#(addrWidth, busWidth,idWidth) s)(Empty);
      mkConnectionWithClocks(clockOf(m), resetOf(m), clockOf(s), resetOf(s), m, s);
   endmodule

   module mkConnectionWithClocks#(Clock mClock, Reset mReset, Clock sClock, Reset sReset,
				  Axi3Master#(addrWidth, busWidth,idWidth) m, Axi3Slave#(addrWidth, busWidth,idWidth) s)(Empty);

      mkConnectionWithClocks(mClock, mReset, sClock, sReset, m.req_ar, s.req_ar);
      mkConnectionWithClocks(sClock, sReset, mClock, mReset, s.resp_read, m.resp_read);

      mkConnectionWithClocks(mClock, mReset, sClock, sReset, m.req_aw, s.req_aw);
      mkConnectionWithClocks(mClock, mReset, sClock, sReset, m.resp_write, s.resp_write);
      mkConnectionWithClocks(sClock, sReset, mClock, mReset, s.resp_b, m.resp_b);

   endmodule
endinstance
