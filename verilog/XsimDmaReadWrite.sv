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

module XsimDmaReadWrite(input CLK,
			input 		  CLK_GATE,
			input 		  RST,

			input 		  en_init,
			input [31:0] 	  init_id,
			input [31:0] 	  init_handle,
			input [31:0] 	  init_size,

			input 		  en_initfd,
			input [31:0] 	  initfd_id,
			input [31:0] 	  initfd_fd,

			input 		  en_idreturn,
			input [31:0] 	  idreturn_id,

			output 		  rdy_readrequest,
			input 		  en_readrequest,
			input [31:0] 	  readrequest_addr,
			input [31:0] 	  readrequest_handle,

			input 		  en_readresponse,
			output 		  rdy_readresponse,
			output [31:0] 	  readresponse_data,

			input 		  en_write32,
			input [31:0] 	  write32_addr,
			input [31:0] 	  write32_handle,
			input [31:0] 	  write32_data,
			input [3:0]       write32_byteenable
			);

   reg 					  readresponse_valid_reg;
   reg [31:0] 				  readresponse_data_reg;
				  
   import "DPI-C" function void simDma_init(input int id, input int handle, input int size);
   import "DPI-C" function void simDma_initfd(input int id, input int fd);
   import "DPI-C" function void simDma_idreturn(input int aid);
   import "DPI-C" function void write_simDma32(input int handle, input int addr, input int data, input int byteenable);
   import "DPI-C" function int read_simDma32(input int handle, input int addr);

   assign rdy_readresponse = readresponse_valid_reg;
   assign rdy_readrequest = !readresponse_valid_reg || en_readresponse;
   assign readresponse_data = readresponse_data_reg;

   always @(posedge CLK) begin
      if (RST == `BSV_RESET_VALUE) begin
	 readresponse_data_reg <= 32'haaaaaaaa;
	 readresponse_valid_reg <= 0;
      end
      else begin
	 if (en_init == 1)
	   simDma_init(init_id, init_handle, init_size);
	 if (en_initfd == 1)
	   simDma_initfd(initfd_id, initfd_fd);

	 if (en_idreturn == 1)
	   simDma_idreturn(idreturn_id);
	 
	 //if (en_readresponse) $display("xsimtop.readresponse data=%h", readresponse_data_reg);
	 if (en_readrequest == 1) begin
	    readresponse_data_reg <= read_simDma32(readrequest_handle, readrequest_addr);
	    //$display("xsimtop.readrequest handle=%h addr=%h", readrequest_handle, readrequest_addr);
	    readresponse_valid_reg <= 1;
	 end
	 else if (en_readresponse) begin
	    readresponse_valid_reg <= 0;
	    readresponse_data_reg <= 32'hbbbbbbbb;
	 end
	 if (en_write32 == 1)
	   write_simDma32(write32_handle, write32_addr, write32_data, write32_byteenable);
      end // else: !if(RST == BSV_RESET_VALUE)
   end // always @ (posedge CLK)
endmodule
