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

typedef struct {
    Bit#(32) address;
    Bit#(4) burstLen;
    // Bit#(3) burstWidth; // assume matches bus width of Axi3Client
    // Bit#(2) readBurstType();  // drive with 2'b01
    // Bit#(2) readBurstProt(); // drive with 3'b000
    // Bit#(3) readBurstCache(); // drive with 4'b0011
    Bit#(idWidth) id;
} Axi3ReadRequest#(type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(2) code;
    Bit#(1) last;
    Bit#(idWidth) id;
} Axi3ReadResponse#(type busWidth, type idWidth) deriving (Bits);

interface Axi3ReadClient#(type busWidth, type idWidth);
   method ActionValue#(Axi3ReadRequest#(idWidth)) address();
   method Action data(Axi3ReadResponse#(busWidth, idWidth) response);
endinterface

typedef struct {
    Bit#(32) address;
    Bit#(4) burstLen;
    // Bit#(3) burstWidth; // assume matches bus width of Axi3Client
    // Bit#(2) burstType;  // drive with 2'b01
    // Bit#(2) burstProt; // drive with 3'b000
    // Bit#(3) burstCache; // drive with 4'b0011
    Bit#(idWidth) id;
} Axi3WriteRequest#(type idWidth) deriving (Bits);

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

interface Axi3WriteClient#(type busWidth, type busWidthBytes, type idWidth);
   method ActionValue#(Axi3WriteRequest#(idWidth)) address();
   method ActionValue#(Axi3WriteData#(busWidth, busWidthBytes, idWidth)) data();
   method Action response(Axi3WriteResponse#(idWidth) response);
endinterface

interface Axi3Client#(type busWidth, type busWidthBytes, type idWidth);
   interface Axi3ReadClient#(busWidth, idWidth) read;
   interface Axi3WriteClient#(busWidth, busWidthBytes, idWidth) write;
endinterface

module mkAxi3Client#(Axi3WriteClient#(busWidth,busWidthBytes,idWidth) writeClient,
                     Axi3ReadClient#(busWidth,idWidth) readClient)
                    (Axi3Client#(busWidth, busWidthBytes, idWidth));
    interface Axi3ReadClient read = readClient;
    interface Axi3WriteClient write = writeClient;
endmodule

interface Axi3ReadServer#(type busWidth, type idWidth);
   method Action address(Axi3ReadRequest#(idWidth) request);
   method ActionValue#(Axi3ReadResponse#(busWidth, idWidth)) data();
endinterface

interface Axi3WriteServer#(type busWidth, type busWidthBytes, type idWidth);
   method Action address(Axi3WriteRequest#(idWidth) request);
   method Action data(Axi3WriteData#(busWidth, busWidthBytes, idWidth) data);
   method ActionValue#(Axi3WriteResponse#(idWidth)) response();
endinterface

interface Axi3Server#(type busWidth, type busWidthBytes, type idWidth);
   interface Axi3ReadServer#(busWidth, idWidth) read;
   interface Axi3WriteServer#(busWidth, busWidthBytes, idWidth) write;
endinterface
