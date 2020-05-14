
`include "ConnectalProjectConfig.bsv"

module awsf1(
	     `include "cl_ports.vh"
	     );

//`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)

   assign cl_sh_id0 = `CL_SH_ID0;
   assign cl_sh_id1 = `CL_SH_ID1;

//Put module name of the CL design here.  This is used to instantiate in top.sv
`define CL_NAME awsf1

//Highly recommeneded.  For lib FIFO block, uses less async reset (take advantage of
// FPGA flop init capability).  This will help with routing resources.
`define FPGA_LESS_RST

`define SH_SDA // Not sure what that does
//uncomment below to make SH and CL async
`define SH_CL_ASYNC

   `include "unused_flr_template.inc"
`ifndef AWSF1_DDR_A
`include "unused_ddr_a_b_d_template.inc"
`endif //  AWSF1_DDR_A
`include "unused_ddr_c_template.inc"
//`include "unused_pcim_template.inc"
`ifndef AWSF1_DMA_PCIS
`include "unused_dma_pcis_template.inc"
`endif
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
//`include "unused_apppf_irq_template.inc"
//`include "unused_sh_ocl_template.inc"


`ifdef AWSF1_DDR_A
   localparam DDR_A_PRESENT=1;
   // DDR B and D are not used, disable them
`ifdef AWSF1_DDR_B
   localparam DDR_B_PRESENT=1;
`else
   localparam DDR_B_PRESENT=0;
`endif
   localparam DDR_D_PRESENT=0;

//   localparam DDR_SCRB_MAX_ADDR = 64'h3FFFFFFFF; //16GB 
//   localparam DDR_SCRB_BURST_LEN_MINUS1 = 15;


   //---------------------------- 
   // Internal signals
   //---------------------------- 
   //axi_bus_t lcl_cl_sh_ddra();
   //axi_bus_t lcl_cl_sh_ddrb();
   //axi_bus_t lcl_cl_sh_ddrd();

   //axi_bus_t sh_cl_dma_pcis_bus();
   //axi_bus_t sh_cl_dma_pcis_q();
   //
   //axi_bus_t cl_sh_pcim_bus();
   //axi_bus_t cl_sh_ddr_bus();

   //axi_bus_t sda_cl_bus();
   //axi_bus_t sh_ocl_bus();

   //cfg_bus_t pcim_tst_cfg_bus();
   //cfg_bus_t ddra_tst_cfg_bus();
   //cfg_bus_t ddrb_tst_cfg_bus();
   //cfg_bus_t ddrc_tst_cfg_bus();
   //cfg_bus_t ddrd_tst_cfg_bus();
   //cfg_bus_t int_tst_cfg_bus();

   // scrb_bus_t ddra_scrb_bus();
   // scrb_bus_t ddrb_scrb_bus();
   // scrb_bus_t ddrc_scrb_bus();
   // scrb_bus_t ddrd_scrb_bus();


   logic clk;
   (* dont_touch = "true" *) logic pipe_rst_n;
   logic pre_sync_rst_n;
   (* dont_touch = "true" *) logic sync_rst_n;
   //logic sh_cl_flr_assert_q;

   //logic [3:0] all_ddr_scrb_done;
   logic [3:0] all_ddr_is_ready;
   logic [2:0] lcl_sh_cl_ddr_is_ready;

   //logic dbg_scrb_en;
   //logic [2:0] dbg_scrb_mem_sel;

   //---------------------------- 
   // End Internal signals
   //----------------------------


   assign clk = clk_main_a0;

   //reset synchronizer
   lib_pipe #(.WIDTH(1), .STAGES(4)) PIPE_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_main_n), .out_bus(pipe_rst_n));
   
   always_ff @(negedge pipe_rst_n or posedge clk)
     if (!pipe_rst_n)
       begin
	  pre_sync_rst_n <= 0;
	  sync_rst_n <= 0;
       end
     else
       begin
	  pre_sync_rst_n <= 1;
	  sync_rst_n <= pre_sync_rst_n;
       end



   //----------------------------------------- 
   // DDR controller instantiation   
   //-----------------------------------------
   logic [7:0] sh_ddr_stat_addr_q[2:0];
   logic [2:0] sh_ddr_stat_wr_q;
   logic [2:0] sh_ddr_stat_rd_q; 
   logic [31:0] sh_ddr_stat_wdata_q[2:0];
   logic [2:0] 	ddr_sh_stat_ack_q;
   logic [31:0] ddr_sh_stat_rdata_q[2:0];
   logic [7:0] 	ddr_sh_stat_int_q[2:0];

   localparam NUM_CFG_STGS_CL_DDR_ATG = 8;
   localparam NUM_CFG_STGS_SH_DDR_ATG = 4;

   lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT0 (.clk(clk), .rst_n(sync_rst_n),
										  .in_bus({sh_ddr_stat_wr0, sh_ddr_stat_rd0, sh_ddr_stat_addr0, sh_ddr_stat_wdata0}),
										  .out_bus({sh_ddr_stat_wr_q[0], sh_ddr_stat_rd_q[0], sh_ddr_stat_addr_q[0], sh_ddr_stat_wdata_q[0]})
										  );


   lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK0 (.clk(clk), .rst_n(sync_rst_n),
										    .in_bus({ddr_sh_stat_ack_q[0], ddr_sh_stat_int_q[0], ddr_sh_stat_rdata_q[0]}),
										    .out_bus({ddr_sh_stat_ack0, ddr_sh_stat_int0, ddr_sh_stat_rdata0})
										    );


   // tie DRAM B to 0
   //lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT1 (.clk(clk), .rst_n(sync_rst_n),
   //                                     .in_bus({sh_ddr_stat_wr1, sh_ddr_stat_rd1, sh_ddr_stat_addr1, sh_ddr_stat_wdata1}),
   //                                     .out_bus({sh_ddr_stat_wr_q[1], sh_ddr_stat_rd_q[1], sh_ddr_stat_addr_q[1], sh_ddr_stat_wdata_q[1]})
   //                                     );
   //lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK1 (.clk(clk), .rst_n(sync_rst_n),
   //                                   .in_bus({ddr_sh_stat_ack_q[1], ddr_sh_stat_int_q[1], ddr_sh_stat_rdata_q[1]}),
   //                                   .out_bus({ddr_sh_stat_ack1, ddr_sh_stat_int1, ddr_sh_stat_rdata1})
   //                                   );
   assign {sh_ddr_stat_wr_q[   1],
           sh_ddr_stat_rd_q[   1],
           sh_ddr_stat_addr_q[ 1],
           sh_ddr_stat_wdata_q[1]} = '0;
   assign ddr_sh_stat_ack1 = 1'b1; // Needed in order not to hang the interface
   assign {ddr_sh_stat_int1,
           ddr_sh_stat_rddata1} = '0;

   // tie DRAM D to 0
   //lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT2 (.clk(clk), .rst_n(sync_rst_n),
   //                                     .in_bus({sh_ddr_stat_wr2, sh_ddr_stat_rd2, sh_ddr_stat_addr2, sh_ddr_stat_wdata2}),
   //                                     .out_bus({sh_ddr_stat_wr_q[2], sh_ddr_stat_rd_q[2], sh_ddr_stat_addr_q[2], sh_ddr_stat_wdata_q[2]})
   //                                     );
   //lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK2 (.clk(clk), .rst_n(sync_rst_n),
   //                                   .in_bus({ddr_sh_stat_ack_q[2], ddr_sh_stat_int_q[2], ddr_sh_stat_rdata_q[2]}),
   //                                   .out_bus({ddr_sh_stat_ack2, ddr_sh_stat_int2, ddr_sh_stat_rdata2})
   //                                   ); 
   assign {sh_ddr_stat_wr_q[   2],
           sh_ddr_stat_rd_q[   2],
           sh_ddr_stat_addr_q[ 2],
           sh_ddr_stat_wdata_q[2]} = '0;
   assign ddr_sh_stat_ack2 = 1'b1; // Needed in order not to hang the interface
   assign {ddr_sh_stat_int2,
           ddr_sh_stat_rddata2} = '0;

   //convert to 2D 
   logic [15:0] cl_sh_ddr_awid_2d[2:0];
   logic [63:0] cl_sh_ddr_awaddr_2d[2:0];
   logic [7:0] 	cl_sh_ddr_awlen_2d[2:0];
   logic [2:0] 	cl_sh_ddr_awsize_2d[2:0];
   logic [1:0] 	cl_sh_ddr_awburst_2d[2:0];
   logic 	cl_sh_ddr_awvalid_2d [2:0];
   logic [2:0] 	sh_cl_ddr_awready_2d;

   logic [15:0] cl_sh_ddr_wid_2d[2:0];
   logic [511:0] cl_sh_ddr_wdata_2d[2:0];
   logic [63:0]  cl_sh_ddr_wstrb_2d[2:0];
   logic [2:0] 	 cl_sh_ddr_wlast_2d;
   logic [2:0] 	 cl_sh_ddr_wvalid_2d;
   logic [2:0] 	 sh_cl_ddr_wready_2d;

   logic [15:0]  sh_cl_ddr_bid_2d[2:0];
   logic [1:0] 	 sh_cl_ddr_bresp_2d[2:0];
   logic [2:0] 	 sh_cl_ddr_bvalid_2d;
   logic [2:0] 	 cl_sh_ddr_bready_2d;

   logic [15:0]  cl_sh_ddr_arid_2d[2:0];
   logic [63:0]  cl_sh_ddr_araddr_2d[2:0];
   logic [7:0] 	 cl_sh_ddr_arlen_2d[2:0];
   logic [2:0] 	 cl_sh_ddr_arsize_2d[2:0];
   logic [1:0] 	 cl_sh_ddr_arburst_2d[2:0];
   logic [2:0] 	 cl_sh_ddr_arvalid_2d;
   logic [2:0] 	 sh_cl_ddr_arready_2d;

   logic [15:0]  sh_cl_ddr_rid_2d[2:0];
   logic [511:0] sh_cl_ddr_rdata_2d[2:0];
   logic [1:0] 	 sh_cl_ddr_rresp_2d[2:0];
   logic [2:0] 	 sh_cl_ddr_rlast_2d;
   logic [2:0] 	 sh_cl_ddr_rvalid_2d;
   logic [2:0] 	 cl_sh_ddr_rready_2d;

   // tie DRAM B to 0
   assign {cl_sh_ddr_awid_2d[   1],
           cl_sh_ddr_awaddr_2d[ 1],
           cl_sh_ddr_awlen_2d[  1],
           cl_sh_ddr_awsize_2d[ 1],
           cl_sh_ddr_awvalid_2d[1],
           cl_sh_ddr_wid_2d[    1],
           cl_sh_ddr_wdata_2d[  1],
           cl_sh_ddr_wstrb_2d[  1],
           cl_sh_ddr_wlast_2d[  1],
           cl_sh_ddr_wvalid_2d[ 1],
           cl_sh_ddr_bready_2d[ 1],
           cl_sh_ddr_arid_2d[   1],
           cl_sh_ddr_araddr_2d[ 1],
           cl_sh_ddr_arlen_2d[  1],
           cl_sh_ddr_arsize_2d[ 1],
           cl_sh_ddr_arvalid_2d[1],
           cl_sh_ddr_rready_2d[ 1]} = '0;

   // tie DRAM D to 0
   assign {cl_sh_ddr_awid_2d[   2],
           cl_sh_ddr_awaddr_2d[ 2],
           cl_sh_ddr_awlen_2d[  2],
           cl_sh_ddr_awsize_2d[ 2],
           cl_sh_ddr_awvalid_2d[2],
           cl_sh_ddr_wid_2d[    2],
           cl_sh_ddr_wdata_2d[  2],
           cl_sh_ddr_wstrb_2d[  2],
           cl_sh_ddr_wlast_2d[  2],
           cl_sh_ddr_wvalid_2d[ 2],
           cl_sh_ddr_bready_2d[ 2],
           cl_sh_ddr_arid_2d[   2],
           cl_sh_ddr_araddr_2d[ 2],
           cl_sh_ddr_arlen_2d[  2],
           cl_sh_ddr_arsize_2d[ 2],
           cl_sh_ddr_arvalid_2d[2],
           cl_sh_ddr_rready_2d[ 2]} = '0;

   assign cl_sh_pcim_araddr[63:40] = 24'd0;
   assign cl_sh_pcim_awaddr[63:40] = 24'd0;

   (* dont_touch = "true" *) logic sh_ddr_sync_rst_n;
   lib_pipe #(.WIDTH(1), .STAGES(4)) SH_DDR_SLC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(sh_ddr_sync_rst_n));
   sh_ddr #(
            .DDR_A_PRESENT(DDR_A_PRESENT),
            .DDR_B_PRESENT(DDR_B_PRESENT),
            .DDR_D_PRESENT(DDR_D_PRESENT)
	    ) SH_DDR
     (
      .clk(clk),
      .rst_n(sh_ddr_sync_rst_n),

      .stat_clk(clk),
      .stat_rst_n(sh_ddr_sync_rst_n),


      .CLK_300M_DIMM0_DP(CLK_300M_DIMM0_DP),
      .CLK_300M_DIMM0_DN(CLK_300M_DIMM0_DN),
      .M_A_ACT_N(M_A_ACT_N),
      .M_A_MA(M_A_MA),
      .M_A_BA(M_A_BA),
      .M_A_BG(M_A_BG),
      .M_A_CKE(M_A_CKE),
      .M_A_ODT(M_A_ODT),
      .M_A_CS_N(M_A_CS_N),
      .M_A_CLK_DN(M_A_CLK_DN),
      .M_A_CLK_DP(M_A_CLK_DP),
      .M_A_PAR(M_A_PAR),
      .M_A_DQ(M_A_DQ),
      .M_A_ECC(M_A_ECC),
      .M_A_DQS_DP(M_A_DQS_DP),
      .M_A_DQS_DN(M_A_DQS_DN),
      .cl_RST_DIMM_A_N(cl_RST_DIMM_A_N),
      
      
      .CLK_300M_DIMM1_DP(CLK_300M_DIMM1_DP),
      .CLK_300M_DIMM1_DN(CLK_300M_DIMM1_DN),
      .M_B_ACT_N(M_B_ACT_N),
      .M_B_MA(M_B_MA),
      .M_B_BA(M_B_BA),
      .M_B_BG(M_B_BG),
      .M_B_CKE(M_B_CKE),
      .M_B_ODT(M_B_ODT),
      .M_B_CS_N(M_B_CS_N),
      .M_B_CLK_DN(M_B_CLK_DN),
      .M_B_CLK_DP(M_B_CLK_DP),
      .M_B_PAR(M_B_PAR),
      .M_B_DQ(M_B_DQ),
      .M_B_ECC(M_B_ECC),
      .M_B_DQS_DP(M_B_DQS_DP),
      .M_B_DQS_DN(M_B_DQS_DN),
      .cl_RST_DIMM_B_N(cl_RST_DIMM_B_N),

      .CLK_300M_DIMM3_DP(CLK_300M_DIMM3_DP),
      .CLK_300M_DIMM3_DN(CLK_300M_DIMM3_DN),
      .M_D_ACT_N(M_D_ACT_N),
      .M_D_MA(M_D_MA),
      .M_D_BA(M_D_BA),
      .M_D_BG(M_D_BG),
      .M_D_CKE(M_D_CKE),
      .M_D_ODT(M_D_ODT),
      .M_D_CS_N(M_D_CS_N),
      .M_D_CLK_DN(M_D_CLK_DN),
      .M_D_CLK_DP(M_D_CLK_DP),
      .M_D_PAR(M_D_PAR),
      .M_D_DQ(M_D_DQ),
      .M_D_ECC(M_D_ECC),
      .M_D_DQS_DP(M_D_DQS_DP),
      .M_D_DQS_DN(M_D_DQS_DN),
      .cl_RST_DIMM_D_N(cl_RST_DIMM_D_N),

      //------------------------------------------------------
      // DDR-4 Interface from CL (AXI-4)
      //------------------------------------------------------
      .cl_sh_ddr_awid(cl_sh_ddr_awid_2d),
      .cl_sh_ddr_awaddr(cl_sh_ddr_awaddr_2d),
      .cl_sh_ddr_awlen(cl_sh_ddr_awlen_2d),
      .cl_sh_ddr_awsize(cl_sh_ddr_awsize_2d),
      .cl_sh_ddr_awburst(cl_sh_ddr_awburst_2d),
      .cl_sh_ddr_awvalid(cl_sh_ddr_awvalid_2d),
      .sh_cl_ddr_awready(sh_cl_ddr_awready_2d),

      .cl_sh_ddr_wid(cl_sh_ddr_wid_2d),
      .cl_sh_ddr_wdata(cl_sh_ddr_wdata_2d),
      .cl_sh_ddr_wstrb(cl_sh_ddr_wstrb_2d),
      .cl_sh_ddr_wlast(cl_sh_ddr_wlast_2d),
      .cl_sh_ddr_wvalid(cl_sh_ddr_wvalid_2d),
      .sh_cl_ddr_wready(sh_cl_ddr_wready_2d),

      .sh_cl_ddr_bid(sh_cl_ddr_bid_2d),
      .sh_cl_ddr_bresp(sh_cl_ddr_bresp_2d),
      .sh_cl_ddr_bvalid(sh_cl_ddr_bvalid_2d),
      .cl_sh_ddr_bready(cl_sh_ddr_bready_2d),

      .cl_sh_ddr_arid(cl_sh_ddr_arid_2d),
      .cl_sh_ddr_araddr(cl_sh_ddr_araddr_2d),
      .cl_sh_ddr_arlen(cl_sh_ddr_arlen_2d),
      .cl_sh_ddr_arsize(cl_sh_ddr_arsize_2d),
      .cl_sh_ddr_arburst(cl_sh_ddr_arburst_2d),
      .cl_sh_ddr_arvalid(cl_sh_ddr_arvalid_2d),
      .sh_cl_ddr_arready(sh_cl_ddr_arready_2d),

      .sh_cl_ddr_rid(sh_cl_ddr_rid_2d),
      .sh_cl_ddr_rdata(sh_cl_ddr_rdata_2d),
      .sh_cl_ddr_rresp(sh_cl_ddr_rresp_2d),
      .sh_cl_ddr_rlast(sh_cl_ddr_rlast_2d),
      .sh_cl_ddr_rvalid(sh_cl_ddr_rvalid_2d),
      .cl_sh_ddr_rready(cl_sh_ddr_rready_2d),

      .sh_cl_ddr_is_ready(lcl_sh_cl_ddr_is_ready),

      .sh_ddr_stat_addr0  (sh_ddr_stat_addr_q[0]) ,
      .sh_ddr_stat_wr0    (sh_ddr_stat_wr_q[0]     ) , 
      .sh_ddr_stat_rd0    (sh_ddr_stat_rd_q[0]     ) , 
      .sh_ddr_stat_wdata0 (sh_ddr_stat_wdata_q[0]  ) , 
      .ddr_sh_stat_ack0   (ddr_sh_stat_ack_q[0]    ) ,
      .ddr_sh_stat_rdata0 (ddr_sh_stat_rdata_q[0]  ),
      .ddr_sh_stat_int0   (ddr_sh_stat_int_q[0]    ),

      .sh_ddr_stat_addr1  (sh_ddr_stat_addr_q[1]) ,
      .sh_ddr_stat_wr1    (sh_ddr_stat_wr_q[1]     ) , 
      .sh_ddr_stat_rd1    (sh_ddr_stat_rd_q[1]     ) , 
      .sh_ddr_stat_wdata1 (sh_ddr_stat_wdata_q[1]  ) , 
      .ddr_sh_stat_ack1   (ddr_sh_stat_ack_q[1]    ) ,
      .ddr_sh_stat_rdata1 (ddr_sh_stat_rdata_q[1]  ),
      .ddr_sh_stat_int1   (ddr_sh_stat_int_q[1]    ),

      .sh_ddr_stat_addr2  (sh_ddr_stat_addr_q[2]) ,
      .sh_ddr_stat_wr2    (sh_ddr_stat_wr_q[2]     ) , 
      .sh_ddr_stat_rd2    (sh_ddr_stat_rd_q[2]     ) , 
      .sh_ddr_stat_wdata2 (sh_ddr_stat_wdata_q[2]  ) , 
      .ddr_sh_stat_ack2   (ddr_sh_stat_ack_q[2]    ) ,
      .ddr_sh_stat_rdata2 (ddr_sh_stat_rdata_q[2]  ),
      .ddr_sh_stat_int2   (ddr_sh_stat_int_q[2]    ) 
      );

   //----------------------------------------- 
   // DDR controller instantiation   
   //-----------------------------------------
`endif //  AWSF1_DDR_A


`ifdef AWSF1_CL_DEBUG_BRIDGE
   ila_connectal_1 cl_ila_slave (
                   .clk    (clk_main_a0),
                   .probe0 (sh_ocl_awvalid),
                   .probe1 (sh_ocl_awaddr),
                   .probe2 (ocl_sh_awready),
                   .probe3 (sh_ocl_arvalid),
                   .probe4 (sh_ocl_araddr),
                   .probe5 (ocl_sh_arready),

                   .probe6 (sh_ocl_wvalid),
                   .probe7 (sh_ocl_wdata),
                   .probe8 (ocl_sh_wready),
                   .probe9 (ocl_sh_rvalid),
                   .probe10 (ocl_sh_rdata),
                   .probe11 (sh_ocl_rready),
                   .probe12 (cl_sh_apppf_irq_req),
                   .probe13 (sh_cl_apppf_irq_ack)
                   );
`ifndef AWSF1_DMA_PCIS

   ila_connectal_2 cl_ila_master  (
                   .clk    (clk_main_a0),
                   .probe0 (cl_sh_pcim_awvalid),
                   .probe1 (cl_sh_pcim_awaddr),
                   .probe2 (sh_cl_pcim_awready),
                   .probe3 (cl_sh_pcim_arvalid),
                   .probe4 (cl_sh_pcim_araddr),
                   .probe5 (sh_cl_pcim_arready),

                   .probe6 (cl_sh_pcim_wvalid),
                   .probe7 (cl_sh_pcim_wdata),
                   .probe8 (sh_cl_pcim_wready),
                   .probe9 (sh_cl_pcim_rvalid),
                   .probe10 (sh_cl_pcim_rdata),
                   .probe11 (cl_sh_pcim_rready),
                   .probe12(cl_sh_pcim_wstrb),
                   .probe13 (cl_sh_pcim_aruser),
                   .probe14 (cl_sh_pcim_awuser),
                   .probe15 (cl_sh_pcim_arlen),
                   .probe16 (cl_sh_pcim_awlen),
                   .probe17 (cl_sh_pcim_arid),
                   .probe18 (cl_sh_pcim_awid),
                   .probe19 (cl_sh_pcim_arsize),
                   .probe20 (cl_sh_pcim_awsize),
                   .probe21 (sh_cl_pcim_bid),
                   .probe22 (sh_cl_pcim_bresp),
                   .probe23 (cl_sh_pcim_bready),
                   .probe24 (sh_cl_pcim_bvalid)
                   );
`else
   wire [159:0] pc_status;
   wire 	pc_asserted;

      ila_connectal_3 cl_ila_pcis  (
                   .clk    (clk_main_a0),
                   .probe0 (sh_cl_dma_pcis_awvalid),
                   .probe1 (sh_cl_dma_pcis_awaddr),
                   .probe2 (cl_sh_dma_pcis_awready),
                   .probe3 (sh_cl_dma_pcis_arvalid),
                   .probe4 (sh_cl_dma_pcis_araddr),
                   .probe5 (cl_sh_dma_pcis_arready),

                   .probe6 (sh_cl_dma_pcis_wvalid),
                   .probe7 (sh_cl_dma_pcis_wdata),
                   .probe8 (cl_sh_dma_pcis_wready),
                   .probe9 (cl_sh_dma_pcis_rvalid),
                   .probe10 (cl_sh_dma_pcis_rdata),
                   .probe11 (sh_cl_dma_pcis_rready),
                   .probe12(sh_cl_dma_pcis_wstrb),
                   .probe13 (sh_cl_dma_pcis_aruser),
                   .probe14 ({sh_cl_dma_pcis_wlast, cl_sh_dma_pcis_rid, cl_sh_dma_pcis_rresp, cl_sh_dma_pcis_rlast, pc_asserted}),
                   .probe15 (sh_cl_dma_pcis_arlen),
                   .probe16 (sh_cl_dma_pcis_awlen),
                   .probe17 (sh_cl_dma_pcis_arid),
                   .probe18 (sh_cl_dma_pcis_awid),
                   .probe19 (sh_cl_dma_pcis_arsize),
                   .probe20 (sh_cl_dma_pcis_awsize),
                   .probe21 (cl_sh_dma_pcis_bid),
                   .probe22 (cl_sh_dma_pcis_bresp),
                   .probe23 (sh_cl_dma_pcis_bready),
                   .probe24 (cl_sh_dma_pcis_bvalid),
                   .probe25 (pc_status)
                   );
`endif
`ifdef AWSF1_DDR_A
   ila_connectal_2 cl_ila_mem  (
                   .clk    (clk_main_a0),
                   .probe0 (cl_sh_ddr_awvalid_2d[0]),
                   .probe1 (cl_sh_ddr_awaddr_2d[0]), // 64
                   .probe2 (sh_cl_ddr_awready_2d[0]),
                   .probe3 (cl_sh_ddr_arvalid_2d[0]),
                   .probe4 (cl_sh_ddr_araddr_2d[0]), // 64
                   .probe5 (sh_cl_ddr_arready_2d[0]),

                   .probe6 (cl_sh_ddr_wvalid_2d[0]),
                   .probe7 (cl_sh_ddr_wdata_2d[0]), // 512
                   .probe8 (sh_cl_ddr_wready_2d[0]),
                   .probe9 (sh_cl_ddr_rvalid_2d[0]),
                   .probe10 (sh_cl_ddr_rdata_2d[0]), // 512
                   .probe11 (cl_sh_ddr_rready_2d[0]),
                   .probe12 (cl_sh_ddr_wstrb_2d[0]), // 64
                   .probe13 (cl_sh_pcim_aruser), // 19
                   .probe14 (cl_sh_pcim_awuser), // 19
                   .probe15 (cl_sh_ddr_arlen_2d[0]),  // 8
                   .probe16 (cl_sh_ddr_awlen_2d[0]), // 8
                   .probe17 (cl_sh_ddr_arsize_2d[0]), // 3
                   .probe18 (cl_sh_ddr_awsize_2d[0]), // 3
                   .probe19 (cl_sh_ddr_awid_2d[0]), // 16
                   .probe20 (cl_sh_ddr_arid_2d[0]), // 16
                   .probe21 (sh_cl_ddr_bid_2d[0]), // 16
                   .probe22 (sh_cl_ddr_bresp_2d[0]), // 2
                   .probe23 (cl_sh_ddr_bready_2d[0]),
                   .probe24 (sh_cl_ddr_bvalid_2d[0])
                   );
`endif
`ifdef AWSF1_DDR_B
   ila_connectal_2 cl_ila_mem  (
                   .clk    (clk_main_a0),
                   .probe0 (cl_sh_ddr_awvalid_2d[1]),
                   .probe1 (cl_sh_ddr_awaddr_2d[1]), // 64
                   .probe2 (sh_cl_ddr_awready_2d[1]),
                   .probe3 (cl_sh_ddr_arvalid_2d[1]),
                   .probe4 (cl_sh_ddr_araddr_2d[1]), // 64
                   .probe5 (sh_cl_ddr_arready_2d[1]),

                   .probe6 (cl_sh_ddr_wvalid_2d[1]),
                   .probe7 (cl_sh_ddr_wdata_2d[1]), // 512
                   .probe8 (sh_cl_ddr_wready_2d[1]),
                   .probe9 (sh_cl_ddr_rvalid_2d[1]),
                   .probe10 (sh_cl_ddr_rdata_2d[1]), // 512
                   .probe11 (cl_sh_ddr_rready_2d[1]),
                   .probe12 (cl_sh_ddr_wstrb_2d[1]), // 64
                   .probe13 (0), // 19
                   .probe14 (0), // 19
                   .probe15 (cl_sh_ddr_arlen_2d[1]),  // 8
                   .probe16 (cl_sh_ddr_awlen_2d[1]), // 8
                   .probe17 (cl_sh_ddr_arsize_2d[1]), // 3
                   .probe18 (cl_sh_ddr_awsize_2d[1]), // 3
                   .probe19 (cl_sh_ddr_awid_2d[1]), // 16
                   .probe20 (cl_sh_ddr_arid_2d[1]), // 16
                   .probe21 (sh_cl_ddr_bid_2d[1]), // 16
                   .probe22 (sh_cl_ddr_bresp_2d[1]), // 2
                   .probe23 (cl_sh_ddr_bready_2d[1]),
                   .probe24 (sh_cl_ddr_bvalid_2d[1])
                   );
`endif

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
`endif // AWSF1_CL_DEBUG_BRIDGE

   assign cl_sh_pcim_awuser = 0;
   assign cl_sh_pcim_aruser = 0;

   mkAwsF1Top awsF1Top(
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
	      // remove import  "unused_flr_template.inc" if the flr_done signal is needed
	      //.cl_sh_flr_done(cl_sh_flr_done),	//Function level reset done indication.  Must be asserted by CL when done processing functional
	      .cl_sh_status0(cl_sh_status0),	//Functionality TBD
	      .cl_sh_status1(cl_sh_status1),	//Functionality TBD
	      //.cl_sh_id0(cl_sh_id0),	
	      //.cl_sh_id1(cl_sh_id1),	

	      .sh_cl_ctl0(sh_cl_ctl0),	//Functionality TBD
	      .sh_cl_ctl1(sh_cl_ctl1),	//Functionality TBD

	      .sh_cl_status_vdip(sh_cl_status_vdip),	//Virtual DIP switches.  Controlled through FPGA management PF and tools.
	      .cl_sh_status_vled(cl_sh_status_vled),	//Virtual LEDs, monitored through FPGA management PF and tools

	      .sh_cl_pwr_state(sh_cl_pwr_state),	//Power state, 2'b00: Normal, 2'b11: Critical

	      .interrupt_apppf_irq_req(cl_sh_apppf_irq_req),
	      .interrupt_apppf_irq_ack_ack(sh_cl_apppf_irq_ack),

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

// DDR 3 through connectal AXI

`ifdef AWSF1_DDR_A
              .pins_araddr(cl_sh_ddr_araddr_2d[0]),
	      .pins_arid(cl_sh_ddr_arid_2d[0]),
	      .pins_arlen(cl_sh_ddr_arlen_2d[0]),
	      .pins_arready(sh_cl_ddr_arready_2d[0]),
	      .pins_arsize(cl_sh_ddr_arsize_2d[0]),
	      .pins_arburst(cl_sh_ddr_arburst_2d[0]),
	      .pins_arvalid(cl_sh_ddr_arvalid_2d[0]),

	      .pins_awaddr(cl_sh_ddr_awaddr_2d[0]),
	      .pins_awid(cl_sh_ddr_awid_2d[0]),
	      .pins_awlen(cl_sh_ddr_awlen_2d[0]),
	      .pins_awready(sh_cl_ddr_awready_2d[0]),
	      .pins_awsize(cl_sh_ddr_awsize_2d[0]),
	      .pins_awburst(cl_sh_ddr_awburst_2d[0]),
	      .pins_awvalid(cl_sh_ddr_awvalid_2d[0]),
	      //.pins_awlock(),

	      .pins_bid(sh_cl_ddr_bid_2d[0]),
	      .pins_bready(cl_sh_ddr_bready_2d[0]),
	      .pins_bresp(sh_cl_ddr_bresp_2d[0]),
	      .pins_bvalid(sh_cl_ddr_bvalid_2d[0]),

	      .pins_rdata(sh_cl_ddr_rdata_2d[0]),
	      .pins_rid(sh_cl_ddr_rid_2d[0]),
	      .pins_rlast(sh_cl_ddr_rlast_2d[0]),
	      .pins_rready(cl_sh_ddr_rready_2d[0]),
	      .pins_rresp(sh_cl_ddr_rresp_2d[0]),
	      .pins_rvalid(sh_cl_ddr_rvalid_2d[0]),

	      .pins_wdata(cl_sh_ddr_wdata_2d[0]),
	      //.pins_wid(cl_sh_ddr_wid_2d[0]),
	      .pins_wlast(cl_sh_ddr_wlast_2d[0]),
	      .pins_wready(sh_cl_ddr_wready_2d[0]),
	      .pins_wstrb(cl_sh_ddr_wstrb_2d[0]),
	      .pins_wvalid(cl_sh_ddr_wvalid_2d[0]),

`endif // AWSF1_DDR_A

`ifdef AWSF1_DDR_B
              .pins_ddr_b_araddr(cl_sh_ddr_araddr_2d[1]),
	      .pins_ddr_b_arid(cl_sh_ddr_arid_2d[1]),
	      .pins_ddr_b_arlen(cl_sh_ddr_arlen_2d[1]),
	      .pins_ddr_b_arready(sh_cl_ddr_arready_2d[1]),
	      .pins_ddr_b_arsize(cl_sh_ddr_arsize_2d[1]),
	      .pins_ddr_b_arburst(cl_sh_ddr_arburst_2d[1]),
	      .pins_ddr_b_arvalid(cl_sh_ddr_arvalid_2d[1]),

	      .pins_ddr_b_awaddr(cl_sh_ddr_awaddr_2d[1]),
	      .pins_ddr_b_awid(cl_sh_ddr_awid_2d[1]),
	      .pins_ddr_b_awlen(cl_sh_ddr_awlen_2d[1]),
	      .pins_ddr_b_awready(sh_cl_ddr_awready_2d[1]),
	      .pins_ddr_b_awsize(cl_sh_ddr_awsize_2d[1]),
	      .pins_ddr_b_awburst(cl_sh_ddr_awburst_2d[1]),
	      .pins_ddr_b_awvalid(cl_sh_ddr_awvalid_2d[1]),
	      //.pins_ddr_b_awlock(),

	      .pins_ddr_b_bid(sh_cl_ddr_bid_2d[1]),
	      .pins_ddr_b_bready(cl_sh_ddr_bready_2d[1]),
	      .pins_ddr_b_bresp(sh_cl_ddr_bresp_2d[1]),
	      .pins_ddr_b_bvalid(sh_cl_ddr_bvalid_2d[1]),

	      .pins_ddr_b_rdata(sh_cl_ddr_rdata_2d[1]),
	      .pins_ddr_b_rid(sh_cl_ddr_rid_2d[1]),
	      .pins_ddr_b_rlast(sh_cl_ddr_rlast_2d[1]),
	      .pins_ddr_b_rready(cl_sh_ddr_rready_2d[1]),
	      .pins_ddr_b_rresp(sh_cl_ddr_rresp_2d[1]),
	      .pins_ddr_b_rvalid(sh_cl_ddr_rvalid_2d[1]),

	      .pins_ddr_b_wdata(cl_sh_ddr_wdata_2d[1]),
	      //.pins_ddr_b_wid(cl_sh_ddr_wid_2d[1]),
	      .pins_ddr_b_wlast(cl_sh_ddr_wlast_2d[1]),
	      .pins_ddr_b_wready(sh_cl_ddr_wready_2d[1]),
	      .pins_ddr_b_wstrb(cl_sh_ddr_wstrb_2d[1]),
	      .pins_ddr_b_wvalid(cl_sh_ddr_wvalid_2d[1]),

`endif // AWSF1_DDR_B

// DDR3 END

 `ifdef AWSF1_DMA_PCIS
	      .pins_pcis_araddr(sh_cl_dma_pcis_araddr[39:0]),
	      .pins_pcis_arburst(1),
	      .pins_pcis_arcache(0),
	      .pins_pcis_arid(sh_cl_dma_pcis_arid),
	      .pins_pcis_arlen(sh_cl_dma_pcis_arlen),
	      .pins_pcis_arlock(0),
	      .pins_pcis_arprot(0),
	      .pins_pcis_arqos(0),
	      .pins_pcis_arready(cl_sh_dma_pcis_arready),
	      .pins_pcis_arsize(sh_cl_dma_pcis_arsize),
	      .pins_pcis_arvalid(sh_cl_dma_pcis_arvalid),

	      .pins_pcis_awaddr(sh_cl_dma_pcis_awaddr[39:0]),
	      .pins_pcis_awburst(1),
	      .pins_pcis_awcache(0),
	      .pins_pcis_awid(sh_cl_dma_pcis_awid),
	      .pins_pcis_awlen(sh_cl_dma_pcis_awlen),
	      .pins_pcis_awlock(0),
	      .pins_pcis_awprot(0),
	      .pins_pcis_awqos(0),
	      .pins_pcis_awready(cl_sh_dma_pcis_awready),
	      .pins_pcis_awsize(sh_cl_dma_pcis_awsize),
	      .pins_pcis_awvalid(sh_cl_dma_pcis_awvalid),

	      .pins_pcis_bid(cl_sh_dma_pcis_bid),
	      .pins_pcis_bready(sh_cl_dma_pcis_bready),
	      .pins_pcis_bresp(cl_sh_dma_pcis_bresp),
	      .pins_pcis_bvalid(cl_sh_dma_pcis_bvalid),

	      .pins_pcis_rdata(cl_sh_dma_pcis_rdata),
	      .pins_pcis_rid(cl_sh_dma_pcis_rid),
	      .pins_pcis_rlast(cl_sh_dma_pcis_rlast),
	      .pins_pcis_rready(sh_cl_dma_pcis_rready),
	      .pins_pcis_rresp(cl_sh_dma_pcis_rresp),
	      .pins_pcis_rvalid(cl_sh_dma_pcis_rvalid),

	      .pins_pcis_wdata(sh_cl_dma_pcis_wdata),
	      .pins_pcis_wlast(sh_cl_dma_pcis_wlast),
	      .pins_pcis_wready(cl_sh_dma_pcis_wready),
	      .pins_pcis_wstrb(sh_cl_dma_pcis_wstrb),
	      .pins_pcis_wvalid(sh_cl_dma_pcis_wvalid),
`endif
	      .pcim_araddr(cl_sh_pcim_araddr[39:0]),
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
	      //RESERVED: .pcim_extra_aruser(cl_sh_pcim_aruser),

	      .pcim_awaddr(cl_sh_pcim_awaddr[39:0]),
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
	      //RESERVED: .pcim_extra_awuser(cl_sh_pcim_awuser),

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
	      //.pcim_wid(cl_sh_pcim_wid), // No longer part of AXI4 spec
	      .pcim_wlast(cl_sh_pcim_wlast),
	      .pcim_wready_v(sh_cl_pcim_wready),
	      .pcim_wstrb(cl_sh_pcim_wstrb),
	      .pcim_wvalid(cl_sh_pcim_wvalid)
);


`ifdef AWSF1_CL_DEBUG_BRIDGE
`ifdef AWSF1_DMA_PCIS
`ifdef AWSF1_AXI_PROTOCOL_CHECKER
axi_protocol_checker_0 axi_protocol_checker_i (
  .pc_status(pc_status),              // output wire [159 : 0] pc_status
  .pc_asserted(pc_asserted),          // output wire pc_asserted
  .aclk(clk_main_a0),                        // input wire aclk
  .aresetn(rst_main_n),                  // input wire aresetn
  .pc_axi_awid(sh_cl_dma_pcis_awid),          // input wire [5 : 0] pc_axi_awid
  .pc_axi_awaddr(sh_cl_dma_pcis_awaddr),      // input wire [63 : 0] pc_axi_awaddr
  .pc_axi_awlen(sh_cl_dma_pcis_awlen),        // input wire [7 : 0] pc_axi_awlen
  .pc_axi_awsize(sh_cl_dma_pcis_awsize),      // input wire [2 : 0] pc_axi_awsize
  .pc_axi_awburst(1),    // input wire [1 : 0] pc_axi_awburst
  .pc_axi_awlock(0),      // input wire [0 : 0] pc_axi_awlock
  .pc_axi_awcache(0),    // input wire [3 : 0] pc_axi_awcache
  .pc_axi_awprot(0),      // input wire [2 : 0] pc_axi_awprot
  .pc_axi_awqos(0),        // input wire [3 : 0] pc_axi_awqos
  .pc_axi_awregion(0),  // input wire [3 : 0] pc_axi_awregion
  .pc_axi_awvalid(sh_cl_dma_pcis_awvalid),    // input wire pc_axi_awvalid
  .pc_axi_awready(cl_sh_dma_pcis_awready),    // input wire pc_axi_awready
  .pc_axi_wlast(sh_cl_dma_pcis_wlast),        // input wire pc_axi_wlast
  .pc_axi_wdata(sh_cl_dma_pcis_wdata),        // input wire [511 : 0] pc_axi_wdata
  .pc_axi_wstrb(sh_cl_dma_pcis_wstrb),        // input wire [63 : 0] pc_axi_wstrb
  .pc_axi_wvalid(sh_cl_dma_pcis_wvalid),      // input wire pc_axi_wvalid
  .pc_axi_wready(cl_sh_dma_pcis_wready),      // input wire pc_axi_wready
  .pc_axi_bid(cl_sh_dma_pcis_bid),            // input wire [5 : 0] pc_axi_bid
  .pc_axi_bresp(cl_sh_dma_pcis_bresp),        // input wire [1 : 0] pc_axi_bresp
  .pc_axi_bvalid(cl_sh_dma_pcis_bvalid),      // input wire pc_axi_bvalid
  .pc_axi_bready(sh_cl_dma_pcis_bready),      // input wire pc_axi_bready
  .pc_axi_arid(sh_cl_dma_pcis_arid),          // input wire [5 : 0] pc_axi_arid
  .pc_axi_araddr(sh_cl_dma_pcis_araddr),      // input wire [63 : 0] pc_axi_araddr
  .pc_axi_arlen(sh_cl_dma_pcis_arlen),        // input wire [7 : 0] pc_axi_arlen
  .pc_axi_arsize(sh_cl_dma_pcis_arsize),      // input wire [2 : 0] pc_axi_arsize
  .pc_axi_arburst(1),    // input wire [1 : 0] pc_axi_arburst
  .pc_axi_arlock(0),      // input wire [0 : 0] pc_axi_arlock
  .pc_axi_arcache(0),    // input wire [3 : 0] pc_axi_arcache
  .pc_axi_arprot(0),      // input wire [2 : 0] pc_axi_arprot
  .pc_axi_arqos(0),        // input wire [3 : 0] pc_axi_arqos
  .pc_axi_arregion(0),  // input wire [3 : 0] pc_axi_arregion
  .pc_axi_arvalid(sh_cl_dma_pcis_arvalid),    // input wire pc_axi_arvalid
  .pc_axi_arready(cl_sh_dma_pcis_arready),    // input wire pc_axi_arready
  .pc_axi_rid(cl_sh_dma_pcis_rid),            // input wire [5 : 0] pc_axi_rid
  .pc_axi_rlast(cl_sh_dma_pcis_rlast),        // input wire pc_axi_rlast
  .pc_axi_rdata(cl_sh_dma_pcis_rdata),        // input wire [511 : 0] pc_axi_rdata
  .pc_axi_rresp(cl_sh_dma_pcis_rresp),        // input wire [1 : 0] pc_axi_rresp
  .pc_axi_rvalid(cl_sh_dma_pcis_rvalid),      // input wire pc_axi_rvalid
  .pc_axi_rready(sh_cl_dma_pcis_rready)      // input wire pc_axi_rready
);
`endif // AWSF1_AXI_PROTOCOL_CHECKER
`endif //  `ifdef AWSF1_DMA_PCIS
`endif //  `ifdef AWSF1_CL_DEBUG_BRIDGE

   endmodule
