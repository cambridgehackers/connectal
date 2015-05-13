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
import "DPI-C" function void dpi_poll();
import "DPI-C" function void dpi_msgSink_beat(output int beat, output int src_rdy);
import "DPI-C" function void dpi_msgSource_beat(input int beat);

module xsimtop();

   reg CLK;
   reg RST_N;
   reg [31:0] count;
   reg msgSource_src_rdy;
   wire msgSource_dst_rdy_b;
   reg [31:0] msgSource_beat;
   
   reg msgSink_dst_rdy;
   reg msgSink_src_rdy_b;
   reg [31:0] msgSink_beat_v;
   wire       CLK_singleClock, CLK_GATE_singleClock, RST_N_singleReset;
   reg msgSource_dst_rdy_b0;

   mkXsimTop xsimtop(.CLK(CLK),
		     .RST_N(RST_N),
		     .msgSource_src_rdy(msgSource_src_rdy),
		     .msgSource_dst_rdy_b(msgSource_dst_rdy_b),
		     .msgSource_beat(msgSource_beat),
		     .msgSink_dst_rdy(msgSink_dst_rdy),
		     .msgSink_src_rdy_b(msgSink_src_rdy_b),
		     .msgSink_beat_v(msgSink_beat_v),
		     .CLK_singleClock(CLK_singleClock),
		     .CLK_GATE_singleClock(CLK_GATE_singleClock),
		     .RST_N_singleReset(RST_N_singleReset)
		     );

   initial begin
      CLK = 0;
      RST_N = 0;
      count = 0;
      msgSink_src_rdy_b = 0;
      
      dpi_init();
   end

   always begin
      #5 
	CLK = !CLK;
   end

   always @(negedge CLK) begin
      dpi_poll();
   end   

   assign msgSource_dst_rdy_b = 1;
   
   always @(posedge CLK) begin
      count <= count + 1;
      if (count == 10) begin
	 RST_N <= 1;
      end

      if (msgSink_dst_rdy) begin
	 dpi_msgSink_beat(msgSink_beat_v, msgSink_src_rdy_b);
      end
      else begin
	 msgSink_src_rdy_b <= 0;
      end

      if (msgSource_src_rdy) begin
	 dpi_msgSource_beat(msgSource_beat);
         msgSource_dst_rdy_b0 <= 1;
      end
   end
endmodule
