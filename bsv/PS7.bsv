
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
    interface Pps7Core#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     core0;
    interface Pps7Core#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     core1;
    interface Pps7Ddr#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ddr;
    interface Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     dma0;
    interface Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     dma1;
    interface Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     dma2;
    interface Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     dma3;
    interface Pps7Enet#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     enet0;
    interface Pps7Enet#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     enet1;
    interface Pps7Event#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     zevent;
    interface Pps7Fclk#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk;
    interface Pps7Fclk_clktrig#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_clktrig0;
    interface Pps7Fclk_clktrig#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_clktrig1;
    interface Pps7Fclk_clktrig#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_clktrig2;
    interface Pps7Fclk_clktrig#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_clktrig3;
    interface Pps7Fclk_reset#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_reset0;
    interface Pps7Fclk_reset#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_reset1;
    interface Pps7Fclk_reset#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_reset2;
    interface Pps7Fclk_reset#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fclk_reset3;
    interface Pps7Fpga#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     fpga;
    interface Pps7Ftmd#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ftmd;
    interface Pps7Ftmt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ftmt;
    interface Pps7Gpio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     gpio;
    interface Pps7I2c#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     i2c0;
    interface Pps7I2c#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     i2c1;
    interface Pps7Irq#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     irq;
    interface Pps7M_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     m_axi_gp0;
    interface Pps7M_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     m_axi_gp1;
    interface Pps7Pjtag#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     pjtag;
    interface Pps7Ps#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ps;
    interface Pps7Sdio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     sdio0;
    interface Pps7Sdio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     sdio1;
    interface Pps7Spi#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     spi0;
    interface Pps7Spi#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     spi1;
    interface Pps7Sram#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     sram;
    interface Pps7S_axi_acp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_acp;
    interface Pps7S_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_gp0;
    interface Pps7S_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_gp1;
    interface Pps7S_axi_hp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_hp0;
    interface Pps7S_axi_hp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_hp1;
    interface Pps7S_axi_hp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_hp2;
    interface Pps7S_axi_hp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     s_axi_hp3;
    interface Pps7Trace#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     trace;
    interface Pps7Ttc#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ttc0;
    interface Pps7Ttc#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     ttc1;
    interface Pps7Uart#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     uart0;
    interface Pps7Uart#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     uart1;
    interface Pps7Usb#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     usb0;
    interface Pps7Usb#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     usb1;
    interface Pps7Wdt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)     wdt;
endinterface

module mkPS7#(int c_dm_width, int c_dq_width, int c_dqs_width, int data_width, int gpio_width, int id_width, int mio_width)
            (PS7#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width));
    PPS7#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)foo <-
    mkPPS7(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width);
    Vector#(2, Pps7Can#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vcan;

    vcan[0] = foo.can0;
    vcan[1] = foo.can1;
    interface Pps7Can can = vcan;
endmodule
