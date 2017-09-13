


module awsf1(
	     `include "cl_ports.vh"
	     );

//`include "cl_common_defines.vh"      // CL Defines for all examples
//`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"
`include "unused_pcim_template.inc"
`include "unused_dma_pcis_template.inc"
//`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"
`include "cl_id_defines.vh"

   assign cl_sh_id0 = `CL_SH_ID0;
   assign cl_sh_id1 = `CL_SH_ID1;

   mkAwsF1Top(
	      .clk_main_a0(clk_main_a0),	//Main clock.  This is the clock for all of the interfaces to the SH
	      .clk_extra_a1(clk_extra_a1),	//Extra clock A1 (phase aligned to "A" clock group)
	      .clk_extra_a2(clk_extra_a2),	//Extra clock A2 (phase aligned to "A" clock group)
	      .clk_extra_a3(clk_extra_a3),	//Extra clock A3 (phase aligned to "A" clock group)
   
	      .clk_extra_b0(clk_extra_b0),	//Extra clock B0 (phase aligned to "B" clock group)
	      .clk_extra_b1(clk_extra_b1),	//Extra clock B1 (phase aligned to "B" clock group)
   
	      .clk_extra_c0(clk_extra_c0),	//Extra clock C0 (phase aligned to "B" clock group)
	      .clk_extra_c1(clk_extra_c1),	//Extra clock C1 (phase aligned to "B" clock group)
	      .kernel_rst_n(kernel_rst_n),	//Kernel reset (for SDA platform)
     
	      .rst_main_n(rst_main_n),	//Reset sync to main clock.

	      .sh_cl_flr_assert(sh_cl_flr_assert), //Function level reset assertion.  Level signal that indicates PCIe function level reset is asserted
	      .cl_sh_flr_done(cl_sh_flr_done),	//Function level reset done indication.  Must be asserted by CL when done processing functional
	      .cl_sh_status0(cl_sh_status0),	//Functionality TBD
	      .cl_sh_status1(cl_sh_status1),	//Functionality TBD
	      //.cl_sh_id0(cl_sh_id0),	
	      //.cl_sh_id1(cl_sh_id1),	

	      .sh_cl_ctl0(sh_cl_ctl0),	//Functionality TBD
	      .sh_cl_ctl1(sh_cl_ctl1),	//Functionality TBD

	      .sh_cl_status_vdip(sh_cl_status_vdip),	//Virtual DIP switches.  Controlled through FPGA management PF and tools.
	      .cl_sh_status_vled(cl_sh_status_vled),	//Virtual LEDs, monitored through FPGA management PF and tools

	      .sh_cl_pwr_state(sh_cl_pwr_state),	//Power state, 2'b00: Normal, 2'b11: Critical

   //------------------------------------------------------------------------------------------
   // AXI-L maps to any inbound PCIe access through ManagementPF BAR4 for developer's use
   // If the CL is created through  Xilinx’s SDAccel, then this configuration bus
   // would be connected automatically to SDAccel generic logic (SmartConnect, APM etc)
   //------------------------------------------------------------------------------------------
	      .sda_awvalid_v(sda_cl_awvalid),
	      .sda_awaddr_v(sda_cl_awaddr),
	      .sda_awready(cl_sda_awready),

	      //Write data
	      .sda_wvalid_v(sda_cl_wvalid),
	      .sda_wvalid_v(sda_cl_wdata),
	      //.(sda_cl_wstrb),
	      .sda_wready(cl_sda_wready),

	      //Write response
	      .sda_bvalid(cl_sda_bvalid),
	      .sda_bresp(cl_sda_bresp),
	      .sda_bready_v(sda_cl_bready),

   //Read address
	      .sda_arvalid_v(sda_cl_arvalid),
	      .sda_araddr_v(sda_cl_araddr),
	      .sda_arready(cl_sda_arready),

   //Read data/response
	      .sda_rvalid(cl_sda_rvalid),
	      .sda_rdata(cl_sda_rdata),
	      .sda_rresp(cl_sda_rresp),

	      .sda_rready_v(sda_cl_rready)

);
   endmodule
