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
import AxiBits::*;

interface AxiMasterCommon#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth);
    method Bit#(1)            aresetn();
    interface Axi3Master#(addrWidth,dataWidth,tagWidth) client;
endinterface

interface AxiSlaveCommon#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth, type extraType);
    method Bit#(1)            aresetn();
    interface Axi3Slave#(addrWidth,dataWidth,tagWidth) server;
    interface extraType   extra;
endinterface

interface AxiMasterWires#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth);
   interface Wire#(Bit#(1)) arready;
   interface Wire#(Bit#(1)) awready;
   interface Wire#(Bit#(1)) rvalid;
   interface Wire#(Bit#(1)) wready;
   interface Wire#(Bit#(1)) bvalid;

   interface Wire#(Bit#(tagWidth)) rid;
   interface Wire#(Bit#(2))  rresp;
   interface Wire#(Bit#(dataWidth)) rdata;
   interface Wire#(Bit#(1))  rlast;
   interface Wire#(Bit#(tagWidth)) bid;
   interface Wire#(Bit#(2)) bresp;
endinterface

interface AxiSlaveWires#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth);
   interface Wire#(Bit#(addrWidth)) araddr;
   interface Wire#(Bit#(2)) arburst;
   interface Wire#(Bit#(4)) arcache;
   interface Wire#(Bit#(tagWidth)) arid;
   interface Wire#(Bit#(4)) arlen;
   interface Wire#(Bit#(2)) arlock;
   interface Wire#(Bit#(3)) arprot;
   interface Wire#(Bit#(4)) arqos;
   interface Wire#(Bit#(2)) arsize;
   interface Wire#(Bit#(1)) arvalid;
   interface Wire#(Bit#(addrWidth)) awaddr;
   interface Wire#(Bit#(2)) awburst;
   interface Wire#(Bit#(4)) awcache;
   interface Wire#(Bit#(tagWidth)) awid;
   interface Wire#(Bit#(4)) awlen;
   interface Wire#(Bit#(2)) awlock;
   interface Wire#(Bit#(3)) awprot;
   interface Wire#(Bit#(4)) awqos;
   interface Wire#(Bit#(2)) awsize;
   interface Wire#(Bit#(1)) awvalid;
   interface Wire#(Bit#(1)) rready;
   interface Wire#(Bit#(tagWidth)) wid;
   interface Wire#(Bit#(TDiv#(dataWidth,8))) wstrb;
   interface Wire#(Bit#(dataWidth)) wdata;
   interface Wire#(Bit#(1)) wlast;
   interface Wire#(Bit#(1)) wvalid;
   interface Wire#(Bit#(1)) bready;
endinterface

module mkAxiMasterWires(AxiMasterWires#(addrWidth, dataWidth, tagWidth));
   Vector#(6, Wire#(Bit#(1))) wires <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(dataWidth))) datawires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(tagWidth))) idwires <- replicateM(mkDWire(0));
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

module mkAxiSlaveWires(AxiSlaveWires#(addrWidth, dataWidth, tagWidth));
   Vector#(5, Wire#(Bit#(1))) wires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(addrWidth))) addrwires <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(dataWidth))) datawires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(2))) burstwires <- replicateM(mkDWire(0));
   Vector#(2, Wire#(Bit#(4))) cachewires <- replicateM(mkDWire(0));
   Vector#(3, Wire#(Bit#(tagWidth))) idwires <- replicateM(mkDWire(0));
   Vector#(1, Wire#(Bit#(TDiv#(dataWidth,8)))) strbwires <- replicateM(mkDWire(0));
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
   interface Wire awvalid = validwires[1];

   interface Wire rready = readywires[0];
   interface Wire wid = idwires[2];
   interface Wire wstrb = strbwires[0];
   interface Wire wdata = datawires[0];
   interface Wire wlast = lastwires[0];
   interface Wire wvalid = validwires[2];
   interface Wire bready = readywires[1];
endmodule

module mkAxi3MasterGather#(AxiMasterBits#(addrWidth, dataWidth, tagWidth, Empty) axiWires)(AxiMasterCommon#(addrWidth, dataWidth, tagWidth));
//provisos(Div#(dataWidth, 8, 4));
   AxiMasterWires#(addrWidth, dataWidth, tagWidth) vtopmw <- mkAxiMasterWires;
   rule handshake1;
        axiWires.arready(vtopmw.arready);
   endrule
   rule handshake2;
        axiWires.awready(vtopmw.awready);
   endrule
   rule handshake3;
        axiWires.rid(vtopmw.rid);
        axiWires.rresp(vtopmw.rresp);
        axiWires.rdata(vtopmw.rdata);
        axiWires.rlast(vtopmw.rlast);
        axiWires.rvalid(vtopmw.rvalid);
   endrule
   rule handshake4;
        axiWires.wready(vtopmw.wready);
   endrule
   rule handshake5;
        axiWires.bvalid(vtopmw.bvalid);
        axiWires.bid(vtopmw.bid);
        axiWires.bresp(vtopmw.bresp);
   endrule

   interface Axi3Master client;
        interface Get req_ar;
             method ActionValue#(Axi3ReadRequest#(addrWidth,tagWidth)) get() if (axiWires.arvalid() != 0);
                 Axi3ReadRequest#(addrWidth,tagWidth) v;
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
            method ActionValue#(Axi3WriteRequest#(addrWidth,tagWidth)) get() if (axiWires.awvalid() != 0);
                Axi3WriteRequest#(addrWidth,tagWidth) v;
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
            method Action put(Axi3ReadResponse#(dataWidth, tagWidth) v) if (axiWires.rready() != 0);
                vtopmw.rid <= v.id;
                vtopmw.rresp <= v.resp;
                vtopmw.rdata <= v.data;
                vtopmw.rlast <= v.last;
                vtopmw.rvalid <= 1;
            endmethod
        endinterface
        interface Get resp_write;
            method ActionValue#(Axi3WriteData#(dataWidth,tagWidth)) get() if (axiWires.wvalid() != 0);
                Axi3WriteData#(dataWidth,tagWidth) v;
                v.id = axiWires.wid();
                v.byteEnable = axiWires.wstrb();
                v.data = axiWires.wdata();
                v.last = axiWires.wlast();

                vtopmw.wready <= 1;
                return v;
            endmethod
        endinterface
        interface Put resp_b;
            method Action put(Axi3WriteResponse#(tagWidth) v) if (axiWires.bready() != 0);
                vtopmw.bvalid <= 1;
                vtopmw.bid    <= v.id;
                vtopmw.bresp  <= v.resp;
            endmethod
        endinterface
    endinterface
    method aresetn = axiWires.aresetn;
endmodule

module mkAxi3SlaveGather#(AxiSlaveBits#(addrWidth, dataWidth, tagWidth,
    extraType) axiWires)(AxiSlaveCommon#(addrWidth, dataWidth,tagWidth,extraType));
    AxiSlaveWires#(addrWidth,dataWidth,tagWidth) vtopsw <- mkAxiSlaveWires;
    rule handshake1;
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
    rule handshake2;
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
    rule handshake3;
         axiWires.rready(vtopsw.rready);
    endrule
    rule handshake4;
          axiWires.wid(vtopsw.wid);
          axiWires.wstrb(vtopsw.wstrb);
          axiWires.wdata(vtopsw.wdata);
          axiWires.wlast(vtopsw.wlast);
          axiWires.wvalid(vtopsw.wvalid);
    endrule
    rule handshake5;
         axiWires.bready(vtopsw.bready);
    endrule
    interface Axi3Slave server;
    interface Put req_ar;
        method Action put(Axi3ReadRequest#(addrWidth,tagWidth) v) if (axiWires.arready() != 0);
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
        method Action put(Axi3WriteRequest#(addrWidth,tagWidth) v) if (axiWires.awready() != 0);
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
        method Action put(Axi3WriteData#(dataWidth,tagWidth) v) if (axiWires.wready() != 0);
           vtopsw.wid <= v.id;
           vtopsw.wstrb <= v.byteEnable;
           vtopsw.wdata <= v.data;
           vtopsw.wlast <= v.last;

           vtopsw.wvalid <= 1;
        endmethod
    endinterface
    interface Get resp_read;
        method ActionValue#(Axi3ReadResponse#(dataWidth, tagWidth)) get() if (axiWires.rvalid() != 0);
            Axi3ReadResponse#(dataWidth, tagWidth) v;
            v.id = axiWires.rid();
            v.resp = axiWires.rresp();
            v.data = axiWires.rdata();
            v.last = axiWires.rlast();

            vtopsw.rready <= 1;
            return v;
        endmethod
         endinterface
    interface Get resp_b;
        method ActionValue#(Axi3WriteResponse#(tagWidth)) get() if (axiWires.bvalid() != 0);
            Axi3WriteResponse#(tagWidth) v;
            v.id = axiWires.bid();
            v.resp = axiWires.bresp();

            vtopsw.bready <= 1;
            return v;
        endmethod
     endinterface
     endinterface
     interface extra = axiWires.extra;
     method aresetn = axiWires.aresetn;
endmodule
