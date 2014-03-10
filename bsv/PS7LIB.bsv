
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
import GetPut::*;
import Connectable::*;
import Vector::*;
import PPS7LIB::*;
import CtrlMux::*;
import Portal::*;
import AxiMasterSlave::*;
import GetPutF::*;

interface AxiMasterCommon;
    method Bit#(1)            aresetn();
    interface Axi3Master#(32,32,12) client;
endinterface

interface AxiSlaveCommon#(numeric type data_width);
    method Bit#(1)            aresetn();
    interface Axi3Slave#(32,data_width,6) server;
endinterface

interface AxiSlaveHighSpeed;
    interface AxiSlaveCommon#(64) axi;
    method Bit#(3)            racount();
    method Bit#(8)            rcount();
    method Action             rdissuecap1en(Bit#(1) v);
    method Bit#(6)            wacount();
    method Bit#(8)            wcount();
    method Action             wrissuecap1en(Bit#(1) v);
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

interface PS7LIB;
`ifdef PS7EXTENDED
    interface Vector#(2, Pps7Can)  can;
    interface Vector#(4, Pps7Dma)  dma;
    interface Vector#(2, Pps7Enet) enet;
    interface Pps7Event            event_;
    interface Vector#(4,Pps7Fclk_clktrig)fclk_clktrig;
    interface Pps7Fpga             fpga;
    interface Pps7Ftmd             ftmd;
    interface Pps7Ftmt             ftmt;
    interface Pps7Pjtag            pjtag;
    interface Vector#(2, Pps7Sdio) sdio;
    interface Vector#(2, Pps7Spi)  spi;
    interface Pps7Sram             sram;
    interface Pps7Trace            trace;
    interface Vector#(2, Pps7Ttc)  ttc;
    interface Vector#(2, Pps7Uart) uart;
    interface Vector#(2, Pps7Usb)  usb;
    interface Pps7Wdt              wdt;
`endif
    interface Pps7Ddr              ddr;
    method Bit#(4)     fclkclk();
    method Action      fclkclktrign(Bit#(4) v);
    method Bit#(4)     fclkresetn();
    method Action      fpgaidlen(Bit#(1) v);
    interface Pps7Emiogpio             gpio;
    interface Vector#(2, Pps7Emioi2c)  i2c;
    interface Pps7Irq              irq;
    interface Inout#(Bit#(54))     mio;
    interface Pps7Ps               ps;

    interface Vector#(2, AxiMasterCommon) m_axi_gp;
    interface AxiSlaveCommon#(32) s_axi_acp;
    interface Vector#(2, AxiSlaveCommon#(32)) s_axi_gp;
    interface Vector#(4, AxiSlaveHighSpeed) s_axi_hp;
endinterface

module mkPS7LIB#(Clock axi_clock, Reset axi_reset)(PS7LIB);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    PPS7LIB foo <- mkPPS7LIB(
        axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset,
        axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset, axi_clock, axi_reset,
        axi_clock, axi_reset);
`ifdef PS7EXTENDED
    Vector#(2, Pps7Can)     vcan;
    Vector#(4, Pps7Dma)     vdma;
    Vector#(2, Pps7Enet)     venet;
    Vector#(2, Pps7Sdio)     vsdio;
    Vector#(2, Pps7Spi)     vspi;
    Vector#(2, Pps7Ttc)     vttc;
    Vector#(2, Pps7Uart)     vuart;
    Vector#(2, Pps7Usb)     vusb;
`endif
    Vector#(2, Pps7Emioi2c)     vi2c;
    Vector#(2, Pps7Maxigp)     vm_axi_gp;
    Vector#(2, Pps7Saxigp)     vs_axi_gp;
    Vector#(4, Pps7Saxihp)     vs_axi_hp;
    Vector#(2, AxiMasterCommon) vtopm_axi_gp;
    Vector#(2, AxiMasterWires) vtopmw_axi_gp <- replicateM(mkAxiMasterWires(clocked_by axi_clock, reset_by axi_reset));
    Vector#(2, AxiSlaveCommon#(32)) vtops_axi_gp;
    Vector#(2, AxiSlaveWires) vtopsw_axi_gp <- replicateM(mkAxiSlaveWires(clocked_by axi_clock, reset_by axi_reset));
    Vector#(4, AxiSlaveHighSpeed) vtops_axi_hp;
    Vector#(4, AxiSlaveWires) vtopsw_axi_hp <- replicateM(mkAxiSlaveWires(clocked_by axi_clock, reset_by axi_reset));

`ifdef PS7EXTENDED
    vcan[0] = foo.can0;
    vcan[1] = foo.can1;
    vdma[0] = foo.dma0;
    vdma[1] = foo.dma1;
    vdma[2] = foo.dma2;
    vdma[3] = foo.dma3;
    venet[0] = foo.enet0;
    venet[1] = foo.enet1;
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
    vi2c[0] = foo.emioi2c0;
    vi2c[1] = foo.emioi2c1;
    vm_axi_gp[0] = foo.maxigp0;
    vm_axi_gp[1] = foo.maxigp1;
    vs_axi_gp[0] = foo.saxigp0;
    vs_axi_gp[1] = foo.saxigp1;
    vs_axi_hp[0] = foo.saxihp0;
    vs_axi_hp[1] = foo.saxihp1;
    vs_axi_hp[2] = foo.saxihp2;
    vs_axi_hp[3] = foo.saxihp3;
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
        vtopm_axi_gp[i] = interface AxiMasterCommon;
       interface Axi3Master client;
            interface Get req_ar;
                 method ActionValue#(Axi3ReadRequest#(32,12)) get() if (vm_axi_gp[i].arvalid() != 0);
                     Axi3ReadRequest#(32,12) v;
                     v.address = vm_axi_gp[i].araddr();
                     v.burst = vm_axi_gp[i].arburst();
                     v.cache = vm_axi_gp[i].arcache();
                     v.id = vm_axi_gp[i].arid();
                     v.len = vm_axi_gp[i].arlen();
                     v.lock = vm_axi_gp[i].arlock();
                     v.prot = vm_axi_gp[i].arprot();
                     v.qos = vm_axi_gp[i].arqos();
                     v.size = {0, vm_axi_gp[i].arsize()};

                    vtopmw_axi_gp[i].arready <= 1;
                    return v;
                endmethod
            endinterface
            interface Get req_aw;
                method ActionValue#(Axi3WriteRequest#(32,12)) get() if (vm_axi_gp[i].awvalid() != 0);
                    Axi3WriteRequest#(32,12) v;
                    v.address = vm_axi_gp[i].awaddr();
                    v.burst = vm_axi_gp[i].awburst();
                    v.cache = vm_axi_gp[i].awcache();
                    v.id = vm_axi_gp[i].awid();
                    v.len = vm_axi_gp[i].awlen();
                    v.lock = vm_axi_gp[i].awlock();
                    v.prot = vm_axi_gp[i].awprot();
                    v.qos = vm_axi_gp[i].awqos();
                    v.size = {0, vm_axi_gp[i].awsize()};

                    vtopmw_axi_gp[i].awready <= 1;
                    return v;
               endmethod
            endinterface
            interface Put resp_read;
                method Action put(Axi3ReadResponse#(32, 12) v) if (vm_axi_gp[i].rready() != 0);
                    vm_axi_gp[i].rid(v.id);
                    vm_axi_gp[i].rresp(v.resp);
                    vm_axi_gp[i].rdata(v.data);
                    vm_axi_gp[i].rlast(v.last);

                    vtopmw_axi_gp[i].rvalid <= 1;
                endmethod
            endinterface
            interface Get resp_write;
                method ActionValue#(Axi3WriteData#(32,12)) get() if (vm_axi_gp[i].wvalid() != 0);
                    Axi3WriteData#(32,12) v;
                    v.id = vm_axi_gp[i].wid();
                    v.byteEnable = vm_axi_gp[i].wstrb();
                    v.data = vm_axi_gp[i].wdata();
                    v.last = vm_axi_gp[i].wlast();

                    vtopmw_axi_gp[i].wready <= 1;
                    return v;
                endmethod
            endinterface
            interface Put resp_b;
                method Action put(Axi3WriteResponse#(12) v) if (vm_axi_gp[i].bready() != 0);
                    vm_axi_gp[i].bid(v.id);
                    vm_axi_gp[i].bresp(v.resp);
	       
                    vtopmw_axi_gp[i].bvalid <= 1;
                endmethod
            endinterface
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
        vtops_axi_gp[i] = interface AxiSlaveCommon#(32);
          interface Axi3Slave server;
            interface Put req_ar;
                method Action put(Axi3ReadRequest#(32,6) v) if (vs_axi_gp[i].arready() != 0);
                    vs_axi_gp[i].araddr(v.address);
                    vs_axi_gp[i].arburst(v.burst);
                    vs_axi_gp[i].arcache(v.cache);
                    vs_axi_gp[i].arid(v.id);
                    vs_axi_gp[i].arlen(v.len);
                    vs_axi_gp[i].arlock(v.lock);
                    vs_axi_gp[i].arprot(v.prot);
                    vs_axi_gp[i].arqos(v.qos);
                    vs_axi_gp[i].arsize(v.size[1:0]);

	            vtopsw_axi_gp[i].arvalid <= 1;
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(Axi3WriteRequest#(32,6) v) if (vs_axi_gp[i].awready() != 0);
                    vs_axi_gp[i].awaddr(v.address);
                    vs_axi_gp[i].awburst(v.burst);
                    vs_axi_gp[i].awcache(v.cache);
                    vs_axi_gp[i].awid(v.id);
                    vs_axi_gp[i].awlen(v.len);
                    vs_axi_gp[i].awlock(v.lock);
                    vs_axi_gp[i].awprot(v.prot);
                    vs_axi_gp[i].awqos(v.qos);
                    vs_axi_gp[i].awsize(v.size[1:0]);

	            vtopsw_axi_gp[i].awvalid <= 1;
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(Axi3WriteData#(32,6) v) if (vs_axi_gp[i].wready() != 0);
                    vs_axi_gp[i].wid(v.id);
                    vs_axi_gp[i].wstrb(v.byteEnable);
                    vs_axi_gp[i].wdata(v.data);
                    vs_axi_gp[i].wlast(v.last);

	            vtopsw_axi_gp[i].wvalid <= 1;
                endmethod
            endinterface
            interface GetF resp_read;
                method ActionValue#(Axi3ReadResponse#(32, 6)) get() if (vs_axi_gp[i].rvalid() != 0);
                    Axi3ReadResponse#(32, 6) v;
                    v.id = vs_axi_gp[i].rid();
                    v.resp = vs_axi_gp[i].rresp();
                    v.data = vs_axi_gp[i].rdata();
                    v.last = vs_axi_gp[i].rlast();

	            vtopsw_axi_gp[i].rready <= 1;
                    return v;
                endmethod
		method Bool notEmpty();
		    return (vs_axi_gp[i].rvalid() != 0);
	        endmethod
	    endinterface
            interface GetF resp_b;
                method ActionValue#(Axi3WriteResponse#(6)) get() if (vs_axi_gp[i].bvalid() != 0);
                    Axi3WriteResponse#(6) v;
                    v.id = vs_axi_gp[i].bid();
                    v.resp = vs_axi_gp[i].bresp();

	            vtopsw_axi_gp[i].bready <= 1;
                    return v;
                endmethod
	        method Bool notEmpty();
		    return (vs_axi_gp[i].bvalid() != 0);
	        endmethod
              endinterface
            endinterface
            method aresetn = vs_axi_gp[i].aresetn;
        endinterface;
    for (Integer i = 0; i < 4; i = i + 1)
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
        vtops_axi_hp[i] = interface AxiSlaveHighSpeed;
            interface AxiSlaveCommon axi;
            interface Axi3Slave server;
            interface Put req_ar;
                method Action put(Axi3ReadRequest#(32,6) v) if (vs_axi_hp[i].arready() != 0);
                    vs_axi_hp[i].araddr(v.address);
                    vs_axi_hp[i].arburst(v.burst);
                    vs_axi_hp[i].arcache(v.cache);
                    vs_axi_hp[i].arid(v.id);
                    vs_axi_hp[i].arlen(v.len);
                    vs_axi_hp[i].arlock(v.lock);
                    vs_axi_hp[i].arprot(v.prot);
                    vs_axi_hp[i].arqos(v.qos);
                    vs_axi_hp[i].arsize(v.size[1:0]);

		    vtopsw_axi_hp[i].arvalid <= 1;
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(Axi3WriteRequest#(32,6) v) if (vs_axi_hp[i].awready() != 0);
                    vs_axi_hp[i].awaddr(v.address);
                    vs_axi_hp[i].awburst(v.burst);
                    vs_axi_hp[i].awcache(v.cache);
                    vs_axi_hp[i].awid(v.id);
                    vs_axi_hp[i].awlen(v.len);
                    vs_axi_hp[i].awlock(v.lock);
                    vs_axi_hp[i].awprot(v.prot);
                    vs_axi_hp[i].awqos(v.qos);
                    vs_axi_hp[i].awsize(v.size[1:0]);

	            vtopsw_axi_hp[i].awvalid <= 1;
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(Axi3WriteData#(64,6) v) if (vs_axi_hp[i].wready() != 0);
                    vs_axi_hp[i].wid(v.id);
                    vs_axi_hp[i].wstrb(v.byteEnable);
                    vs_axi_hp[i].wdata(v.data);
                    vs_axi_hp[i].wlast(v.last);

	            vtopsw_axi_hp[i].wvalid <= 1;
                endmethod
            endinterface
            interface GetF resp_read;
                method ActionValue#(Axi3ReadResponse#(64,6)) get() if (vs_axi_hp[i].rvalid() != 0);
                    Axi3ReadResponse#(64, 6) v;
                    v.id = vs_axi_hp[i].rid();
                    v.resp = vs_axi_hp[i].rresp();
                    v.data = vs_axi_hp[i].rdata();
                    v.last = vs_axi_hp[i].rlast();

	            vtopsw_axi_hp[i].rready <= 1;
                    return v;
                endmethod
	        method Bool notEmpty();
		    return (vs_axi_hp[i].rvalid() != 0);
                endmethod
            endinterface
            interface GetF resp_b;
                method ActionValue#(Axi3WriteResponse#(6)) get() if (vs_axi_hp[i].bvalid() != 0);
                    Axi3WriteResponse#(6) v;
                    v.id = vs_axi_hp[i].bid();
                    v.resp = vs_axi_hp[i].bresp();

		    vtopsw_axi_hp[i].bready <= 1;
                    return v;
                endmethod
	        method Bool notEmpty();
		    return (vs_axi_hp[i].bvalid() != 0);
                endmethod
              endinterface: resp_b
            endinterface: server
            method aresetn = vs_axi_hp[i].aresetn;
            endinterface: axi
            method racount = vs_axi_hp[i].racount;
            method rcount = vs_axi_hp[i].rcount;
            method rdissuecap1en = vs_axi_hp[i].rdissuecap1en;
            method wacount = vs_axi_hp[i].wacount;
            method wcount = vs_axi_hp[i].wcount;
            method wrissuecap1en = vs_axi_hp[i].wrissuecap1en;
        endinterface;

`ifdef PS7EXTENDED
    interface Pps7Can can = vcan;
    interface Pps7Dma     dma = vdma;
    interface Pps7Enet     enet = venet;
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
    interface Pps7Emioi2c    i2c = vi2c;
    interface Pps7Ddr     ddr = foo.ddr;
    interface Bit        fclkclk = foo.fclkclk;
    interface Bit        fclkresetn = foo.fclkresetn;
    method Action      fclkclktrign(Bit#(4) v);
        foo.fclkclktrign(v);
    endmethod
    method Action      fpgaidlen(Bit#(1) v);
        foo.fpgaidlen(v);
    endmethod
    interface Pps7Emiogpio     gpio = foo.emiogpio;
    interface Pps7Irq     irq = foo.irq;
    interface Inout     mio = foo.mio;
    interface Pps7Ps     ps = foo.ps;

    interface AxiMasterCommon m_axi_gp = vtopm_axi_gp;
    interface AxiSlaveCommon s_axi_gp = vtops_axi_gp;
    interface AxiSlaveHighSpeed s_axi_hp = vtops_axi_hp;
    //interface AxiSlaveCommon s_axi_acp;
endmodule

interface ZynqPins;
    (* prefix="DDR_Addr" *) interface Inout#(Bit#(15))     a;
    (* prefix="DDR_BankAddr" *) interface Inout#(Bit#(3))     ba;
    (* prefix="DDR_CAS_n" *) interface Inout#(Bit#(1))     casb;
    (* prefix="DDR_CKE" *) interface Inout#(Bit#(1))     cke;
    (* prefix="DDR_CS_n" *) interface Inout#(Bit#(1))     csb;
    (* prefix="DDR_Clk_n" *) interface Inout#(Bit#(1))     ckn;
    (* prefix="DDR_Clk_p" *) interface Inout#(Bit#(1))     ckp;
    (* prefix="DDR_DM" *) interface Inout#(Bit#(4))     dm;
    (* prefix="DDR_DQ" *) interface Inout#(Bit#(32))     dq;
    (* prefix="DDR_DQS_n" *) interface Inout#(Bit#(4))     dqsn;
    (* prefix="DDR_DQS_p" *) interface Inout#(Bit#(4))     dqsp;
    (* prefix="DDR_DRSTB" *) interface Inout#(Bit#(1))     drstb;
    (* prefix="DDR_ODT" *) interface Inout#(Bit#(1))     odt;
    (* prefix="DDR_RAS_n" *) interface Inout#(Bit#(1))     rasb;
    (* prefix="FIXED_IO_ddr_vrn" *) interface Inout#(Bit#(1))     vrn;
    (* prefix="FIXED_IO_ddr_vrp" *) interface Inout#(Bit#(1))     vrp;
    (* prefix="DDR_WEB" *) interface Inout#(Bit#(1))     web;
    (* prefix="FIXED_IO_mio" *)
    interface Inout#(Bit#(54))       mio;
    (* prefix="FIXED_IO_ps" *)
    interface Pps7Ps ps;
endinterface

interface PS7;
    (* prefix="" *)
    interface ZynqPins pins;
    interface Vector#(2, AxiMasterCommon)     m_axi_gp;
    interface Vector#(2, AxiSlaveCommon#(32)) s_axi_gp;
    interface Vector#(4, AxiSlaveHighSpeed)   s_axi_hp;
    method Action                             interrupt(Bit#(1) v);
    method Bit#(4)     fclkclk();
    method Bit#(4)     fclkresetn();
endinterface

module mkPS7#(Clock axi_clock, Reset axi_reset)(PS7);
    PS7LIB ps7 <- mkPS7LIB(axi_clock, axi_reset);

    rule arb_rule;
        ps7.ddr.arb(4'b0);
    endrule

    interface ZynqPins pins;
    interface Inout  a = ps7.ddr.a;
    interface Inout  ba = ps7.ddr.ba;
    interface Inout  casb = ps7.ddr.casb;
    interface Inout  cke = ps7.ddr.cke;
    interface Inout  csb = ps7.ddr.csb;
    interface Inout  ckn = ps7.ddr.ckn;
    interface Inout  ckp = ps7.ddr.ckp;
    interface Inout  dm = ps7.ddr.dm;
    interface Inout  dq = ps7.ddr.dq;
    interface Inout  dqsn = ps7.ddr.dqsn;
    interface Inout  dqsp = ps7.ddr.dqsp;
    interface Inout  drstb = ps7.ddr.drstb;
    interface Inout  odt = ps7.ddr.odt;
    interface Inout  rasb = ps7.ddr.rasb;
    interface Inout  vrn = ps7.ddr.vrn;
    interface Inout  vrp = ps7.ddr.vrp;
    interface Inout  web = ps7.ddr.web;
    interface Inout  mio = ps7.mio;
    interface Pps7Ps ps = ps7.ps;
    endinterface
    interface AxiMasterCommon m_axi_gp = ps7.m_axi_gp;
    interface AxiSlaveCommon s_axi_gp = ps7.s_axi_gp;
    interface AxiSlaveHighSpeed s_axi_hp = ps7.s_axi_hp;
    method Bit#(4)     fclkclk() = ps7.fclkclk;
    method Bit#(4)     fclkresetn() = ps7.fclkresetn;
    method Action interrupt(Bit#(1) v);
        ps7.irq.f2p({19'b0, v});
    endmethod
endmodule
