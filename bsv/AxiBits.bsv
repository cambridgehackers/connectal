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

module mkPhysMemSlave#(Axi4SlaveLiteBits#(axiAddrWidth,dataWidth) axiSlave)(PhysMemSlave#(addrWidth,dataWidth))
   provisos (Add#(axiAddrWidth,a__,addrWidth));
   FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) arfifo <- mkFIFOF();   
   FIFOF#(MemData#(dataWidth)) rfifo <- mkFIFOF();
   FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) awfifo <- mkFIFOF();   
   FIFOF#(MemData#(dataWidth)) wfifo <- mkFIFOF();
   FIFOF#(Bit#(MemTagSize)) bfifo <- mkFIFOF();   
   FIFOF#(Bit#(MemTagSize)) rtagfifo <- mkFIFOF();   
   FIFOF#(Bit#(MemTagSize)) wtagfifo <- mkFIFOF();   

   rule rl_arfifo;
      if (arfifo.notEmpty && axiSlave.arready() == 1) begin
	 let req <- toGet(arfifo).get();
	 rtagfifo.enq(req.tag);
	 axiSlave.arvalid(1);
	 axiSlave.araddr(truncate(req.addr));
      end
      else begin
	 axiSlave.arvalid(0);
	 axiSlave.araddr(0);
      end
   endrule
   rule rl_ardata;
      if (axiSlave.rvalid() == 1) begin
	 let rtag <- toGet(rtagfifo).get();
	 rfifo.enq(MemData { data: axiSlave.rdata(), tag: rtag } );
	 axiSlave.rready(1);
      end
      else begin
	 axiSlave.rready(0);
      end
   endrule

   rule rl_awfifo;
      if (awfifo.notEmpty && axiSlave.awready() == 1) begin
	 let req <- toGet(awfifo).get();
	 rtagfifo.enq(req.tag);
	 axiSlave.awvalid(1);
	 axiSlave.awaddr(truncate(req.addr));
      end
      else begin
	 axiSlave.awvalid(0);
	 axiSlave.awaddr(0);
      end
   endrule
   rule rl_wdata;
      if (axiSlave.wready() == 1) begin
	 let rtag <- toGet(rtagfifo).get();
	 let md <- toGet(wfifo).get();
	 axiSlave.wvalid(1);
	 axiSlave.wdata(md.data);
	 bfifo.enq(md.tag);
      end
      else begin
	 axiSlave.wvalid(0);
	 axiSlave.wdata(0);
      end
   endrule
   rule rl_done;
      if (axiSlave.bvalid() == 1) begin
	 let tag <- toGet(wtagfifo).get();
	 axiSlave.bready(1);
	 bfifo.enq(tag);
      end
      else begin
	 axiSlave.bready(0);
      end
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

typedef AxiMasterBits#(32,32,12,Empty) Pps7Maxigp;
typedef AxiSlaveBits#(32,32,6,Empty) Pps7Saxigp;
typedef AxiSlaveBits#(32,64,6,HPType) Pps7Saxihp;
typedef AxiSlaveBits#(32,64,3,ACPType) Pps7Saxiacp;
