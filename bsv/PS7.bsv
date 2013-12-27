
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
    method Action             aclk(Bit#(1) v);
    method Bit#(1)            aresetn();
    interface Get#(AxiREQ#(id_width)) req_ar;
    interface Get#(AxiREQ#(id_width)) req_aw;
    interface Put#(AxiRead#(data_width, id_width)) resp_read;
    interface Get#(AxiWrite#(data_width, id_width)) resp_write;
    interface Put#(AxiRESP#(id_width)) resp_b;
endinterface

interface AxiSlaveCommon#(numeric type data_width, numeric type id_width);
    method Action             aclk(Bit#(1) v);
    method Bit#(1)            aresetn();
    interface Put#(AxiREQ#(id_width)) req_ar;
    interface Put#(AxiREQ#(id_width)) req_aw;
    interface Put#(AxiWrite#(data_width, id_width)) resp_write;
    interface Get#(AxiRead#(data_width, id_width)) resp_read;
    interface Get#(AxiRESP#(id_width)) resp_b;
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

interface AxiMasterWires;
   interface Wire#(Bit#(1)) arready;
   interface Wire#(Bit#(1)) awready;
   interface Wire#(Bit#(1)) rvalid;
   interface Wire#(Bit#(1)) wready;
   interface Wire#(Bit#(1)) bvalid;
endinterface

interface AxiSlaveWires;
   interface Wire#(Bit#(1)) arvalid;
   interface Wire#(Bit#(1)) awvalid;
   interface Wire#(Bit#(1)) rready;
   interface Wire#(Bit#(1)) wvalid;
   interface Wire#(Bit#(1)) bready;
endinterface

module mkAxiMasterWires(AxiMasterWires);
   Vector#(5, Wire#(Bit#(1))) wires <- replicateM(mkDWire(0));
   interface Wire arready = wires[0];
   interface Wire awready = wires[1];
   interface Wire rvalid = wires[2];
   interface Wire wready = wires[3];
   interface Wire bvalid = wires[4];
endmodule

module mkAxiSlaveWires(AxiSlaveWires);
   Vector#(5, Wire#(Bit#(1))) wires <- replicateM(mkDWire(0));
   interface Wire arvalid = wires[0];
   interface Wire awvalid = wires[1];
   interface Wire rready = wires[2];
   interface Wire wvalid = wires[3];
   interface Wire bready = wires[4];
endmodule

(* always_ready, always_enabled *)
interface Bidir#(numeric type data_width);
    method Action             i(Bit#(data_width) v);
    method Bit#(data_width)   o();
    method Bit#(data_width)   t();
endinterface

interface PS7#(numeric type c_dm_width, numeric type c_dq_width, numeric type c_dqs_width, numeric type data_width, numeric type gpio_width, numeric type id_width, numeric type mio_width);
    interface Vector#(2, Pps7Can#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  can;
    interface Vector#(2, Pps7Core#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) core;
    interface Pps7Ddr#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)              ddr;
    interface Vector#(4, Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  dma;
    interface Vector#(2, Pps7Enet#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) enet;
    interface Pps7Event#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)            event_;
    interface Pps7Fclk#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             fclk;
    interface Vector#(4,Pps7Fclk_clktrig#(c_dm_width,c_dq_width,c_dqs_width,data_width,gpio_width,id_width,mio_width))fclk_clktrig;
    interface Vector#(4,Pps7Fclk_reset#(c_dm_width,c_dq_width,c_dqs_width,data_width,gpio_width,id_width,mio_width))  fclk_reset;
    interface Pps7Fpga#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             fpga;
    interface Pps7Gpio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             gpio;
    interface Pps7Ftmd#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             ftmd;
    interface Pps7Ftmt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             ftmt;
    interface Vector#(2, Pps7I2c#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  i2c;
    interface Pps7Irq#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)              irq;
    interface Inout#(Bit#(mio_width))     mio;
    interface Pps7Pjtag#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)            pjtag;
    interface Pps7Ps#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)               ps;
    interface Vector#(2, Pps7Sdio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) sdio;
    interface Vector#(2, Pps7Spi#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  spi;
    interface Pps7Sram#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             sram;
    interface Pps7Trace#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)            trace;
    interface Vector#(2, Pps7Ttc#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  ttc;
    interface Vector#(2, Pps7Uart#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) uart;
    interface Vector#(2, Pps7Usb#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  usb;
    interface Pps7Wdt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)              wdt;

    interface Vector#(2, AxiMasterCommon#(32, id_width)) m_axi_gp;
    interface AxiSlaveCommon#(32, id_width) s_axi_acp;
    interface Vector#(2, AxiSlaveCommon#(32, id_width)) s_axi_gp;
    interface Vector#(4, AxiSlaveHighSpeed#(data_width, id_width)) s_axi_hp;
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
    Vector#(2, AxiMasterCommon#(32, id_width)) vtopm_axi_gp;
    Vector#(2, AxiMasterWires) vtopmw_axi_gp <- replicateM(mkAxiMasterWires());
    Vector#(2, AxiSlaveCommon#(32, id_width)) vtops_axi_gp;
    Vector#(2, AxiSlaveWires) vtopsw_axi_gp <- replicateM(mkAxiSlaveWires());
    Vector#(4, AxiSlaveHighSpeed#(data_width, id_width)) vtops_axi_hp;
    Vector#(2, AxiSlaveWires) vtopsw_axi_hp <- replicateM(mkAxiSlaveWires());

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
    for (Integer i = 0; i < 2; i = i + 1)
       begin
       rule axi_master_handshake1;
	    vm_axi_gp[i].arready(vtopmw_axi_gp[i].arready);
       endrule
       rule axi_master_handshake2;
	    vm_axi_gp[i].awready(vtopmw_axi_gp[i].awready);
       endrule
       rule axi_master_handshake3;
            vm_axi_gp[i].rvalid(vtopmw_axi_gp[i].rvalid);
       endrule
       rule axi_master_handshake4;
	    vm_axi_gp[i].wready(vtopmw_axi_gp[i].wready);
       endrule
       rule axi_master_handshake5;
            vm_axi_gp[i].bvalid(vtopmw_axi_gp[i].bvalid);
       endrule
       end
    for (Integer i = 0; i < 2; i = i + 1)
        vtopm_axi_gp[i] = interface AxiMasterCommon#(32, id_width);
            interface Get req_ar;
                 method ActionValue#(AxiREQ#(id_width)) get() if (vm_axi_gp[i].arvalid() != 0);
                     actionvalue
                     AxiREQ#(id_width) v;
                     v.addr = vm_axi_gp[i].araddr();
                     v.burst = vm_axi_gp[i].arburst();
                     v.cache = vm_axi_gp[i].arcache();
                     v.id = vm_axi_gp[i].arid();
                     v.len = vm_axi_gp[i].arlen();
                     v.lock = vm_axi_gp[i].arlock();
                     v.prot = vm_axi_gp[i].arprot();
                     v.qos = vm_axi_gp[i].arqos();
                     v.size = vm_axi_gp[i].arsize();

		     vm_axi_gp[i].arready(1);
                     return v;
                     endactionvalue
                 endmethod
            endinterface
            interface Get req_aw;
                 method ActionValue#(AxiREQ#(id_width)) get() if (vm_axi_gp[i].awvalid() != 0);
                     actionvalue
                     AxiREQ#(id_width) v;
                     v.addr = vm_axi_gp[i].awaddr();
                     v.burst = vm_axi_gp[i].awburst();
                     v.cache = vm_axi_gp[i].awcache();
                     v.id = vm_axi_gp[i].awid();
                     v.len = vm_axi_gp[i].awlen();
                     v.lock = vm_axi_gp[i].awlock();
                     v.prot = vm_axi_gp[i].awprot();
                     v.qos = vm_axi_gp[i].awqos();
                     v.size = vm_axi_gp[i].awsize();

	             vm_axi_gp[i].awready(1);
                     return v;
                     endactionvalue
                endmethod
            endinterface
            interface Put resp_read;
                method Action put(AxiRead#(32, id_width) v) if (vm_axi_gp[i].rready() != 0);
                    vm_axi_gp[i].rid(v.r.id);
                    vm_axi_gp[i].rresp(v.r.resp);
                    vm_axi_gp[i].rdata(v.rd.data);
                    vm_axi_gp[i].rlast(v.rd.last);

	            vm_axi_gp[i].rvalid(1);
                endmethod
            endinterface
            interface Get resp_write;
                 method ActionValue#(AxiWrite#(32, id_width)) get() if (vm_axi_gp[i].wvalid() != 0);
                     actionvalue
                     AxiWrite#(32, id_width) v;
                     v.wid = vm_axi_gp[i].wid();
                     v.wstrb = vm_axi_gp[i].wstrb();
                     v.wd.data = vm_axi_gp[i].wdata();
                     v.wd.last = vm_axi_gp[i].wlast();

	             vm_axi_gp[i].wready(1);
                     return v;
                     endactionvalue
                endmethod
            endinterface
            interface Put resp_b;
                method Action put(AxiRESP#(id_width) v) if (vm_axi_gp[i].bready() != 0);
                    vm_axi_gp[i].bid(v.id);
                    vm_axi_gp[i].bresp(v.resp);
	       
	            vm_axi_gp[i].bvalid(1);
                endmethod
            endinterface
            method aclk = vm_axi_gp[i].aclk;
            method aresetn = vm_axi_gp[i].aresetn;
            endinterface;
    for (Integer i = 0; i < 2; i = i + 1)
       begin
       rule axi_master_handshake1;
	    vs_axi_gp[i].arvalid(vtopsw_axi_gp[i].arvalid);
       endrule
       rule axi_master_handshake2;
	    vs_axi_gp[i].awvalid(vtopsw_axi_gp[i].awvalid);
       endrule
       rule axi_master_handshake3;
            vs_axi_gp[i].rready(vtopsw_axi_gp[i].rready);
       endrule
       rule axi_master_handshake4;
	    vs_axi_gp[i].wvalid(vtopsw_axi_gp[i].wvalid);
       endrule
       rule axi_master_handshake5;
            vs_axi_gp[i].bready(vtopsw_axi_gp[i].bready);
       endrule
       end
    for (Integer i = 0; i < 2; i = i + 1)
        vtops_axi_gp[i] = interface AxiSlaveCommon#(32, id_width);
            interface Put req_ar;
                method Action put(AxiREQ#(id_width) v) if (vs_axi_gp[i].arready() != 0);
                    vs_axi_gp[i].araddr(v.addr);
                    vs_axi_gp[i].arburst(v.burst);
                    vs_axi_gp[i].arcache(v.cache);
                    vs_axi_gp[i].arid(v.id);
                    vs_axi_gp[i].arlen(v.len);
                    vs_axi_gp[i].arlock(v.lock);
                    vs_axi_gp[i].arprot(v.prot);
                    vs_axi_gp[i].arqos(v.qos);
                    vs_axi_gp[i].arsize(v.size);

	            vs_axi_gp[i].arvalid(1);
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(AxiREQ#(id_width) v) if (vs_axi_gp[i].awready() != 0);
                    vs_axi_gp[i].awaddr(v.addr);
                    vs_axi_gp[i].awburst(v.burst);
                    vs_axi_gp[i].awcache(v.cache);
                    vs_axi_gp[i].awid(v.id);
                    vs_axi_gp[i].awlen(v.len);
                    vs_axi_gp[i].awlock(v.lock);
                    vs_axi_gp[i].awprot(v.prot);
                    vs_axi_gp[i].awqos(v.qos);
                    vs_axi_gp[i].awsize(v.size);

	            vs_axi_gp[i].awvalid(1);
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(AxiWrite#(32, id_width) v) if (vs_axi_gp[i].wready() != 0);
                    vs_axi_gp[i].wid(v.wid);
                    vs_axi_gp[i].wstrb(v.wstrb);
                    vs_axi_gp[i].wdata(v.wd.data);
                    vs_axi_gp[i].wlast(v.wd.last);

	            vs_axi_gp[i].wvalid(1);
                endmethod
            endinterface
            interface Get resp_read;
                method ActionValue#(AxiRead#(32, id_width)) get() if (vs_axi_gp[i].rvalid() != 0);
                    AxiRead#(32, id_width) v;
                    v.r.id = vs_axi_gp[i].rid();
                    v.r.resp = vs_axi_gp[i].rresp();
                    v.rd.data = vs_axi_gp[i].rdata();
                    v.rd.last = vs_axi_gp[i].rlast();

	            vs_axi_gp[i].rready(1);
                    return v;
                endmethod
            endinterface
            interface Get resp_b;
                method ActionValue#(AxiRESP#(id_width)) get() if (vs_axi_gp[i].bvalid() != 0);
                    AxiRESP#(id_width) v;
                    v.id = vs_axi_gp[i].bid();
                    v.resp = vs_axi_gp[i].bresp();

	            vs_axi_gp[i].bready(1);
                    return v;
                endmethod
            endinterface
            method aclk = vs_axi_gp[i].aclk;
            method aresetn = vs_axi_gp[i].aresetn;
        endinterface;
    for (Integer i = 0; i < 2; i = i + 1)
       begin
       rule axi_master_handshake1;
	    vs_axi_hp[i].arvalid(vtopsw_axi_hp[i].arvalid);
       endrule
       rule axi_master_handshake2;
	    vs_axi_hp[i].awvalid(vtopsw_axi_hp[i].awvalid);
       endrule
       rule axi_master_handshake3;
            vs_axi_hp[i].rready(vtopsw_axi_hp[i].rready);
       endrule
       rule axi_master_handshake4;
	    vs_axi_hp[i].wvalid(vtopsw_axi_hp[i].wvalid);
       endrule
       rule axi_master_handshake5;
            vs_axi_hp[i].bready(vtopsw_axi_hp[i].bready);
       endrule
       end
    for (Integer i = 0; i < 4; i = i + 1)
        vtops_axi_hp[i] = interface AxiSlaveHighSpeed#(data_width, id_width);
            interface AxiSlaveCommon axi;
            interface Put req_ar;
                method Action put(AxiREQ#(id_width) v) if (vs_axi_hp[i].arready() != 0);
                    vs_axi_hp[i].araddr(v.addr);
                    vs_axi_hp[i].arburst(v.burst);
                    vs_axi_hp[i].arcache(v.cache);
                    vs_axi_hp[i].arid(v.id);
                    vs_axi_hp[i].arlen(v.len);
                    vs_axi_hp[i].arlock(v.lock);
                    vs_axi_hp[i].arprot(v.prot);
                    vs_axi_hp[i].arqos(v.qos);
                    vs_axi_hp[i].arsize(v.size);

		    vs_axi_hp[i].arvalid(1);
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(AxiREQ#(id_width) v) if (vs_axi_hp[i].awready() != 0);
                    vs_axi_hp[i].awaddr(v.addr);
                    vs_axi_hp[i].awburst(v.burst);
                    vs_axi_hp[i].awcache(v.cache);
                    vs_axi_hp[i].awid(v.id);
                    vs_axi_hp[i].awlen(v.len);
                    vs_axi_hp[i].awlock(v.lock);
                    vs_axi_hp[i].awprot(v.prot);
                    vs_axi_hp[i].awqos(v.qos);
                    vs_axi_hp[i].awsize(v.size);

	            vs_axi_hp[i].awvalid(1);
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(AxiWrite#(data_width, id_width) v) if (vs_axi_hp[i].wready() != 0);
                    vs_axi_hp[i].wid(v.wid);
                    vs_axi_hp[i].wstrb(v.wstrb);
                    vs_axi_hp[i].wdata(v.wd.data);
                    vs_axi_hp[i].wlast(v.wd.last);

	            vs_axi_hp[i].wvalid(1);
                endmethod
            endinterface
            interface Get resp_read;
                method ActionValue#(AxiRead#(data_width, id_width)) get() if (vs_axi_hp[i].rvalid() != 0);
                    AxiRead#(data_width, id_width) v;
                    v.r.id = vs_axi_hp[i].rid();
                    v.r.resp = vs_axi_hp[i].rresp();
                    v.rd.data = vs_axi_hp[i].rdata();
                    v.rd.last = vs_axi_hp[i].rlast();

	            vs_axi_hp[i].rready(1);
                    return v;
                endmethod
            endinterface
            interface Get resp_b;
                method ActionValue#(AxiRESP#(id_width)) get() if (vs_axi_hp[i].bvalid() != 0);
                    AxiRESP#(id_width) v;
                    v.id = vs_axi_hp[i].bid();
                    v.resp = vs_axi_hp[i].bresp();

		    vs_axi_hp[i].bready(1);
                    return v;
                endmethod
            endinterface
            method aclk = vs_axi_hp[i].aclk;
            method aresetn = vs_axi_hp[i].aresetn;
            endinterface
            method racount = vs_axi_hp[i].racount;
            method rcount = vs_axi_hp[i].rcount;
            method rdissuecap1_en = vs_axi_hp[i].rdissuecap1_en;
            method wacount = vs_axi_hp[i].wacount;
            method wcount = vs_axi_hp[i].wcount;
            method wrissuecap1_en = vs_axi_hp[i].wrissuecap1_en;
        endinterface;

    interface Pps7Can can = vcan;
    interface Pps7Core     core = vcore;
    interface Pps7Dma     dma = vdma;
    interface Pps7Enet     enet = venet;
    interface Pps7Fclk_clktrig    fclk_clktrig = vfclk_clktrig;
    interface Pps7Fclk_reset    fclk_reset = vfclk_reset;
    interface Pps7I2c    i2c = vi2c;
    interface Pps7Sdio    sdio = vsdio;
    interface Pps7Spi    spi = vspi;
    interface Pps7Ttc    ttc = vttc;
    interface Pps7Uart    uart = vuart;
    interface Pps7Usb    usb = vusb;

    interface Pps7Ddr     ddr = foo.ddr;
    interface Pps7Event     event_ = foo.event_;
    interface Pps7Fclk     fclk = foo.fclk;
    interface Pps7Fpga     fpga = foo.fpga;
    interface Pps7Gpio     gpio = foo.gpio;
    interface Pps7Ftmd     ftmd = foo.ftmd;
    interface Pps7Ftmt     ftmt = foo.ftmt;
    interface Pps7Irq     irq = foo.irq;
    interface Inout     mio = foo.mio;
    interface Pps7Pjtag     pjtag = foo.pjtag;
    interface Pps7Ps     ps = foo.ps;
    interface Pps7Sram     sram = foo.sram;
    interface Pps7Trace     trace = foo.trace;
    interface Pps7Wdt     wdt = foo.wdt;
    interface AxiMasterCommon m_axi_gp = vtopm_axi_gp;
    interface AxiSlaveCommon s_axi_gp = vtops_axi_gp;
    interface AxiSlaveHighSpeed s_axi_hp = vtops_axi_hp;
    //interface AxiSlaveCommon s_axi_acp;
endmodule
