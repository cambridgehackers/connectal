
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import PPS7::*;

typedef struct {
    Bit#(32)                  addr;
    Bit#(2)                   burst;
    Bit#(4)                   cache;
    Bit#(id_width)            id;
    Bit#(4)                   len;
    Bit#(2)                   lock;
    Bit#(3)                   prot;
    Bit#(4)                   qos;
    Bit#(3)                   size;
} AxiREQ#(numeric type id_width);
typedef struct {
    Bit#(id_width)            id;
    Bit#(2)                   resp;
} AxiRESP#(numeric type id_width);
typedef struct {
    Bit#(data_width)          data;
    Bit#(1)                   last;
} AxiDATA#(numeric type data_width);
typedef struct {
    Bit#(id_width)            wid;
    AxiDATA#(data_width)      wd;
    Bit#(TDiv#(data_width, 8))wstrb;
} AxiWrite#(numeric type data_width, numeric type id_width);
typedef struct {
    AxiRESP#(id_width)        r;
    AxiDATA#(data_width)      rd;
} AxiRead#(numeric type data_width, numeric type id_width);

interface AxiMasterCommon#(numeric type data_width, numeric type id_width);
    method Action             aclk(Bit#(1) v); // common
    method Bit#(1)            aresetn();      // common

    method Bit#(1)            arvalid();
    interface Get#(AxiREQ#(id_width)) req_ar;
    method Action             arready(Bit#(1) v);

    method Bit#(1)            awvalid();
    interface Get#(AxiREQ#(id_width)) req_aw;
    method Action             awready(Bit#(1) v);

    method Action             rvalid(Bit#(1) v);
    interface Put#(AxiRead#(data_width, id_width)) resp_read;
    method Bit#(1)            rready();

    method Bit#(1)            wvalid();
    interface Get#(AxiWrite#(data_width, id_width)) resp_write;
    method Action             wready(Bit#(1) v);

    method Action             bvalid(Bit#(1) v);
    interface Put#(AxiRESP#(id_width)) resp_b;
    method Bit#(1)            bready();
endinterface

interface AxiSlaveCommon#(numeric type data_width, numeric type id_width);
    method Action             aclk(Bit#(1) v); // common
    method Bit#(1)            aresetn();      // common

    method Action             arvalid(Bit#(1) v);
    interface Put#(AxiREQ#(id_width)) req_ar;
    method Bit#(1)            arready();

    method Action             awvalid(Bit#(1) v);
    interface Put#(AxiREQ#(id_width)) req_aw;
    method Bit#(1)            awready();

    method Action             wvalid(Bit#(1) v);
    interface Put#(AxiWrite#(data_width, id_width)) resp_write;
    method Bit#(1)            wready();

    method Bit#(1)            rvalid();
    interface Get#(AxiRead#(data_width, id_width)) resp_read;
    method Action             rready(Bit#(1) v);

    method Bit#(1)            bvalid();
    interface Get#(AxiRESP#(id_width)) resp_b;
    method Action             bready(Bit#(1) v);
endinterface

interface AxiSlaveHighSpeed#(numeric type data_width, numeric type id_width);
    interface AxiSlaveCommon#(data_width, id_width) axi;
    method Bit#(3)            racount();
    method Bit#(8)            rcount();
    method Action             rdissuecap1_en(Bit#(1) v);
    method Bit#(6)            wacount();
    method Bit#(8)            wcount();
    method Action             wrissuecap1_en(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface Bidir#(numeric type data_width);
    method Action             i(Bit#(data_width) v);
    method Bit#(data_width)   o();
    method Bit#(data_width)   t();
endinterface
interface Can;
    method Action             phy_rx(Bit#(1) v);
    method Bit#(1)            phy_tx();
endinterface
interface Core;
    method Action             n_fiq(Bit#(1) v);
    method Action             n_irq(Bit#(1) v);
endinterface
interface Ddr#(numeric type dm_width, numeric type dq_width, numeric type dqs_width);
    method Action             arb(Bit#(4) v);
    method Bit#(15)           addr();
    method Bit#(3)            bankaddr();
    method Bit#(1)            cas_n();
    method Bit#(1)            cke();
    method Bit#(1)            cs_n();
    method Bit#(1)            clk();
    method Bit#(1)            clk_n();
    method Bit#(dm_width)     dm();
    method Bit#(dq_width)     dq();
    method Bit#(dqs_width)    dqs();
    method Bit#(dqs_width)    dqs_n();
    method Bit#(1)            drstb();
    method Bit#(1)            odt();
    method Bit#(1)            ras_n();
    method Bit#(1)            vrn();
    method Bit#(1)            vrp();
    method Bit#(1)            web();
endinterface
interface Dma;
    method Action             aclk(Bit#(1) v);
    method Action             daready(Bit#(1) v);
    method Bit#(2)            datype();
    method Bit#(1)            davalid();
    method Action             drlast(Bit#(1) v);
    method Bit#(1)            drready();
    method Action             drtype(Bit#(2) v);
    method Action             drvalid(Bit#(1) v);
    method Bit#(1)            rstn();
endinterface
interface Enet;
    method Action             ext_intin(Bit#(1) v);
    method Action             gmii_col(Bit#(1) v);
    method Action             gmii_crs(Bit#(1) v);
    method Action             gmii_rxd(Bit#(8) v);
    method Action             gmii_rx_clk(Bit#(1) v);
    method Action             gmii_rx_dv(Bit#(1) v);
    method Action             gmii_rx_er(Bit#(1) v);
    method Bit#(8)            gmii_txd();
    method Action             gmii_tx_clk(Bit#(1) v);
    method Bit#(1)            gmii_tx_en();
    method Bit#(1)            gmii_tx_er();
    method Bit#(1)            mdio_mdc();
    interface Bidir#(1)       mdio;
    method Bit#(1)            ptp_delay_req_rx();
    method Bit#(1)            ptp_delay_req_tx();
    method Bit#(1)            ptp_pdelay_req_rx();
    method Bit#(1)            ptp_pdelay_req_tx();
    method Bit#(1)            ptp_pdelay_resp_rx();
    method Bit#(1)            ptp_pdelay_resp_tx();
    method Bit#(1)            ptp_sync_frame_rx();
    method Bit#(1)            ptp_sync_frame_tx();
    method Bit#(1)            sof_rx();
    method Bit#(1)            sof_tx();
endinterface
interface I2c;
    interface Bidir#(1)       scl;
    interface Bidir#(1)       sda;
endinterface
interface Sdio;
    method Bit#(1)            buspow();
    method Bit#(3)            busvolt();
    method Action             cdn(Bit#(1) v);
    method Bit#(1)            clk();
    method Action             clk_fb(Bit#(1) v);
    interface Bidir#(1)       cmd;
    interface Bidir#(4)       data;
    method Bit#(1)            led();
    method Action             wp(Bit#(1) v);
endinterface
interface Spi;
    interface Bidir#(1)       miso;
    interface Bidir#(1)       mosi;
    interface Bidir#(1)       sclk;
    method Bit#(1)            ss1_o();
    method Bit#(1)            ss2_o();
    interface Bidir#(1)       ss;
endinterface
interface Ttc;
    method Action             clk0_in(Bit#(1) v);
    method Action             clk1_in(Bit#(1) v);
    method Action             clk2_in(Bit#(1) v);
    method Bit#(1)            wave0_out();
    method Bit#(1)            wave1_out();
    method Bit#(1)            wave2_out();
endinterface
interface Uart;
    method Action             ctsn(Bit#(1) v);
    method Action             dcdn(Bit#(1) v);
    method Action             dsrn(Bit#(1) v);
    method Bit#(1)            dtrn();
    method Action             rin(Bit#(1) v);
    method Bit#(1)            rtsn();
    method Action             rx(Bit#(1) v);
    method Bit#(1)            tx();
endinterface
interface Usb;
    method Bit#(2)            port_indctl();
    method Action             vbus_pwrfault(Bit#(1) v);
    method Bit#(1)            vbus_pwrselect();
endinterface

interface PS7#(numeric type data_width, numeric type id_width, numeric type gpio_width, numeric type mio_width);
    interface Can             can0;
    interface Can             can1;
    interface Core            core0;
    interface Core            core1;
    interface Ddr#(10,1,1)    ddr;
    interface Dma             dma0;
    interface Dma             dma1;
    interface Dma             dma2;
    interface Dma             dma3;
    interface Enet            enet0;
    interface Enet            enet1;
    method Action             event_eventi(Bit#(1) v);
    method Bit#(1)            event_evento();
    method Bit#(2)            event_standbywfe();
    method Bit#(2)            event_standbywfi();
    method Bit#(1)            fclk_clk0();
    method Bit#(1)            fclk_clk1();
    method Bit#(1)            fclk_clk2();
    method Bit#(1)            fclk_clk3();
    method Action             fclk_clktrig0_n(Bit#(1) v);
    method Action             fclk_clktrig1_n(Bit#(1) v);
    method Action             fclk_clktrig2_n(Bit#(1) v);
    method Action             fclk_clktrig3_n(Bit#(1) v);
    method Bit#(1)            fclk_reset0_n();
    method Bit#(1)            fclk_reset1_n();
    method Bit#(1)            fclk_reset2_n();
    method Bit#(1)            fclk_reset3_n();
    method Action             fpga_idle_n(Bit#(1) v);
    method Action             ftmd_tracein_atid(Bit#(4) v);
    method Action             ftmd_tracein_clk(Bit#(1) v);
    method Action             ftmd_tracein_data(Bit#(32) v);
    method Action             ftmd_tracein_valid(Bit#(1) v);
    method Action             ftmt_f2p_debug(Bit#(32) v);
    method Action             ftmt_f2p_trig(Bit#(4) v);
    method Bit#(4)            ftmt_f2p_trigack();
    method Bit#(32)           ftmt_p2f_debug();
    method Bit#(4)            ftmt_p2f_trig();
    method Action             ftmt_p2f_trigack(Bit#(4) v);
    interface Bidir#(gpio_width) gpio;
    interface I2c             i2c0;
    interface I2c             i2c1;
    method Action             irq_f2p(Bit#(16) v);
    method Bit#(1)            irq_p2f_can0();
    method Bit#(1)            irq_p2f_can1();
    method Bit#(1)            irq_p2f_cti();
    method Bit#(1)            irq_p2f_dmac0();
    method Bit#(1)            irq_p2f_dmac1();
    method Bit#(1)            irq_p2f_dmac2();
    method Bit#(1)            irq_p2f_dmac3();
    method Bit#(1)            irq_p2f_dmac4();
    method Bit#(1)            irq_p2f_dmac5();
    method Bit#(1)            irq_p2f_dmac6();
    method Bit#(1)            irq_p2f_dmac7();
    method Bit#(1)            irq_p2f_dmac_abort();
    method Bit#(1)            irq_p2f_enet0();
    method Bit#(1)            irq_p2f_enet1();
    method Bit#(1)            irq_p2f_enet_wake0();
    method Bit#(1)            irq_p2f_enet_wake1();
    method Bit#(1)            irq_p2f_gpio();
    method Bit#(1)            irq_p2f_i2c0();
    method Bit#(1)            irq_p2f_i2c1();
    method Bit#(1)            irq_p2f_qspi();
    method Bit#(1)            irq_p2f_sdio0();
    method Bit#(1)            irq_p2f_sdio1();
    method Bit#(1)            irq_p2f_smc();
    method Bit#(1)            irq_p2f_spi0();
    method Bit#(1)            irq_p2f_spi1();
    method Bit#(1)            irq_p2f_uart0();
    method Bit#(1)            irq_p2f_uart1();
    method Bit#(1)            irq_p2f_usb0();
    method Bit#(1)            irq_p2f_usb1();
    method Bit#(mio_width)mio();
    interface AxiSlaveCommon#(data_width, id_width)    s_axi_acp;
    method Action             s_axi_acp_aruser(Bit#(5) v);
    method Action             s_axi_acp_awuser(Bit#(5) v);
    //interface AxiSlaveCommon#(data_width, id_width)    s_axi_gp0;
    //interface AxiSlaveCommon#(data_width, id_width)    s_axi_gp1;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp0;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp1;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp2;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp3;
    interface AxiMasterCommon#(data_width, id_width)   m_axi_gp0;
    //interface AxiMasterCommon#(data_width, id_width)   m_axi_gp1;
    method Action             pjtag_tck(Bit#(1) v);
    interface Bidir#(1)       pjtag_td;
    method Action             pjtag_tms(Bit#(1) v);
    method Action             ps_clk(Bit#(1) v);
    method Action             ps_porb(Bit#(1) v);
    method Action             ps_srstb(Bit#(1) v);
    interface Sdio            sdio0;
    interface Sdio            sdio1;
    interface Spi             spi0;
    interface Spi             spi1;
    method Action             sram_intin(Bit#(1) v);
    method Action             trace_clk(Bit#(1) v);
    method Bit#(1)            trace_ctl();
    method Bit#(32)           trace_data();
    interface Ttc             ttc0;
    interface Ttc             ttc1;
    interface Uart            uart0;
    interface Uart            uart1;
    interface Usb             usb0;
    interface Usb             usb1;
    method Action             wdt_clk_in(Bit#(1) v);
    method Bit#(1)            wdt_rst_out();
endinterface

module mkPS7#(int data_width, int id_width, int gpio_width, int mio_width)(PS7#(data_width, id_width, gpio_width, mio_width));
    PPS7#(4, 4, 4, 32, 70, 12, 50)foo <- mkPPS7(4, 4, 4, 32, 70, 12, 50);

    interface Can can0;
    //method phy_rx(CAN0_PHY_RX) ;
    //method CAN0_PHY_TX phy_tx();
    endinterface
    interface Can can1;
    //method phy_rx(CAN1_PHY_RX) ;
    //method CAN1_PHY_TX phy_tx();
    endinterface
    interface Core core0;
    //method n_fiq(CORE0_N_FIQ);
    //method n_irq(CORE0_N_IRQ);
    endinterface
    interface Core core1;
    //method n_fiq(CORE1_N_FIQ);
    //method n_irq(CORE1_N_IRQ);
    endinterface
    interface Ddr    ddr;
    //method arb(ARB) ;
    //method DDR_ADDR     addr();
    //method DDR_BANKADDR bankaddr();
    //method DDR_CAS_N    cas_n();
    //method DDR_CKE      cke();
    //method DDR_CS_N     cs_n();
    //method DDR_CLK      clk();
    //method DDR_CLK_N    clk_n();
    //method DDR_DM       dm();
    //method DDR_DQ       dq();
    //method DDR_DQS      dqs();
    //method DDR_DQS_N    dqs_n();
    //method DDR_DRSTB    drstb();
    //method DDR_ODT      odt();
    //method DDR_RAS_N    ras_n();
    //method DDR_VRN      vrn();
    //method DDR_VRP      vrp();
    //method DDR_WEB      web();
    endinterface
    interface Dma dma0;
    //method aclk(DMA0_ACLK);
    //method daready(DMA0_DAREADY);
    //method DMA0_DATYPE datype();
    //method DMA0_DAVALID davalid();
    //method drlast(DMA0_DRLAST);
    //method DMA0_DRREADY drready();
    //method drtype(DMA0_DRTYPE);
    //method drvalid(DMA0_DRVALID);
    //method DMA0_RSTN rstn();
    endinterface
    interface Dma dma1;
    //method aclk(DMA1_ACLK);
    //method daready(DMA1_DAREADY);
    //method DMA1_DATYPE datype();
    //method DMA1_DAVALID davalid();
    //method drlast(DMA1_DRLAST);
    //method DMA1_DRREADY drready();
    //method drtype(DMA1_DRTYPE);
    //method drvalid(DMA1_DRVALID);
    //method DMA1_RSTN rstn();
    endinterface
    interface Dma dma2;
    //method aclk(DMA2_ACLK);
    //method daready(DMA2_DAREADY);
    //method DMA2_DATYPE datype();
    //method DMA2_DAVALID davalid();
    //method drlast(DMA2_DRLAST);
    //method DMA2_DRREADY drready();
    //method drtype(DMA2_DRTYPE);
    //method drvalid(DMA2_DRVALID);
    //method DMA2_RSTN rstn();
    endinterface
    interface Dma dma3;
    //method aclk(DMA3_ACLK);
    //method daready(DMA3_DAREADY);
    //method DMA3_DATYPE datype();
    //method DMA3_DAVALID davalid();
    //method drlast(DMA3_DRLAST);
    //method DMA3_DRREADY drready();
    //method drtype(DMA3_DRTYPE);
    //method drvalid(DMA3_DRVALID);
    //method DMA3_RSTN rstn();
    endinterface
    interface Enet enet0;
    //method ext_intin(ENET0_EXT_INTIN);
    //method gmii_col(ENET0_GMII_COL);
    //method gmii_crs(ENET0_GMII_CRS);
    //method gmii_rxd(ENET0_GMII_RXD);
    //method gmii_rx_clk(ENET0_GMII_RX_CLK);
    //method gmii_rx_dv(ENET0_GMII_RX_DV);
    //method gmii_rx_er(ENET0_GMII_RX_ER);
    //method ENET0_GMII_TXD gmii_txd();
    //method gmii_tx_clk(ENET0_GMII_TX_CLK);
    //method ENET0_GMII_TX_EN gmii_tx_en();
    //method ENET0_GMII_TX_ER gmii_tx_er();
    //method ENET0_MDIO_MDC mdio_mdc();
    interface Bidir       mdio;
        //method i(ENET0_MDIO_I);
        //method ENET0_MDIO_O o();
        //method ENET0_MDIO_T t();
    endinterface
    //method ENET0_PTP_DELAY_REQ_RX ptp_delay_req_rx();
    //method ENET0_PTP_DELAY_REQ_TX ptp_delay_req_tx();
    //method ENET0_PTP_PDELAY_REQ_RX ptp_pdelay_req_rx();
    //method ENET0_PTP_PDELAY_REQ_TX ptp_pdelay_req_tx();
    //method ENET0_PTP_PDELAY_RESP_RX ptp_pdelay_resp_rx();
    //method ENET0_PTP_PDELAY_RESP_TX ptp_pdelay_resp_tx();
    //method ENET0_PTP_SYNC_FRAME_RX ptp_sync_frame_rx();
    //method ENET0_PTP_SYNC_FRAME_TX ptp_sync_frame_tx();
    //method ENET0_SOF_RX sof_rx();
    //method ENET0_SOF_TX sof_tx();
    endinterface
    interface Enet enet1;
    //method ext_intin(ENET1_EXT_INTIN);
    //method gmii_col(ENET1_GMII_COL);
    //method gmii_crs(ENET1_GMII_CRS);
    //method gmii_rxd(ENET1_GMII_RXD);
    //method gmii_rx_clk(ENET1_GMII_RX_CLK);
    //method gmii_rx_dv(ENET1_GMII_RX_DV);
    //method gmii_rx_er(ENET1_GMII_RX_ER);
    //method ENET1_GMII_TXD gmii_txd();
    //method gmii_tx_clk(ENET1_GMII_TX_CLK);
    //method ENET1_GMII_TX_EN gmii_tx_en();
    //method ENET1_GMII_TX_ER gmii_tx_er();
    //method ENET1_MDIO_MDC mdio_mdc();
    interface Bidir       mdio;
        //method i(ENET1_MDIO_I);
        //method ENET1_MDIO_O o();
        //method ENET1_MDIO_T t();
    endinterface
    //method ENET1_PTP_DELAY_REQ_RX ptp_delay_req_rx();
    //method ENET1_PTP_DELAY_REQ_TX ptp_delay_req_tx();
    //method ENET1_PTP_PDELAY_REQ_RX ptp_pdelay_req_rx();
    //method ENET1_PTP_PDELAY_REQ_TX ptp_pdelay_req_tx();
    //method ENET1_PTP_PDELAY_RESP_RX ptp_pdelay_resp_rx();
    //method ENET1_PTP_PDELAY_RESP_TX ptp_pdelay_resp_tx();
    //method ENET1_PTP_SYNC_FRAME_RX ptp_sync_frame_rx();
    //method ENET1_PTP_SYNC_FRAME_TX ptp_sync_frame_tx();
    //method ENET1_SOF_RX sof_rx();
    //method ENET1_SOF_TX sof_tx();
    endinterface
    //method event_eventi(EVENT_EVENTI) ;
    //method EVENT_EVENTO event_evento();
    //method EVENT_STANDBYWFE event_standbywfe();
    //method EVENT_STANDBYWFI event_standbywfi();
    //method FCLK_CLK0 fclk_clk0();
    //method FCLK_CLK1 fclk_clk1();
    //method FCLK_CLK2 fclk_clk2();
    //method FCLK_CLK3 fclk_clk3();
    //method fclk_clktrig0_n(FCLK_CLKTRIG0_N) ;
    //method fclk_clktrig1_n(FCLK_CLKTRIG1_N) ;
    //method fclk_clktrig2_n(FCLK_CLKTRIG2_N) ;
    //method fclk_clktrig3_n(FCLK_CLKTRIG3_N) ;
    //method FCLK_RESET0_N fclk_reset0_n();
    //method FCLK_RESET1_N fclk_reset1_n();
    //method FCLK_RESET2_N fclk_reset2_n();
    //method FCLK_RESET3_N fclk_reset3_n();
    //method fpga_idle_n(FPGA_IDLE_N) ;
    //method ftmd_tracein_atid(FTMD_TRACEIN_ATID) ;
    //method ftmd_tracein_clk(FTMD_TRACEIN_CLK) ;
    //method ftmd_tracein_data(FTMD_TRACEIN_DATA) ;
    //method ftmd_tracein_valid(FTMD_TRACEIN_VALID) ;
    //method ftmt_f2p_debug(FTMT_F2P_DEBUG) ;
    //method ftmt_f2p_trig(FTMT_F2P_TRIG) ;
    //method FTMT_F2P_TRIGACK ftmt_f2p_trigack();
    //method FTMT_P2F_DEBUG ftmt_p2f_debug();
    //method FTMT_P2F_TRIG ftmt_p2f_trig();
    //method ftmt_p2f_trigack(FTMT_P2F_TRIGACK) ;
    interface Bidir gpio;
        //method i(GPIO_SCL_I);
        //method GPIO_SCL_O o();
        //method GPIO_SCL_T t();
    endinterface
    interface I2c i2c0;
    interface Bidir       scl;
        //method i(I2C0_SCL_I);
        //method I2C0_SCL_O o();
        //method I2C0_SCL_T t();
    endinterface
    interface Bidir       sda;
        //method i(I2C0_SDA_I);
        //method I2C0_SDA_O o();
        //method I2C0_SDA_T t();
    endinterface
    endinterface
    interface I2c i2c1;
    interface Bidir       scl;
        //method i(I2C1_SCL_I);
        //method I2C1_SCL_O o();
        //method I2C1_SCL_T t();
    endinterface
    interface Bidir       sda;
        //method i(I2C1_SDA_I);
        //method I2C1_SDA_O o();
        //method I2C1_SDA_T t();
    endinterface
    endinterface
    //method irq_f2p(IRQ_F2P) ;
    //method IRQ_P2F_CAN0 irq_p2f_can0();
    //method IRQ_P2F_CAN1 irq_p2f_can1();
    //method IRQ_P2F_CTI irq_p2f_cti();
    //method IRQ_P2F_DMAC0 irq_p2f_dmac0();
    //method IRQ_P2F_DMAC1 irq_p2f_dmac1();
    //method IRQ_P2F_DMAC2 irq_p2f_dmac2();
    //method IRQ_P2F_DMAC3 irq_p2f_dmac3();
    //method IRQ_P2F_DMAC4 irq_p2f_dmac4();
    //method IRQ_P2F_DMAC5 irq_p2f_dmac5();
    //method IRQ_P2F_DMAC6 irq_p2f_dmac6();
    //method IRQ_P2F_DMAC7 irq_p2f_dmac7();
    //method IRQ_P2F_DMAC_ABORT irq_p2f_dmac_abort();
    //method IRQ_P2F_ENET0 irq_p2f_enet0();
    //method IRQ_P2F_ENET1 irq_p2f_enet1();
    //method IRQ_P2F_ENET_WAKE0 irq_p2f_enet_wake0();
    //method IRQ_P2F_ENET_WAKE1 irq_p2f_enet_wake1();
    //method IRQ_P2F_GPIO irq_p2f_gpio();
    //method IRQ_P2F_I2C0 irq_p2f_i2c0();
    //method IRQ_P2F_I2C1 irq_p2f_i2c1();
    //method IRQ_P2F_QSPI irq_p2f_qspi();
    //method IRQ_P2F_SDIO0 irq_p2f_sdio0();
    //method IRQ_P2F_SDIO1 irq_p2f_sdio1();
    //method IRQ_P2F_SMC irq_p2f_smc();
    //method IRQ_P2F_SPI0 irq_p2f_spi0();
    //method IRQ_P2F_SPI1 irq_p2f_spi1();
    //method IRQ_P2F_UART0 irq_p2f_uart0();
    //method IRQ_P2F_UART1 irq_p2f_uart1();
    //method IRQ_P2F_USB0 irq_p2f_usb0();
    //method IRQ_P2F_USB1 irq_p2f_usb1();
    //method MIO mio();
    //method pjtag_tck(PJTAG_TCK) ;
    interface Bidir       pjtag_td;
        //method i(PJTAG_TD_CMD_I);
        //method PJTAG_TD_CMD_O o();
        //method PJTAG_TD_CMD_T t();
    endinterface
    //method pjtag_tms(PJTAG_TMS) ;
    //method ps_clk(PS_CLK) ;
    //method ps_porb(PS_PORB) ;
    //method ps_srstb(PS_SRTSB) ;
    interface Sdio sdio0;
    //method SDIO0_BUSPOW buspow();
    //method SDIO0_BUSVOLT busvolt();
    //method cdn(SDIO0_CDN);
    //method SDIO0_CLK clk();
    //method clk_fb(SDIO0_CLK_FB);
    interface Bidir       cmd;
        //method i(SDIO0_CMD_I);
        //method SDIO0_CMD_O o();
        //method SDIO0_CMD_T t();
    endinterface
    interface Bidir       data;
        //method i(SDIO0_DATA_I);
        //method SDIO0_DATA_O o();
        //method SDIO0_DATA_T t();
    endinterface
    //method SDIO0_LED led();
    //method wp(SDIO0_WP);
    endinterface
    interface Sdio sdio1;
    //method SDIO1_BUSPOW buspow();
    //method SDIO1_BUSVOLT busvolt();
    //method cdn(SDIO1_CDN);
    //method SDIO1_CLK clk();
    //method clk_fb(SDIO1_CLK_FB);
    interface Bidir       cmd;
        //method i(SDIO1_CMD_I);
        //method SDIO1_CMD_O o();
        //method SDIO1_CMD_T t();
    endinterface
    interface Bidir       data;
        //method i(SDIO1_DATA_I);
        //method SDIO1_DATA_O o();
        //method SDIO1_DATA_T t();
    endinterface
    //method SDIO1_LED led();
    //method wp(SDIO1_WP);
    endinterface
    interface Spi spi0;
    interface Bidir       miso;
        //method i(SPI0_MISO_I);
        //method SPI0_MISO_O o();
        //method SPI0_MISO_T t();
    endinterface
    interface Bidir       mosi;
        //method i(SPI0_MOSI_I);
        //method SPI0_MOSI_O o();
        //method SPI0_MOSI_T t();
    endinterface
    interface Bidir       sclk;
        //method i(SPI0_SCLK_I);
        //method SPI0_SCLK_O o();
        //method SPI0_SCLK_T t();
    endinterface
    //method SPI0_SS1_O ss1_o();
    //method SPI0_SS2_O ss2_o();
    interface Bidir       ss;
        //method i(SPI0_SS_I);
        //method SPI0_SS_O o();
        //method SPI0_SS_T t();
    endinterface
    endinterface
    interface Spi spi1;
    interface Bidir       miso;
        //method i(SPI1_MISO_I);
        //method SPI1_MISO_O o();
        //method SPI1_MISO_T t();
    endinterface
    interface Bidir       mosi;
        //method i(SPI1_MOSI_I);
        //method SPI1_MOSI_O o();
        //method SPI1_MOSI_T t();
    endinterface
    interface Bidir       sclk;
        //method i(SPI1_SCLK_I);
        //method SPI1_SCLK_O o();
        //method SPI1_SCLK_T t();
    endinterface
    //method SPI1_SS1_O ss1_o();
    //method SPI1_SS2_O ss2_o();
    interface Bidir       ss;
        //method i(SPI1_SS_I);
        //method SPI1_SS_O o();
        //method SPI1_SS_T t();
    endinterface
    endinterface
    //method sram_intin(SRAM_INTIN) ;
    //method trace_clk(TRACE_CLK) ;
    //method   TRACE_CTL trace_ctl();
    //method   TRACE_DATA trace_data();
    interface Ttc ttc0;
    //method clk0_in(TTC0_CLK0_IN);
    //method clk1_in(TTC0_CLK1_IN);
    //method clk2_in(TTC0_CLK2_IN);
    //method TTC0_WAVE0_OUT wave0_out();
    //method TTC0_WAVE1_OUT wave1_out();
    //method TTC0_WAVE2_OUT wave2_out();
    endinterface
    interface Ttc ttc1;
    //method clk0_in(TTC1_CLK0_IN);
    //method clk1_in(TTC1_CLK1_IN);
    //method clk2_in(TTC1_CLK2_IN);
    //method TTC1_WAVE0_OUT wave0_out();
    //method TTC1_WAVE1_OUT wave1_out();
    //method TTC1_WAVE2_OUT wave2_out();
    endinterface
    interface Uart uart0;
    //method ctsn(UART0_CTSN);
    //method dcdn(UART0_DCDN);
    //method dsrn(UART0_DSRN);
    //method UART0_DTRN dtrn();
    //method rin(UART0_RIN);
    //method UART0_RTSN rtsn();
    //method rx(UART0_RX);
    //method UART0_TX tx();
    endinterface
    interface Uart uart1;
    //method ctsn(UART1_CTSN);
    //method dcdn(UART1_DCDN);
    //method dsrn(UART1_DSRN);
    //method UART1_DTRN dtrn();
    //method rin(UART1_RIN);
    //method UART1_RTSN rtsn();
    //method rx(UART1_RX);
    //method UART1_TX tx();
    endinterface
    interface Usb usb0;
        //method vbus_pwrfault(VBUS_PWRFAULT);
        //method VBUS_PWRSELECT vbus_pwrselect();
        //method PORT_INDCTL port_indctl();
    endinterface
    interface Usb usb1;
        //method vbus_pwrfault(VBUS_PWRFAULT1);
        //method VBUS_PWRSELECT1 vbus_pwrselect();
        //method PORT_INDCTL1 port_indctl();
    endinterface
    //method wdt_clk_in(WDT_CLK_IN) ;
    //method WDT_RST_OUT wdt_rst_out();

    interface AxiSlaveCommon    s_axi_acp;
    endinterface
    //method s_axi_acp_aruser(S_AXI_ACP_ARUSER) ;
    //method s_axi_acp_awuser(S_AXI_ACP_AWUSER) ;

    //interface AxiSlaveCommon    s_axi_gp0;
    //endinterface
    //interface AxiSlaveCommon    s_axi_gp1;
    //endinterface
    //interface AxiSlaveHighSpeed s_axi_hp0;
    //interface AxiSlaveCommon axi;
    //endinterface
    ////method S_AXI_HP0_RACOUNT racount();
    ////method S_AXI_HP0_RCOUNT rcount();
    ////method rdissuecap1_en(S_AXI_HP0_RDISSUECAP1_EN);
    ////method S_AXI_HP0_WACOUNT wacount();
    ////method S_AXI_HP0_WCOUNT wcount();
    ////method wrissuecap1_en(S_AXI_HP0_WRISSUECAP1_EN);
    //endinterface
    //interface AxiSlaveHighSpeed s_axi_hp1;
    //endinterface
    //interface AxiSlaveHighSpeed s_axi_hp2;
    //endinterface
    //interface AxiSlaveHighSpeed s_axi_hp3;
    //endinterface
    interface AxiMasterCommon   m_axi_gp0;
    endinterface
    //interface AxiMasterCommon   m_axi_gp1;
    //endinterface
endmodule
