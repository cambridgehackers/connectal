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

module xsimtop();
   reg CLK;
   reg RST_N;
   reg [31:0] count;

   mkXsimTop xsimtop(.CLK(CLK), .RST_N(RST_N)); 
   initial begin
      CLK = 0;
      RST_N = 0;
      count = 0;
      dpi_init();
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
   end
endmodule

import "DPI-C" function void dpi_msgSource_beat(input int portal, input int beat);
module XsimSource( input CLK, input CLK_GATE, input RST, input [31:0] portal, input en_beat, input [31:0] beat);
   always @(posedge CLK) begin
      if (en_beat)
          dpi_msgSource_beat(portal, beat);
   end
endmodule

import "DPI-C" function void dpi_msgSink_beat(input int portal, output int beat, output int src_rdy);
module XsimSink(input CLK, input CLK_GATE, input RST, input [31:0] portal, output reg src_rdy, output reg [31:0] beat);
   always @(posedge CLK) begin
      dpi_msgSink_beat(portal, beat, src_rdy);
   end
endmodule

import "DPI-C" function void pareff_init(input int id, input int handle, input int size);
import "DPI-C" function void pareff_initfd(input int id, input int fd);
import "DPI-C" function void write_pareff32(input int handle, input int addr, input int data);
import "DPI-C" function void write_pareff64(input int handle, input int addr, input int data);
import "DPI-C" function int read_pareff32(input int handle, input int addr);
import "DPI-C" function longint read_pareff64(input int handle, input int addr);

module XsimMemReadWrite(input CLK,
			input 		  CLK_GATE,
			input 		  RST,

			input 		  en_init,
			input [31:0] 	  init_id,
			input [31:0] 	  init_handle,
			input [31:0] 	  init_size,

			input 		  en_initfd,
			input [31:0] 	  initfd_id,
			input [31:0] 	  initfd_fd,

			input 		  en_read32,
			input [31:0] 	  read32_addr,
			input [31:0] 	  read32_handle,
			output reg [31:0] read32_data,

			input 		  en_read64,
			input [31:0] 	  read64_addr,
			input [31:0] 	  read64_handle,
			output reg [63:0] read64_data,

			input 		  en_write32,
			input [31:0] 	  write32_addr,
			input [31:0] 	  write32_handle,
			input [31:0] 	  write32_data,

			input 		  en_write64,
			input [31:0] 	  write64_addr,
			input [31:0] 	  write64_handle,
			input [63:0] 	  write64_data
			);

   always @(posedge CLK) begin
      if (RST == 0) begin
	 // do nothing
      end
      else begin
	 if (en_init == 1)
	   pareff_init(init_id, init_handle, init_size);
	 if (en_initfd == 1)
	   pareff_initfd(initfd_id, initfd_fd);
	 
	 if (en_read32 == 1)
	   read32_data = read_pareff32(read32_handle, read32_addr);
	 if (en_read64 == 1) begin
	    $display("read_pareff64_xsim handle=%h addr=%h", read64_handle, read64_addr);
	    read64_data = read_pareff64(read64_handle, read64_addr);
	 end
	 if (en_write32 == 1)
	   write_pareff32(write32_handle, write32_addr, write32_data);
	 if (en_write64 == 1)
	   write_pareff64(write64_handle, write64_addr, write64_data);
      end // else: !if(RST == 0)
   end // always @ (posedge CLK)
endmodule
