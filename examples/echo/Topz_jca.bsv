// bsv libraries
//import SpecialFIFOs::*;
//import Vector::*;
//import StmtFSM::*;
//import FIFO::*;
//import Connectable::*;
import GetPut::*;

// portz libraries
import AxiMasterSlave::*;
//import Directory::*;
import CtrlMux::*;
//import Portal::*;
import Leds::*;
import Top::*;
import PPS7::*;
import PS7::*;

interface EchoPins#(numeric type gpio_width, numeric type mio_width);
    interface Pps7Ddr#(4, 32, 4, 32, 64, 12, 54) ddr;
    interface Inout#(Bit#(mio_width))       mio;
    interface Pps7Ps#(4, 32, 4, 32, 64, 12, 54) ps;
    interface LEDS                          leds;
endinterface

module mkZynqTop(EchoPins#(64/*gpio_width*/, 54));
    let axiTop <- mkAxiTop();
    let data_width = 32;
    let id_width = 12;
    PS7#(4, 32, 4, 32/*data_width*/, 64/*gpio_width*/, 12/*id_width*/, 54) ps7 <- mkPS7(4, 32/*data_width*/, 4, 32, 64/*gpio_width*/, 12/*id_width*/, 54);

    Bool intval <- axiTop.interrupt();
    //Bit#(1) intval <- axiTop.interrupt ? 1'b1 : 1'b0;
    ps7.irq.f2p({15'b0, pack(intval)});
    let fclock0 <- ps7.fclk.clk0();
    ps7.m_axi_gp[0].aclk(fclock0);
    //ps7.s_axi_hp[0].axi.aclk(fclock0);
    //ps7.fclk_reset[0].n = ?;

    rule m_ar_rule; //.M_AXI_GP0_ARREADY(ctrl_arready), .M_AXI_GP0_ARVALID(ctrl_arvalid),
        let m_ar <- ps7.m_axi_gp[0].req_ar.get();
            //m_ar.lock; //m_ar.qos;
        axiTop.ctrl.read.readAddr(m_ar.addr, m_ar.len, m_ar.size, m_ar.burst, m_ar.prot, m_ar.cache, m_ar.id);
    endrule

    rule m_aw_rule; //.M_AXI_GP0_AWREADY(ctrl_awready), .M_AXI_GP0_AWVALID(ctrl_awvalid),
        let m_aw <- ps7.m_axi_gp[0].req_aw.get();
            //m_aw.lock; //m_aw.qos;
        axiTop.ctrl.write.writeAddr(m_aw.addr, m_aw.len, m_aw.size, m_aw.burst, m_aw.prot, m_aw.cache, m_aw.id);
    endrule

    rule m_arespb_rule; //.M_AXI_GP0_BREADY(ctrl_bready), .M_AXI_GP0_BVALID(ctrl_bvalid),
        AxiRESP#(12/*id_width*/) m_arespb;
        m_arespb.id <- axiTop.ctrl.write.bid();
        m_arespb.resp <- axiTop.ctrl.write.writeResponse();
        ps7.m_axi_gp[0].resp_b.put(m_arespb);
    endrule

    rule m_arespr_rule; //.M_AXI_GP0_RREADY(ctrl_rready), .M_AXI_GP0_RVALID(ctrl_rvalid),
        AxiRead#(32/*data_width*/, 12/*id_width*/) m_arespr;
        m_arespr.r.id = axiTop.ctrl.read.rid();
        m_arespr.r.resp = 2'b0; //.M_AXI_GP0_RRESP(ctrl_rresp),
        m_arespr.rd.data <- axiTop.ctrl.read.readData();
        m_arespr.rd.last = axiTop.ctrl.read.last();
        ps7.m_axi_gp[0].resp_read.put(m_arespr);
    endrule

    rule m_arespw_rule; //.M_AXI_GP0_WREADY(ctrl_wready), .M_AXI_GP0_WVALID(ctrl_wvalid),
        let m_arespw <- ps7.m_axi_gp[0].resp_write.get();
        axiTop.ctrl.write.writeData(m_arespw.wd.data, m_arespw.wstrb, m_arespw.wd.last, m_arespw.wid);
    endrule

/* m_axi interface not bound in examples/echo/Top.bsv
    rule s_areqr_rule; //.S_AXI_HP0_ARREADY(m_axi_arready), .S_AXI_HP0_ARVALID(m_axi_arvalid),
        AxiREQ#(12/*id_width* /) s_areqr;
        s_areqr.lock = 0;
        s_areqr.qos = 0;
        s_areqr.addr = axiTop.m_axi.read.readAddr();
        s_areqr.burst = axiTop.m_axi.read.readBurstType();
        s_areqr.cache = axiTop.m_axi.read.readBurstCache();
        s_areqr.id = axiTop.m_axi.read.readId();
        s_areqr.len = axiTop.m_axi.read.readBurstLen();
        s_areqr.prot = axiTop.m_axi.read.readBurstProt();
        s_areqr.size = axiTop.m_axi.read.readBurstWidth();
        ps7.s_axi_hp[0].axi.req_ar.put(s_areqr);
    endrule

    rule s_areqw_rule; //.S_AXI_HP0_AWREADY(m_axi_awready), .S_AXI_HP0_AWVALID(m_axi_awvalid),
        AxiREQ#(12/*id_width* /) s_areqw;
        s_areqw.lock = 0;
        s_areqw.qos = 0;
        s_areqw.addr = axiTop.m_axi.write.writeAddr();
        s_areqw.burst = axiTop.m_axi.write.writeBurstType();
        s_areqw.cache = axiTop.m_axi.write.writeBurstCache();
        s_areqw.id = axiTop.m_axi.write.writeId();
        s_areqw.len = axiTop.m_axi.write.writeBurstLen();
        s_areqw.prot = axiTop.m_axi.write.writeBurstProt();
        s_areqw.size = axiTop.m_axi.write.writeBurstWidth();
        ps7.s_axi_hp[0].axi.req_ar.put(s_areqr);
    endrule

    rule s_arespb_rule; //.S_AXI_HP0_BREADY(m_axi_bready), .S_AXI_HP0_BVALID(m_axi_bvalid),
        let s_arespb = ps7.s_axi_hp[0].axi.resp_b.get();
        axiTop.m_axi.write.writeResponse(s_arespb.resp, s_arespb.id);
    endrule

    rule s_arespr_rule; //.S_AXI_HP0_RREADY(m_axi_rready), .S_AXI_HP0_RVALID(m_axi_rvalid),
        let s_arespr = ps7.s_axi_hp[0].axi.resp_read.get();
        axiTop.m_axi.read.readData(s_arespr.rd.data, s_arespr.r.resp, s_arespr.rd.last, s_arespr.r.id);
    endrule

    rule s_arespw_rule; //.S_AXI_HP0_WREADY(m_axi_wready), .S_AXI_HP0_WVALID(m_axi_wvalid),
        AxiWrite#(32/*data_width* /, 12/*id_width* /) s_arespw;
        s_arespw.wid = axiTop.m_axi.write.writeWid();
        //??s_arespw.wd.data <= axiTop.m_axi.write.writeWid(); //.m_axi_write_writeData(m_axi_wdata_wire),
        //.S_AXI_HP0_WDATA(m_axi_wdata),
        s_arespw.wd.last = axiTop.m_axi.write.writeLastDataBeat();
        s_arespw.wstrb = axiTop.m_axi.write.writeDataByteEnable();
        ps7.s_axi_hp[0].axi.resp_write.put(s_arespw);
    endrule
end of m_axi */

    interface Pps7Ddr ddr = ps7.ddr;
    interface Inout   mio = ps7.mio;
    interface Pps7Ps  ps = ps7.ps;
    interface LEDS    leds = axiTop.leds;
endmodule : mkZynqTop

