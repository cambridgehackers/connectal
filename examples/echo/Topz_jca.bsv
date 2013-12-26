// bsv libraries
//import SpecialFIFOs::*;
//import Vector::*;
//import StmtFSM::*;
//import FIFO::*;
//import Connectable::*;

// portz libraries
//import AxiMasterSlave::*;
//import Directory::*;
//import CtrlMux::*;
//import Portal::*;
//import Leds::*;
import Top::*;
import PS7::*;

module mkZynqTop(AxiTop);
    let axiTop <- mkAxiTop();
    PS7#(4, 32, 4, 32, 64/*gpio_width*/, 12, 54) ps7 <- mkPS7(4, 32, 4, 32, 64/*gpio_width*/, 12, 54);
        //.M_AXI_GP0_ACLK(processing_system7_1_fclk_clk0),
        //.S_AXI_HP0_ACLK(processing_system7_1_fclk_clk0),

    rule m_ar_rule; //.M_AXI_GP0_ARREADY(ctrl_arready), .M_AXI_GP0_ARVALID(ctrl_arvalid),
        let m_ar = ps7.m_axi_gp[0].req_ar.get();
            //req_ar lock; //req_ar qos;
        //.M_AXI_GP0_ARLOCK(ctrl_arlock),
        ctrl.read.readAddr(m_ar.addr, m_ar.len, m_ar.size, m_ar.burst, m_ar.prot, m_ar.cache, m_ar.id);
    endrule

    rule m_aw_rule; //.M_AXI_GP0_AWREADY(ctrl_awready), .M_AXI_GP0_AWVALID(ctrl_awvalid),
        let m_aw = ps7.m_axi_gp[0].req_aw.get();
            //req_aw lock; //req_aw qos;
            //.M_AXI_GP0_AWLOCK(ctrl_awlock),
        ctrl.write.writeAddr(m_aw.addr, m_aw.len, m_aw.size, m_aw.burst, m_aw.prot, m_aw.cache, m_aw.id);
    endrule

    rule m_arespb_rule; //.M_AXI_GP0_BREADY(ctrl_bready), .M_AXI_GP0_BVALID(ctrl_bvalid),
        AxiResp#(12) m_arespb;
        m_arespb.id = ctrl.write.bid();
        m_arespb.resp = ctrl.write.writeResponse();
        ps7.m_axi_gp[0].resp_b.put(m_arespb);
    endrule

    rule m_arespr_rule; //.M_AXI_GP0_RREADY(ctrl_rready), .M_AXI_GP0_RVALID(ctrl_rvalid),
        AxiRead#(32, 12) m_arespr;
        m_arespr.r.id = ctrl.read.rid();
        m_arespr.r.resp = ??; //.M_AXI_GP0_RRESP(ctrl_rresp),
        m_arespr.rd.data = ctrl.read.readData();
        m_arespr.rd.last = ctrl.read.last();
        ps7.m_axi_gp[0].resp_read.put(m_arespr);
    endrule

    rule m_arespw_rule; //.M_AXI_GP0_WREADY(ctrl_wready), .M_AXI_GP0_WVALID(ctrl_wvalid),
        let m_arespw = ps7.m_axi_gp[0].resp_write.get();
        ctrl.write.writeData(m_arespw.wd.data, m_arespw.wstrb, m_arespw.wd.last, m_aresp.wid);
    endrule

    rule s_areqr_rule; //.S_AXI_HP0_ARREADY(m_axi_arready), .S_AXI_HP0_ARVALID(m_axi_arvalid),
        AxiREQ#(12) s_areqr;
        //.S_AXI_HP0_ARLOCK .S_AXI_HP0_ARQOS .S_AXI_HP0_AWLOCK .S_AXI_HP0_AWQOS
        s_areqr.addr = m_axi.read.readAddr();
        s_areqr.burst = m_axi.read.readBurstType();
        s_areqr.cache = m_axi.read.readBurstCache();
        s_areqr.id = m_axi.read.readId();
        s_areqr.len = m_axi.read.readBurstLen();
        s_areqr.prot = m_axi.read.readBurstProt();
        s_areqr.size = m_axi.read.readBurstWidth();
        ps7.s_axi_hp[0].req_ar(s_areqr);
    endrule

    rule s_areqw_rule; //.S_AXI_HP0_AWREADY(m_axi_awready), .S_AXI_HP0_AWVALID(m_axi_awvalid),
        AxiREQ#(12) s_areqw;
        s_areqw.addr = m_axi.write.writeAddr();
        s_areqw.burst = m_axi.write.writeBurstType();
        s_areqw.cache = m_axi.write.writeBurstCache();
        s_areqw.id = m_axi.write.writeId();
        s_areqw.len = m_axi.write.writeBurstLen();
        s_areqw.prot = m_axi.write.writeBurstProt();
        s_areqw.size = m_axi.write.writeBurstWidth();
        ps7.s_axi_hp[0].req_ar(s_areqr);
    endrule

    rule s_arespb_rule; //.S_AXI_HP0_BREADY(m_axi_bready), .S_AXI_HP0_BVALID(m_axi_bvalid),
        let s_arespb = ps7.s_axi_hp[0].resp_b.get();
        m_axi.write.writeResponse(s_arespb.resp, s_arespb.id);
    endrule

    rule s_arespr_rule; //.S_AXI_HP0_RREADY(m_axi_rready), .S_AXI_HP0_RVALID(m_axi_rvalid),
        let s_arespr = ps7.s_axi_hp[0].resp_read.get();
        m_axi.read.readData(s_arespr.rd.data, s_arespr.r.resp, s_arespr.rd.last, s_arespr.r.id);
    endrule

    rule s_arespw_rule; //.S_AXI_HP0_WREADY(m_axi_wready), .S_AXI_HP0_WVALID(m_axi_wvalid),
        s_arespw.wid = m_axi.write.writeWid();
        //??s_arespw.wd.data = m_axi.write.writeWid(); //.m_axi_write_writeData(m_axi_wdata_wire),
        //.S_AXI_HP0_WDATA(m_axi_wdata),
        s_arespw.wd.last = m_axi.write.writeLastDataBeat();
        s_arespw.wstrb = m_axi.write.writeDataByteEnable();
        ps7.s_axi_hp[0].resp_write(s_arespw);
    endrule

        //.DDR_Addr(DDR_Addr[14:0]), .DDR_BankAddr(DDR_BankAddr[2:0]),
        //.DDR_CAS_n(DDR_CAS_n), .DDR_CKE(DDR_CKE), .DDR_CS_n(DDR_CS_n), .DDR_Clk(DDR_Clk_p),
        //.DDR_Clk_n(DDR_Clk_n), .DDR_DM(DDR_DM[3:0]), .DDR_DQ(DDR_DQ[31:0]),
        //.DDR_DQS(DDR_DQS_p[3:0]), .DDR_DQS_n(DDR_DQS_n[3:0]), .DDR_DRSTB(DDR_DRSTB),
        //.DDR_ODT(DDR_ODT), .DDR_RAS_n(DDR_RAS_n),
        //.DDR_VRN(FIXED_IO_ddr_vrn), .DDR_VRP(FIXED_IO_ddr_vrp), .DDR_WEB(DDR_WEB),
        //.FCLK_CLK0(processing_system7_1_fclk_clk0),
        //.FCLK_CLK1(processing_system7_1_fclk_clk1),
        //.FCLK_CLK2(processing_system7_1_fclk_clk2),
        //.FCLK_CLK3(processing_system7_1_fclk_clk3),
        //.FCLK_RESET0_N(processing_system7_1_fclk_reset0_n),
        //.IRQ_F2P(irq_f2p),
        //.MIO(FIXED_IO_mio[53:0]),
        //.PS_PORB(FIXED_IO_ps_porb),
        //.PS_SRSTB(FIXED_IO_ps_srstb), 
        //.PS_CLK(FIXED_IO_ps_clk)); 
   return axiTop;
endmodule : mkZynqTop

