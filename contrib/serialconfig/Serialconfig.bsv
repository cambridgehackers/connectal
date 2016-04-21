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

import FIFO::*;
import SpiTap::*;
import SpiRoot::*;
import Connectable::*;

interface SerialconfigIndication;
   method Action ack(Bit#(32) a, Bit#(32) d);
endinterface
      
interface SerialconfigRequest;
   method Action send(Bit#(32) a, Bit#(32) d);
endinterface

interface Serialconfig;
    interface SerialconfigRequest request;
endinterface

module mkSerialconfig#(SerialconfigIndication indication)(Serialconfig);

   
   SpiReg#(Bit#(32)) tap1 <- mkSpiReg('h11110000);
   SpiReg#(Bit#(24)) tap2 <- mkSpiReg('h22220000);
   SpiReg#(Bit#(16)) tap3 <- mkSpiReg('h33330000);
   SpiReg#(Bit#(8)) tap4 <- mkSpiReg('h44440000);

   mkConnection(tap1.tap.out, tap2.tap.in);
   mkConnection(tap2.tap.out, tap3.tap.in);
   mkConnection(tap3.tap.out, tap4.tap.in);

   FIFO#(SpiItem) spi <- mkSpiRoot(SpiTap{in: tap1.tap.in, out: tap4.tap.out});
  
   rule getresults;
      indication.ack(spi.first().a, spi.first().d);
      spi.deq();
   endrule

   interface SerialconfigRequest request;
 
      method Action send(Bit#(32) a, Bit#(32) d);
         spi.enq(SpiItem{a: a, d: d});
      endmethod

  endinterface
   
endmodule
