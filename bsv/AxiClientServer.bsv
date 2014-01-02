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

import RegFile::*;
import BRAMFIFO::*;
import FIFO::*;
import FIFOF::*;
import FIFOLevel::*;
import SpecialFIFOs::*;
import Connectable::*;

typedef struct {
    Bit#(addrWidth) address;
    Bit#(4) burstLen;
    // Bit#(3) burstWidth; // assume matches bus width of Axi3Client
    // Bit#(2) readBurstType();  // drive with 2'b01
    // Bit#(2) readBurstProt(); // drive with 3'b000
    // Bit#(3) readBurstCache(); // drive with 4'b0011
    Bit#(idWidth) id;
} Axi3ReadRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(2) code;
    Bit#(1) last;
    Bit#(idWidth) id;
} Axi3ReadResponse#(type busWidth, type idWidth) deriving (Bits);

interface Axi3ReadClient#(type addrWidth, type busWidth, type idWidth);
   method ActionValue#(Axi3ReadRequest#(addrWidth, idWidth)) address();
   method Action data(Axi3ReadResponse#(busWidth, idWidth) response);
endinterface

typedef struct {
    Bit#(addrWidth) address;
    Bit#(4) burstLen;
    // Bit#(3) burstWidth; // assume matches bus width of Axi3Client
    // Bit#(2) burstType;  // drive with 2'b01
    // Bit#(2) burstProt; // drive with 3'b000
    // Bit#(3) burstCache; // drive with 4'b0011
    Bit#(idWidth) id;
} Axi3WriteRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(busWidthBytes) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi3WriteData#(type busWidth, type busWidthBytes, type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) code;
    Bit#(idWidth) id;
} Axi3WriteResponse#(type idWidth) deriving (Bits);

interface Axi3WriteClient#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   method ActionValue#(Axi3WriteRequest#(addrWidth, idWidth)) address();
   method ActionValue#(Axi3WriteData#(busWidth, busWidthBytes, idWidth)) data();
   method Action response(Axi3WriteResponse#(idWidth) response);
endinterface

interface Axi3Client#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Axi3ReadClient#(addrWidth, busWidth, idWidth) read;
   interface Axi3WriteClient#(addrWidth, busWidth, busWidthBytes, idWidth) write;
endinterface

module mkAxi3Client#(Axi3WriteClient#(addrWidth, busWidth,busWidthBytes,idWidth) writeClient,
                     Axi3ReadClient#(addrWidth, busWidth,idWidth) readClient)
                    (Axi3Client#(addrWidth, busWidth, busWidthBytes, idWidth));
    interface Axi3ReadClient read = readClient;
    interface Axi3WriteClient write = writeClient;
endmodule

interface Axi3ReadServer#(type addrWidth, type busWidth, type idWidth);
   method Action address(Axi3ReadRequest#(addrWidth, idWidth) request);
   method ActionValue#(Axi3ReadResponse#(busWidth, idWidth)) data();
endinterface

interface Axi3WriteServer#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   method Action address(Axi3WriteRequest#(addrWidth, idWidth) request);
   method Action data(Axi3WriteData#(busWidth, busWidthBytes, idWidth) data);
   method ActionValue#(Axi3WriteResponse#(idWidth)) response();
endinterface

interface Axi3Server#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Axi3ReadServer#(addrWidth, busWidth, idWidth) read;
   interface Axi3WriteServer#(addrWidth, busWidth, busWidthBytes, idWidth) write;
endinterface

typedef struct {
    Bit#(addrWidth) address;
    Bit#(8) burstLen;
    // Bit#(3) burstWidth; // assume matches bus width of Axi4Client
    // Bit#(2) readBurstType();  // drive with 2'b01
    // Bit#(2) readBurstProt(); // drive with 3'b000
    // Bit#(3) readBurstCache(); // drive with 4'b0011
    Bit#(idWidth) id;
} Axi4ReadRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(2) code;
    Bit#(1) last;
    Bit#(idWidth) id;
} Axi4ReadResponse#(type busWidth, type idWidth) deriving (Bits);

interface Axi4ReadClient#(type addrWidth, type busWidth, type idWidth);
   method ActionValue#(Axi4ReadRequest#(addrWidth, idWidth)) address();
   method Action data(Axi4ReadResponse#(busWidth, idWidth) response);
endinterface

typedef struct {
    Bit#(addrWidth) address;
    Bit#(8) burstLen;
    // Bit#(3) burstWidth; // assume matches bus width of Axi4Client
    // Bit#(2) burstType;  // drive with 2'b01
    // Bit#(2) burstProt; // drive with 3'b000
    // Bit#(3) burstCache; // drive with 4'b0011
    Bit#(idWidth) id;
} Axi4WriteRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(busWidthBytes) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi4WriteData#(type busWidth, type busWidthBytes, type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) code;
    Bit#(idWidth) id;
} Axi4WriteResponse#(type idWidth) deriving (Bits);

interface Axi4WriteClient#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   method ActionValue#(Axi4WriteRequest#(addrWidth, idWidth)) address();
   method ActionValue#(Axi4WriteData#(busWidth, busWidthBytes, idWidth)) data();
   method Action response(Axi4WriteResponse#(idWidth) response);
endinterface

interface Axi4Client#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Axi4ReadClient#(addrWidth, busWidth, idWidth) read;
   interface Axi4WriteClient#(addrWidth, busWidth, busWidthBytes, idWidth) write;
endinterface

module mkAxi4Client#(Axi4WriteClient#(addrWidth, busWidth,busWidthBytes,idWidth) writeClient,
                     Axi4ReadClient#(addrWidth, busWidth,idWidth) readClient)
                    (Axi4Client#(addrWidth, busWidth, busWidthBytes, idWidth));
    interface Axi4ReadClient read = readClient;
    interface Axi4WriteClient write = writeClient;
endmodule

interface Axi4ReadServer#(type addrWidth, type busWidth, type idWidth);
   method Action address(Axi4ReadRequest#(addrWidth, idWidth) request);
   method ActionValue#(Axi4ReadResponse#(busWidth, idWidth)) data();
endinterface

interface Axi4WriteServer#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   method Action address(Axi4WriteRequest#(addrWidth, idWidth) request);
   method Action data(Axi4WriteData#(busWidth, busWidthBytes, idWidth) data);
   method ActionValue#(Axi4WriteResponse#(idWidth)) response();
endinterface

interface Axi4Server#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Axi4ReadServer#(addrWidth, busWidth, idWidth) read;
   interface Axi4WriteServer#(addrWidth, busWidth, busWidthBytes, idWidth) write;
endinterface

instance Connectable#(Axi3Client#(addrWidth, busWidth,busWidthBytes,idWidth), Axi3Server#(addrWidth, busWidth,busWidthBytes,idWidth));
   module mkConnection#(Axi3Client#(addrWidth, busWidth,busWidthBytes,idWidth) m, Axi3Server#(addrWidth, busWidth,busWidthBytes,idWidth) s)(Empty);

      rule connectionReadAddr;
         let req <- m.read.address();
         s.read.address(req);
      endrule
      rule connectionReadData;
         let d <- s.read.data();
         m.read.data(d);
      endrule

      rule connectionWriteAddr;
         let req <- m.write.address();
         s.write.address(req);
      endrule
      (* aggressive_implicit_conditions *)
      rule connectionWriteData;
         let d <- m.write.data();
         s.write.data(d);
      endrule
      rule connectionWriteResponse;
         let r <- s.write.response();
         m.write.response(r);
      endrule

   endmodule
endinstance

instance Connectable#(Axi4Client#(addrWidth, busWidth,busWidthBytes,idWidth), Axi4Server#(addrWidth, busWidth,busWidthBytes,idWidth));
   module mkConnection#(Axi4Client#(addrWidth, busWidth,busWidthBytes,idWidth) m, Axi4Server#(addrWidth, busWidth,busWidthBytes,idWidth) s)(Empty);

      rule connectionReadAddr;
         let req <- m.read.address();
         s.read.address(req);
      endrule
      rule connectionReadData;
         let d <- s.read.data();
         m.read.data(d);
      endrule

      rule connectionWriteAddr;
         let req <- m.write.address();
         s.write.address(req);
      endrule
      rule connectionWriteData;
         let d <- m.write.data();
         s.write.data(d);
      endrule
      rule connectionWriteResponse;
         let r <- s.write.response();
         m.write.response(r);
      endrule

   endmodule
endinstance
