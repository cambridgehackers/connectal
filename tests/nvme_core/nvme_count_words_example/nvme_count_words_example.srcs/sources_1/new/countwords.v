`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/23/2016 11:05:52 AM
// Design Name: 
// Module Name: countwords
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module countwords(
		  accel_clock,
		  accel_reset,

		  accel_dataFromNvme_tdata,
		  accel_dataFromNvme_tkeep,
		  accel_dataFromNvme_tlast,
		  accel_dataFromNvme_tready,
		  accel_dataFromNvme_tvalid,

		  accel_msgToSoftware_tdata,
		  accel_msgToSoftware_tkeep,
		  accel_msgToSoftware_tlast,
		  accel_msgToSoftware_tready,
		  accel_msgToSoftware_tvalid

    );

   input accel_clock;
   input accel_reset;
   

   output [127 : 0] accel_dataFromNvme_tdata;
   output [15 : 0] 	  accel_dataFromNvme_tkeep;
   output 		  accel_dataFromNvme_tlast;
   input 		  accel_dataFromNvme_tready;
   output 		  accel_dataFromNvme_tvalid;

   input [31 : 0] 	  accel_msgToSoftware_tdata;
   input [3 : 0] 	  accel_msgToSoftware_tkeep;
   input 		  accel_msgToSoftware_tlast;
   output 		  accel_msgToSoftware_tready;
   input 		  accel_msgToSoftware_tvalid;

   reg [31 : 0] count;
   
   // we're always ready
   assign accel_dataFromNvme_tready = 1;

   // we should use a FIFO in case msgToSoftware is not ready when dataFromNvme.tvalid and tlast are asserted
   assign accel_msgToSoftware_tvalid = ((accel_dataFromNvme_tvalid == 1) && (accel_dataFromNvme_tlast == 1));
   assign accel_msgToSoftware_tkeep = 16'hffff;
   assign accel_msgToSoftware_tlast = 1;
   assign accel_msgToSoftware_tdata = count;
   
   always@(posedge accel_clock)
     begin
	if (accel_reset == 0) begin
	   count <= 0;
	end
	else begin
	   if (accel_dataFromNvme_tvalid == 1) begin
	      count <= count + 1;
	   end
	end
     end

endmodule
