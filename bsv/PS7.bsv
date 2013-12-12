
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
import Vector::*;
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

interface PS7#(numeric type c_dm_width, numeric type c_dq_width, numeric type c_dqs_width, numeric type data_width, numeric type gpio_width, numeric type id_width, numeric type mio_width);
    interface Vector#(2, Pps7Can#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     can;
    interface Vector#(2, Pps7Core#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     core;
    interface Pps7Ddr#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ddr;
    interface Vector#(4, Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     dma;
    interface Vector#(2, Pps7Enet#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     enet;
    interface Pps7Event#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     zevent;
    interface Pps7Fclk#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk;
    interface Vector#(4, Pps7Fclk_clktrig#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     fclk_clktrig;
    interface Vector#(4, Pps7Fclk_reset#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     fclk_reset;
    interface Pps7Fpga#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fpga;
    interface Pps7Gpio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     gpio;
    interface Pps7Ftmd#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ftmd;
    interface Pps7Ftmt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ftmt;
    interface Vector#(2, Pps7I2c#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     i2c;
    interface Pps7Irq#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     irq;
    interface Vector#(2, Pps7M_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     m_axi_gp;
    interface Pps7Pjtag#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     pjtag;
    interface Pps7Ps#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ps;
    interface Vector#(2, Pps7Sdio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     sdio;
    interface Vector#(2, Pps7Spi#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     spi;
    interface Pps7Sram#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     sram;
    interface Pps7S_axi_acp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_acp;
    interface Vector#(2, Pps7S_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     s_axi_gp;
    interface Vector#(4, Pps7S_axi_hp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     s_axi_hp;
    interface Pps7Trace#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     trace;
    interface Vector#(2, Pps7Ttc#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     ttc;
    interface Vector#(2, Pps7Uart#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     uart;
    interface Vector#(2, Pps7Usb#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     usb;
    interface Pps7Wdt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     wdt;
endinterface

module mkPS7#(int c_dm_width, int c_dq_width, int c_dqs_width, int data_width, int gpio_width, int id_width, int mio_width)
            (PS7#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width));
    PPS7#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)foo <-
        mkPPS7(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width);
    Vector#(2, Pps7Can#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vcan;
    Vector#(2, Pps7Core#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vcore;
    Vector#(4, Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vdma;
    Vector#(2, Pps7Enet#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     venet;
    Vector#(4, Pps7Fclk_clktrig#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vfclk_clktrig;
    Vector#(4, Pps7Fclk_reset#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vfclk_reset;
    Vector#(2, Pps7I2c#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vi2c;
    Vector#(2, Pps7M_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vm_axi_gp;
    Vector#(2, Pps7Sdio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vsdio;
    Vector#(2, Pps7Spi#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vspi;
    Vector#(2, Pps7S_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vs_axi_gp;
    Vector#(4, Pps7S_axi_hp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vs_axi_hp;
    Vector#(2, Pps7Ttc#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vttc;
    Vector#(2, Pps7Uart#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vuart;
    Vector#(2, Pps7Usb#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vusb;

    vcan[0] = foo.can0;
    vcan[1] = foo.can1;
    vcore[0] = foo.core0;
    vcore[1] = foo.core1;
    vdma[0] = foo.dma0;
    vdma[1] = foo.dma1;
    vdma[2] = foo.dma2;
    vdma[3] = foo.dma3;
    venet[0] = foo.enet0;
    venet[1] = foo.enet1;
    vfclk_clktrig[0] = foo.fclk_clktrig0;
    vfclk_clktrig[1] = foo.fclk_clktrig1;
    vfclk_clktrig[2] = foo.fclk_clktrig2;
    vfclk_clktrig[3] = foo.fclk_clktrig3;
    vfclk_reset[0] = foo.fclk_reset0;
    vfclk_reset[1] = foo.fclk_reset1;
    vfclk_reset[2] = foo.fclk_reset2;
    vfclk_reset[3] = foo.fclk_reset3;
    vi2c[0] = foo.i2c0;
    vi2c[1] = foo.i2c1;
    vm_axi_gp[0] = foo.m_axi_gp0;
    vm_axi_gp[1] = foo.m_axi_gp1;
    vsdio[0] = foo.sdio0;
    vsdio[1] = foo.sdio1;
    vspi[0] = foo.spi0;
    vspi[1] = foo.spi1;
    vs_axi_gp[0] = foo.s_axi_gp0;
    vs_axi_gp[1] = foo.s_axi_gp1;
    vs_axi_hp[0] = foo.s_axi_hp0;
    vs_axi_hp[1] = foo.s_axi_hp1;
    vs_axi_hp[2] = foo.s_axi_hp2;
    vs_axi_hp[3] = foo.s_axi_hp3;
    vttc[0] = foo.ttc0;
    vttc[1] = foo.ttc1;
    vuart[0] = foo.uart0;
    vuart[1] = foo.uart1;
    vusb[0] = foo.usb0;
    vusb[1] = foo.usb1;

    interface Pps7Can can = vcan;
    interface Pps7Core     core = vcore;
    interface Pps7Dma     dma = vdma;
    interface Pps7Enet     enet = venet;
    interface Pps7Fclk_clktrig    fclk_clktrig = vfclk_clktrig;
    interface Pps7Fclk_reset    fclk_reset = vfclk_reset;
    //interface Pps7Ftmd    ftmd = foo.ftmd;
    //interface Pps7Ftmt    ftmt = foo.ftmt;
    interface Pps7I2c    i2c = vi2c;
    interface Pps7M_axi_gp    m_axi_gp = vm_axi_gp;
    interface Pps7Sdio    sdio = vsdio;
    interface Pps7Spi    spi = vspi;
    interface Pps7S_axi_gp    s_axi_gp = vs_axi_gp;
    interface Pps7S_axi_hp    s_axi_hp = vs_axi_hp;
    interface Pps7Ttc    ttc = vttc;
    interface Pps7Uart    uart = vuart;
    interface Pps7Usb    usb = vusb;
endmodule
