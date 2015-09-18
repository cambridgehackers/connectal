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

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module LinkInverter(CLK,
		  RST,

		  put,
		  EN_put,
		  RDY_put,

		  get,
		  EN_get,
		  RDY_get,
                  modReady,
                  inverseReady
		  );
   parameter DATA_WIDTH = 1;

   input CLK;
   input RST;
   output [DATA_WIDTH-1 : 0] get;
   input  [DATA_WIDTH-1 : 0] put;
   input 		   EN_get;
   input 		   EN_put;
   output 		   RDY_get;
   output 		   RDY_put;
   output 		   modReady;
   output 		   inverseReady;

   // will this work?
   assign get = put;
   assign RDY_get = 1;
   assign RDY_put = 1;
   assign modReady = EN_get;
   assign inverseReady = EN_put;
endmodule // LinkInverter
