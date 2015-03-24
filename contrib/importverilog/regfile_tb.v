module regfile_tb;

   reg clock;
   reg reset;
   reg [1:0] read_address;

   reg [1:0] write_address;

   reg [7:0] write_data;
   reg   write_en;
   wire [7:0] read_data;

   initial begin
      $monitor ("we=%b, wa=%b, wd=%b, ra=%b, rd=%b",
		write_en, write_address, write_data,
		read_address, read_data);
      clock=0;
      reset=0;
      write_address=0;
      write_data=0;
      write_en=0;
      read_address=0;

      #20 reset = 1;
      #20 reset = 0;

      #20 read_address = 2'b00;
      #20 read_address = 2'b01;
      #20 read_address = 2'b10;
      #20 read_address = 2'b11;

      #20 write_address = 2'b00;
      #1 write_data = 8'b00010000;
      
      #20 write_en = 1;
      #20 write_address = 2'b01;
      #1 write_data = 8'b00010001;
      #20 write_address = 2'b10;
      #1 write_data = 8'b00010010;
      #20 write_address = 2'b11;
      #1 write_data = 8'b00010011;
      #20 write_en = 0;
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
	       .clock (clock),
	       .reset (reset),
	       .write_address (write_address),
	       .write_data (write_data),
	       .write_en (write_en),
	       .read_address (read_address),
	       .read_data (read_data)
	       );
   
   
endmodule // regfile_tb
