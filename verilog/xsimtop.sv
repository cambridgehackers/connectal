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

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module xsimtop();
   reg CLK;
   reg DERIVED_CLK;
   reg RST_N;
   reg DERIVED_RST_N;
   reg [31:0] count;

   mkXsimTop xsimtop(.CLK(CLK), .RST_N(RST_N), .CLK_derivedClock(DERIVED_CLK), .RST_N_derivedReset(DERIVED_RST_N)); 
   initial begin
      CLK = 0;
      RST_N = `BSV_RESET_VALUE;
      DERIVED_CLK = 0;
      DERIVED_RST_N = `BSV_RESET_VALUE;
      $display("asserting reset to value %d", `BSV_RESET_VALUE);
      count = 0;
      dpi_init();
   end

   always begin
      #(`MainClockPeriod/2)
	CLK = !CLK;
   end
   always begin
      #(`DerivedClockPeriod/2)
	DERIVED_CLK = !DERIVED_CLK;
   end
   
   always @(posedge CLK) begin
      count <= count + 1;
   end
   always @(`BSV_RESET_EDGE CLK) begin
      if (count == 20) begin
	 $display("deasserting reset to value %d", !`BSV_RESET_VALUE);
	 RST_N <= !`BSV_RESET_VALUE;
      end
   end
   always @(`BSV_RESET_EDGE DERIVED_CLK) begin
      if (count == (20*`MainClockPeriod/`DerivedClockPeriod)) begin
	 $display("deasserting derived_reset to value %d", !`BSV_RESET_VALUE);
	 DERIVED_RST_N <= !`BSV_RESET_VALUE;
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

import "DPI-C" function void simDma_init(input int id, input int handle, input int size);
import "DPI-C" function void simDma_initfd(input int id, input int fd);
import "DPI-C" function void simDma_idreturn(input int aid);
import "DPI-C" function void write_simDma32(input int handle, input int addr, input int data);
import "DPI-C" function int read_simDma32(input int handle, input int addr);

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
			input [31:0] 	  write32_data
			);

   reg 					  readresponse_valid_reg;
   reg [31:0] 				  readresponse_data_reg;
				  
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
	   write_simDma32(write32_handle, write32_addr, write32_data);
      end // else: !if(RST == BSV_RESET_VALUE)
   end // always @ (posedge CLK)
endmodule


import "DPI-C" function int  bsimLinkUp(input int linknumber, input int listening);
import "DPI-C" function void bsimLinkOpen(input int linknumber, input int listening);
import "DPI-C" function int bsimLinkCanReceive(input int linknumber, input int listening);
import "DPI-C" function int bsimLinkCanTransmit(input int linknumber, input int listening);
import "DPI-C" function int bsimLinkReceive32(input int linknumber, input int listening);
import "DPI-C" function void bsimLinkTransmit32(input int linknumber, input int listening, input int val);
import "DPI-C" function int bsimLinkReceive64(input int linknumber, input int listening);
import "DPI-C" function void bsimLinkTransmit64(input int linknumber, input int listening, input int val);

module XsimLink #(parameter DATAWIDTH=32) (
		 input RST,
		 input CLK,
		 input CLK_GATE,
		 input start_listening,
		 input en_start,
		 input [31:0] start_linknumber,
		 input [DATAWIDTH-1:0] tx_enq_v,
		 input en_rx_deq,
		 input en_tx_enq,
		 output [DATAWIDTH-1:0] rx_first,
		 output rdy_rx_first,
		 output rdy_rx_deq,
		 output rdy_tx_enq,
		 output tx_not_full,
		 output rx_not_empty,
		 output link_up
		 );
   
   reg 			[31:0] linknumber_reg;
   reg 			started;
   reg 			listeningreg;
   reg                  link_up_reg;
   reg 			rx_valid;
   reg 			tx_valid;
   reg 			[DATAWIDTH-1:0] rx_reg;
   reg 			[DATAWIDTH-1:0] tx_reg;
   int   		       rx_val;

   assign rx_first     = rx_reg;
   assign rdy_rx_first = rx_valid && started;
   assign rdy_rx_deq   = rx_valid && started;
   assign rdy_tx_enq   = !tx_valid && started;
   assign tx_not_full  = !tx_valid;
   assign rx_not_empty = rx_valid;
   assign link_up      = link_up_reg;

   always @(posedge CLK) begin
      if (RST == `BSV_RESET_VALUE) begin
	 started <= 0;
	 linknumber_reg <= 0;
	 link_up_reg <= 0;
	 listeningreg <= 0;
	 rx_valid <= 0;
	 tx_valid  <= 0;
	 rx_reg <= 32'haaaaaaaa;
	 tx_reg <= 32'haaaaaaaa;
      end
      else begin
	 if (en_start == 1 && started == 0) begin
	    $display("start linknumber=%d listening=%d", start_linknumber, start_listening);
	    bsimLinkOpen(start_linknumber, start_listening);
	    linknumber_reg <= start_linknumber;
	    listeningreg <= start_listening;
	    started <= 1;
	 end
	 
	 if (started && !rx_valid && bsimLinkCanReceive(linknumber_reg, listeningreg)) begin
	    if (DATAWIDTH == 32)
	      rx_val = bsimLinkReceive32(linknumber_reg, listeningreg);
	    else
	      rx_val = bsimLinkReceive64(linknumber_reg, listeningreg);
	    rx_reg <= rx_val;
	    rx_valid <= 1;
	    $display("link %d.%d received %d %h", linknumber_reg, listeningreg, rx_valid, rx_val);
	 end
	 if (started && tx_valid && bsimLinkCanTransmit(linknumber_reg, listeningreg)) begin
	    $display("link %d.%d transmitting %d %h", linknumber_reg, listeningreg, tx_valid, tx_reg);
	    if (DATAWIDTH == 32)
	      bsimLinkTransmit32(linknumber_reg, listeningreg, tx_reg);
	    else
	      bsimLinkTransmit64(linknumber_reg, listeningreg, tx_reg);
	    tx_valid <= 0;
	 end
	 if (started && en_rx_deq) begin
	    rx_valid <= 0;
	    $display("%d.%d rx_deq %d %h", linknumber_reg, listeningreg, rx_valid, rx_reg);
	 end
	 if (started && en_tx_enq && !tx_valid) begin
	    tx_valid <= 1;
	    tx_reg <= tx_enq_v;
	    $display("%d.%d tx_enq %h", linknumber_reg, listeningreg, tx_enq_v);
	 end
	 link_up_reg <= bsimLinkUp(linknumber_reg, listeningreg);
      end
   end

endmodule
