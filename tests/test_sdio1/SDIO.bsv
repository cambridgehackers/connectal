
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
import XilinxCells::*;
import SDIORequest::*;
import SDIOIndication::*;

interface SDIOPins;
   method Bit#(1) clk;
   interface Inout cmd;
   interface Inout dat0;
   interface Inout dat1;
   interface Inout dat2;
   interface Inout dat3;
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
   let cmdb <- mkIOBUF(~sdio.cmdn, sdio.cmdo);
   
   rule xxx;
      sdio.cmdi(cmdb.o);
      sdio.clkfp(sdio.clk);
      sdio.wp(wp_reg);
      sdio.cd(cd_reg);
   endrule

   interface SDIORequest req;
      method Action read_req(Bit#(4) idx);
	 ind.read_resp(0);
      endmethod
   endinterface
   
   interface SDIOPins pins;
      method Bit#(1) clk = sdio.clk;
      interface cmd = cmdb.io;
      interface d0 = ?;
      interface d1 = ?;
      interface d2 = ?;
      interface d3 = ?;
      method Action cd(Bit#(1) v) = cd_reg._write(v);
      method Action wp(Bit#(1) v) = wp_reg._write(v);
   endinterface

endmodule : mkConnectalTop

export HBridgeController::*;
export HBridgeSimplePins;
export mkConnectalTop;

