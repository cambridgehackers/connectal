// simple verilog example of a 2 port register file with 4 registers

 module regfile (clk, reset, write_address, write_data, write_enable,
		read_address, read_data);
   input clk;
   input reset;
   input [1:0] write_address;
   input [7:0] write_data;
   input       write_enable;
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

   
   always @ (posedge clk)
   if (reset == 1) begin
      reg0 <= 0;
   end else begin
      if (write_enable) begin
	 case(write_address)
	   0: reg0 <= write_data;
	   1: reg1 <= write_data;
	   2: reg2 <= write_data;
	   3: reg3 <= write_data;
	 endcase // case (write_address)
      end
   end // else: !if(rst)

endmodule

module regfile_tb;

   reg clock;
   reg reset;
   reg [1:0] read_address;

   reg [1:0] write_address;

   reg [7:0] write_data;
   reg   write_enable;
   wire [7:0] read_data;

   initial begin
      $monitor ("we=%b, wa=%b, wd=%b, ra=%b, rd=%b",
		write_enable, write_address, write_data,
		read_address, read_data);
      clock=0;
      reset=0;
      write_address=0;
      write_data=0;
      write_enable=0;
      read_address=0;

      #20 reset = 1;
      #20 reset = 0;

      #20 read_address = 2'b00;
      #20 read_address = 2'b01;
      #20 read_address = 2'b10;
      #20 read_address = 2'b11;

      #20 write_address = 2'b00;
      #1 write_data = 8'b00010000;
      
      #20 write_enable = 1;
      #20 write_address = 2'b01;
      #1 write_data = 8'b00010001;
      #20 write_address = 2'b10;
      #1 write_data = 8'b00010010;
      #20 write_address = 2'b11;
      #1 write_data = 8'b00010011;
      #20 write_enable = 0;
      #20 read_address = 2'b00;
      #20 read_address = 2'b01;
      #20 read_address = 2'b10;
      #20 read_address = 2'b11;
   $finish;
   end // initial begin
   always begin
      #5 clock = !clock;
   end

   regfile U0 (
	       .clk (clock),
	       .reset (reset),
	       .write_address (write_address),
	       .write_data (write_data),
	       .write_enable (write_enable),
	       .read_address (read_address),
	       .read_data (read_data)
	       );
   
   
endmodule // regfile_tb
