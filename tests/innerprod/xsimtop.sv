//`timescale 1ns / 1ps

import "DPI-C" function int dpi_msgSink_src_rdy_b();
import "DPI-C" function int dpi_msgSink_beat();
import "DPI-C" function int dpi_msgSource_dst_rdy_b();
import "DPI-C" function int dpi_msgSource_beat(int x);

module xsimtop();

   reg CLK;
   reg RST_N;
   reg [31:0] count;
   reg msgSource_src_rdy;
   reg msgSource_dst_rdy_b;
   reg [31:0] msgSource_beat;
   reg msgSink_dst_rdy;
   reg msgSink_src_rdy_b;
   reg [31:0] msgSink_beat_v;
   wire       CLK_singleClock, CLK_GATE_singleClock, RST_N_singleReset;
   

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
      msgSource_dst_rdy_b = 0;
      msgSink_src_rdy_b = 0;
   end

   always begin
      #5 
	CLK = !CLK;
   end

   always @(posedge CLK) begin
      count <= count + 1;
      if (count == 10) begin
	 RST_N <= 1;
      end

      msgSink_src_rdy_b <= dpi_msgSink_src_rdy_b();
      if (msgSink_dst_rdy)
	msgSink_beat_v <= dpi_msgSink_beat();

      msgSource_dst_rdy_b <= dpi_msgSource_dst_rdy_b();
      if (msgSource_src_rdy)
	dpi_msgSource_beat(msgSource_beat);

   end
endmodule
