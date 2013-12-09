
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
    method Action             put(AxiMISO#(data_width, id_width) v);
    method ActionValue#(AxiMOSI#(data_width, id_width)) get();
endinterface

interface AxiSlaveCommon#(numeric type data_width, numeric type id_width);
    method Action             aclk(Bit#(1) v); // common
    method Bit#(1)            aresetn();      // common
    method Action             put(AxiMOSI#(data_width, id_width) v);
    method ActionValue#(AxiMISO#(data_width, id_width)) get();
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
    interface Vector#(2, Can) can;
    interface Vector#(2, Core)core;
    interface Ddr#(10,1,1)    ddr;
    interface Vector#(4, Dma) dma;
    interface Vector#(2, Enet)enet;
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
    interface Vector#(2, I2c)i2c;
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
    interface AxiSlaveCommon#(data_width, id_width)    s_axi_gp0;
    interface AxiSlaveCommon#(data_width, id_width)    s_axi_gp1;
    interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp0;
    interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp1;
    interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp2;
    interface AxiSlaveHighSpeed#(data_width, id_width) s_axi_hp3;
    interface AxiMasterCommon#(data_width, id_width)   m_axi_gp0;
    interface AxiMasterCommon#(data_width, id_width)   m_axi_gp1;
    method Action             pjtag_tck(Bit#(1) v);
    interface Bidir#(1)       pjtag_td;
    method Action             pjtag_tms(Bit#(1) v);
    method Action             ps_clk(Bit#(1) v);
    method Action             ps_porb(Bit#(1) v);
    method Action             ps_srstb(Bit#(1) v);
    interface Vector#(2, Sdio)sdio;
    interface Vector#(2, Spi) spi;
    method Action             sram_intin(Bit#(1) v);
    method Action             trace_clk(Bit#(1) v);
    method Bit#(1)            trace_ctl();
    method Bit#(32)           trace_data();
    interface Vector#(2, Ttc) ttc;
    interface Vector#(2, Uart)uart;
    interface Vector#(2, Usb) usb;
    method Action             wdt_clk_in(Bit#(1) v);
    method Bit#(1)            wdt_rst_out();
    //schedule (datain, idatain, inc, ce) CF (datain, idatain, inc, ce);
endinterface

module mkPS7#(int data_width, int id_width, int gpio_width, int mio_width)(PS7#(data_width, id_width, gpio_width, mio_width));
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
endmodule
