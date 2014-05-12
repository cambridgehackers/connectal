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


module mkSerialconfigRequest#(SerialconfigIndication indication)(SerialconfigRequest);

   
   SpiTap tap1 <- mkSpiTap('h11110000);
   SpiTap tap2 <- mkSpiTap('h22220000);
   SpiTap tap3 <- mkSpiTap('h33330000);
   SpiTap tap4 <- mkSpiTap('h44440000);

   mkConnection(tap1.out, tap2.in);
   mkConnection(tap2.out, tap3.in);
   mkConnection(tap3.out, tap4.in);

   FIFO#(SpiItem) spi <- mkSpiRoot(SpiTap{in: tap1.in, out: tap4.out});
  
   rule getresults;
      indication.ack(spi.first().a, spi.first().d);
      spi.deq();
   endrule

 
   method Action send(Bit#(32) a, Bit#(32) d);
      spi.enq(SpiItem{a: a, d: d});
   endmethod
  
   
endmodule
