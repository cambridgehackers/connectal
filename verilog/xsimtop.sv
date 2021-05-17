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
`timescale 1ns / 1ps


`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

`ifndef MainClockPeriod
   `define MainClockPeriod 4
`endif
`ifndef DerivedClockPeriod
   `define DerivedClockPeriod 4
`endif
`define XSIM

module xsimtop(
`ifndef XSIM
	       CLK, DERIVED_CLK, sys_clk
`endif
);
`ifndef XSIM
   input CLK;
   input DERIVED_CLK;
   input sys_clk;
`else
   reg 	 CLK;
   reg DERIVED_CLK;
   reg sys_clk;
`endif
   reg RST_N;
   reg DERIVED_RST_N;
   reg [31:0] count;
   reg [31:0] count_derived;
   reg finish;

   import "DPI-C" function void dpi_init(input int unused);
   import "DPI-C" function bit dpi_cycle(input int returns); // unused non-zero if verilog should $finish().

`ifdef __ATOMICC__
   VsimTop connectalTop(.CLK(CLK), .nRST(RST_N),
			  .CLK_derivedClock(DERIVED_CLK), .nRST_derivedReset(DERIVED_RST_N),
			  .CLK_sys_clk(sys_clk));
`else
   mkXsimTop connectalTop(.CLK(CLK), .RST_N(RST_N),
			  .CLK_derivedClock(DERIVED_CLK), .RST_N_derivedReset(DERIVED_RST_N),
			  .CLK_sys_clk(sys_clk));
`endif
   initial begin
`ifdef XSIM
      CLK = 1'b0;
      DERIVED_CLK = 1'b0;
      sys_clk = 1'b0;
`endif
      RST_N = `BSV_RESET_VALUE;
      DERIVED_RST_N = `BSV_RESET_VALUE;
      count = 0;
      count_derived = 0;
      finish = 1'b0;
      dpi_init(0);
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
   always begin
      #2.5
	sys_clk = !sys_clk;
   end
`endif
   
   always @(posedge CLK) begin
      count <= count + 1;
      finish <= dpi_cycle(0);
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
      count_derived <= count_derived + 1;
      if (count_derived == 20) begin
	 DERIVED_RST_N <= !`BSV_RESET_VALUE;
      end
   end
endmodule


