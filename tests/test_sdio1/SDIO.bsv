
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

import Vector::*;
import ConnectalXilinxCells::*;
import PPS7LIB::*;

interface SDIOPins;
   method Bit#(1) clk;
   interface Inout#(Bit#(1)) cmd;
   interface Inout#(Bit#(1)) d0;
   interface Inout#(Bit#(1)) d1;
   interface Inout#(Bit#(1)) d2;
   interface Inout#(Bit#(1)) d3;
   method Action cd(Bit#(1) v);
   method Action wp(Bit#(1) v);
endinterface

interface SDIORequest;
   method Action read_req(Bit#(4) idx);
endinterface

interface SDIOResponse;
   method Action read_resp(Bit#(1) v);
endinterface

interface Controller;
   interface SDIOPins pins;
   interface SDIORequest req;
endinterface

module mkController#(SDIOResponse ind, Pps7Emiosdio sdio)(Controller);
   
   Reg#(Bit#(1)) cd_reg <- mkReg(0);
   Reg#(Bit#(1)) wp_reg <- mkReg(0);
   let cmdb <- mkIOBUF(~sdio.cmdtn, sdio.cmdo);
   
   let d0b <- mkIOBUF(~sdio.datatn[0], sdio.datao[0]);
   let d1b <- mkIOBUF(~sdio.datatn[1], sdio.datao[1]);
   let d2b <- mkIOBUF(~sdio.datatn[2], sdio.datao[2]);
   let d3b <- mkIOBUF(~sdio.datatn[3], sdio.datao[3]);
   
   rule xxx;
      sdio.cmdi(cmdb.o);
      sdio.clkfb(sdio.clk);
      sdio.wp(wp_reg);
      sdio.cdn(~cd_reg);
   endrule

   interface SDIORequest req;
      method Action read_req(Bit#(4) idx);
	 ind.read_resp(0);
      endmethod
   endinterface
   
   interface SDIOPins pins;
      method Bit#(1) clk = sdio.clk;
      interface cmd = cmdb.io;
      interface d0 = d0b.io;
      interface d1 = d1b.io;
      interface d2 = d2b.io;
      interface d3 = d3b.io;
      method Action cd(Bit#(1) v) = cd_reg._write(v);
      method Action wp(Bit#(1) v) = wp_reg._write(v);
   endinterface

endmodule


