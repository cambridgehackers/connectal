
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

module GetInverse(CLK,
		  RST,

		  get,
		  EN_get,
		  RDY_get,

		  put,
		  EN_put,
		  RDY_put
		  );
   parameter DATA_WIDTH = 1;

   input CLK;
   input RST;
   output [DATA_WIDTH-1,0] get;
   input  [DATA_WIDTH-1,0] put;
   input 		   EN_get;
   input 		   EN_put;
   output 		   RDY_get;
   output 		   RDY_put;

   // will this work?
   assign get = put;
   assign RDY_get = EN_put;
   assign RDY_put = EN_get;
   
endmodule // GetInverse
