
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

import Clocks       :: *;
import DefaultValue :: *;
import XilinxCells  :: *;
import Vector       :: *;

(* always_ready, always_enabled *)
interface Bidir#(DATA_WIDTH);
    method Action            i(Bit#(DATA_WIDTH) v);
    method Bit#(DATA_WIDTH)  o();
    method Bit#(DATA_WIDTH)  t();
endinterface
typedef struct {
    Bit#(32)                 addr;
    Bit#(2)                  burst;
    Bit#(4)                  cache;
    Bit#(ID_WIDTH)           id;
    Bit#(4)                  len;
    Bit#(2)                  lock;
    Bit#(3)                  prot;
    Bit#(4)                  qos;
    Bit#(3)                  size;
    Bit#(1)                  valid;
} AxiREQ#(numeric type ID_WIDTH);
typedef struct {
    AxiREQ                   ar;
    AxiREQ                   aw;
    Bit#(1)                  bready;
    Bit#(1)                  rready;
    Bit#(DATA_WIDTH)         wdata;
    Bit#(ID_WIDTH)           wid;
    Bit#(1)                  wlast;
    Bit#(DATA_WIDTH/8)       wstrb;
    Bit#(1)                  wvalid;
} AxiMOSI#(numeric type DATA_WIDTH, numeric type ID_WIDTH);
typedef struct {
    Bit#(ID_WIDTH)           id;
    Bit#(2)                  resp;
    Bit#(1)                  valid;
} AxiVALID#(numeric type ID_WIDTH);
typedef struct {
    Bit#(1)                  arready;
    Bit#(1)                  awready;
    AxiVALID#(DATA_WIDTH, ID_WIDTH) b;
    AxiVALID#(DATA_WIDTH, ID_WIDTH) r;
    Bit#(DATA_WIDTH)         rdata;
    Bit#(1)                  rlast;
    Bit#(1)                  wready;
} AxiMISO(numeric type DATA_WIDTH, numeric type ID_WIDTH);

interface AxiMasterCommon#(numeric type DATA_WIDTH, numeric type ID_WIDTH);
    method Action            aclk(Bit#(1) v); // common
    method Bit#(1)           aresetn();      // common
    AxiMOSI#(DATA_WIDTH, ID_WIDTH);
    AxiMISO#(DATA_WIDTH, ID_WIDTH);
    method Action            araddr(Bit#(32) v);
    method Bit#(1)           arready();
endinterface

interface AxiSlaveCommon#(numeric type DATA_WIDTH, numeric type ID_WIDTH);
    method Action            aclk(Bit#(1) v); // common
    method Bit#(1)           aresetn();      // common
    AxiMOSI#(DATA_WIDTH, ID_WIDTH);
    AxiMISO#(DATA_WIDTH, ID_WIDTH);
    method Action            araddr(Bit#(32) v);
    method Bit#(1)           arready();
endinterface

interface AxiSlaveHighSpeed#(numeric type DATA_WIDTH, numeric type ID_WIDTH);
    interface AxiCommon#(DATA_WIDTH, ID_WIDTH) axi;
    method Bit#(3)           racount();
    method Bit#(8)           rcount();
    method Action            rdissuecap1_en(Bit#(1) v);
    method Bit#(6)           wacount();
    method Bit#(8)           wcount();
    method Action            wrissuecap1_en(Bit#(1) v);
endinterface
interface Ddr;
    method Action            arb(Bit#(4) v);
    method Bit#(15)          addr();
    method Bit#(3)           bankaddr();
    method Bit#(1)           cas_n();
    method Bit#(1)           cke();
    method Bit#(1)           cs_n();
    method Bit#(1)           clk();
    method Bit#(1)           clk_n();
    method Bit#(DM_WIDTH)    dm();
    method Bit#(DQ_WIDTH)    dq();
    method Bit#(DQS_WIDTH) dqs();
    method Bit#(DQS_WIDTH) dqs_n();
    method Bit#(1)           drstb();
    method Bit#(1)           odt();
    method Bit#(1)           ras_n();
    method Bit#(1)           vrn();
    method Bit#(1)           vrp();
    method Bit#(1)           web();
endinterface
interface Dma;
    method Action            aclk(Bit#(1) v);
    method Action            daready(Bit#(1) v);
    method Bit#(2)           datype();
    method Bit#(1)           davalid();
    method Action            drlast(Bit#(1) v);
    method Bit#(1)           drready();
    method Action            drtype(Bit#(2) v);
    method Action            drvalid(Bit#(1) v);
    method Bit#(1)           rstn();
endinterface
interface Enet;
    method Action            ext_intin(Bit#(1) v);
    method Action            gmii_col(Bit#(1) v);
    method Action            gmii_crs(Bit#(1) v);
    method Action            gmii_rxd(Bit#(8) v);
    method Action            gmii_rx_clk(Bit#(1) v);
    method Action            gmii_rx_dv(Bit#(1) v);
    method Action            gmii_rx_er(Bit#(1) v);
    method Bit#(8)           gmii_txd();
    method Action            gmii_tx_clk(Bit#(1) v);
    method Bit#(1)           gmii_tx_en();
    method Bit#(1)           gmii_tx_er();
    method Bit#(1)           mdio_mdc();
    interface Bidir(1)       mdio;
    method Bit#(1)           ptp_delay_req_rx();
    method Bit#(1)           ptp_delay_req_tx();
    method Bit#(1)           ptp_pdelay_req_rx();
    method Bit#(1)           ptp_pdelay_req_tx();
    method Bit#(1)           ptp_pdelay_resp_rx();
    method Bit#(1)           ptp_pdelay_resp_tx();
    method Bit#(1)           ptp_sync_frame_rx();
    method Bit#(1)           ptp_sync_frame_tx();
    method Bit#(1)           sof_rx();
    method Bit#(1)           sof_tx();
endinterface
interface Sdio;
    method Bit#(1)           buspow();
    method Bit#(3)           busvolt();
    method Action            cdn(Bit#(1) v);
    method Bit#(1)           clk();
    method Action            clk_fb(Bit#(1) v);
    interface Bidir(1)       cmd;
    interface Bidir(4)       data;
    method Bit#(1)           led();
    method Action            wp(Bit#(1) v);
endinterface
interface Spi;
    interface Bidir(1)       miso;
    interface Bidir(1)       mosi;
    interface Bidir(1)       sclk;
    method Bit#(1)           ss1_o();
    method Bit#(1)           ss2_o();
    interface Bidir(1)       ss;
endinterface
interface Ttc;
    method Action            clk0_in(Bit#(1) v);
    method Action            clk1_in(Bit#(1) v);
    method Action            clk2_in(Bit#(1) v);
    method Bit#(1)           wave0_out();
    method Bit#(1)           wave1_out();
    method Bit#(1)           wave2_out();
endinterface
interface Uart;
    method Action            ctsn(Bit#(1) v);
    method Action            dcdn(Bit#(1) v);
    method Action            dsrn(Bit#(1) v);
    method Bit#(1)           dtrn();
    method Action            rin(Bit#(1) v);
    method Bit#(1)           rtsn();
    method Action            rx(Bit#(1) v);
    method Bit#(1)           tx();
endinterface
interface Usb;
    method Bit#(2)           port_indctl();
    method Action            vbus_pwrfault(Bit#(1) v);
    method Bit#(1)           vbus_pwrselect();
endinterface
interface I2c;
    interface Bidir(1)       scl;
    interface Bidir(1)       sda;
endinterface
interface Can;
    method Action            phy_rx(Bit#(1) v);
    method Bit#(1)           phy_tx();
endinterface
interface Core;
    method Action            n_fiq(Bit#(1) v);
    method Action            n_irq(Bit#(1) v);
endinterface

interface Ps7#(numeric type EMIO_GPIO_WIDTH);
    interface Can            can0;
    interface Can            can1;
    interface Core           core0;
    interface Core           core1;
    interface Ddr            ddr;
    interface Dma            dma0;
    interface Dma            dma1;
    interface Dma            dma2;
    interface Dma            dma3;
    interface Enet           enet0;
    interface Enet           enet1;
    method Action            event_eventi(Bit#(1) v);
    method Bit#(1)           event_evento();
    method Bit#(2)           event_standbywfe();
    method Bit#(2)           event_standbywfi();
    method Bit#(1)           fclk_clk0();
    method Bit#(1)           fclk_clk1();
    method Bit#(1)           fclk_clk2();
    method Bit#(1)           fclk_clk3();
    method Action            fclk_clktrig0_n(Bit#(1) v);
    method Action            fclk_clktrig1_n(Bit#(1) v);
    method Action            fclk_clktrig2_n(Bit#(1) v);
    method Action            fclk_clktrig3_n(Bit#(1) v);
    method Bit#(1)           fclk_reset0_n();
    method Bit#(1)           fclk_reset1_n();
    method Bit#(1)           fclk_reset2_n();
    method Bit#(1)           fclk_reset3_n();
    method Action            fpga_idle_n(Bit#(1) v);
    method Action            ftmd_tracein_atid(Bit#(4) v);
    method Action            ftmd_tracein_clk(Bit#(1) v);
    method Action            ftmd_tracein_data(Bit#(32) v);
    method Action            ftmd_tracein_valid(Bit#(1) v);
    method Action            ftmt_f2p_debug(Bit#(32) v);
    method Action            ftmt_f2p_trig(Bit#(4) v);
    method Bit#(4)           ftmt_f2p_trigack();
    method Bit#(32)          ftmt_p2f_debug();
    method Bit#(4)           ftmt_p2f_trig();
    method Action            ftmt_p2f_trigack(Bit#(4) v);
    interface Bidir(EMIO_GPIO_WIDTH) gpio;
    interface I2c            i2c0;
    interface I2c            i2c1;
    method Action            irq_f2p(Bit#(16) v);
    method Bit#(1)           irq_p2f_can0();
    method Bit#(1)           irq_p2f_can1();
    method Bit#(1)           irq_p2f_cti();
    method Bit#(1)           irq_p2f_dmac0();
    method Bit#(1)           irq_p2f_dmac1();
    method Bit#(1)           irq_p2f_dmac2();
    method Bit#(1)           irq_p2f_dmac3();
    method Bit#(1)           irq_p2f_dmac4();
    method Bit#(1)           irq_p2f_dmac5();
    method Bit#(1)           irq_p2f_dmac6();
    method Bit#(1)           irq_p2f_dmac7();
    method Bit#(1)           irq_p2f_dmac_abort();
    method Bit#(1)           irq_p2f_enet0();
    method Bit#(1)           irq_p2f_enet1();
    method Bit#(1)           irq_p2f_enet_wake0();
    method Bit#(1)           irq_p2f_enet_wake1();
    method Bit#(1)           irq_p2f_gpio();
    method Bit#(1)           irq_p2f_i2c0();
    method Bit#(1)           irq_p2f_i2c1();
    method Bit#(1)           irq_p2f_qspi();
    method Bit#(1)           irq_p2f_sdio0();
    method Bit#(1)           irq_p2f_sdio1();
    method Bit#(1)           irq_p2f_smc();
    method Bit#(1)           irq_p2f_spi0();
    method Bit#(1)           irq_p2f_spi1();
    method Bit#(1)           irq_p2f_uart0();
    method Bit#(1)           irq_p2f_uart1();
    method Bit#(1)           irq_p2f_usb0();
    method Bit#(1)           irq_p2f_usb1();
    method Bit#(MIO_PRIMITIVE)       mio();
    interface AxiSlaveCommon#(DATA_WIDTH, ID_WIDTH)    s_axi_acp;
    method Action            s_axi_acp_aruser(Bit#(5) v);
    method Action            s_axi_acp_awuser(Bit#(5) v);
    interface AxiSlaveCommon#(DATA_WIDTH, ID_WIDTH)    s_axi_gp0;
    interface AxiSlaveCommon#(DATA_WIDTH, ID_WIDTH)    s_axi_gp1;
    interface AxiSlaveHighSpeed#(DATA_WIDTH, ID_WIDTH) s_axi_hp0;
    interface AxiSlaveHighSpeed#(DATA_WIDTH, ID_WIDTH) s_axi_hp1;
    interface AxiSlaveHighSpeed#(DATA_WIDTH, ID_WIDTH) s_axi_hp2;
    interface AxiSlaveHighSpeed#(DATA_WIDTH, ID_WIDTH) s_axi_hp3;
    interface AxiMasterCommon#(DATA_WIDTH, ID_WIDTH)   m_axi_gp0;
    interface AxiMasterCommon#(DATA_WIDTH, ID_WIDTH)   m_axi_gp1;
    method Action            pjtag_tck(Bit#(1) v);
    interface Bidir(1)       pjtag_td;
    method Action            pjtag_tms(Bit#(1) v);
    method Action            ps_clk(Bit#(1) v);
    method Action            ps_porb(Bit#(1) v);
    method Action            ps_srstb(Bit#(1) v);
    interface Sdio           sdio0;
    interface Sdio           sdio1;
    interface Spi            spi0;
    interface Spi            spi1;
    method Action            sram_intin(Bit#(1) v);
    method Action            trace_clk(Bit#(1) v);
    method Bit#(1)           trace_ctl();
    method Bit#(32)          trace_data();
    interface Ttc            ttc0;
    interface Ttc            ttc1;
    interface Uart           uart0;
    interface Uart           uart1;
    interface Usb            usb0;
    interface Usb            usb1;
    method Action            wdt_clk_in(Bit#(1) v);
    method Bit#(1)           wdt_rst_out();

   schedule (datain, idatain, inc, ce) CF (datain, idatain, inc, ce);
endmodule
