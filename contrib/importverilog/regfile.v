// simple verilog example of a 2 port register file with 4 registers

 module regfile (clock, reset, write_address, write_data, write_en,
		read_address, read_data);
   input clock;
   input reset;
   input [1:0] write_address;
   input [7:0] write_data;
   input       write_en;
   input [1:0] read_address;
   output [7:0] read_data;

   reg [7:0] 	reg0;
   reg [7:0] 	reg1;
   reg [7:0] 	reg2;
   reg [7:0] 	reg3;
   wire [7:0] 	read_data;
   
  assign read_data = (read_address == 0) ? reg0 :
		      (read_address == 1) ? reg1 :
		      (read_address == 2) ? reg2 :
		     (read_address == 3) ? reg3 : 0;

   
   always @ (posedge clock)
   if (reset == 1) begin
      reg0 <= 0;
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

