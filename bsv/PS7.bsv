
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
import AxiMasterSlave::*;
import CtrlMux::*;
import Portal::*;
import AxiClientServer::*;

interface AxiMasterCommon#(numeric type data_width, numeric type id_width);
    method Bit#(1)            aresetn();
    interface Get#(Axi3ReadRequest#(32,id_width)) req_ar;
    interface Get#(Axi3WriteRequest#(32,id_width)) req_aw;
    interface Put#(Axi3ReadResponse#(data_width, id_width)) resp_read;
    interface Get#(Axi3WriteData#(data_width, TDiv#(data_width, 8), id_width)) resp_write;
    interface Put#(Axi3WriteResponse#(id_width)) resp_b;
endinterface

interface AxiSlaveCommon#(numeric type data_width, numeric type id_width);
    method Bit#(1)            aresetn();
    interface Put#(Axi3ReadRequest#(32,id_width)) req_ar;
    interface Put#(Axi3WriteRequest#(32,id_width)) req_aw;
    interface Put#(Axi3WriteData#(data_width, TDiv#(data_width, 8), id_width)) resp_write;
    interface Get#(Axi3ReadResponse#(data_width, id_width)) resp_read;
    interface Get#(Axi3WriteResponse#(id_width)) resp_b;
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
`ifdef PS7EXTENDED
    interface Vector#(2, Pps7Can#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  can;
    interface Vector#(2, Pps7Core#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) core;
    interface Vector#(4, Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  dma;
    interface Vector#(2, Pps7Enet#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) enet;
    interface Pps7Event#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)            event_;
    interface Vector#(4,Pps7Fclk_clktrig#(c_dm_width,c_dq_width,c_dqs_width,data_width,gpio_width,id_width,mio_width))fclk_clktrig;
    interface Pps7Fpga#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             fpga;
    interface Pps7Ftmd#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             ftmd;
    interface Pps7Ftmt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             ftmt;
    interface Pps7Pjtag#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)            pjtag;
    interface Vector#(2, Pps7Sdio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) sdio;
    interface Vector#(2, Pps7Spi#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  spi;
    interface Pps7Sram#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             sram;
    interface Pps7Trace#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)            trace;
    interface Vector#(2, Pps7Ttc#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  ttc;
    interface Vector#(2, Pps7Uart#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)) uart;
    interface Vector#(2, Pps7Usb#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  usb;
    interface Pps7Wdt#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)              wdt;
`endif
    interface Pps7Ddr#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)              ddr;
    interface Vector#(4,Pps7Fclk_reset#(c_dm_width,c_dq_width,c_dqs_width,data_width,gpio_width,id_width,mio_width))  fclk_reset;
    interface Pps7Fclk#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             fclk;
    interface Pps7Gpio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)             gpio;
    interface Vector#(2, Pps7I2c#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))  i2c;
    interface Pps7Irq#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)              irq;
    interface Inout#(Bit#(mio_width))     mio;
    interface Pps7Ps#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)               ps;

    interface Vector#(2, AxiMasterCommon#(32, id_width)) m_axi_gp;
    interface AxiSlaveCommon#(32, id_width) s_axi_acp;
    interface Vector#(2, AxiSlaveCommon#(32, id_width)) s_axi_gp;
    interface Vector#(4, AxiSlaveHighSpeed#(data_width, id_width)) s_axi_hp;
endinterface

typedef PS7#(4, 32, 4, 64/*data_width*/, 64/*gpio_width*/, 12/*id_width*/, 54) StdPS7;

module mkPS7#(Clock axi_clock, Reset axi_reset)(PS7#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width));
    let c_dm_width = valueOf(c_dm_width);
    let c_dq_width = valueOf(c_dq_width);
    let c_dqs_width = valueOf(c_dqs_width);
    let data_width = valueOf(data_width);
    let gpio_width = valueOf(gpio_width);
    let id_width = valueOf(id_width);
    let mio_width = valueOf(mio_width);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    PPS7#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width)foo <- mkPPS7(
        axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset,
        axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset,
        axi_clock, axi_reset);
`ifdef PS7EXTENDED
    Vector#(2, Pps7Can#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vcan;
    Vector#(2, Pps7Core#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vcore;
    Vector#(4, Pps7Dma#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vdma;
    Vector#(2, Pps7Enet#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     venet;
    Vector#(4, Pps7Fclk_clktrig#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vfclk_clktrig;
    Vector#(2, Pps7Sdio#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vsdio;
    Vector#(2, Pps7Spi#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vspi;
    Vector#(2, Pps7Ttc#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vttc;
    Vector#(2, Pps7Uart#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vuart;
    Vector#(2, Pps7Usb#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vusb;
`endif
    Vector#(4, Pps7Fclk_reset#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vfclk_reset;
    Vector#(2, Pps7I2c#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vi2c;
    Vector#(2, Pps7M_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vm_axi_gp;
    Vector#(2, Pps7S_axi_gp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vs_axi_gp;
    Vector#(4, Pps7S_axi_hp#(c_dm_width, c_dq_width, c_dqs_width, data_width, gpio_width, id_width, mio_width))     vs_axi_hp;
    Vector#(2, AxiMasterCommon#(32, id_width)) vtopm_axi_gp;
    Vector#(2, AxiMasterWires) vtopmw_axi_gp <- replicateM(mkAxiMasterWires(clocked_by axi_clock, reset_by axi_reset));
    Vector#(2, AxiSlaveCommon#(32, id_width)) vtops_axi_gp;
    Vector#(2, AxiSlaveWires) vtopsw_axi_gp <- replicateM(mkAxiSlaveWires(clocked_by axi_clock, reset_by axi_reset));
    Vector#(4, AxiSlaveHighSpeed#(data_width, id_width)) vtops_axi_hp;
    Vector#(2, AxiSlaveWires) vtopsw_axi_hp <- replicateM(mkAxiSlaveWires(clocked_by axi_clock, reset_by axi_reset));

`ifdef PS7EXTENDED
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
    vsdio[0] = foo.sdio0;
    vsdio[1] = foo.sdio1;
    vspi[0] = foo.spi0;
    vspi[1] = foo.spi1;
    vttc[0] = foo.ttc0;
    vttc[1] = foo.ttc1;
    vuart[0] = foo.uart0;
    vuart[1] = foo.uart1;
    vusb[0] = foo.usb0;
    vusb[1] = foo.usb1;
`endif
    vfclk_reset[0] = foo.fclk_reset0;
    vfclk_reset[1] = foo.fclk_reset1;
    vfclk_reset[2] = foo.fclk_reset2;
    vfclk_reset[3] = foo.fclk_reset3;
    vi2c[0] = foo.i2c0;
    vi2c[1] = foo.i2c1;
    vm_axi_gp[0] = foo.m_axi_gp0;
    vm_axi_gp[1] = foo.m_axi_gp1;
    vs_axi_gp[0] = foo.s_axi_gp0;
    vs_axi_gp[1] = foo.s_axi_gp1;
    vs_axi_hp[0] = foo.s_axi_hp0;
    vs_axi_hp[1] = foo.s_axi_hp1;
    vs_axi_hp[2] = foo.s_axi_hp2;
    vs_axi_hp[3] = foo.s_axi_hp3;
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
                 method ActionValue#(Axi3ReadRequest#(32,id_width)) get() if (vm_axi_gp[i].arvalid() != 0);
                     Axi3ReadRequest#(32,id_width) v;
                     v.address = vm_axi_gp[i].araddr();
                     v.burst = vm_axi_gp[i].arburst();
                     v.cache = vm_axi_gp[i].arcache();
                     v.id = vm_axi_gp[i].arid();
                     v.len = vm_axi_gp[i].arlen();
                     v.lock = vm_axi_gp[i].arlock();
                     v.prot = vm_axi_gp[i].arprot();
                     v.qos = vm_axi_gp[i].arqos();
                     v.size = vm_axi_gp[i].arsize();

                    vtopmw_axi_gp[i].arready <= 1;
                    return v;
                endmethod
            endinterface
            interface Get req_aw;
                method ActionValue#(Axi3WriteRequest#(32,id_width)) get() if (vm_axi_gp[i].awvalid() != 0);
                    Axi3WriteRequest#(32,id_width) v;
                    v.address = vm_axi_gp[i].awaddr();
                    v.burst = vm_axi_gp[i].awburst();
                    v.cache = vm_axi_gp[i].awcache();
                    v.id = vm_axi_gp[i].awid();
                    v.len = vm_axi_gp[i].awlen();
                    v.lock = vm_axi_gp[i].awlock();
                    v.prot = vm_axi_gp[i].awprot();
                    v.qos = vm_axi_gp[i].awqos();
                    v.size = vm_axi_gp[i].awsize();

                    vtopmw_axi_gp[i].awready <= 1;
                    return v;
               endmethod
            endinterface
            interface Put resp_read;
                method Action put(Axi3ReadResponse#(32, id_width) v) if (vm_axi_gp[i].rready() != 0);
                    vm_axi_gp[i].rid(v.id);
                    vm_axi_gp[i].rresp(v.resp);
                    vm_axi_gp[i].rdata(v.data);
                    vm_axi_gp[i].rlast(v.last);

                    vtopmw_axi_gp[i].rvalid <= 1;
                endmethod
            endinterface
            interface Get resp_write;
                method ActionValue#(Axi3WriteData#(32, TDiv#(32, 8), id_width)) get() if (vm_axi_gp[i].wvalid() != 0);
                    Axi3WriteData#(32, TDiv#(32, 8), id_width) v;
                    v.id = vm_axi_gp[i].wid();
                    v.byteEnable = vm_axi_gp[i].wstrb();
                    v.data = vm_axi_gp[i].wdata();
                    v.last = vm_axi_gp[i].wlast();

                    vtopmw_axi_gp[i].wready <= 1;
                    return v;
                endmethod
            endinterface
            interface Put resp_b;
                method Action put(Axi3WriteResponse#(id_width) v) if (vm_axi_gp[i].bready() != 0);
                    vm_axi_gp[i].bid(v.id);
                    vm_axi_gp[i].bresp(v.resp);
	       
                    vtopmw_axi_gp[i].bvalid <= 1;
                endmethod
            endinterface
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
                method Action put(Axi3ReadRequest#(32,id_width) v) if (vs_axi_gp[i].arready() != 0);
                    vs_axi_gp[i].araddr(v.address);
                    vs_axi_gp[i].arburst(v.burst);
                    vs_axi_gp[i].arcache(v.cache);
                    vs_axi_gp[i].arid(v.id);
                    vs_axi_gp[i].arlen(v.len);
                    vs_axi_gp[i].arlock(v.lock);
                    vs_axi_gp[i].arprot(v.prot);
                    vs_axi_gp[i].arqos(v.qos);
                    vs_axi_gp[i].arsize(v.size);

	            vtopsw_axi_gp[i].arvalid <= 1;
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(Axi3WriteRequest#(32,id_width) v) if (vs_axi_gp[i].awready() != 0);
                    vs_axi_gp[i].awaddr(v.address);
                    vs_axi_gp[i].awburst(v.burst);
                    vs_axi_gp[i].awcache(v.cache);
                    vs_axi_gp[i].awid(v.id);
                    vs_axi_gp[i].awlen(v.len);
                    vs_axi_gp[i].awlock(v.lock);
                    vs_axi_gp[i].awprot(v.prot);
                    vs_axi_gp[i].awqos(v.qos);
                    vs_axi_gp[i].awsize(v.size);

	            vtopsw_axi_gp[i].awvalid <= 1;
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(Axi3WriteData#(32, TDiv#(32, 8), id_width) v) if (vs_axi_gp[i].wready() != 0);
                    vs_axi_gp[i].wid(v.id);
                    vs_axi_gp[i].wstrb(v.byteEnable);
                    vs_axi_gp[i].wdata(v.data);
                    vs_axi_gp[i].wlast(v.last);

	            vtopsw_axi_gp[i].wvalid <= 1;
                endmethod
            endinterface
            interface Get resp_read;
                method ActionValue#(Axi3ReadResponse#(32, id_width)) get() if (vs_axi_gp[i].rvalid() != 0);
                    Axi3ReadResponse#(32, id_width) v;
                    v.id = vs_axi_gp[i].rid();
                    v.resp = vs_axi_gp[i].rresp();
                    v.data = vs_axi_gp[i].rdata();
                    v.last = vs_axi_gp[i].rlast();

	            vtopsw_axi_gp[i].rready <= 1;
                    return v;
                endmethod
            endinterface
            interface Get resp_b;
                method ActionValue#(Axi3WriteResponse#(id_width)) get() if (vs_axi_gp[i].bvalid() != 0);
                    Axi3WriteResponse#(id_width) v;
                    v.id = vs_axi_gp[i].bid();
                    v.resp = vs_axi_gp[i].bresp();

	            vtopsw_axi_gp[i].bready <= 1;
                    return v;
                endmethod
            endinterface
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
                method Action put(Axi3ReadRequest#(32,id_width) v) if (vs_axi_hp[i].arready() != 0);
                    vs_axi_hp[i].araddr(v.address);
                    vs_axi_hp[i].arburst(v.burst);
                    vs_axi_hp[i].arcache(v.cache);
                    vs_axi_hp[i].arid(v.id);
                    vs_axi_hp[i].arlen(v.len);
                    vs_axi_hp[i].arlock(v.lock);
                    vs_axi_hp[i].arprot(v.prot);
                    vs_axi_hp[i].arqos(v.qos);
                    vs_axi_hp[i].arsize(v.size);

		    vtopsw_axi_hp[i].arvalid <= 1;
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(Axi3WriteRequest#(32,id_width) v) if (vs_axi_hp[i].awready() != 0);
                    vs_axi_hp[i].awaddr(v.address);
                    vs_axi_hp[i].awburst(v.burst);
                    vs_axi_hp[i].awcache(v.cache);
                    vs_axi_hp[i].awid(v.id);
                    vs_axi_hp[i].awlen(v.len);
                    vs_axi_hp[i].awlock(v.lock);
                    vs_axi_hp[i].awprot(v.prot);
                    vs_axi_hp[i].awqos(v.qos);
                    vs_axi_hp[i].awsize(v.size);

	            vtopsw_axi_hp[i].awvalid <= 1;
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(Axi3WriteData#(data_width, TDiv#(data_width, 8), id_width) v) if (vs_axi_hp[i].wready() != 0);
                    vs_axi_hp[i].wid(v.id);
                    vs_axi_hp[i].wstrb(v.byteEnable);
                    vs_axi_hp[i].wdata(v.data);
                    vs_axi_hp[i].wlast(v.last);

	            vtopsw_axi_hp[i].wvalid <= 1;
                endmethod
            endinterface
            interface Get resp_read;
                method ActionValue#(Axi3ReadResponse#(data_width, id_width)) get() if (vs_axi_hp[i].rvalid() != 0);
                    Axi3ReadResponse#(data_width, id_width) v;
                    v.id = vs_axi_hp[i].rid();
                    v.resp = vs_axi_hp[i].rresp();
                    v.data = vs_axi_hp[i].rdata();
                    v.last = vs_axi_hp[i].rlast();

	            vtopsw_axi_hp[i].rready <= 1;
                    return v;
                endmethod
            endinterface
            interface Get resp_b;
                method ActionValue#(Axi3WriteResponse#(id_width)) get() if (vs_axi_hp[i].bvalid() != 0);
                    Axi3WriteResponse#(id_width) v;
                    v.id = vs_axi_hp[i].bid();
                    v.resp = vs_axi_hp[i].bresp();

		    vtopsw_axi_hp[i].bready <= 1;
                    return v;
                endmethod
            endinterface
            method aresetn = vs_axi_hp[i].aresetn;
            endinterface
            method racount = vs_axi_hp[i].racount;
            method rcount = vs_axi_hp[i].rcount;
            method rdissuecap1_en = vs_axi_hp[i].rdissuecap1_en;
            method wacount = vs_axi_hp[i].wacount;
            method wcount = vs_axi_hp[i].wcount;
            method wrissuecap1_en = vs_axi_hp[i].wrissuecap1_en;
        endinterface;

`ifdef PS7EXTENDED
    interface Pps7Can can = vcan;
    interface Pps7Core     core = vcore;
    interface Pps7Dma     dma = vdma;
    interface Pps7Enet     enet = venet;
    interface Pps7Fclk_clktrig    fclk_clktrig = vfclk_clktrig;
    interface Pps7Sdio    sdio = vsdio;
    interface Pps7Spi    spi = vspi;
    interface Pps7Ttc    ttc = vttc;
    interface Pps7Uart    uart = vuart;
    interface Pps7Usb    usb = vusb;
    interface Pps7Event     event_ = foo.event_;
    interface Pps7Fpga     fpga = foo.fpga;
    interface Pps7Ftmd     ftmd = foo.ftmd;
    interface Pps7Ftmt     ftmt = foo.ftmt;
    interface Pps7Pjtag     pjtag = foo.pjtag;
    interface Pps7Sram     sram = foo.sram;
    interface Pps7Trace     trace = foo.trace;
    interface Pps7Wdt     wdt = foo.wdt;
`endif
    interface Pps7Fclk_reset    fclk_reset = vfclk_reset;
    interface Pps7I2c    i2c = vi2c;
    interface Pps7Ddr     ddr = foo.ddr;
    interface Pps7Fclk     fclk = foo.fclk;
    interface Pps7Gpio     gpio = foo.gpio;
    interface Pps7Irq     irq = foo.irq;
    interface Inout     mio = foo.mio;
    interface Pps7Ps     ps = foo.ps;

    interface AxiMasterCommon m_axi_gp = vtopm_axi_gp;
    interface AxiSlaveCommon s_axi_gp = vtops_axi_gp;
    interface AxiSlaveHighSpeed s_axi_hp = vtops_axi_hp;
    //interface AxiSlaveCommon s_axi_acp;
endmodule

interface ZynqPinsInternal#(numeric type c_dm_width, numeric type c_dq_width, numeric type c_dqs_width, numeric type data_width, numeric type gpio_width, numeric type id_width, numeric type mio_width);
    (* prefix="DDR_Addr" *) interface Inout#(Bit#(15))     addr;
    (* prefix="DDR_BankAddr" *) interface Inout#(Bit#(3))     bankaddr;
    (* prefix="DDR_CAS_n" *) interface Inout#(Bit#(1))     cas_n;
    (* prefix="DDR_CKE" *) interface Inout#(Bit#(1))     cke;
    (* prefix="DDR_CS_n" *) interface Inout#(Bit#(1))     cs_n;
    (* prefix="DDR_Clk_n" *) interface Inout#(Bit#(1))     clk_n;
    (* prefix="DDR_Clk_p" *) interface Inout#(Bit#(1))     clk;
    (* prefix="DDR_DM" *) interface Inout#(Bit#(c_dm_width))     dm;
    (* prefix="DDR_DQ" *) interface Inout#(Bit#(c_dq_width))     dq;
    (* prefix="DDR_DQS_n" *) interface Inout#(Bit#(c_dqs_width))     dqs_n;
    (* prefix="DDR_DQS_p" *) interface Inout#(Bit#(c_dqs_width))     dqs;
    (* prefix="DDR_DRSTB" *) interface Inout#(Bit#(1))     drstb;
    (* prefix="DDR_ODT" *) interface Inout#(Bit#(1))     odt;
    (* prefix="DDR_RAS_n" *) interface Inout#(Bit#(1))     ras_n;
    (* prefix="FIXED_IO_ddr_vrn" *) interface Inout#(Bit#(1))     vrn;
    (* prefix="FIXED_IO_ddr_vrp" *) interface Inout#(Bit#(1))     vrp;
    (* prefix="DDR_WEB" *) interface Inout#(Bit#(1))     web;
    (* prefix="FIXED_IO_mio" *)
    interface Inout#(Bit#(mio_width))       mio;
    (* prefix="FIXED_IO_ps" *)
    interface Pps7Ps#(4, 32, 4, 64, 64, 12, 54) ps;
    interface Clock                         fclk_clk0;
    interface Bit#(1)                       fclk_reset0_n;
endinterface

typedef ZynqPinsInternal#(4, 32, 4, 64/*data_width*/, 64/*gpio_width*/, 12/*id_width*/, 54) ZynqPins;

typedef AxiSlaveHighSpeed#(64/*data_width*/, 12/*id_width*/) HSSlave;
typedef Axi3ReadRequest#(32,12/*id_width*/) StdAxiREQR;
typedef Axi3WriteRequest#(32,12/*id_width*/) StdAxiREQW;

interface HackInterface;
endinterface

module mkPS7MasterInternal#(StdAxi3Master m_axi, HSSlave hp)(HackInterface);
    rule s_areqr_rule;
        let address <- m_axi.read.readAddr();
        hp.axi.req_ar.put(StdAxiREQR{ address: address[31:0],
            len: m_axi.read.readBurstLen(),
            size: m_axi.read.readBurstWidth(),
            burst: m_axi.read.readBurstType(),
            prot: m_axi.read.readBurstProt(),
            cache: m_axi.read.readBurstCache(),
            id: m_axi.read.readId(), lock: 0, qos: 0});
    endrule

    rule s_areqw_rule;
        let address <- m_axi.write.writeAddr();
        hp.axi.req_aw.put(StdAxiREQW{ address: address[31:0],
            len: m_axi.write.writeBurstLen(),
            size: m_axi.write.writeBurstWidth(),
            burst: m_axi.write.writeBurstType(),
            prot: m_axi.write.writeBurstProt(),
            cache: m_axi.write.writeBurstCache(),
            id: m_axi.write.writeId(), lock: 0, qos: 0});
    endrule

    rule s_arespb_rule;
        let s_arespb <- hp.axi.resp_b.get();
        m_axi.write.writeResponse(s_arespb.resp, s_arespb.id);
    endrule

    rule s_arespr_rule;
        let s_arespr <- hp.axi.resp_read.get();
        m_axi.read.readData(s_arespr.data, s_arespr.resp, s_arespr.last, s_arespr.id);
    endrule

    rule s_arespw_rule;
        let data <- m_axi.write.writeData();
        Axi3WriteData#(64/*data_width*/, TDiv#(64, 8), 12/*id_width*/) s_arespw;
        s_arespw.data = data;
        s_arespw.byteEnable = m_axi.write.writeDataByteEnable();
        s_arespw.last = m_axi.write.writeLastDataBeat();
        s_arespw.id = m_axi.write.writeWid();
        hp.axi.resp_write.put(s_arespw);
    endrule
endmodule

module mkPS7Slave#(Clock axi_clock, Reset axi_reset, StdAxi3Slave ctrl, Integer nmasters, StdAxi3Master m_axi, ReadOnly#(Bool) interrupt)(ZynqPins);
    StdPS7 ps7 <- mkPS7(axi_clock, axi_reset);

    rule send_int_rule;
    ps7.irq.f2p({15'b0, interrupt ? 1'b1 : 1'b0});
    endrule

    rule m_ar_rule;
        let m_ar <- ps7.m_axi_gp[0].req_ar.get();
        ctrl.read.readAddr(m_ar.address, m_ar.len, m_ar.size, m_ar.burst, m_ar.prot, m_ar.cache, m_ar.id);
    endrule

    rule m_aw_rule;
        let m_aw <- ps7.m_axi_gp[0].req_aw.get();
        ctrl.write.writeAddr(m_aw.address, m_aw.len, m_aw.size, m_aw.burst, m_aw.prot, m_aw.cache, m_aw.id);
    endrule

    rule m_arespb_rule;
        Axi3WriteResponse#(12/*id_width*/) m_arespb;
        m_arespb.resp <- ctrl.write.writeResponse();
        m_arespb.id <- ctrl.write.bid();
        ps7.m_axi_gp[0].resp_b.put(m_arespb);
    endrule

    rule m_arespr_rule;
        let data <- ctrl.read.readData();
        Axi3ReadResponse#(32/*data_width*/, 12/*id_width*/) m_arespr;
        m_arespr.data = data;
        m_arespr.resp = 2'b0;
        m_arespr.last = ctrl.read.last();
        m_arespr.id = ctrl.read.rid();
        ps7.m_axi_gp[0].resp_read.put(m_arespr);
    endrule

    rule m_arespw_rule;
        let m_arespw <- ps7.m_axi_gp[0].resp_write.get();
        ctrl.write.writeData(m_arespw.data, m_arespw.byteEnable, m_arespw.last, m_arespw.id);
    endrule

if (nmasters > 0) begin
    let myhp <- mkPS7MasterInternal(m_axi, ps7.s_axi_hp[0]);
end

    interface Inout  addr = ps7.ddr.addr;
    interface Inout  bankaddr = ps7.ddr.bankaddr;
    interface Inout  cas_n = ps7.ddr.cas_n;
    interface Inout  cke = ps7.ddr.cke;
    interface Inout  cs_n = ps7.ddr.cs_n;
    interface Inout  clk_n = ps7.ddr.clk_n;
    interface Inout  clk = ps7.ddr.clk;
    interface Inout  dm = ps7.ddr.dm;
    interface Inout  dq = ps7.ddr.dq;
    interface Inout  dqs_n = ps7.ddr.dqs_n;
    interface Inout  dqs = ps7.ddr.dqs;
    interface Inout  drstb = ps7.ddr.drstb;
    interface Inout  odt = ps7.ddr.odt;
    interface Inout  ras_n = ps7.ddr.ras_n;
    interface Inout  vrn = ps7.ddr.vrn;
    interface Inout  vrp = ps7.ddr.vrp;
    interface Inout  web = ps7.ddr.web;
    interface Inout  mio = ps7.mio;
    interface Pps7Ps ps = ps7.ps;
    interface Clock  fclk_clk0 = ps7.fclk.clk0;
    interface Bit    fclk_reset0_n = ps7.fclk_reset[0].n;
endmodule
