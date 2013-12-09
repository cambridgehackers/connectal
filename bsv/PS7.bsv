
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
import Vector::*;
import GetPut::*;

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
    Bit#(1)                   valid;
} AxiREQ#(numeric type id_width);
typedef struct {
    AxiREQ#(id_width)         ar;
    AxiREQ#(id_width)         aw;
    Bit#(1)                   bready;
    Bit#(1)                   rready;
    Bit#(data_width)          wdata;
    Bit#(id_width)            wid;
    Bit#(1)                   wlast;
    Bit#(TDiv#(data_width, 8))wstrb;
    Bit#(1)                   wvalid;
} AxiMOSI#(numeric type data_width, numeric type id_width);
typedef struct {
    Bit#(id_width)            id;
    Bit#(2)                   resp;
    Bit#(1)                   valid;
} AxiVALID#(numeric type id_width);
typedef struct {
    Bit#(1)                   arready;
    Bit#(1)                   awready;
    AxiVALID#(id_width)       b;
    AxiVALID#(id_width)       r;
    Bit#(data_width)          rdata;
    Bit#(1)                   rlast;
    Bit#(1)                   wready;
} AxiMISO#(numeric type data_width, numeric type id_width);

interface AxiMasterCommon#(numeric type data_width, numeric type id_width);
    method Action             aclk(Bit#(1) v); // common
    method Bit#(1)            aresetn();      // common
    interface Put#(AxiMISO#(data_width, id_width)) req;
    interface Get#(AxiMOSI#(data_width, id_width)) resp;
endinterface

interface AxiSlaveCommon#(numeric type data_width, numeric type id_width);
    method Action             aclk(Bit#(1) v); // common
    method Bit#(1)            aresetn();      // common
    interface Put#(AxiMOSI#(data_width, id_width)) req;
    interface Get#(AxiMISO#(data_width, id_width)) resp;
    method Action             araddr(Bit#(32) v);
    method Bit#(1)            arready();
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
interface I2c;
    interface Bidir#(1)       scl;
    interface Bidir#(1)       sda;
endinterface
interface Can;
    method Action             phy_rx(Bit#(1) v);
    method Bit#(1)            phy_tx();
endinterface
interface Core;
    method Action             n_fiq(Bit#(1) v);
    method Action             n_irq(Bit#(1) v);
endinterface

interface PS7#(numeric type data_width, numeric type id_width, numeric type gpio_width, numeric type mio_width);
    //interface Vector#(2, Can) can;
    //interface Vector#(2, Core)core;
    interface Ddr#(10,1,1)    ddr;
    //interface Vector#(4, Dma) dma;
    //interface Vector#(2, Enet)enet;
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
    //interface Bidir#(gpio_width) gpio;
    //interface Vector#(2, I2c)i2c;
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
    //interface AxiSlaveCommon#(data_width, id_width)    s_axi_acp;
    method Action             s_axi_acp_aruser(Bit#(5) v);
    method Action             s_axi_acp_awuser(Bit#(5) v);
    //interface AxiSlaveCommon#(data_width, id_width)    s_axi_gp0;
    //interface AxiSlaveCommon#(data_width, id_width)    s_axi_gp1;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp0;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp1;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp2;
    //interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp3;
    //interface AxiMasterCommon#(data_width, id_width)   m_axi_gp0;
    //interface AxiMasterCommon#(data_width, id_width)   m_axi_gp1;
    method Action             pjtag_tck(Bit#(1) v);
    //interface Bidir#(1)       pjtag_td;
    method Action             pjtag_tms(Bit#(1) v);
    method Action             ps_clk(Bit#(1) v);
    method Action             ps_porb(Bit#(1) v);
    method Action             ps_srstb(Bit#(1) v);
    //interface Vector#(2, Sdio)sdio;
    //interface Vector#(2, Spi) spi;
    method Action             sram_intin(Bit#(1) v);
    method Action             trace_clk(Bit#(1) v);
    method Bit#(1)            trace_ctl();
    method Bit#(32)           trace_data();
    //interface Vector#(2, Ttc) ttc;
    //interface Vector#(2, Uart)uart;
    //interface Vector#(2, Usb) usb;
    method Action             wdt_clk_in(Bit#(1) v);
    method Bit#(1)            wdt_rst_out();
endinterface

import "BVI" processing_system7 =
module mkPS7#(int data_width, int id_width, int gpio_width, int mio_width)(PS7#(data_width, id_width, gpio_width, mio_width));
   default_clock clk(C);
   no_reset;
//    parameter USE_TRACE_DATA_EDGE_DETECTOR = 0;
//    parameter C_DM_WIDTH = 0;
//    parameter C_DQS_WIDTH = 0;
//    parameter C_DQ_WIDTH = 0;
//    parameter C_EMIO_GPIO_WIDTH = 0;
//    parameter C_EN_EMIO_ENET0 = 0;
//    parameter C_EN_EMIO_ENET1 = 0;
//    parameter C_EN_EMIO_TRACE = 0;
//    parameter C_FCLK_CLK0_BUF = 0;
//    parameter C_FCLK_CLK1_BUF = 0;
//    parameter C_FCLK_CLK2_BUF = 0;
//    parameter C_FCLK_CLK3_BUF = 0;
//    parameter C_INCLUDE_ACP_TRANS_CHECK = 0;
//    parameter C_INCLUDE_TRACE_BUFFER = 0;
//    parameter C_MIO_PRIMITIVE = 0;
//    parameter C_M_AXI_GP0_ENABLE_STATIC_REMAP = 0;
//    parameter C_M_AXI_GP0_ID_WIDTH = 0;
//    parameter C_M_AXI_GP0_THREAD_ID_WIDTH = 0;
//    parameter C_M_AXI_GP1_ENABLE_STATIC_REMAP = 0;
//    parameter C_M_AXI_GP1_ID_WIDTH = 0;
//    parameter C_M_AXI_GP1_THREAD_ID_WIDTH = 0;
    parameter C_NUM_F2P_INTR_INPUTS = 16;
//    parameter C_PACKAGE_NAME = 0;
//    parameter C_PS7_SI_REV = 0;
//    parameter C_S_AXI_ACP_ARUSER_VAL = 0;
//    parameter C_S_AXI_ACP_AWUSER_VAL = 0;
//    parameter C_S_AXI_ACP_ID_WIDTH = 0;
//    parameter C_S_AXI_GP0_ID_WIDTH = 0;
//    parameter C_S_AXI_GP1_ID_WIDTH = 0;
//    parameter C_S_AXI_HP0_DATA_WIDTH = 0;
//    parameter C_S_AXI_HP0_ID_WIDTH = 0;
//    parameter C_S_AXI_HP1_DATA_WIDTH = 0;
//    parameter C_S_AXI_HP1_ID_WIDTH = 0;
//    parameter C_S_AXI_HP2_DATA_WIDTH = 0;
//    parameter C_S_AXI_HP2_ID_WIDTH = 0;
//    parameter C_S_AXI_HP3_DATA_WIDTH = 0;
//    parameter C_S_AXI_HP3_ID_WIDTH = 0;
//    parameter C_TRACE_BUFFER_CLOCK_DELAY = 0;
//    parameter C_TRACE_BUFFER_FIFO_SIZE = 0;
//    parameter C_USE_DEFAULT_ACP_USER_VAL = 0;
    //interface can;
    //method phy_rx(PHY_RX)  enable((*inhigh*) en26);
    //method   PHY_TX phy_tx();
    //endinterface
    //interface core;
    //endinterface
    //interface ddr;
    //interface Ddr#(10,1,1)    ddr;
    interface Ddr    ddr;
    method arb(ARB)  enable((*inhigh*) en25);
    method DDR_ADDR     addr();
    method DDR_BANKADDR bankaddr();
    method DDR_CAS_N    cas_n();
    method DDR_CKE      cke();
    method DDR_CS_N     cs_n();
    method DDR_CLK      clk();
    method DDR_CLK_N    clk_n();
    method DDR_DM       dm();
    method DDR_DQ       dq();
    method DDR_DQS      dqs();
    method DDR_DQS_N    dqs_n();
    method DDR_DRSTB    drstb();
    method DDR_ODT      odt();
    method DDR_RAS_N    ras_n();
    method DDR_VRN      vrn();
    method DDR_VRP      vrp();
    method DDR_WEB      web();
    endinterface
    //interface dma;
    //endinterface
    //interface enet;
    //endinterface
    method event_eventi(EVENT_EVENTI)  enable((*inhigh*) en24);
    method   EVENT_EVENTO event_evento();
    method   EVENT_STANDBYWFE event_standbywfe();
    method   EVENT_STANDBYWFI event_standbywfi();
    method   FCLK_CLK0 fclk_clk0();
    method   FCLK_CLK1 fclk_clk1();
    method   FCLK_CLK2 fclk_clk2();
    method   FCLK_CLK3 fclk_clk3();
    method fclk_clktrig0_n(FCLK_CLKTRIG0_N)  enable((*inhigh*) en23);
    method fclk_clktrig1_n(FCLK_CLKTRIG1_N)  enable((*inhigh*) en22);
    method fclk_clktrig2_n(FCLK_CLKTRIG2_N)  enable((*inhigh*) en21);
    method fclk_clktrig3_n(FCLK_CLKTRIG3_N)  enable((*inhigh*) en20);
    method   FCLK_RESET0_N fclk_reset0_n();
    method   FCLK_RESET1_N fclk_reset1_n();
    method   FCLK_RESET2_N fclk_reset2_n();
    method   FCLK_RESET3_N fclk_reset3_n();
    method fpga_idle_n(FPGA_IDLE_N)  enable((*inhigh*) en19);
    method ftmd_tracein_atid(FTMD_TRACEIN_ATID)  enable((*inhigh*) en18);
    method ftmd_tracein_clk(FTMD_TRACEIN_CLK)  enable((*inhigh*) en17);
    method ftmd_tracein_data(FTMD_TRACEIN_DATA)  enable((*inhigh*) en16);
    method ftmd_tracein_valid(FTMD_TRACEIN_VALID)  enable((*inhigh*) en15);
    method ftmt_f2p_debug(FTMT_F2P_DEBUG)  enable((*inhigh*) en14);
    method ftmt_f2p_trig(FTMT_F2P_TRIG)  enable((*inhigh*) en13);
    method   FTMT_F2P_TRIGACK ftmt_f2p_trigack();
    method   FTMT_P2F_DEBUG ftmt_p2f_debug();
    method   FTMT_P2F_TRIG ftmt_p2f_trig();
    method ftmt_p2f_trigack(FTMT_P2F_TRIGACK)  enable((*inhigh*) en12);
    //interface gpio;
    //endinterface
    //interface i2c;
    //endinterface
    method irq_f2p(IRQ_F2P)  enable((*inhigh*) en11);
    method   IRQ_P2F_CAN0 irq_p2f_can0();
    method   IRQ_P2F_CAN1 irq_p2f_can1();
    method   IRQ_P2F_CTI irq_p2f_cti();
    method   IRQ_P2F_DMAC0 irq_p2f_dmac0();
    method   IRQ_P2F_DMAC1 irq_p2f_dmac1();
    method   IRQ_P2F_DMAC2 irq_p2f_dmac2();
    method   IRQ_P2F_DMAC3 irq_p2f_dmac3();
    method   IRQ_P2F_DMAC4 irq_p2f_dmac4();
    method   IRQ_P2F_DMAC5 irq_p2f_dmac5();
    method   IRQ_P2F_DMAC6 irq_p2f_dmac6();
    method   IRQ_P2F_DMAC7 irq_p2f_dmac7();
    method   IRQ_P2F_DMAC_ABORT irq_p2f_dmac_abort();
    method   IRQ_P2F_ENET0 irq_p2f_enet0();
    method   IRQ_P2F_ENET1 irq_p2f_enet1();
    method   IRQ_P2F_ENET_WAKE0 irq_p2f_enet_wake0();
    method   IRQ_P2F_ENET_WAKE1 irq_p2f_enet_wake1();
    method   IRQ_P2F_GPIO irq_p2f_gpio();
    method   IRQ_P2F_I2C0 irq_p2f_i2c0();
    method   IRQ_P2F_I2C1 irq_p2f_i2c1();
    method   IRQ_P2F_QSPI irq_p2f_qspi();
    method   IRQ_P2F_SDIO0 irq_p2f_sdio0();
    method   IRQ_P2F_SDIO1 irq_p2f_sdio1();
    method   IRQ_P2F_SMC irq_p2f_smc();
    method   IRQ_P2F_SPI0 irq_p2f_spi0();
    method   IRQ_P2F_SPI1 irq_p2f_spi1();
    method   IRQ_P2F_UART0 irq_p2f_uart0();
    method   IRQ_P2F_UART1 irq_p2f_uart1();
    method   IRQ_P2F_USB0 irq_p2f_usb0();
    method   IRQ_P2F_USB1 irq_p2f_usb1();
    method   MIO mio();
    //interface s_axi_acp;
    //endinterface
    method s_axi_acp_aruser(YY1)  enable((*inhigh*) en10);
    method s_axi_acp_awuser(YY)  enable((*inhigh*) en09);
    //interface s_axi_gp0;
    //endinterface
    //interface s_axi_gp1;
    //endinterface
    //interface s_axi_hp0;
    //endinterface
    //interface s_axi_hp1;
    //endinterface
    //interface s_axi_hp2;
    //endinterface
    //interface s_axi_hp3;
    //endinterface
    //interface m_axi_gp0;
    //endinterface
    //interface m_axi_gp1;
    //endinterface
    method pjtag_tck(PJTAG_TCK)  enable((*inhigh*) en08);
    //interface pjtag_td;
    //endinterface
    method pjtag_tms(PJTAG_TMS)  enable((*inhigh*) en07);
    method ps_clk(PS_CLK)  enable((*inhigh*) en06);
    method ps_porb(PS_PORB)  enable((*inhigh*) en05);
    method ps_srstb(PS_SRTSB)  enable((*inhigh*) en04);
    //interface sdio;
    //endinterface
    //interface spi;
    //endinterface
    method sram_intin(SRAM_INTIN)  enable((*inhigh*) en03);
    method trace_clk(TRACE_CLK)  enable((*inhigh*) en02);
    method   TRACE_CTL trace_ctl();
    method   TRACE_DATA trace_data();
    //interface ttc;
    //endinterface
    //interface uart;
    //endinterface
    //interface usb;
//    Vector#(2, Usb) usbif;
//    usbif[0] = interface Usb;
//        method PORT_INDCTL port_indctl();
//            return ?;
//        endmethod
//        //method vbus_pwrfault(VBUS_PWRFAULT) enable((*inhigh*) en00);
//        //endmethod
//        method VBUS_PWRSELECT vbus_pwrselect();
//            return ?;
//        endmethod
//        //method Bit#(2)            port_indctl();
//        method Action             vbus_pwrfault(Bit#(1) v);
//        endmethod
//        //method Bit#(1)            vbus_pwrselect();
//        //endmethod
//        endinterface;
//    usbif[1] = interface Usb;
//        method PORT_INDCTL1 port_indctl();
//            return ?;
//        endmethod
//        //method vbus_pwrfault(VBUS_PWRFAULT1) enable((*inhigh*) en00);
//        //endmethod
//        method VBUS_PWRSELECT1 vbus_pwrselect();
//            return ?;
//        endmethod
//        //method Bit#(2)            port_indctl();
//        method Action             vbus_pwrfault(Bit#(1) v);
//        endmethod
//        //method Bit#(1)            vbus_pwrselect();
//        //endmethod
//        endinterface;
//    //interface Vector#(2, Usb) usb = usbif;
    //interface Vector usb;
        //method VBUS_PWRSELECT1 vbus_pwrselect[0]();
    //endinterface
    method wdt_clk_in(WDT_CLK_IN)  enable((*inhigh*) en01);
    method WDT_RST_OUT wdt_rst_out();
    //schedule (datain, idatain, inc, ce) CF (datain, idatain, inc, ce);
endmodule
