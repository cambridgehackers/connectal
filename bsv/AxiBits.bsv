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
import Vector::*;
import Clocks::*;
import FIFOF::*;
import GetPut::*;
import MemTypes::*;
import EHRM::*;

interface AxiMasterBits#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth, type extraType);
    method Bit#(addrWidth)     araddr();
    method Bit#(2)     arburst();
    method Bit#(4)     arcache();
    method Bit#(1)     aresetn();
    method Bit#(tagWidth)     arid();
    method Bit#(4)     arlen();
    method Bit#(2)     arlock();
    method Bit#(3)     arprot();
    method Bit#(4)     arqos();
    method Action      arready(Bit#(1) v);
    method Bit#(2)     arsize();
    method Bit#(1)     arvalid();
    method Bit#(addrWidth)     awaddr();
    method Bit#(2)     awburst();
    method Bit#(4)     awcache();
    method Bit#(tagWidth)     awid();
    method Bit#(4)     awlen();
    method Bit#(2)     awlock();
    method Bit#(3)     awprot();
    method Bit#(4)     awqos();
    method Action      awready(Bit#(1) v);
    method Bit#(2)     awsize();
    method Bit#(1)     awvalid();
    method Action      bid(Bit#(tagWidth) v);
    method Bit#(1)     bready();
    method Action      bresp(Bit#(2) v);
    method Action      bvalid(Bit#(1) v);
    method Action      rdata(Bit#(dataWidth) v);
    method Action      rid(Bit#(tagWidth) v);
    method Action      rlast(Bit#(1) v);
    method Bit#(1)     rready();
    method Action      rresp(Bit#(2) v);
    method Action      rvalid(Bit#(1) v);
    method Bit#(dataWidth)     wdata();
    method Bit#(tagWidth)     wid();
    method Bit#(1)     wlast();
    method Action      wready(Bit#(1) v);
    method Bit#(TDiv#(dataWidth,8))     wstrb();
    method Bit#(1)     wvalid();
    interface extraType   extra;
endinterface

interface HPType;
    method Bit#(3)     racount();
    method Bit#(8)     rcount();
    method Action      rdissuecap1en(Bit#(1) v);
    method Bit#(6)     wacount();
    method Bit#(8)     wcount();
    method Action      wrissuecap1en(Bit#(1) v);
endinterface

interface ACPType;
    method Action      aruser(Bit#(5) v);
    method Action      awuser(Bit#(5) v);
endinterface

interface AxiSlaveBits#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth, type extraType);
    method Action      araddr(Bit#(addrWidth) v);
    method Action      arburst(Bit#(2) v);
    method Action      arcache(Bit#(4) v);
    method Bit#(1)     aresetn();
    method Action      arid(Bit#(tagWidth) v);
    method Action      arlen(Bit#(4) v);
    method Action      arlock(Bit#(2) v);
    method Action      arprot(Bit#(3) v);
    method Action      arqos(Bit#(4) v);
    method Bit#(1)     arready();
    method Action      arsize(Bit#(2) v);
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(addrWidth) v);
    method Action      awburst(Bit#(2) v);
    method Action      awcache(Bit#(4) v);
    method Action      awid(Bit#(tagWidth) v);
    method Action      awlen(Bit#(4) v);
    method Action      awlock(Bit#(2) v);
    method Action      awprot(Bit#(3) v);
    method Action      awqos(Bit#(4) v);
    method Bit#(1)     awready();
    method Action      awsize(Bit#(2) v);
    method Action      awvalid(Bit#(1) v);
    method Bit#(tagWidth)     bid();
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(dataWidth)     rdata();
    method Bit#(1)     rlast();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(dataWidth) v);
    method Action      wid(Bit#(tagWidth) v);
    method Action      wlast(Bit#(1) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(TDiv#(dataWidth,8)) v);
    method Action      wvalid(Bit#(1) v);
    method Bit#(tagWidth)     rid();
    interface extraType   extra;
endinterface

interface Axi4MasterBits#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth, type extraType);
    method Bit#(addrWidth)     araddr();
    method Bit#(2)     arburst();
    method Bit#(4)     arcache();
    method Bit#(1)     aresetn();
    method Bit#(tagWidth)     arid();
    method Bit#(8)     arlen();
    method Bit#(2)     arlock();
    method Bit#(3)     arprot();
    method Bit#(4)     arqos();
    method Action      arready(Bit#(1) v);
    method Bit#(3)     arsize();
    method Bit#(1)     arvalid();
    method Bit#(addrWidth)     awaddr();
    method Bit#(2)     awburst();
    method Bit#(4)     awcache();
    method Bit#(tagWidth)     awid();
    method Bit#(8)     awlen();
    method Bit#(2)     awlock();
    method Bit#(3)     awprot();
    method Bit#(4)     awqos();
    method Action      awready(Bit#(1) v);
    method Bit#(3)     awsize();
    method Bit#(1)     awvalid();
    method Action      bid(Bit#(tagWidth) v);
    method Bit#(1)     bready();
    method Action      bresp(Bit#(2) v);
    method Action      bvalid(Bit#(1) v);
    method Action      rdata(Bit#(dataWidth) v);
    method Action      rid(Bit#(tagWidth) v);
    method Action      rlast(Bit#(1) v);
    method Bit#(1)     rready();
    method Action      rresp(Bit#(2) v);
    method Action      rvalid(Bit#(1) v);
    method Bit#(dataWidth)     wdata();
    method Bit#(tagWidth)     wid();
    method Bit#(1)     wlast();
    method Action      wready(Bit#(1) v);
    method Bit#(TDiv#(dataWidth,8))     wstrb();
    method Bit#(1)     wvalid();
    interface extraType   extra;
endinterface

interface Axi4MasterUntaggedBits#(numeric type addrWidth, numeric type dataWidth);
    method Bit#(addrWidth)     araddr();
    method Bit#(2)     arburst();
    method Bit#(4)     arcache();
    method Bit#(8)     arlen();
    //method Bit#(2)     arlock();
    method Bit#(3)     arprot();
    //method Bit#(4)     arqos();
    method Action      arready(Bit#(1) v);
    method Bit#(3)     arsize();
    method Bit#(1)     arvalid();
    method Bit#(addrWidth)     awaddr();
    method Bit#(2)     awburst();
    method Bit#(4)     awcache();
    method Bit#(8)     awlen();
    //method Bit#(2)     awlock();
    method Bit#(3)     awprot();
    //method Bit#(4)     awqos();
    method Action      awready(Bit#(1) v);
    method Bit#(3)     awsize();
    method Bit#(1)     awvalid();
    method Bit#(1)     bready();
    method Action      bresp(Bit#(2) v);
    method Action      bvalid(Bit#(1) v);
    method Action      rdata(Bit#(dataWidth) v);
    method Action      rlast(Bit#(1) v);
    method Bit#(1)     rready();
    method Action      rresp(Bit#(2) v);
    method Action      rvalid(Bit#(1) v);
    method Bit#(dataWidth)     wdata();
    method Bit#(1)     wlast();
    method Action      wready(Bit#(1) v);
    method Bit#(TDiv#(dataWidth,8))     wstrb();
    method Bit#(1)     wvalid();
endinterface

typeclass ToAxi4MasterBits#(type atype, type btype);
   function atype toAxi4MasterBits(btype b);
endtypeclass

instance ToAxi4MasterBits#(Axi4MasterBits#(addrWidth,dataWidth,tagWidth,Empty), Axi4MasterUntaggedBits#(addrWidth,dataWidth));
function Axi4MasterBits#(addrWidth,dataWidth,tagWidth,Empty) toAxi4MasterBits(Axi4MasterUntaggedBits#(addrWidth,dataWidth) m);
   return (interface Axi4MasterBits#(addrWidth,dataWidth,tagWidth,Empty);
    method araddr = m.araddr;
      method arburst = m.arburst;
      method arcache = m.arcache;
      //method aresetn = no_reset;
      method Bit#(tagWidth)     arid(); return 0; endmethod
      method arlen = m.arlen;
      //method arlock = m.arlock;
      method arprot = m.arprot;
      //method arqos = m.arqos;
      method arready = m.arready;
      method arsize = m.arsize;
      method arvalid = m.arvalid;
      method awaddr = m.awaddr;
      method awburst = m.awburst;
      method awcache = m.awcache;
      method Bit#(tagWidth)     awid(); return 0; endmethod
      method awlen = m.awlen;
      //method awlock = m.awlock;
      method awprot = m.awprot;
      //method awqos = m.awqos;
      method awready = m.awready;
      method awsize = m.awsize;
      method awvalid = m.awvalid;
      method Action      bid(Bit#(tagWidth) v); endmethod
      method bready = m.bready;
      method bresp = m.bresp;
      method bvalid = m.bvalid;
      method rdata = m.rdata;
      method Action      rid(Bit#(tagWidth) v); endmethod
      method rlast = m.rlast;
      method rready = m.rready;
      method rresp = m.rresp;
      method rvalid = m.rvalid;
      method wdata = m.wdata;
      method Bit#(tagWidth)     wid(); return 0; endmethod
      method wlast = m.wlast;
      method wready = m.wready;
      method wstrb = m.wstrb;
      method wvalid = m.wvalid;
      interface extra = ?;   
      endinterface);
endfunction
endinstance

interface Axi4SlaveBits#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth, type extraType);
    method Action      araddr(Bit#(addrWidth) v);
    method Action      arburst(Bit#(2) v);
    method Action      arcache(Bit#(4) v);
    method Bit#(1)     aresetn();
    method Action      arid(Bit#(tagWidth) v);
    method Action      arlen(Bit#(8) v);
    method Action      arlock(Bit#(2) v);
    method Action      arprot(Bit#(3) v);
    method Action      arqos(Bit#(4) v);
    method Bit#(1)     arready();
    method Action      arsize(Bit#(3) v);
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(addrWidth) v);
    method Action      awburst(Bit#(2) v);
    method Action      awcache(Bit#(4) v);
    method Action      awid(Bit#(tagWidth) v);
    method Action      awlen(Bit#(8) v);
    method Action      awlock(Bit#(2) v);
    method Action      awprot(Bit#(3) v);
    method Action      awqos(Bit#(4) v);
    method Bit#(1)     awready();
    method Action      awsize(Bit#(3) v);
    method Action      awvalid(Bit#(1) v);
    method Bit#(tagWidth)     bid();
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(dataWidth)     rdata();
    method Bit#(1)     rlast();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(dataWidth) v);
    method Action      wid(Bit#(tagWidth) v);
    method Action      wlast(Bit#(1) v);
    method Bit#(1)     wready();
    method Action      wstrb(Bit#(TDiv#(dataWidth,8)) v);
    method Action      wvalid(Bit#(1) v);
    method Bit#(tagWidth)     rid();
    interface extraType   extra;
endinterface

interface Axi4SlaveLiteBits#(numeric type addrWidth, numeric type dataWidth);
    method Action      araddr(Bit#(addrWidth) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(addrWidth) v);
    method Bit#(1)     awready();
    method Action      awvalid(Bit#(1) v);
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(dataWidth)     rdata();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(dataWidth) v);
    method Bit#(1)     wready();
    method Action      wvalid(Bit#(1) v);
endinterface

typeclass ToAxi4SlaveBits#(type atype, type btype);
   function atype toAxi4SlaveBits(btype b);
endtypeclass

module mkAxiFifoF(FIFOF#(t)) provisos(Bits#(t, tSz));
  Ehr#(2, t) da <- mkEhr(?);
  Ehr#(2, Bool) va <- mkEhr(False);
  Ehr#(2, t) db <- mkEhr(?);
  Ehr#(2, Bool) vb <- mkEhr(False);

  rule canon if(vb[1] && !va[1]);
    da[1] <= db[1];
    va[1] <= True;
    vb[1] <= False;
  endrule

  method Bool notFull = !vb[0];

  method Action enq(t x) if(!vb[0]);
    db[0] <= x;
    vb[0] <= True;
  endmethod

  method Bool notEmpty = va[0];

  method Action deq if (va[0]);
    va[0] <= False;
  endmethod

  // no implicit guard, to simplify rule guards below
  method t first;
    return da[0];
  endmethod

  // conflicts with enq, deq, but we do not call it   
  method Action clear;
    vb[0] <= False;
    va[0] <= False;
  endmethod
endmodule

module mkPhysMemSlave#(Axi4SlaveLiteBits#(axiAddrWidth,dataWidth) axiSlave)(PhysMemSlave#(addrWidth,dataWidth))
   provisos (Add#(axiAddrWidth,a__,addrWidth));
   FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) arfifo <- mkAxiFifoF();
   FIFOF#(MemData#(dataWidth)) rfifo <- mkAxiFifoF();
   FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) awfifo <- mkAxiFifoF();
   FIFOF#(MemData#(dataWidth)) wfifo <- mkAxiFifoF();
   FIFOF#(Bit#(MemTagSize)) bfifo <- mkAxiFifoF();   
   FIFOF#(Bit#(MemTagSize)) rtagfifo <- mkAxiFifoF();   
   FIFOF#(Bit#(MemTagSize)) wtagfifo <- mkAxiFifoF();   

   rule rl_arvalid_araddr;
      axiSlave.arvalid(pack(arfifo.notEmpty && rtagfifo.notFull));
      let addr = 0;
      if (arfifo.notEmpty)
	 addr = truncate(arfifo.first.addr);
      axiSlave.araddr(addr);
   endrule
   rule rl_arfifo if (axiSlave.arready() == 1);
      let req <- toGet(arfifo).get();
      rtagfifo.enq(req.tag);
   endrule
   rule rl_rready;
      axiSlave.rready(pack(rfifo.notFull && rtagfifo.notEmpty));
   endrule   
   rule rl_rdata if (axiSlave.rvalid() == 1);
      let rtag <- toGet(rtagfifo).get();
      rfifo.enq(MemData { data: axiSlave.rdata(), tag: rtag } );
   endrule

   rule rl_awvalid_awaddr;
      axiSlave.awvalid(pack(awfifo.notEmpty && wtagfifo.notFull));
      let addr = 0;
      if (awfifo.notEmpty)
	 addr = truncate(awfifo.first.addr);
      axiSlave.awaddr(addr);
   endrule   
   rule rl_awfifo if (axiSlave.awready() == 1);
      let req <- toGet(awfifo).get();
      wtagfifo.enq(req.tag);
   endrule
   rule rl_wvalid;
      axiSlave.wvalid(pack(wfifo.notEmpty));
      let wdata = 0;
      if (wfifo.notEmpty)
	 wdata = wfifo.first.data;
      axiSlave.wdata(wdata);
   endrule   
   rule rl_wdata if (axiSlave.wready() == 1);
      let md <- toGet(wfifo).get();
   endrule
   rule rl_bready;
      axiSlave.bready(pack(wtagfifo.notEmpty && bfifo.notFull));
   endrule   
   rule rl_done if (axiSlave.bvalid() == 1);
      let tag <- toGet(wtagfifo).get();
      bfifo.enq(tag);
   endrule

   interface PhysMemReadServer read_server;
      interface Put readReq = toPut(arfifo);
      interface Get readData = toGet(rfifo);
   endinterface   
   interface PhysMemWriteServer write_server;
      interface Put writeReq = toPut(awfifo);
      interface Put writeData = toPut(wfifo);
      interface Get writeDone = toGet(bfifo);
   endinterface   
endmodule   

function MemReadClient#(dataWidth) toMemReadClient(Axi4MasterBits#(32,dataWidth,MemTagSize,Empty) m);
   return (interface MemReadClient;
   interface Get readReq;
      method ActionValue#(MemRequest) get() if (m.arvalid() == 1);
	 m.arready(1);
	 let addr = m.araddr();   
	 return MemRequest { sglId: extend(addr[31:28]), offset: extend(addr[27:0]), burstLen: extend(m.arlen()), tag: extend(m.arid()) };
      endmethod
   endinterface
   interface Put readData;
      method Action put(MemData#(dataWidth) md) if (m.rready() == 1);
	 m.rvalid(1);
         m.rdata(md.data);
	 m.rlast(pack(md.last));
	 m.rresp(0);
	 m.rid(truncate(md.tag));
      endmethod
   endinterface   
   endinterface);   
endfunction

function MemWriteClient#(dataWidth) toMemWriteClient(Axi4MasterBits#(32,dataWidth,MemTagSize,Empty) m);
   return (interface MemWriteClient;
   interface Get writeReq;
      method ActionValue#(MemRequest) get() if (m.awvalid() == 1);
	 m.awready(1);
	 let addr = m.awaddr();
	 return MemRequest { sglId: extend(addr[31:28]), offset: extend(addr[27:0]), burstLen: extend(m.awlen()), tag: extend(m.awid()) };
      endmethod
   endinterface
   interface Get writeData;
      method ActionValue#(MemData#(dataWidth)) get() if (m.wvalid() == 1);
	 m.wready(1);
      return MemData { data: m.wdata(), last: unpack(m.wlast()), tag: extend(m.wid()) };
      endmethod
   endinterface
   interface Put writeDone;
      method Action put(Bit#(MemTagSize) tag) if (m.bready() == 1);
	 m.bvalid(1);
	 m.bresp(0);
	 m.bid(truncate(tag));
      endmethod
   endinterface
   endinterface);
endfunction

typedef AxiMasterBits#(32,32,12,Empty) Pps7Maxigp;
typedef AxiSlaveBits#(32,32,6,Empty) Pps7Saxigp;
typedef AxiSlaveBits#(32,64,6,HPType) Pps7Saxihp;
typedef AxiSlaveBits#(32,64,3,ACPType) Pps7Saxiacp;
