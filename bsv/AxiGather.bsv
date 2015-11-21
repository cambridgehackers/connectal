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
import Axi4MasterSlave::*;
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

interface Axi4SlaveCommon#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth, type extraType);
    method Bit#(1)            aresetn();
    interface Axi4Slave#(addrWidth,dataWidth,tagWidth) server;
    interface extraType   extra;
endinterface

module mkAxi3MasterGather#(AxiMasterBits#(addrWidth, dataWidth, tagWidth, Empty) axiWires)(AxiMasterCommon#(addrWidth, dataWidth, tagWidth));
   Wire#(Bit#(1)) arready <- mkDWire(0);
   Wire#(Bit#(1)) awready <- mkDWire(0);
   Wire#(Bit#(1)) rvalid <- mkDWire(0);
   Wire#(Bit#(1)) wready <- mkDWire(0);
   Wire#(Bit#(tagWidth)) rid <- mkDWire(0);
   Wire#(Bit#(2)) rresp <- mkDWire(0);
   Wire#(Bit#(dataWidth)) rdata <- mkDWire(0);
   Wire#(Bit#(1)) rlast <- mkDWire(0);
   Wire#(Bit#(1)) bvalid <- mkDWire(0);
   Wire#(Bit#(tagWidth)) bid <- mkDWire(0);
   Wire#(Bit#(2)) bresp <- mkDWire(0);

   rule handshake1;
        axiWires.arready(arready);
   endrule
   rule handshake2;
        axiWires.awready(awready);
   endrule
   rule handshake3;
        axiWires.rid(rid);
        axiWires.rresp(rresp);
        axiWires.rdata(rdata);
        axiWires.rlast(rlast);
        axiWires.rvalid(rvalid);
   endrule
   rule handshake4;
        axiWires.wready(wready);
   endrule
   rule handshake5;
        axiWires.bvalid(bvalid);
        axiWires.bid(bid);
        axiWires.bresp(bresp);
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

                arready <= 1;
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

                awready <= 1;
                return v;
           endmethod
        endinterface
        interface Put resp_read;
            method Action put(Axi3ReadResponse#(dataWidth, tagWidth) v) if (axiWires.rready() != 0);
                rid <= v.id;
                rresp <= v.resp;
                rdata <= v.data;
                rlast <= v.last;
                rvalid <= 1;
            endmethod
        endinterface
        interface Get resp_write;
            method ActionValue#(Axi3WriteData#(dataWidth,tagWidth)) get() if (axiWires.wvalid() != 0);
                Axi3WriteData#(dataWidth,tagWidth) v;
                v.id = axiWires.wid();
                v.byteEnable = axiWires.wstrb();
                v.data = axiWires.wdata();
                v.last = axiWires.wlast();

                wready <= 1;
                return v;
            endmethod
        endinterface
        interface Put resp_b;
            method Action put(Axi3WriteResponse#(tagWidth) v) if (axiWires.bready() != 0);
                bvalid <= 1;
                bid    <= v.id;
                bresp  <= v.resp;
            endmethod
        endinterface
    endinterface
    method aresetn = axiWires.aresetn;
endmodule

module mkAxi3SlaveGather#(AxiSlaveBits#(addrWidth, dataWidth, tagWidth,
    extraType) axiWires)(AxiSlaveCommon#(addrWidth, dataWidth,tagWidth,extraType));
    Wire#(Bit#(addrWidth)) araddr <- mkDWire(0);
    Wire#(Bit#(2)) arburst <- mkDWire(0);
    Wire#(Bit#(4)) arcache <- mkDWire(0);
    Wire#(Bit#(tagWidth)) arid <- mkDWire(0);
    Wire#(Bit#(4)) arlen <- mkDWire(0);
    Wire#(Bit#(2)) arlock <- mkDWire(0);
    Wire#(Bit#(3)) arprot <- mkDWire(0);
    Wire#(Bit#(4)) arqos <- mkDWire(0);
    Wire#(Bit#(2)) arsize <- mkDWire(0);
    Wire#(Bit#(1)) arvalid <- mkDWire(0);

    Wire#(Bit#(addrWidth)) awaddr <- mkDWire(0);
    Wire#(Bit#(2)) awburst <- mkDWire(0);
    Wire#(Bit#(4)) awcache <- mkDWire(0);
    Wire#(Bit#(tagWidth)) awid <- mkDWire(0);
    Wire#(Bit#(4)) awlen <- mkDWire(0);
    Wire#(Bit#(2)) awlock <- mkDWire(0);
    Wire#(Bit#(3)) awprot <- mkDWire(0);
    Wire#(Bit#(4)) awqos <- mkDWire(0);
    Wire#(Bit#(2)) awsize <- mkDWire(0);
    Wire#(Bit#(1)) awvalid <- mkDWire(0);

    Wire#(Bit#(1)) rready <- mkDWire(0);
    Wire#(Bit#(tagWidth)) wid <- mkDWire(0);
    Wire#(Bit#(TDiv#(dataWidth,8))) wstrb <- mkDWire(0);
    Wire#(Bit#(dataWidth)) wdata <- mkDWire(0);
    Wire#(Bit#(1)) wlast <- mkDWire(0);
    Wire#(Bit#(1)) wvalid <- mkDWire(0);
    Wire#(Bit#(1)) bready <- mkDWire(0);

    rule handshake1;
          axiWires.araddr(araddr);
          axiWires.arburst(arburst);
          axiWires.arcache(arcache);
          axiWires.arid(arid);
          axiWires.arlen(arlen);
          axiWires.arlock(arlock);
          axiWires.arprot(arprot);
          axiWires.arqos(arqos);
          axiWires.arsize(arsize);
          axiWires.arvalid(arvalid);
    endrule
    rule handshake2;
          axiWires.awaddr(awaddr);
          axiWires.awburst(awburst);
          axiWires.awcache(awcache);
          axiWires.awid(awid);
          axiWires.awlen(awlen);
          axiWires.awlock(awlock);
          axiWires.awprot(awprot);
          axiWires.awqos(awqos);
          axiWires.awsize(awsize);
          axiWires.awvalid(awvalid);
    endrule
    rule handshake3;
         axiWires.rready(rready);
    endrule
    rule handshake4;
          axiWires.wid(wid);
          axiWires.wstrb(wstrb);
          axiWires.wdata(wdata);
          axiWires.wlast(wlast);
          axiWires.wvalid(wvalid);
    endrule
    rule handshake5;
         axiWires.bready(bready);
    endrule
    interface Axi3Slave server;
    interface Put req_ar;
        method Action put(Axi3ReadRequest#(addrWidth,tagWidth) v) if (axiWires.arready() != 0);
           araddr <= v.address;
           arburst <= v.burst;
           arcache <= v.cache;
           arid <= v.id;
           arlen <= v.len;
           arlock <= v.lock;
           arprot <= v.prot;
           arqos <= v.qos;
           arsize <= v.size[1:0];

           arvalid <= 1;
        endmethod
    endinterface
    interface Put req_aw;
        method Action put(Axi3WriteRequest#(addrWidth,tagWidth) v) if (axiWires.awready() != 0);
           awaddr <= v.address;
           awburst <= v.burst;
           awcache <= v.cache;
           awid <= v.id;
           awlen <= v.len;
           awlock <= v.lock;
           awprot <= v.prot;
           awqos <= v.qos;
           awsize <= v.size[1:0];

           awvalid <= 1;
        endmethod
    endinterface
    interface Put resp_write;
        method Action put(Axi3WriteData#(dataWidth,tagWidth) v) if (axiWires.wready() != 0);
           wid <= v.id;
           wstrb <= v.byteEnable;
           wdata <= v.data;
           wlast <= v.last;

           wvalid <= 1;
        endmethod
    endinterface
    interface Get resp_read;
        method ActionValue#(Axi3ReadResponse#(dataWidth, tagWidth)) get() if (axiWires.rvalid() != 0);
            Axi3ReadResponse#(dataWidth, tagWidth) v;
            v.id = axiWires.rid();
            v.resp = axiWires.rresp();
            v.data = axiWires.rdata();
            v.last = axiWires.rlast();

            rready <= 1;
            return v;
        endmethod
         endinterface
    interface Get resp_b;
        method ActionValue#(Axi3WriteResponse#(tagWidth)) get() if (axiWires.bvalid() != 0);
            Axi3WriteResponse#(tagWidth) v;
            v.id = axiWires.bid();
            v.resp = axiWires.bresp();

            bready <= 1;
            return v;
        endmethod
     endinterface
     endinterface
     interface extra = axiWires.extra;
     method aresetn = axiWires.aresetn;
endmodule

module mkAxi4SlaveGather#(Axi4SlaveBits#(addrWidth, dataWidth, tagWidth, extraType) axiWires)
   (Axi4SlaveCommon#(addrWidth, dataWidth,tagWidth,extraType));
    Wire#(Bit#(addrWidth)) araddr <- mkDWire(0);
    Wire#(Bit#(2)) arburst <- mkDWire(0);
    Wire#(Bit#(4)) arcache <- mkDWire(0);
    Wire#(Bit#(tagWidth)) arid <- mkDWire(0);
    Wire#(Bit#(8)) arlen <- mkDWire(0);
    Wire#(Bit#(2)) arlock <- mkDWire(0);
    Wire#(Bit#(3)) arprot <- mkDWire(0);
    Wire#(Bit#(4)) arqos <- mkDWire(0);
    Wire#(Bit#(3)) arsize <- mkDWire(0);
    Wire#(Bit#(1)) arvalid <- mkDWire(0);

    Wire#(Bit#(addrWidth)) awaddr <- mkDWire(0);
    Wire#(Bit#(2)) awburst <- mkDWire(0);
    Wire#(Bit#(4)) awcache <- mkDWire(0);
    Wire#(Bit#(tagWidth)) awid <- mkDWire(0);
    Wire#(Bit#(8)) awlen <- mkDWire(0);
    Wire#(Bit#(2)) awlock <- mkDWire(0);
    Wire#(Bit#(3)) awprot <- mkDWire(0);
    Wire#(Bit#(4)) awqos <- mkDWire(0);
    Wire#(Bit#(3)) awsize <- mkDWire(0);
    Wire#(Bit#(1)) awvalid <- mkDWire(0);

    Wire#(Bit#(1)) rready <- mkDWire(0);
    Wire#(Bit#(tagWidth)) wid <- mkDWire(0);
    Wire#(Bit#(TDiv#(dataWidth,8))) wstrb <- mkDWire(0);
    Wire#(Bit#(dataWidth)) wdata <- mkDWire(0);
    Wire#(Bit#(1)) wlast <- mkDWire(0);
    Wire#(Bit#(1)) wvalid <- mkDWire(0);
    Wire#(Bit#(1)) bready <- mkDWire(0);

    rule handshake1;
          axiWires.araddr(araddr);
          axiWires.arburst(arburst);
          axiWires.arcache(arcache);
          axiWires.arid(arid);
          axiWires.arlen(arlen);
          axiWires.arlock(arlock);
          axiWires.arprot(arprot);
          axiWires.arqos(arqos);
          axiWires.arsize(arsize);
          axiWires.arvalid(arvalid);
    endrule
    rule handshake2;
          axiWires.awaddr(awaddr);
          axiWires.awburst(awburst);
          axiWires.awcache(awcache);
          axiWires.awid(awid);
          axiWires.awlen(awlen);
          axiWires.awlock(awlock);
          axiWires.awprot(awprot);
          axiWires.awqos(awqos);
          axiWires.awsize(awsize);
          axiWires.awvalid(awvalid);
    endrule
    rule handshake3;
         axiWires.rready(rready);
    endrule
    rule handshake4;
          axiWires.wid(wid);
          axiWires.wstrb(wstrb);
          axiWires.wdata(wdata);
          axiWires.wlast(wlast);
          axiWires.wvalid(wvalid);
    endrule
    rule handshake5;
         axiWires.bready(bready);
    endrule
    interface Axi4Slave server;
    interface Put req_ar;
        method Action put(Axi4ReadRequest#(addrWidth,tagWidth) v) if (axiWires.arready() != 0);
           araddr <= v.address;
           arburst <= v.burst;
           arcache <= v.cache;
           arid <= v.id;
           arlen <= v.len;
           arlock <= v.lock;
           arprot <= v.prot;
           arqos <= v.qos;
           arsize <= v.size;

           arvalid <= 1;
        endmethod
    endinterface
    interface Put req_aw;
        method Action put(Axi4WriteRequest#(addrWidth,tagWidth) v) if (axiWires.awready() != 0);
           awaddr <= v.address;
           awburst <= v.burst;
           awcache <= v.cache;
           awid <= v.id;
           awlen <= v.len;
           awlock <= v.lock;
           awprot <= v.prot;
           awqos <= v.qos;
           awsize <= v.size;

           awvalid <= 1;
        endmethod
    endinterface
    interface Put resp_write;
        method Action put(Axi4WriteData#(dataWidth,tagWidth) v) if (axiWires.wready() != 0);
           wid <= v.id;
           wstrb <= v.byteEnable;
           wdata <= v.data;
           wlast <= v.last;

           wvalid <= 1;
        endmethod
    endinterface
    interface Get resp_read;
        method ActionValue#(Axi4ReadResponse#(dataWidth, tagWidth)) get() if (axiWires.rvalid() != 0);
            Axi4ReadResponse#(dataWidth, tagWidth) v;
            v.id = axiWires.rid();
            v.resp = axiWires.rresp();
            v.data = axiWires.rdata();
            v.last = axiWires.rlast();

            rready <= 1;
            return v;
        endmethod
         endinterface
    interface Get resp_b;
        method ActionValue#(Axi4WriteResponse#(tagWidth)) get() if (axiWires.bvalid() != 0);
            Axi4WriteResponse#(tagWidth) v;
            v.id = axiWires.bid();
            v.resp = axiWires.bresp();

            bready <= 1;
            return v;
        endmethod
     endinterface
     endinterface
     interface extra = axiWires.extra;
     method aresetn = axiWires.aresetn;
endmodule
