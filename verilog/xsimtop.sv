// Copyright (c) 2015 The Connectal Project

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
//`timescale 1ns / 1ps

import "DPI-C" function void dpi_init();
//import "DPI-C" function void dpi_poll();
import "DPI-C" function bit dpi_finish();

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module xsimtop(
`ifndef XSIM
	       CLK, DERIVED_CLK
`endif
);
`ifndef XSIM
   input CLK;
   input DERIVED_CLK;
`else
   reg 	 CLK;
   reg DERIVED_CLK;
`endif
   reg RST_N;
   reg DERIVED_RST_N;
   reg [31:0] count;
   reg finish;

   mkXsimTop xsimtop(.CLK(CLK), .RST_N(RST_N), .CLK_derivedClock(DERIVED_CLK), .RST_N_derivedReset(DERIVED_RST_N)); 
   initial begin
`ifdef XSIM
      CLK = 0;
      DERIVED_CLK = 0;
`endif
      RST_N = `BSV_RESET_VALUE;
      DERIVED_RST_N = `BSV_RESET_VALUE;
      count = 0;
      finish = 0;
      dpi_init();
   end

`ifdef XSIM
   always begin
      #(`MainClockPeriod/2)
	CLK = !CLK;
   end
   always begin
      #(`DerivedClockPeriod/2)
	DERIVED_CLK = !DERIVED_CLK;
   end
`endif
   
   always @(posedge CLK) begin
      count <= count + 1;
      finish <= dpi_finish();
      if (finish) begin
	 $display("simulator calling $finish");
	 $finish();
      end
   end
   always @(`BSV_RESET_EDGE CLK) begin
      if (count == 20) begin
	 RST_N <= !`BSV_RESET_VALUE;
      end
   end
   always @(`BSV_RESET_EDGE DERIVED_CLK) begin
      if (count == (20*`MainClockPeriod/`DerivedClockPeriod)) begin
	 DERIVED_RST_N <= !`BSV_RESET_VALUE;
      end
   end
endmodule


