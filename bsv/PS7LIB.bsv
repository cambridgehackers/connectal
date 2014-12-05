
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
import ConnectableWithTrace::*;
import Bscan::*;
import Vector::*;
import PPS7LIB::*;
import CtrlMux::*;
import Portal::*;
import AxiMasterSlave::*;
import AxiDma::*;
import XilinxCells::*;
import ConnectalXilinxCells::*;

interface AxiMasterCommon;
    method Bit#(1)            aresetn();
    interface Axi3Master#(32,32,12) client;
endinterface

interface AxiSlaveCommon#(numeric type data_width, numeric type id_width);
    method Bit#(1)            aresetn();
    interface Axi3Slave#(32,data_width,id_width) server;
endinterface

interface AxiSlaveHighSpeed;
    interface AxiSlaveCommon#(64,6) axi;
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

   interface Wire#(Bit#(12)) rid;
   interface Wire#(Bit#(2))  rresp;
   interface Wire#(Bit#(32)) rdata;
   interface Wire#(Bit#(1))  rlast;
   interface Wire#(Bit#(12)) bid;
   interface Wire#(Bit#(2)) bresp;
endinterface

interface AxiSlaveWires#(numeric type data_width, numeric type id_width);
   interface Wire#(Bit#(32)) araddr;
   interface Wire#(Bit#(2)) arburst;
   interface Wire#(Bit#(4)) arcache;
   interface Wire#(Bit#(id_width)) arid;
   interface Wire#(Bit#(4)) arlen;
   interface Wire#(Bit#(2)) arlock;
   interface Wire#(Bit#(3)) arprot;
   interface Wire#(Bit#(4)) arqos;
   interface Wire#(Bit#(2)) arsize;
   interface Wire#(Bit#(5)) aruser;
   interface Wire#(Bit#(1)) arvalid;
   interface Wire#(Bit#(32)) awaddr;
   interface Wire#(Bit#(2)) awburst;
   interface Wire#(Bit#(4)) awcache;
   interface Wire#(Bit#(id_width)) awid;
   interface Wire#(Bit#(4)) awlen;
   interface Wire#(Bit#(2)) awlock;
   interface Wire#(Bit#(3)) awprot;
   interface Wire#(Bit#(4)) awqos;
   interface Wire#(Bit#(2)) awsize;
   interface Wire#(Bit#(5)) awuser;
   interface Wire#(Bit#(1)) awvalid;
   interface Wire#(Bit#(1)) rready;
   interface Wire#(Bit#(id_width)) wid;
   interface Wire#(Bit#(TDiv#(data_width,8))) wstrb;
   interface Wire#(Bit#(data_width)) wdata;
   interface Wire#(Bit#(1)) wlast;
   interface Wire#(Bit#(1)) wvalid;
   interface Wire#(Bit#(1)) bready;
endinterface

module mkAxiMasterWires(AxiMasterWires);
   Vector#(6, Wire#(Bit#(1))) wires <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(32))) datawires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(12))) idwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(2))) respwires <- replicateM(mkDWire(0));
   interface Wire arready = wires[0];
   interface Wire awready = wires[1];
   interface Wire rvalid = wires[2];
   interface Wire wready = wires[3];
   interface Wire rid  = idwires[0];
   interface Wire rresp  = respwires[0];
   interface Wire rdata  = datawires[0];
   interface Wire rlast  = wires[4];
   interface Wire bvalid = wires[5];
   interface Wire bid    = idwires[1];
   interface Wire bresp  = respwires[1];
endmodule

module mkAxiSlaveWires(AxiSlaveWires#(data_width, id_width));
   Vector#(5, Wire#(Bit#(1))) wires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(32))) addrwires <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(data_width))) datawires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(2))) burstwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(4))) cachewires <- replicateM(mkDWire(0));
   Vector#(3, Wire#(Bit#(id_width))) idwires <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(TDiv#(data_width,8)))) strbwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(4))) lenwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(2))) lockwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(3))) protwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(4))) qoswires <- replicateM(mkDWire(0));
   Vector#(3, Wire#(Bit#(1))) validwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(2))) sizewires <- replicateM(mkDWire(0));
   Vector#(3, Wire#(Bit#(1))) readywires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(5))) userwires <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(1))) lastwires <- replicateM(mkDWire(0));
   interface Wire araddr = addrwires[0];
   interface Wire arburst = burstwires[0];
   interface Wire arcache = cachewires[0];
   interface Wire arid = idwires[0];
   interface Wire arlen = lenwires[0];
   interface Wire arlock = lockwires[0];
   interface Wire arprot = protwires[0];
   interface Wire arqos = qoswires[0];
   interface Wire arsize = sizewires[0];
   interface Wire aruser = userwires[0];
   interface Wire arvalid = validwires[0];

   interface Wire awaddr = addrwires[1];
   interface Wire awburst = burstwires[1];
   interface Wire awcache = cachewires[1];
   interface Wire awid = idwires[1];
   interface Wire awlen = lenwires[1];
   interface Wire awlock = lockwires[1];
   interface Wire awprot = protwires[1];
   interface Wire awqos = qoswires[1];
   interface Wire awsize = sizewires[1];
   interface Wire awuser = userwires[1];
   interface Wire awvalid = validwires[1];

   interface Wire rready = readywires[0];
   interface Wire wid = idwires[2];
   interface Wire wstrb = strbwires[0];
   interface Wire wdata = datawires[0];
   interface Wire wlast = lastwires[0];
   interface Wire wvalid = validwires[2];
   interface Wire bready = readywires[1];
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
    interface Vector#(2, AxiSlaveCommon#(32,6)) s_axi_gp;
    interface Vector#(4, AxiSlaveHighSpeed) s_axi_hp;
    interface AxiSlaveCommon#(64,3) s_axi_acp;
endinterface

module mkPS7LIB#(Clock axi_clock, Reset axi_reset)(PS7LIB);
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
    Vector#(1, Pps7Saxiacp)    vs_axi_acp;
    Vector#(4, Pps7Saxihp)     vs_axi_hp;
    Vector#(2, AxiMasterCommon) vtopm_axi_gp;
    Vector#(2, AxiMasterWires) vtopmw_axi_gp <- replicateM(mkAxiMasterWires(clocked_by axi_clock, reset_by axi_reset));
    Vector#(2, AxiSlaveCommon#(32,6)) vtops_axi_gp;
    Vector#(1, AxiSlaveCommon#(64,3)) vtops_axi_acp;
    Vector#(2, AxiSlaveWires#(32,6)) vtopsw_axi_gp <- replicateM(mkAxiSlaveWires(clocked_by axi_clock, reset_by axi_reset));
    Vector#(4, AxiSlaveHighSpeed) vtops_axi_hp;
    Vector#(4, AxiSlaveWires#(64,6)) vtopsw_axi_hp <- replicateM(mkAxiSlaveWires(clocked_by axi_clock, reset_by axi_reset));
    Vector#(1, AxiSlaveWires#(64,3)) vtopsw_axi_acp <- replicateM(mkAxiSlaveWires(clocked_by axi_clock, reset_by axi_reset));

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
    vs_axi_acp[0] = foo.saxiacp;
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
            vm_axi_gp[i].rid(vtopmw_axi_gp[i].rid);
            vm_axi_gp[i].rresp(vtopmw_axi_gp[i].rresp);
            vm_axi_gp[i].rdata(vtopmw_axi_gp[i].rdata);
            vm_axi_gp[i].rlast(vtopmw_axi_gp[i].rlast);
            vm_axi_gp[i].rvalid(vtopmw_axi_gp[i].rvalid);
       endrule
       rule axi_master_handshake4;
	    vm_axi_gp[i].wready(vtopmw_axi_gp[i].wready);
       endrule
       rule axi_master_handshake5;
            vm_axi_gp[i].bvalid(vtopmw_axi_gp[i].bvalid);
	    vm_axi_gp[i].bid(vtopmw_axi_gp[i].bid);
	    vm_axi_gp[i].bresp(vtopmw_axi_gp[i].bresp);
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
                    vtopmw_axi_gp[i].rid <= v.id;
                    vtopmw_axi_gp[i].rresp <= v.resp;
                    vtopmw_axi_gp[i].rdata <= v.data;
                    vtopmw_axi_gp[i].rlast <= v.last;
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
                    vtopmw_axi_gp[i].bvalid <= 1;
                    vtopmw_axi_gp[i].bid    <= v.id;
                    vtopmw_axi_gp[i].bresp  <= v.resp;
                endmethod
            endinterface
            endinterface
            method aresetn = vm_axi_gp[i].aresetn;
            endinterface;
    for (Integer i = 0; i < 2; i = i + 1)
       begin
       rule axi_master_handshake1;
	  vs_axi_gp[i].araddr(vtopsw_axi_gp[i].araddr);
	  vs_axi_gp[i].arburst(vtopsw_axi_gp[i].arburst);
	  vs_axi_gp[i].arcache(vtopsw_axi_gp[i].arcache);
	  vs_axi_gp[i].arid(vtopsw_axi_gp[i].arid);
	  vs_axi_gp[i].arlen(vtopsw_axi_gp[i].arlen);
	  vs_axi_gp[i].arlock(vtopsw_axi_gp[i].arlock);
	  vs_axi_gp[i].arprot(vtopsw_axi_gp[i].arprot);
	  vs_axi_gp[i].arqos(vtopsw_axi_gp[i].arqos);
	  vs_axi_gp[i].arsize(vtopsw_axi_gp[i].arsize);
	  vs_axi_gp[i].arvalid(vtopsw_axi_gp[i].arvalid);
       endrule
       rule axi_master_handshake2;
	  vs_axi_gp[i].awaddr(vtopsw_axi_gp[i].awaddr);
	  vs_axi_gp[i].awburst(vtopsw_axi_gp[i].awburst);
	  vs_axi_gp[i].awcache(vtopsw_axi_gp[i].awcache);
	  vs_axi_gp[i].awid(vtopsw_axi_gp[i].awid);
	  vs_axi_gp[i].awlen(vtopsw_axi_gp[i].awlen);
	  vs_axi_gp[i].awlock(vtopsw_axi_gp[i].awlock);
	  vs_axi_gp[i].awprot(vtopsw_axi_gp[i].awprot);
	  vs_axi_gp[i].awqos(vtopsw_axi_gp[i].awqos);
	  vs_axi_gp[i].awsize(vtopsw_axi_gp[i].awsize);
	  vs_axi_gp[i].awvalid(vtopsw_axi_gp[i].awvalid);
       endrule
       rule axi_master_handshake3;
            vs_axi_gp[i].rready(vtopsw_axi_gp[i].rready);
       endrule
       rule axi_master_handshake4;
	  vs_axi_gp[i].wid(vtopsw_axi_gp[i].wid);
	  vs_axi_gp[i].wstrb(vtopsw_axi_gp[i].wstrb);
	  vs_axi_gp[i].wdata(vtopsw_axi_gp[i].wdata);
	  vs_axi_gp[i].wlast(vtopsw_axi_gp[i].wlast);
	  vs_axi_gp[i].wvalid(vtopsw_axi_gp[i].wvalid);
       endrule
       rule axi_master_handshake5;
            vs_axi_gp[i].bready(vtopsw_axi_gp[i].bready);
       endrule
       end
    for (Integer i = 0; i < 1; i = i + 1)
       begin
       rule axi_master_handshake1;
	  vs_axi_acp[i].araddr(vtopsw_axi_acp[i].araddr);
	  vs_axi_acp[i].arburst(vtopsw_axi_acp[i].arburst);
	  vs_axi_acp[i].arcache(vtopsw_axi_acp[i].arcache);
	  vs_axi_acp[i].arid(vtopsw_axi_acp[i].arid);
	  vs_axi_acp[i].arlen(vtopsw_axi_acp[i].arlen);
	  vs_axi_acp[i].arlock(vtopsw_axi_acp[i].arlock);
	  vs_axi_acp[i].arprot(vtopsw_axi_acp[i].arprot);
	  vs_axi_acp[i].arqos(vtopsw_axi_acp[i].arqos);
	  vs_axi_acp[i].arsize(vtopsw_axi_acp[i].arsize);
	  vs_axi_acp[i].aruser(vtopsw_axi_acp[i].aruser);
	  vs_axi_acp[i].arvalid(vtopsw_axi_acp[i].arvalid);
       endrule
       rule axi_master_handshake2;
	  vs_axi_acp[i].awaddr(vtopsw_axi_acp[i].awaddr);
	  vs_axi_acp[i].awburst(vtopsw_axi_acp[i].awburst);
	  vs_axi_acp[i].awcache(vtopsw_axi_acp[i].awcache);
	  vs_axi_acp[i].awid(vtopsw_axi_acp[i].awid);
	  vs_axi_acp[i].awlen(vtopsw_axi_acp[i].awlen);
	  vs_axi_acp[i].awlock(vtopsw_axi_acp[i].awlock);
	  vs_axi_acp[i].awprot(vtopsw_axi_acp[i].awprot);
	  vs_axi_acp[i].awqos(vtopsw_axi_acp[i].awqos);
	  vs_axi_acp[i].awsize(vtopsw_axi_acp[i].awsize);
	  vs_axi_acp[i].awuser(vtopsw_axi_acp[i].awuser);
	  vs_axi_acp[i].awvalid(vtopsw_axi_acp[i].awvalid);
       endrule
       rule axi_master_handshake3;
            vs_axi_acp[i].rready(vtopsw_axi_acp[i].rready);
       endrule
       rule axi_master_handshake4;
	  vs_axi_acp[i].wid(vtopsw_axi_acp[i].wid);
	  vs_axi_acp[i].wstrb(vtopsw_axi_acp[i].wstrb);
	  vs_axi_acp[i].wdata(vtopsw_axi_acp[i].wdata);
	  vs_axi_acp[i].wlast(vtopsw_axi_acp[i].wlast);
	  vs_axi_acp[i].wvalid(vtopsw_axi_acp[i].wvalid);
       endrule
       rule axi_master_handshake5;
            vs_axi_acp[i].bready(vtopsw_axi_acp[i].bready);
       endrule
       end
    for (Integer i = 0; i < 2; i = i + 1)
        vtops_axi_gp[i] = interface AxiSlaveCommon#(32,6);
          interface Axi3Slave server;
            interface Put req_ar;
                method Action put(Axi3ReadRequest#(32,6) v) if (vs_axi_gp[i].arready() != 0);
                   vtopsw_axi_gp[i].araddr <= v.address;
                   vtopsw_axi_gp[i].arburst <= v.burst;
                   vtopsw_axi_gp[i].arcache <= v.cache;
                   vtopsw_axi_gp[i].arid <= v.id;
                   vtopsw_axi_gp[i].arlen <= v.len;
                   vtopsw_axi_gp[i].arlock <= v.lock;
                   vtopsw_axi_gp[i].arprot <= v.prot;
                   vtopsw_axi_gp[i].arqos <= v.qos;
                   vtopsw_axi_gp[i].arsize <= v.size[1:0];

	           vtopsw_axi_gp[i].arvalid <= 1;
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(Axi3WriteRequest#(32,6) v) if (vs_axi_gp[i].awready() != 0);
                   vtopsw_axi_gp[i].awaddr <= v.address;
                   vtopsw_axi_gp[i].awburst <= v.burst;
                   vtopsw_axi_gp[i].awcache <= v.cache;
                   vtopsw_axi_gp[i].awid <= v.id;
                   vtopsw_axi_gp[i].awlen <= v.len;
                   vtopsw_axi_gp[i].awlock <= v.lock;
                   vtopsw_axi_gp[i].awprot <= v.prot;
                   vtopsw_axi_gp[i].awqos <= v.qos;
                   vtopsw_axi_gp[i].awsize <= v.size[1:0];

	           vtopsw_axi_gp[i].awvalid <= 1;
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(Axi3WriteData#(32,6) v) if (vs_axi_gp[i].wready() != 0);
                   vtopsw_axi_gp[i].wid <= v.id;
                   vtopsw_axi_gp[i].wstrb <= v.byteEnable;
                   vtopsw_axi_gp[i].wdata <= v.data;
                   vtopsw_axi_gp[i].wlast <= v.last;

	           vtopsw_axi_gp[i].wvalid <= 1;
                endmethod
            endinterface
            interface Get resp_read;
                method ActionValue#(Axi3ReadResponse#(32, 6)) get() if (vs_axi_gp[i].rvalid() != 0);
                    Axi3ReadResponse#(32, 6) v;
                    v.id = vs_axi_gp[i].rid();
                    v.resp = vs_axi_gp[i].rresp();
                    v.data = vs_axi_gp[i].rdata();
                    v.last = vs_axi_gp[i].rlast();

	            vtopsw_axi_gp[i].rready <= 1;
                    return v;
                endmethod
	    endinterface
            interface Get resp_b;
                method ActionValue#(Axi3WriteResponse#(6)) get() if (vs_axi_gp[i].bvalid() != 0);
                    Axi3WriteResponse#(6) v;
                    v.id = vs_axi_gp[i].bid();
                    v.resp = vs_axi_gp[i].bresp();

	            vtopsw_axi_gp[i].bready <= 1;
                    return v;
                endmethod
              endinterface
            endinterface
            method aresetn = vs_axi_gp[i].aresetn;
        endinterface;
    for (Integer i = 0; i < 1; i = i + 1)
        vtops_axi_acp[i] = interface AxiSlaveCommon#(64,3);
          interface Axi3Slave server;
            interface Put req_ar;
                method Action put(Axi3ReadRequest#(32,3) v) if (vs_axi_acp[i].arready() != 0);
                   vtopsw_axi_acp[i].araddr <= v.address;
                   vtopsw_axi_acp[i].arburst <= v.burst;
                   vtopsw_axi_acp[i].arcache <= v.cache;
                   vtopsw_axi_acp[i].arid <= v.id;
                   vtopsw_axi_acp[i].arlen <= v.len;
                   vtopsw_axi_acp[i].arlock <= v.lock;
                   vtopsw_axi_acp[i].arprot <= v.prot;
                   vtopsw_axi_acp[i].arqos <= v.qos;
                   vtopsw_axi_acp[i].arsize <= v.size[1:0];

	           vtopsw_axi_acp[i].arvalid <= 1;
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(Axi3WriteRequest#(32,3) v) if (vs_axi_acp[i].awready() != 0);
                   vtopsw_axi_acp[i].awaddr <= v.address;
                   vtopsw_axi_acp[i].awburst <= v.burst;
                   vtopsw_axi_acp[i].awcache <= v.cache;
                   vtopsw_axi_acp[i].awid <= v.id;
                   vtopsw_axi_acp[i].awlen <= v.len;
                   vtopsw_axi_acp[i].awlock <= v.lock;
                   vtopsw_axi_acp[i].awprot <= v.prot;
                   vtopsw_axi_acp[i].awqos <= v.qos;
                   vtopsw_axi_acp[i].awsize <= v.size[1:0];

	           vtopsw_axi_acp[i].awvalid <= 1;
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(Axi3WriteData#(64,3) v) if (vs_axi_acp[i].wready() != 0);
                   vtopsw_axi_acp[i].wid <= v.id;
                   vtopsw_axi_acp[i].wstrb <= v.byteEnable;
                   vtopsw_axi_acp[i].wdata <= v.data;
                   vtopsw_axi_acp[i].wlast <= v.last;

	           vtopsw_axi_acp[i].wvalid <= 1;
                endmethod
            endinterface
            interface Get resp_read;
                method ActionValue#(Axi3ReadResponse#(64, 3)) get() if (vs_axi_acp[i].rvalid() != 0);
                    Axi3ReadResponse#(64, 3) v;
                    v.id = vs_axi_acp[i].rid();
                    v.resp = vs_axi_acp[i].rresp();
                    v.data = vs_axi_acp[i].rdata();
                    v.last = vs_axi_acp[i].rlast();

	            vtopsw_axi_acp[i].rready <= 1;
                    return v;
                endmethod
	    endinterface
            interface Get resp_b;
                method ActionValue#(Axi3WriteResponse#(3)) get() if (vs_axi_acp[i].bvalid() != 0);
                    Axi3WriteResponse#(3) v;
                    v.id = vs_axi_acp[i].bid();
                    v.resp = vs_axi_acp[i].bresp();

	            vtopsw_axi_acp[i].bready <= 1;
                    return v;
                endmethod
              endinterface
            endinterface
            method aresetn = vs_axi_acp[i].aresetn;
        endinterface;
    for (Integer i = 0; i < 4; i = i + 1)
       begin
       rule axi_master_handshake1;
	  vs_axi_hp[i].araddr(vtopsw_axi_hp[i].araddr);
	  vs_axi_hp[i].arburst(vtopsw_axi_hp[i].arburst);
	  vs_axi_hp[i].arcache(vtopsw_axi_hp[i].arcache);
	  vs_axi_hp[i].arid(vtopsw_axi_hp[i].arid);
	  vs_axi_hp[i].arlen(vtopsw_axi_hp[i].arlen);
	  vs_axi_hp[i].arlock(vtopsw_axi_hp[i].arlock);
	  vs_axi_hp[i].arprot(vtopsw_axi_hp[i].arprot);
	  vs_axi_hp[i].arqos(vtopsw_axi_hp[i].arqos);
	  vs_axi_hp[i].arsize(vtopsw_axi_hp[i].arsize);
	  vs_axi_hp[i].arvalid(vtopsw_axi_hp[i].arvalid);
       endrule
       rule axi_master_handshake2;
	  vs_axi_hp[i].awaddr(vtopsw_axi_hp[i].awaddr);
	  vs_axi_hp[i].awburst(vtopsw_axi_hp[i].awburst);
	  vs_axi_hp[i].awcache(vtopsw_axi_hp[i].awcache);
	  vs_axi_hp[i].awid(vtopsw_axi_hp[i].awid);
	  vs_axi_hp[i].awlen(vtopsw_axi_hp[i].awlen);
	  vs_axi_hp[i].awlock(vtopsw_axi_hp[i].awlock);
	  vs_axi_hp[i].awprot(vtopsw_axi_hp[i].awprot);
	  vs_axi_hp[i].awqos(vtopsw_axi_hp[i].awqos);
	  vs_axi_hp[i].awsize(vtopsw_axi_hp[i].awsize);
	  vs_axi_hp[i].awvalid(vtopsw_axi_hp[i].awvalid);
       endrule
       rule axi_master_handshake3;
          vs_axi_hp[i].rready(vtopsw_axi_hp[i].rready);
       endrule
       rule axi_master_handshake4;
	  vs_axi_hp[i].wid(vtopsw_axi_hp[i].wid);
	  vs_axi_hp[i].wstrb(vtopsw_axi_hp[i].wstrb);
	  vs_axi_hp[i].wdata(vtopsw_axi_hp[i].wdata);
	  vs_axi_hp[i].wlast(vtopsw_axi_hp[i].wlast);
	  vs_axi_hp[i].wvalid(vtopsw_axi_hp[i].wvalid);
       endrule
       rule axi_master_handshake5;
            vs_axi_hp[i].bready(vtopsw_axi_hp[i].bready);
       endrule
       rule issuecap;
	  vs_axi_hp[i].rdissuecap1en(0);
	  vs_axi_hp[i].wrissuecap1en(0);
       endrule
       end
    for (Integer i = 0; i < 4; i = i + 1)
        vtops_axi_hp[i] = interface AxiSlaveHighSpeed;
            interface AxiSlaveCommon axi;
            interface Axi3Slave server;
            interface Put req_ar;
                method Action put(Axi3ReadRequest#(32,6) v) if (vs_axi_hp[i].arready() != 0);
                   vtopsw_axi_hp[i].araddr <= v.address;
                   vtopsw_axi_hp[i].arburst <= v.burst;
                   vtopsw_axi_hp[i].arcache <= v.cache;
                   vtopsw_axi_hp[i].arid <= v.id;
                   vtopsw_axi_hp[i].arlen <= v.len;
                   vtopsw_axi_hp[i].arlock <= v.lock;
                   vtopsw_axi_hp[i].arprot <= v.prot;
                   vtopsw_axi_hp[i].arqos <= v.qos;
                   vtopsw_axi_hp[i].arsize <= v.size[1:0];

		   vtopsw_axi_hp[i].arvalid <= 1;
                endmethod
            endinterface
            interface Put req_aw;
                method Action put(Axi3WriteRequest#(32,6) v) if (vs_axi_hp[i].awready() != 0);
                   vtopsw_axi_hp[i].awaddr <= v.address;
                   vtopsw_axi_hp[i].awburst <= v.burst;
                   vtopsw_axi_hp[i].awcache <= v.cache;
                   vtopsw_axi_hp[i].awid <= v.id;
                   vtopsw_axi_hp[i].awlen <= v.len;
                   vtopsw_axi_hp[i].awlock <= v.lock;
                   vtopsw_axi_hp[i].awprot <= v.prot;
                   vtopsw_axi_hp[i].awqos <= v.qos;
                   vtopsw_axi_hp[i].awsize <= v.size[1:0];

	           vtopsw_axi_hp[i].awvalid <= 1;
                endmethod
            endinterface
            interface Put resp_write;
                method Action put(Axi3WriteData#(64,6) v) if (vs_axi_hp[i].wready() != 0);
                   vtopsw_axi_hp[i].wid <= v.id;
                   vtopsw_axi_hp[i].wstrb <= v.byteEnable;
                   vtopsw_axi_hp[i].wdata <= v.data;
                   vtopsw_axi_hp[i].wlast <= v.last;

	           vtopsw_axi_hp[i].wvalid <= 1;
                endmethod
            endinterface
            interface Get resp_read;
                method ActionValue#(Axi3ReadResponse#(64,6)) get() if (vs_axi_hp[i].rvalid() != 0);
                    Axi3ReadResponse#(64, 6) v;
                    v.id = vs_axi_hp[i].rid();
                    v.resp = vs_axi_hp[i].rresp();
                    v.data = vs_axi_hp[i].rdata();
                    v.last = vs_axi_hp[i].rlast();

	            vtopsw_axi_hp[i].rready <= 1;
                    return v;
                endmethod
            endinterface
            interface Get resp_b;
                method ActionValue#(Axi3WriteResponse#(6)) get() if (vs_axi_hp[i].bvalid() != 0);
                    Axi3WriteResponse#(6) v;
                    v.id = vs_axi_hp[i].bid();
                    v.resp = vs_axi_hp[i].bresp();

		    vtopsw_axi_hp[i].bready <= 1;
                    return v;
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
   Wire#(Bit#(1)) fpgaidlenw <- mkDWire(1);
   rule fpgaidle;
      foo.fpgaidlen(fpgaidlenw);
   endrule
   rule misc;
      foo.emiosramintin(0);
      // UG585 "fclkclktrign is currently not supported and must be tied to ground"
      foo.fclkclktrign(0);
   endrule

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
       fpgaidlenw <= v;
    endmethod
    interface Pps7Emiogpio     gpio = foo.emiogpio;
    interface Pps7Irq     irq = foo.irq;
    interface Inout     mio = foo.mio;
    interface Pps7Ps     ps = foo.ps;

    interface AxiMasterCommon m_axi_gp = vtopm_axi_gp;
    interface AxiSlaveCommon s_axi_gp = vtops_axi_gp;
    interface AxiSlaveHighSpeed s_axi_hp = vtops_axi_hp;
    interface AxiSlaveCommon s_axi_acp = vtops_axi_acp[0];
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
    interface Vector#(2, AxiSlaveCommon#(32,6)) s_axi_gp;
    interface Vector#(4, AxiSlaveHighSpeed)   s_axi_hp;
    method Action                             interrupt(Bit#(1) v);
    interface Vector#(4, Clock) fclkclk;
    interface Vector#(4, Reset) fclkreset;
    interface Vector#(2, Pps7Emioi2c)  i2c;
    interface Clock derivedClock;
    interface Reset derivedReset;
endinterface

module mkPS7(PS7);
   // B2C converts a bit to a clock, enabling us to break the apparent cycle
   Vector#(4, B2C) b2c <- replicateM(mkB2C());

   // need the bufg here to reduce clock skew
   module mkBufferedClock#(Integer i)(Clock); let c <- mkClockBUFG(clocked_by b2c[i].c); return c; endmodule
   module mkBufferedReset#(Integer i)(Reset); let r <- mkResetBUFG(clocked_by b2c[i].c, reset_by b2c[i].r); return r; endmodule
   Vector#(4, Clock) fclk <- genWithM(mkBufferedClock);
   Vector#(4, Reset) freset <- genWithM(mkBufferedReset);

   Clock single_clock = fclk[0];
`ifdef ZYNQ_NO_RESET
   freset[0]          = noReset;
`endif
   let single_reset   = freset[0];

   ClockGenerator7Params clockParams = defaultValue;
   // input clock 200MHz for speed grade -2, 100MHz for speed grade -1
   // Muliplying by 6.0 keeps the clock in the required range 600MHz - 1200MHz for either input clock
   clockParams.clkfbout_mult_f       = 6.000;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkfbout_phase     = 0.0;
   clockParams.clkin1_period      = 5.000;
   clockParams.clkout0_divide_f   = 3.000;
   clockParams.clkout0_duty_cycle = 0.5;
   clockParams.clkout0_phase      = 0.0000;
   clockParams.clkout0_buffer     = True;
   clockParams.clkin_buffer = False;
   ClockGenerator7   clockGen <- mkClockGenerator7(clockParams, clocked_by single_clock, reset_by single_reset);
   let derived_clock = clockGen.clkout0;
   let derived_reset_unbuffered <- mkAsyncReset(2, single_reset, derived_clock);
   let derived_reset <- mkResetBUFG(clocked_by derived_clock, reset_by derived_reset_unbuffered);

   PS7LIB ps7 <- mkPS7LIB(single_clock, single_reset, clocked_by single_clock, reset_by single_reset);

   // this rule connects the fclkclk wires to the clock net via B2C
   for (Integer i = 0; i < 4; i = i + 1) begin
      ReadOnly#(Bit#(4)) fclkb;
      ReadOnly#(Bit#(4)) fclkresetnb;
      fclkb       <- mkNullCrossingWire(b2c[i].c, ps7.fclkclk);
      fclkresetnb <- mkNullCrossingWire(b2c[i].c, ps7.fclkresetn);
      rule b2c_rule1;
	 b2c[i].inputclock(fclkb[i]);
	 b2c[i].inputreset(fclkresetnb[i]);
      endrule
   end

   IDELAYCTRL idel <- mkIDELAYCTRL(2, clocked_by fclk[3], reset_by freset[0]);

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
    interface fclkclk = fclk;
    interface fclkreset = freset;
    interface derivedClock = derived_clock;
    interface derivedReset = derived_reset;
    method Action interrupt(Bit#(1) v);
        ps7.irq.f2p({19'b0, v});
    endmethod
    interface Pps7Emioi2c       i2c = ps7.i2c;
endmodule

instance ConnectableWithTrace#(PS7, ConnectalTop#(32,64,ipins,nMasters), BscanTop);
   module mkConnectionWithTrace#(PS7 ps7, ConnectalTop#(32,64,ipins,nMasters) top, BscanTop bscan)(Empty);

      Axi3Slave#(32,32,12) ctrl <- mkAxiDmaSlave(top.slave);
      mkConnectionWithTrace(ps7.m_axi_gp[0].client, ctrl, bscan);

      module mkAxiMasterConnection#(Integer i)(Axi3Master#(32,64,6));
	 let m_axi <- mkAxiDmaMaster(top.masters[i]);
	 mkConnection(m_axi, ps7.s_axi_hp[i].axi.server);
	 return m_axi;
      endmodule
      Vector#(nMasters, Axi3Master#(32,64,6)) m_axis <- genWithM(mkAxiMasterConnection);

   endmodule
endinstance
