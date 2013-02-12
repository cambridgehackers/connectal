// Copyright (c) 2000-2011 Bluespec, Inc.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// $Revision: 28325 $
// $Date: 2012-04-25 18:22:57 +0000 (Wed, 25 Apr 2012) $

`ifdef BSV_ASSIGNMENT_DELAY
`else
 `define BSV_ASSIGNMENT_DELAY
`endif

// Dual-Ported BRAM (WRITE FIRST)
module NRCCBRAM2(CLKA,
                 RSTA_N,
                 ENA,
                 WEA,
                 ADDRA,
                 DIA,
                 DOA,
                 DRA,
                 CLKB,
                 RSTB_N,
                 ENB,
                 WEB,
                 ADDRB,
                 DIB,
                 DOB,
                 DRB
                 );

   parameter                      PIPELINED  = 1;
   parameter                      ADDR_WIDTH = 1;
   parameter                      DATA_WIDTH = 1;
   parameter                      MEMSIZE    = 1;

   input                          CLKA;
   input                          RSTA_N;
   input                          ENA;
   input                          WEA;
   input [ADDR_WIDTH-1:0]         ADDRA;
   input [DATA_WIDTH-1:0]         DIA;
   output [DATA_WIDTH-1:0]        DOA;
   output                         DRA;
   
   input                          CLKB;
   input                          RSTB_N;
   input                          ENB;
   input                          WEB;
   input [ADDR_WIDTH-1:0]         ADDRB;
   input [DATA_WIDTH-1:0]         DIB;
   output [DATA_WIDTH-1:0]        DOB;
   output                         DRB;
   

   reg [DATA_WIDTH-1:0]           DUALPORTBRAM[0:MEMSIZE-1] /* synthesis syn_ramstyle="no_rw_check" */ ;
   reg [DATA_WIDTH-1:0]           DOA_R;
   reg [DATA_WIDTH-1:0]           DOB_R;
   reg [DATA_WIDTH-1:0]           DOA_R2;
   reg [DATA_WIDTH-1:0]           DOB_R2;
   reg                            DRA_R;
   reg                            DRA_R2;
   reg                            DRB_R;
   reg                            DRB_R2;
   

`ifdef BSV_NO_INITIAL_BLOCKS
`else
   // synopsys translate_off
   integer                        i;
   initial
   begin : init_block
      for (i = 0; i < MEMSIZE; i = i + 1) begin
         DUALPORTBRAM[i] = { ((DATA_WIDTH+1)/2) { 2'b10 } };
      end
      DOA_R = { ((DATA_WIDTH+1)/2) { 2'b10 } };
      DOB_R = { ((DATA_WIDTH+1)/2) { 2'b10 } };
      DOA_R2 = { ((DATA_WIDTH+1)/2) { 2'b10 } };
      DOB_R2 = { ((DATA_WIDTH+1)/2) { 2'b10 } };
   end
   // synopsys translate_on
`endif // !`ifdef BSV_NO_INITIAL_BLOCKS

   always @(posedge CLKA) begin
      if (ENA) begin
         if (WEA) begin
            DUALPORTBRAM[ADDRA] <= `BSV_ASSIGNMENT_DELAY DIA;
            DOA_R <= `BSV_ASSIGNMENT_DELAY DIA;
         end
         else begin
            DOA_R <= `BSV_ASSIGNMENT_DELAY DUALPORTBRAM[ADDRA];
         end
      end
      DOA_R2 <= `BSV_ASSIGNMENT_DELAY DOA_R;
   end

   always @(posedge CLKA) begin
      if (RSTA_N == 0) begin
         DRA_R <= 0;
         DRA_R2 <= 0;
      end
      else if (ENA) begin
         if (WEA) begin
            DRA_R <= `BSV_ASSIGNMENT_DELAY 0;
         end
         else begin
            DRA_R <= `BSV_ASSIGNMENT_DELAY 1;
         end
      end
      DRA_R2 <= `BSV_ASSIGNMENT_DELAY DRA_R;
   end

   always @(posedge CLKB) begin
      if (ENB) begin
         if (WEB) begin
            DUALPORTBRAM[ADDRB] <= `BSV_ASSIGNMENT_DELAY DIB;
            DOB_R <= `BSV_ASSIGNMENT_DELAY DIB;
         end
         else begin
            DOB_R <= `BSV_ASSIGNMENT_DELAY DUALPORTBRAM[ADDRB];
         end
      end
      DOB_R2 <= `BSV_ASSIGNMENT_DELAY DOB_R;
   end

   always @(posedge CLKB) begin
      if (RSTB_N == 0) begin
         DRB_R <= 0;
         DRB_R2 <= 0;
      end
      else if (ENB) begin
         if (WEB) begin
            DRB_R <= `BSV_ASSIGNMENT_DELAY 0;
         end
         else begin
            DRB_R <= `BSV_ASSIGNMENT_DELAY 1;
         end
      end
      DRB_R2 <= `BSV_ASSIGNMENT_DELAY DRB_R;
   end

   // Output drivers
   assign DOA = (PIPELINED) ? DOA_R2 : DOA_R;
   assign DOB = (PIPELINED) ? DOB_R2 : DOB_R;
   assign DRA = (PIPELINED) ? DRA_R2 : DRA_R;
   assign DRB = (PIPELINED) ? DRB_R2 : DRB_R;

endmodule // BRAM2
