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

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module XsimSink(input CLK, input CLK_GATE, input RST, input [31:0] portal, output RDY_beat, input EN_beat, output [31:0] beat);
   reg     valid_reg;
   reg 	   [31:0] beat_reg;
   
   import "DPI-C" function longint dpi_msgSink_beat(input int portal);

   assign RDY_beat = valid_reg;
   assign beat = beat_reg;
   
   always @(posedge CLK) begin
      if (RST == `BSV_RESET_VALUE) begin
	 valid_reg <= 0;
	 beat_reg <= 32'haaaaaaaa;
      end
      else if (EN_beat == 1 || valid_reg == 0) begin
`ifndef BOARD_cvc
	 automatic longint v = dpi_msgSink_beat(portal);
	 valid_reg <= v[32];
	 beat_reg <= v[31:0];
`else
	 { valid_reg, beat_reg } <= dpi_msgSink_beat(portal);
`endif
      end
   end
endmodule
