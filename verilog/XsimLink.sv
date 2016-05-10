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
   longint   		       rx_val64;

   import "DPI-C" function int  bsimLinkUp(input int linknumber, input bit listening);
   import "DPI-C" function void bsimLinkOpen(input int linknumber, input bit listening);
   import "DPI-C" function int bsimLinkCanReceive(input int linknumber, input bit listening);
   import "DPI-C" function int bsimLinkCanTransmit(input int linknumber, input bit listening);
   import "DPI-C" function int bsimLinkReceive32(input int linknumber, input bit listening);
   import "DPI-C" function void bsimLinkTransmit32(input int linknumber, input bit listening, input int val);
   import "DPI-C" function longint bsimLinkReceive64(input int linknumber, input bit listening);
   import "DPI-C" function void bsimLinkTransmit64(input int linknumber, input bit listening, input longint val);

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
	    //$display("start linknumber=%d listening=%d", start_linknumber, start_listening);
	    bsimLinkOpen(start_linknumber, start_listening);
	    linknumber_reg <= start_linknumber;
	    listeningreg <= start_listening;
	    started <= 1;
	 end
	 
	 if (started && !rx_valid && bsimLinkCanReceive(linknumber_reg, listeningreg)) begin
	    if (DATAWIDTH == 32) begin
	       rx_val = bsimLinkReceive32(linknumber_reg, listeningreg);
	       rx_reg <= rx_val;
	    end
	    else begin
	       rx_val64 = bsimLinkReceive64(linknumber_reg, listeningreg);
	       rx_reg <= rx_val64;
	    end
	    rx_valid <= 1;
	    //$display("link %d.%d received %d %h", linknumber_reg, listeningreg, rx_valid, rx_val);
	 end
	 if (started && tx_valid && bsimLinkCanTransmit(linknumber_reg, listeningreg)) begin
	    //$display("link %d.%d transmitting %d %h", linknumber_reg, listeningreg, tx_valid, tx_reg);
	    if (DATAWIDTH == 32)
	      bsimLinkTransmit32(linknumber_reg, listeningreg, tx_reg);
	    else
	      bsimLinkTransmit64(linknumber_reg, listeningreg, tx_reg);
	    tx_valid <= 0;
	 end
	 if (started && en_rx_deq) begin
	    rx_valid <= 0;
	    //$display("%d.%d rx_deq %d %h", linknumber_reg, listeningreg, rx_valid, rx_reg);
	 end
	 if (started && en_tx_enq && !tx_valid) begin
	    tx_valid <= 1;
	    tx_reg <= tx_enq_v;
	    //$display("%d.%d tx_enq %h", linknumber_reg, listeningreg, tx_enq_v);
	 end
	 link_up_reg <= bsimLinkUp(linknumber_reg, listeningreg);
      end
   end

endmodule
