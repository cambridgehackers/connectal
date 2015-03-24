// simple verilog example of a 2 port register file with 4 registers

 module regfile (clock, reset_n, write_address, write_data, write_en,
		read_address, read_data);
   input clock;
   input reset_n;
   input [1:0] write_address;
   input [7:0] write_data;
   input       write_en;
   input [1:0] read_address;
   output [7:0] read_data;

   reg [7:0] 	reg0;
   reg [7:0] 	reg1;
   reg [7:0] 	reg2;
   reg [7:0] 	reg3;
   reg [1:0] 	ra;
   
   wire [7:0] 	read_data;
   
  assign read_data = (ra == 0) ? reg0 :
		      (ra == 1) ? reg1 :
		      (ra == 2) ? reg2 :
		     (ra == 3) ? reg3 : 0;

   
   always @ (posedge clock)
     ra <= read_address;
   
   always @ (posedge clock)
   if (reset_n == 0) begin
      reg0 <= 0;
      reg1 <= 0;
      reg2 <= 0;
      reg3 <= 0;
   end else begin
      if (write_en) begin
	 case(write_address)
	   0: reg0 <= write_data;
	   1: reg1 <= write_data;
	   2: reg2 <= write_data;
	   3: reg3 <= write_data;
	 endcase // case (write_address)
      end
   end // else: !if(rst)

endmodule

