


module awsf1(
	     `include "cl_ports.vh"
	     );

//`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"
//`include "unused_pcim_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"
//`include "unused_sh_ocl_template.inc"

   assign cl_sh_id0 = `CL_SH_ID0;
   assign cl_sh_id1 = `CL_SH_ID1;

   ila_connectal_1 CL_ILA_0 (
                   .clk    (clk_main_a0),
                   .probe0 (sh_ocl_awvalid),
                   .probe1 ({32'b0,sh_ocl_awaddr}),
                   .probe2 (ocl_sh_awready),
                   .probe3 (sh_ocl_arvalid),
                   .probe4 ({32'b0,sh_ocl_araddr}),
                   .probe5 (ocl_sh_arready),

                   .probe6 (sh_ocl_wvalid),
                   .probe7 ({32'b0,sh_ocl_wdata[31:0]}),
                   .probe8 (ocl_sh_wready),
                   .probe9 (ocl_sh_rvalid),
                   .probe10 ({32'b0,ocl_sh_rdata[31:0]}),
                   .probe11 (sh_ocl_rready)
                   );

// Debug Bridge 
 cl_debug_bridge CL_DEBUG_BRIDGE (
      .clk(clk_main_a0),
      .S_BSCAN_drck(drck),
      .S_BSCAN_shift(shift),
      .S_BSCAN_tdi(tdi),
      .S_BSCAN_update(update),
      .S_BSCAN_sel(sel),
      .S_BSCAN_tdo(tdo),
      .S_BSCAN_tms(tms),
      .S_BSCAN_tck(tck),
      .S_BSCAN_runtest(runtest),
      .S_BSCAN_reset(reset),
      .S_BSCAN_capture(capture),
      .S_BSCAN_bscanid_en(bscanid_en)
   );

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
	      .ocl_awvalid_v(sh_ocl_awvalid),
	      .ocl_awaddr_v(sh_ocl_awaddr),
	      .ocl_awready(ocl_sh_awready),

	      //Write data
	      .ocl_wvalid_v(sh_ocl_wvalid),
	      .ocl_wdata_v(sh_ocl_wdata),
	      //.(sh_ocl_wstrb),
	      .ocl_wready(ocl_sh_wready),

	      //Write response
	      .ocl_bvalid(ocl_sh_bvalid),
	      .ocl_bresp(ocl_sh_bresp),
	      .ocl_bready_v(sh_ocl_bready),

   //Read address
	      .ocl_arvalid_v(sh_ocl_arvalid),
	      .ocl_araddr_v(sh_ocl_araddr),
	      .ocl_arready(ocl_sh_arready),

   //Read data/response
	      .ocl_rvalid(ocl_sh_rvalid),
	      .ocl_rdata(ocl_sh_rdata),
	      .ocl_rresp(ocl_sh_rresp),

	      .ocl_rready_v(sh_ocl_rready),

	      .pcim_araddr(cl_sh_pcim_araddr),
	      //.pcim_arburst(pcim_arburst),
	      //.pcim_arcache(pcim_arcache),
	      //.pcim_aresetn(pcim_aresetn),
	      .pcim_arid(cl_sh_pcim_arid),
	      .pcim_arlen(cl_sh_pcim_arlen),
	      //.pcim_arlock(pcim_arlock),
	      //.pcim_arprot(pcim_arprot),
	      //.pcim_arqos(pcim_arqos),
	      .pcim_arready_v(sh_cl_pcim_arready),
	      .pcim_arsize(cl_sh_pcim_arsize),
	      .pcim_arvalid(cl_sh_pcim_arvalid),
	      //FIXME: .pcim_aruser(pcim_extra_aruser),

	      .pcim_awaddr(cl_sh_pcim_awaddr),
	      //.pcim_awburst(pcim_awburst),
	      //.pcim_awcache(pcim_awcache),
	      .pcim_awid(cl_sh_pcim_awid),
	      .pcim_awlen(cl_sh_pcim_awlen),
	      //.pcim_awlock(pcim_awlock),
	      //.pcim_awprot(pcim_awprot),
	      //.pcim_awqos(pcim_awqos),
	      .pcim_awready_v(sh_cl_pcim_awready),
	      .pcim_awsize(cl_sh_pcim_awsize),
	      .pcim_awvalid(cl_sh_pcim_awvalid),
	      //FIXME .pcim_awuser(pcim_extra_awuser),

	      .pcim_bid_v(sh_cl_pcim_bid),
	      .pcim_bready(cl_sh_pcim_bready),
	      .pcim_bresp_v(sh_cl_pcim_bresp),
	      .pcim_bvalid_v(sh_cl_pcim_bvalid),

	      .pcim_rdata_v(sh_cl_pcim_rdata),
	      .pcim_rid_v(sh_cl_pcim_rid),
	      .pcim_rlast_v(sh_cl_pcim_rlast),
	      .pcim_rready(cl_sh_pcim_rready),
	      .pcim_rresp_v(sh_cl_pcim_rresp),
	      .pcim_rvalid_v(sh_cl_pcim_rvalid),

	      .pcim_wdata(cl_sh_pcim_wdata),
	      .pcim_wid(cl_sh_pcim_wid),
	      .pcim_wlast(cl_sh_pcim_wlast),
	      .pcim_wready_v(sh_cl_pcim_wready),
	      .pcim_wstrb(cl_sh_pcim_wstrb),
	      .pcim_wvalid(cl_sh_pcim_wvalid)
);
   endmodule
