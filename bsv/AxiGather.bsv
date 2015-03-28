// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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
import GetPut::*;
import Vector::*;
import PPS7LIB::*;
import AxiMasterSlave::*;

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

module mkAxi3MasterGather#(Pps7Maxigp axiWires)(AxiMasterCommon);
   AxiMasterWires vtopmw <- mkAxiMasterWires;
   rule axi_gp_handshake1;
        axiWires.arready(vtopmw.arready);
   endrule
   rule axi_gp_handshake2;
        axiWires.awready(vtopmw.awready);
   endrule
   rule axi_gp_handshake3;
        axiWires.rid(vtopmw.rid);
        axiWires.rresp(vtopmw.rresp);
        axiWires.rdata(vtopmw.rdata);
        axiWires.rlast(vtopmw.rlast);
        axiWires.rvalid(vtopmw.rvalid);
   endrule
   rule axi_gp_handshake4;
        axiWires.wready(vtopmw.wready);
   endrule
   rule axi_gp_handshake5;
        axiWires.bvalid(vtopmw.bvalid);
        axiWires.bid(vtopmw.bid);
        axiWires.bresp(vtopmw.bresp);
   endrule

   interface Axi3Master client;
        interface Get req_ar;
             method ActionValue#(Axi3ReadRequest#(32,12)) get() if (axiWires.arvalid() != 0);
                 Axi3ReadRequest#(32,12) v;
                 v.address = axiWires.araddr();
                 v.burst = axiWires.arburst();
                 v.cache = axiWires.arcache();
                 v.id = axiWires.arid();
                 v.len = axiWires.arlen();
                 v.lock = axiWires.arlock();
                 v.prot = axiWires.arprot();
                 v.qos = axiWires.arqos();
                 v.size = {0, axiWires.arsize()};

                vtopmw.arready <= 1;

                return v;
            endmethod
        endinterface
        interface Get req_aw;
            method ActionValue#(Axi3WriteRequest#(32,12)) get() if (axiWires.awvalid() != 0);
                Axi3WriteRequest#(32,12) v;
                v.address = axiWires.awaddr();
                v.burst = axiWires.awburst();
                v.cache = axiWires.awcache();
                v.id = axiWires.awid();
                v.len = axiWires.awlen();
                v.lock = axiWires.awlock();
                v.prot = axiWires.awprot();
                v.qos = axiWires.awqos();
                v.size = {0, axiWires.awsize()};

                vtopmw.awready <= 1;
                return v;
           endmethod
        endinterface
        interface Put resp_read;
            method Action put(Axi3ReadResponse#(32, 12) v) if (axiWires.rready() != 0);
                vtopmw.rid <= v.id;
                vtopmw.rresp <= v.resp;
                vtopmw.rdata <= v.data;
                vtopmw.rlast <= v.last;
                vtopmw.rvalid <= 1;
            endmethod
        endinterface
        interface Get resp_write;
            method ActionValue#(Axi3WriteData#(32,12)) get() if (axiWires.wvalid() != 0);
                Axi3WriteData#(32,12) v;
                v.id = axiWires.wid();
                v.byteEnable = axiWires.wstrb();
                v.data = axiWires.wdata();
                v.last = axiWires.wlast();

                vtopmw.wready <= 1;
                return v;
            endmethod
        endinterface
        interface Put resp_b;
            method Action put(Axi3WriteResponse#(12) v) if (axiWires.bready() != 0);
                vtopmw.bvalid <= 1;
                vtopmw.bid    <= v.id;
                vtopmw.bresp  <= v.resp;
            endmethod
        endinterface
    endinterface
    method aresetn = axiWires.aresetn;
endmodule

module mkAxi3SlaveGather#(Pps7Saxigp axiWires)(AxiSlaveCommon#(32,6));
    AxiSlaveWires#(32,6) vtopsw <- mkAxiSlaveWires;
    rule axi_gp_handshake11;
          axiWires.araddr(vtopsw.araddr);
          axiWires.arburst(vtopsw.arburst);
          axiWires.arcache(vtopsw.arcache);
          axiWires.arid(vtopsw.arid);
          axiWires.arlen(vtopsw.arlen);
          axiWires.arlock(vtopsw.arlock);
          axiWires.arprot(vtopsw.arprot);
          axiWires.arqos(vtopsw.arqos);
          axiWires.arsize(vtopsw.arsize);
          axiWires.arvalid(vtopsw.arvalid);
    endrule
    rule axi_gp_handshake12;
          axiWires.awaddr(vtopsw.awaddr);
          axiWires.awburst(vtopsw.awburst);
          axiWires.awcache(vtopsw.awcache);
          axiWires.awid(vtopsw.awid);
          axiWires.awlen(vtopsw.awlen);
          axiWires.awlock(vtopsw.awlock);
          axiWires.awprot(vtopsw.awprot);
          axiWires.awqos(vtopsw.awqos);
          axiWires.awsize(vtopsw.awsize);
          axiWires.awvalid(vtopsw.awvalid);
    endrule
    rule axi_gp_handshake13;
         axiWires.rready(vtopsw.rready);
    endrule
    rule axi_gp_handshake14;
          axiWires.wid(vtopsw.wid);
          axiWires.wstrb(vtopsw.wstrb);
          axiWires.wdata(vtopsw.wdata);
          axiWires.wlast(vtopsw.wlast);
          axiWires.wvalid(vtopsw.wvalid);
    endrule
    rule axi_gp_handshake15;
         axiWires.bready(vtopsw.bready);
    endrule
    interface Axi3Slave server;
    interface Put req_ar;
        method Action put(Axi3ReadRequest#(32,6) v) if (axiWires.arready() != 0);
           vtopsw.araddr <= v.address;
           vtopsw.arburst <= v.burst;
           vtopsw.arcache <= v.cache;
           vtopsw.arid <= v.id;
           vtopsw.arlen <= v.len;
           vtopsw.arlock <= v.lock;
           vtopsw.arprot <= v.prot;
           vtopsw.arqos <= v.qos;
           vtopsw.arsize <= v.size[1:0];

           vtopsw.arvalid <= 1;
        endmethod
    endinterface
    interface Put req_aw;
        method Action put(Axi3WriteRequest#(32,6) v) if (axiWires.awready() != 0);
           vtopsw.awaddr <= v.address;
           vtopsw.awburst <= v.burst;
           vtopsw.awcache <= v.cache;
           vtopsw.awid <= v.id;
           vtopsw.awlen <= v.len;
           vtopsw.awlock <= v.lock;
           vtopsw.awprot <= v.prot;
           vtopsw.awqos <= v.qos;
           vtopsw.awsize <= v.size[1:0];

           vtopsw.awvalid <= 1;
        endmethod
    endinterface
    interface Put resp_write;
        method Action put(Axi3WriteData#(32,6) v) if (axiWires.wready() != 0);
           vtopsw.wid <= v.id;
           vtopsw.wstrb <= v.byteEnable;
           vtopsw.wdata <= v.data;
           vtopsw.wlast <= v.last;

           vtopsw.wvalid <= 1;
        endmethod
    endinterface
    interface Get resp_read;
        method ActionValue#(Axi3ReadResponse#(32,6)) get() if (axiWires.rvalid() != 0);
            Axi3ReadResponse#(32, 6) v;
            v.id = axiWires.rid();
            v.resp = axiWires.rresp();
            v.data = axiWires.rdata();
            v.last = axiWires.rlast();

            vtopsw.rready <= 1;
            return v;
        endmethod
            endinterface
    interface Get resp_b;
        method ActionValue#(Axi3WriteResponse#(6)) get() if (axiWires.bvalid() != 0);
            Axi3WriteResponse#(6) v;
            v.id = axiWires.bid();
            v.resp = axiWires.bresp();

            vtopsw.bready <= 1;
            return v;
        endmethod
      endinterface
    endinterface
    method aresetn = axiWires.aresetn;
endmodule

module mkAxi3SlaveGather64#(Pps7Saxiacp axiWires)(AxiSlaveCommon#(64,3));
    AxiSlaveWires#(64,3) vtopsw <- mkAxiSlaveWires;
    rule axi_acp_handshake1;
          axiWires.araddr(vtopsw.araddr);
          axiWires.arburst(vtopsw.arburst);
          axiWires.arcache(vtopsw.arcache);
          axiWires.arid(vtopsw.arid);
          axiWires.arlen(vtopsw.arlen);
          axiWires.arlock(vtopsw.arlock);
          axiWires.arprot(vtopsw.arprot);
          axiWires.arqos(vtopsw.arqos);
          axiWires.arsize(vtopsw.arsize);
          axiWires.aruser(vtopsw.aruser);
          axiWires.arvalid(vtopsw.arvalid);
    endrule
    rule axi_acp_handshake2;
          axiWires.awaddr(vtopsw.awaddr);
          axiWires.awburst(vtopsw.awburst);
          axiWires.awcache(vtopsw.awcache);
          axiWires.awid(vtopsw.awid);
          axiWires.awlen(vtopsw.awlen);
          axiWires.awlock(vtopsw.awlock);
          axiWires.awprot(vtopsw.awprot);
          axiWires.awqos(vtopsw.awqos);
          axiWires.awsize(vtopsw.awsize);
          axiWires.awuser(vtopsw.awuser);
          axiWires.awvalid(vtopsw.awvalid);
    endrule
    rule axi_acp_handshake3;
         axiWires.rready(vtopsw.rready);
    endrule
    rule axi_acp_handshake4;
          axiWires.wid(vtopsw.wid);
          axiWires.wstrb(vtopsw.wstrb);
          axiWires.wdata(vtopsw.wdata);
          axiWires.wlast(vtopsw.wlast);
          axiWires.wvalid(vtopsw.wvalid);
    endrule
    rule axi_acp_handshake5;
         axiWires.bready(vtopsw.bready);
    endrule
    interface Axi3Slave server;
    interface Put req_ar;
        method Action put(Axi3ReadRequest#(32,3) v) if (axiWires.arready() != 0);
           vtopsw.araddr <= v.address;
           vtopsw.arburst <= v.burst;
           vtopsw.arcache <= v.cache;
           vtopsw.arid <= v.id;
           vtopsw.arlen <= v.len;
           vtopsw.arlock <= v.lock;
           vtopsw.arprot <= v.prot;
           vtopsw.arqos <= v.qos;
           vtopsw.arsize <= v.size[1:0];

           vtopsw.arvalid <= 1;
        endmethod
    endinterface
    interface Put req_aw;
        method Action put(Axi3WriteRequest#(32,3) v) if (axiWires.awready() != 0);
           vtopsw.awaddr <= v.address;
           vtopsw.awburst <= v.burst;
           vtopsw.awcache <= v.cache;
           vtopsw.awid <= v.id;
           vtopsw.awlen <= v.len;
           vtopsw.awlock <= v.lock;
           vtopsw.awprot <= v.prot;
           vtopsw.awqos <= v.qos;
           vtopsw.awsize <= v.size[1:0];

           vtopsw.awvalid <= 1;
        endmethod
    endinterface
    interface Put resp_write;
        method Action put(Axi3WriteData#(64,3) v) if (axiWires.wready() != 0);
           vtopsw.wid <= v.id;
           vtopsw.wstrb <= v.byteEnable;
           vtopsw.wdata <= v.data;
           vtopsw.wlast <= v.last;

           vtopsw.wvalid <= 1;
        endmethod
    endinterface
    interface Get resp_read;
        method ActionValue#(Axi3ReadResponse#(64, 3)) get() if (axiWires.rvalid() != 0);
            Axi3ReadResponse#(64, 3) v;
            v.id = axiWires.rid();
            v.resp = axiWires.rresp();
            v.data = axiWires.rdata();
            v.last = axiWires.rlast();

            vtopsw.rready <= 1;
            return v;
        endmethod
         endinterface
    interface Get resp_b;
        method ActionValue#(Axi3WriteResponse#(3)) get() if (axiWires.bvalid() != 0);
            Axi3WriteResponse#(3) v;
            v.id = axiWires.bid();
            v.resp = axiWires.bresp();

            vtopsw.bready <= 1;
            return v;
        endmethod
     endinterface
     endinterface
     method aresetn = axiWires.aresetn;
endmodule

module mkAxiSlaveHighSpeedGather#(Pps7Saxihp axiWires)(AxiSlaveHighSpeed);
    AxiSlaveWires#(64,6) vtopsw <- mkAxiSlaveWires;
    rule axi_hp_handshake1;
          axiWires.araddr(vtopsw.araddr);
          axiWires.arburst(vtopsw.arburst);
          axiWires.arcache(vtopsw.arcache);
          axiWires.arid(vtopsw.arid);
          axiWires.arlen(vtopsw.arlen);
          axiWires.arlock(vtopsw.arlock);
          axiWires.arprot(vtopsw.arprot);
          axiWires.arqos(vtopsw.arqos);
          axiWires.arsize(vtopsw.arsize);
          axiWires.arvalid(vtopsw.arvalid);
    endrule
    rule axi_hp_handshake2;
          axiWires.awaddr(vtopsw.awaddr);
          axiWires.awburst(vtopsw.awburst);
          axiWires.awcache(vtopsw.awcache);
          axiWires.awid(vtopsw.awid);
          axiWires.awlen(vtopsw.awlen);
          axiWires.awlock(vtopsw.awlock);
          axiWires.awprot(vtopsw.awprot);
          axiWires.awqos(vtopsw.awqos);
          axiWires.awsize(vtopsw.awsize);
          axiWires.awvalid(vtopsw.awvalid);
    endrule
    rule axi_hp_handshake3;
       axiWires.rready(vtopsw.rready);
    endrule
    rule axi_hp_handshake4;
          axiWires.wid(vtopsw.wid);
          axiWires.wstrb(vtopsw.wstrb);
          axiWires.wdata(vtopsw.wdata);
          axiWires.wlast(vtopsw.wlast);
          axiWires.wvalid(vtopsw.wvalid);
    endrule
    rule axi_hp_handshake5;
         axiWires.bready(vtopsw.bready);
    endrule
    rule issuecap;
          axiWires.rdissuecap1en(0);
          axiWires.wrissuecap1en(0);
    endrule
    interface AxiSlaveCommon axi;
    interface Axi3Slave server;
    interface Put req_ar;
        method Action put(Axi3ReadRequest#(32,6) v) if (axiWires.arready() != 0);
           vtopsw.araddr <= v.address;
           vtopsw.arburst <= v.burst;
           vtopsw.arcache <= v.cache;
           vtopsw.arid <= v.id;
           vtopsw.arlen <= v.len;
           vtopsw.arlock <= v.lock;
           vtopsw.arprot <= v.prot;
           vtopsw.arqos <= v.qos;
           vtopsw.arsize <= v.size[1:0];

                vtopsw.arvalid <= 1;
        endmethod
    endinterface
    interface Put req_aw;
        method Action put(Axi3WriteRequest#(32,6) v) if (axiWires.awready() != 0);
           vtopsw.awaddr <= v.address;
           vtopsw.awburst <= v.burst;
           vtopsw.awcache <= v.cache;
           vtopsw.awid <= v.id;
           vtopsw.awlen <= v.len;
           vtopsw.awlock <= v.lock;
           vtopsw.awprot <= v.prot;
           vtopsw.awqos <= v.qos;
           vtopsw.awsize <= v.size[1:0];

           vtopsw.awvalid <= 1;
        endmethod
    endinterface
    interface Put resp_write;
        method Action put(Axi3WriteData#(64,6) v) if (axiWires.wready() != 0);
           vtopsw.wid <= v.id;
           vtopsw.wstrb <= v.byteEnable;
           vtopsw.wdata <= v.data;
           vtopsw.wlast <= v.last;

           vtopsw.wvalid <= 1;
        endmethod
    endinterface
    interface Get resp_read;
        method ActionValue#(Axi3ReadResponse#(64,6)) get() if (axiWires.rvalid() != 0);
            Axi3ReadResponse#(64, 6) v;
            v.id = axiWires.rid();
            v.resp = axiWires.rresp();
            v.data = axiWires.rdata();
            v.last = axiWires.rlast();

            vtopsw.rready <= 1;
            return v;
        endmethod
    endinterface
    interface Get resp_b;
        method ActionValue#(Axi3WriteResponse#(6)) get() if (axiWires.bvalid() != 0);
            Axi3WriteResponse#(6) v;
            v.id = axiWires.bid();
            v.resp = axiWires.bresp();

            vtopsw.bready <= 1;
            return v;
        endmethod
      endinterface: resp_b
    endinterface: server
    method aresetn = axiWires.aresetn;
    endinterface: axi
    method racount = axiWires.racount;
    method rcount = axiWires.rcount;
    method rdissuecap1en = axiWires.rdissuecap1en;
    method wacount = axiWires.wacount;
    method wcount = axiWires.wcount;
    method wrissuecap1en = axiWires.wrissuecap1en;
endmodule
