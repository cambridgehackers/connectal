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

import GetPut::*;
import Connectable::*;
import DefaultValue::*;

typedef struct {
   Bit#(addrWidth) address;
   Bit#(4) len;
   Bit#(3) size; // assume matches bus width of Axi3Client
   Bit#(2) burst;  // drive with 2'b01
   Bit#(3) prot; // drive with 3'b000
   Bit#(4) cache; // drive with 4'b0011
   Bit#(idWidth) id;
   Bit#(2) lock;
   Bit#(4) qos;
} Axi3ReadRequest#(type addrWidth, type idWidth) deriving (Bits);

function Bit#(3) axiBusSize(Integer busWidth);
   if (busWidth == 32)
      return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
   else if (busWidth == 64)
      return 3'b011;
   else if (busWidth == 128)
      return 3'b100;
   else
      return 3'b011;
endfunction

typedef struct {
   Bit#(busWidth) data;
   Bit#(2) resp;
   Bit#(1) last;
   Bit#(idWidth) id;
} Axi3ReadResponse#(type busWidth, type idWidth) deriving (Bits);

typedef struct {
   Bit#(addrWidth) address;
   Bit#(4) len;
   Bit#(3) size; // assume matches bus width of Axi3Client
   Bit#(2) burst;  // drive with 2'b01
   Bit#(3) prot; // drive with 3'b000
   Bit#(4) cache; // drive with 4'b0011
   Bit#(idWidth) id;
   Bit#(2) lock;
   Bit#(4) qos;
} Axi3WriteRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(busWidthBytes) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi3WriteData#(type busWidth, type busWidthBytes, type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) resp;
    Bit#(idWidth) id;
} Axi3WriteResponse#(type idWidth) deriving (Bits);

interface Axi3Client#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Get#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Put#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Get#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Get#(Axi3WriteData#(busWidth, busWidthBytes, idWidth)) resp_write;
   interface Put#(Axi3WriteResponse#(idWidth)) resp_b;
endinterface

interface Axi3Server#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Put#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Get#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Put#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Put#(Axi3WriteData#(busWidth, busWidthBytes, idWidth)) resp_write;
   interface Get#(Axi3WriteResponse#(idWidth)) resp_b;
endinterface

typedef struct {
    Bit#(addrWidth) address;
    Bit#(8) len;
    Bit#(3) size; // assume matches bus width of Axi4Client
    Bit#(2) burst;  // drive with 2'b01
    Bit#(3) prot; // drive with 3'b000
    Bit#(4) cache; // drive with 4'b0011
    Bit#(idWidth) id;
    Bit#(2) lock;
    Bit#(4) qos;
} Axi4ReadRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(2) resp;
    Bit#(1) last;
    Bit#(idWidth) id;
} Axi4ReadResponse#(type busWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(addrWidth) address;
    Bit#(8) len;
    Bit#(3) size; // assume matches bus width of Axi4Client
    Bit#(2) burst;  // drive with 2'b01
    Bit#(3) prot; // drive with 3'b000
    Bit#(4) cache; // drive with 4'b0011
    Bit#(idWidth) id;
    Bit#(2) lock;
    Bit#(4) qos;
} Axi4WriteRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(busWidthBytes) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi4WriteData#(type busWidth, type busWidthBytes, type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) resp;
    Bit#(idWidth) id;
} Axi4WriteResponse#(type idWidth) deriving (Bits);

interface Axi4Client#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Get#(Axi4ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Put#(Axi4ReadResponse#(busWidth, idWidth)) resp_read;

   interface Get#(Axi4WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Get#(Axi4WriteData#(busWidth, busWidthBytes, idWidth)) resp_write;
   interface Put#(Axi4WriteResponse#(idWidth)) resp_b;
endinterface

interface Axi4Server#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Put#(Axi4ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Get#(Axi4ReadResponse#(busWidth, idWidth)) resp_read;
   interface Put#(Axi4WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Put#(Axi4WriteData#(busWidth, busWidthBytes, idWidth)) resp_write;
   interface Get#(Axi4WriteResponse#(idWidth)) resp_b;
endinterface

instance Connectable#(Axi3Client#(addrWidth, busWidth,busWidthBytes,idWidth), Axi3Server#(addrWidth, busWidth,busWidthBytes,idWidth));
   module mkConnection#(Axi3Client#(addrWidth, busWidth,busWidthBytes,idWidth) m, Axi3Server#(addrWidth, busWidth,busWidthBytes,idWidth) s)(Empty);

      mkConnection(m.req_ar, s.req_ar);
      mkConnection(s.resp_read, m.resp_read);

      mkConnection(m.req_aw, s.req_aw);
      mkConnection(m.resp_write, s.resp_write);
      mkConnection(s.resp_b, m.resp_b);

   endmodule
endinstance

instance Connectable#(Axi4Client#(addrWidth, busWidth,busWidthBytes,idWidth), Axi4Server#(addrWidth, busWidth,busWidthBytes,idWidth));
   module mkConnection#(Axi4Client#(addrWidth, busWidth,busWidthBytes,idWidth) m, Axi4Server#(addrWidth, busWidth,busWidthBytes,idWidth) s)(Empty);

      mkConnection(m.req_ar, s.req_ar);
      mkConnection(s.resp_read, m.resp_read);

      mkConnection(m.req_aw, s.req_aw);
      mkConnection(m.resp_write, s.resp_write);
      mkConnection(s.resp_b, m.resp_b);

   endmodule
endinstance
