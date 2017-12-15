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
`include "ConnectalProjectConfig.bsv"
import Vector::*;
import Clocks::*;
import FIFOF::*;
import ConnectalFIFO::*;
import GetPut::*;
import Probe::*;
import ConnectalMemTypes::*;
import ConnectalEHR::*;
import Axi4MasterSlave::*;
import Connectable::*;
import ConnectalBramFifo::*;

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

(* always_ready, always_enabled *)
interface AwsF1Extra;
    //10:0 Length in DW of the transaction
    //14:11 are the byte-enable for the first DW (bit value 1 mean byte is enable, i.e. not masked)
    //18:15 are the byte-enable for the last DW (bit value 1 mean byte is enable, i.e. not masked)
    method Bit#(19) awuser;
    // 10:0 Length in DW of the transaction
    // 18:11 Must be set to 0xFF, could be ignored in next release
    method Bit#(19) aruser;
endinterface

module mkAxi4MasterBits#(Axi4Master#(addrWidth,dataWidth,tagWidth) m)(Axi4MasterBits#(addrWidth,busDataWidth,busTagWidth,AwsF1Extra))
    provisos (Add#(dataWidth,d__,busDataWidth),
              Div#(dataWidth,32,dataWidthWords),
    	      Add#(tagWidth,t__,busTagWidth),
    	      Add#(a__, TDiv#(dataWidth, 8), TDiv#(busDataWidth, 8)));
	    let arfifo <- mkCFFIFOF();
	    let araddrWire <- mkDWire(0);
	    let arburstWire <- mkDWire(0);
	    let arcacheWire <- mkDWire(0);
	    let aridWire <- mkDWire(0);
	    let arreadyWire <- mkDWire(False);
	    let arprotWire <- mkDWire(0);
	    let arlenWire <- mkDWire(0);
	    let arsizeWire <- mkDWire(0);
	    let aruserWire <- mkDWire(0);

	    let awfifo <- mkCFFIFOF();
	    let awaddrWire <- mkDWire(0);
	    let awburstWire <- mkDWire(0);
	    let awcacheWire <- mkDWire(0);
	    let awidWire <- mkDWire(0);
	    let awreadyWire <- mkDWire(False);
	    let awprotWire <- mkDWire(0);
	    let awlenWire <- mkDWire(0);
	    let awsizeWire <- mkDWire(0);
	    let awuserWire <- mkDWire(0);

	    let rfifo <- mkCFFIFOF();
	    let rdataWire <- mkDWire(0);
	    let rrespWire <- mkDWire(0);
	    let rlastWire <- mkDWire(0);
	    let ridWire <- mkDWire(0);	    
	    let rvalidWire <- mkDWire(False);

	    let wfifo <- mkCFFIFOF();
	    let wdataWire <- mkDWire(0);
	    let widWire <- mkDWire(0);
	    let wstrbWire <- mkDWire(0);
	    let wlastWire <- mkDWire(0);
	    let wreadyWire <- mkDWire(False);

	    let bfifo <- mkCFFIFOF();
	    let bidWire <- mkDWire(0);
	    let brespWire <- mkDWire(0);
	    let bvalidWire <- mkDWire(False);

	    rule arfifo_enq;
	       let req <- m.req_ar.get();
	       arfifo.enq(req);
	    endrule

	    rule arwire_rule;
	       araddrWire <= arfifo.first.address;
	       arlenWire <= arfifo.first.len;
	       Bit#(11) dwlen = extend(arfifo.first.len) / fromInteger(valueOf(dataWidthWords));
	       Bit#(8) mustbeone = 8'hf;
	       aruserWire <= { mustbeone, dwlen };
	       arsizeWire <= arfifo.first.size;
	       arburstWire <= 2'b01; //arfifo.first.burst;
	       arprotWire <= 3'b000; //arfifo.first.prot;
	       arcacheWire <= 4'b0011; // arfifo.first.cache;
	       aridWire <= arfifo.first.id;
	    endrule

	    rule ar_handshake if (arreadyWire);
	      arfifo.deq();
	    endrule

	    rule awfifo_enq;
	       let req <- m.req_aw.get();
	       awfifo.enq(req);
	    endrule

	    rule awwire_rule;
	       awaddrWire <= awfifo.first.address;
	       let lenbytes = awfifo.first.len;
	       awlenWire <= lenbytes;
	       Bit#(11) dwlen = extend(lenbytes) / fromInteger(valueOf(dataWidthWords));
	       Bit#(4) firstBE = 4'hf;
	       Bit#(4) lastBE = (lenbytes > 4) ? 4'hf : 0;
	       awuserWire <= { lastBE, firstBE, dwlen };
	       awsizeWire <= awfifo.first.size;
	       awburstWire <= 2'b01; //awfifo.first.burst;
	       awprotWire <= 3'b000; //awfifo.first.prot;
	       awcacheWire <= 4'b0011; // awfifo.first.cache;
	       awidWire <= awfifo.first.id;
	    endrule

	    rule aw_handshake if (awreadyWire);
	      awfifo.deq();
	    endrule

	    rule rdata_put;
	       let data <- toGet(rfifo).get();
	       m.resp_read.put(data); 
	    endrule

	    rule r_handshake if (rvalidWire);
	      rfifo.enq(Axi4ReadResponse {data: truncate(rdataWire),
	      				  resp: rrespWire,
					  last: rlastWire,
					  id: ridWire });
	    endrule

	    rule wdata_get;
	       let data <- m.resp_write.get();
	       wfifo.enq(data);
	    endrule

	    rule w_handshake if (wreadyWire);
	      let data <- toGet(wfifo).get();
	      wdataWire <= extend(data.data);
	      wlastWire <= pack(data.last);
	      wstrbWire <= data.byteEnable;
	      widWire <= data.id;
	    endrule

	    rule bresp_put;
	       let resp <- toGet(bfifo).get();
	       m.resp_b.put(resp); 
	    endrule

	    rule b_handshake if (bvalidWire);
	      bfifo.enq(Axi4WriteResponse {resp: brespWire,
					  id: bidWire });
	    endrule

	    interface AwsF1Extra extra;
	       method aruser = aruserWire;
	       method awuser = awuserWire;
	    endinterface

	    method araddr = araddrWire;
	    method arburst = arburstWire;
	    method arcache = arcacheWire;
	    method aresetn = 1;
	    method arid = extend(aridWire);
	    method arlen = arlenWire;
	    // method Bit#(2)     arlock();
	    method arprot = arprotWire;
	    // method Bit#(4)     arqos();
	    method Action      arready(Bit#(1) v); arreadyWire <= unpack(v); endmethod
	    method arsize = arsizeWire;
	    method arvalid = pack(arfifo.notEmpty);

	    method awaddr = awaddrWire;
	    method awburst = awburstWire;
	    method awcache = awcacheWire;
	    method awid = extend(awidWire);
	    method awlen = awlenWire;
	    //method awlock = awlockWire;
	    method awprot = awprotWire;
	    // method Bit#(4)     awqos();
	    method Action      awready(Bit#(1) v); awreadyWire <= unpack(v); endmethod
	    method awsize = awsizeWire;
	    method awvalid = pack(awfifo.notEmpty);

	    method Action      bid(Bit#(busTagWidth) v); bidWire <= truncate(v); endmethod
	    method bready = pack(bfifo.notFull());
	    method Action      bresp(Bit#(2) v); brespWire <= v; endmethod
	    method Action      bvalid(Bit#(1) v); bvalidWire <= unpack(v); endmethod

	    method Action      rdata(Bit#(busDataWidth) v); rdataWire <= v; endmethod
	    method Action      rid(Bit#(busTagWidth) v); ridWire <= truncate(v); endmethod
	    method Action      rlast(Bit#(1) v); rlastWire <= unpack(v); endmethod
	    method rready = pack(rfifo.notFull());
	    method Action      rresp(Bit#(2) v); rrespWire <= v; endmethod
	    method Action      rvalid(Bit#(1) v); rvalidWire <= unpack(v); endmethod

	    method wdata = wdataWire;
	    method wid = extend(widWire);
	    method wlast = wlastWire;
	    method Action      wready(Bit#(1) v); wreadyWire <= unpack(v); endmethod
	    method wstrb = extend(wstrbWire);
	    method wvalid = pack(wfifo.notEmpty);

endmodule

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

  method Bool notFull = !vb[0]; // technically, canEnqueue

  method Action enq(t x) if(!vb[0]);
    db[0] <= x;
    vb[0] <= True;
  endmethod

  method Bool notEmpty = va[0]; // technically, canDequeue

  method Action deq if (va[0]);
    va[0] <= False;
  endmethod

  method t first if (va[0]);
    return da[0];
  endmethod

  // conflicts with enq, deq, but we do not call it   
  method Action clear;
    vb[0] <= False;
    va[0] <= False;
  endmethod
endmodule

typedef 40 MpsocMAxiAddrWidth; // MAXI:40bit SAXI:49bit
typedef 128 MpsocAxiDataWidth;
typedef 16 MpsocMAxiIdWidth;   // MAXI:16bit SAXI: 6bit
typedef 32 PhysMemDataWidth;
typedef 32 PhysMemAddrWidth;
instance MkPhysMemMaster#(Axi4MasterBits#(MpsocMAxiAddrWidth,MpsocAxiDataWidth,MpsocMAxiIdWidth,extra),PhysMemAddrWidth,PhysMemDataWidth)
      provisos (Add#(PhysMemAddrWidth,a__,MpsocMAxiAddrWidth),
		Add#(c__, 6, MpsocMAxiIdWidth)
		);
   module mkPhysMemMaster#(Axi4MasterBits#(MpsocMAxiAddrWidth,MpsocAxiDataWidth,MpsocMAxiIdWidth,extra) axiMaster)(PhysMemMaster#(PhysMemAddrWidth,PhysMemDataWidth));
      FIFOF#(PhysMemRequest#(PhysMemAddrWidth,PhysMemDataWidth)) arfifo <- mkAxiFifoF();
      FIFOF#(MemData#(PhysMemDataWidth)) rfifo <- mkAxiFifoF();
      FIFOF#(PhysMemRequest#(PhysMemAddrWidth,PhysMemDataWidth)) awfifo <- mkAxiFifoF();
      FIFOF#(MemData#(PhysMemDataWidth)) wfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MemTagSize)) bfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MpsocMAxiIdWidth)) rtagfifo <- mkAxiFifoF();
      FIFOF#(Tuple2#(Bit#(MpsocMAxiIdWidth),Bit#(2))) awtagfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MpsocMAxiIdWidth)) wtagfifo <- mkAxiFifoF();

   let beatShift = fromInteger(valueOf(TLog#(TDiv#(PhysMemDataWidth,8))));
// req_ar (M=>S)
      let arreadyProbe <- mkProbe();
      rule rl_arready;
	 let arready = pack(arfifo.notFull && rtagfifo.notFull);
	 arreadyProbe <= arready;
	 axiMaster.arready(arready);
      endrule
      rule rl_arfifo if (axiMaster.arvalid() == 1);
	 let addr = truncate(axiMaster.araddr());
	 let burstLen = extend(axiMaster.arlen+1) << beatShift; // calculate burstLen
	 arfifo.enq(PhysMemRequest{ addr: addr, burstLen: burstLen, tag: 0 } ); // burstlen corrected
	 rtagfifo.enq(axiMaster.arid()); // what if the single request with multiple transfer
      endrule

// resp_read (S=>M)
      let rvalidProbe <- mkProbe();
      rule rl_rvalid;
	 let rvalid = pack(rfifo.notEmpty && rtagfifo.notEmpty);
	 rvalidProbe <= rvalid;
	 axiMaster.rvalid(rvalid);
      endrule
      rule rl_rdata if (axiMaster.rready() == 1);
	 //let rtag <- toGet(rtagfifo).get();
	 let rtag = rtagfifo.first();
	 let rdata <- toGet(rfifo).get();

	 if (rdata.last) begin
		 rtagfifo.deq(); // deq rtagfifo only if last beat
	 end
	 
	 axiMaster.rresp(0); //okay
	 Vector#(4,Bit#(32)) words = replicate(rdata.data);
	 axiMaster.rdata(pack(words));
	 axiMaster.rid(extend(rtag));
	 axiMaster.rlast(rdata.last?1:0); // added
      endrule

// req_aw (M=>S)
      let awreadyProbe <- mkProbe();
      rule rl_awvalid_awaddr;
	 let awready = pack(awfifo.notFull && awtagfifo.notFull);
	 awreadyProbe <= awready;
	 axiMaster.awready(awready);
      endrule
      rule rl_awfifo if (axiMaster.awvalid() == 1);
	 Bit#(PhysMemAddrWidth) addr = truncate(axiMaster.awaddr());
	 let burstLen = extend(axiMaster.awlen+1) << beatShift; // calculate burstLen
	 let tag = axiMaster.awid();
	 awfifo.enq(PhysMemRequest{ addr: addr, tag: truncate(tag), burstLen: burstLen }); // burstlen corrected
	 awtagfifo.enq(tuple2(tag, addr[3:2])); // what if the single request with multiple transfer??
      endrule

// resp_wr (M=>S) sending data
      let wreadyProbe <- mkProbe();
      rule rl_wready;
	 let wready = pack(wfifo.notFull && awtagfifo.notEmpty && wtagfifo.notFull);
	 wreadyProbe <= wready;
	 axiMaster.wready(wready);
      endrule
      rule rl_wdata if (axiMaster.wvalid() == 1);
	 let last = axiMaster.wlast == 1;
	 match { .tag, .lane } = awtagfifo.first;
	 Vector#(4, Bit#(PhysMemDataWidth)) words = unpack(axiMaster.wdata());
	 wfifo.enq(MemData { data: words[lane], tag: truncate(tag), last: last});
	 if (last) begin
	    awtagfifo.deq();
	    wtagfifo.enq(tag);
	 end
      endrule

// resp_b (S=>M) 
      let bvalidProbe <- mkProbe();
      rule rl_bvalid;
	 let bvalid = pack(wtagfifo.notEmpty && bfifo.notEmpty);
	 bvalidProbe <= bvalid;
	 axiMaster.bvalid(bvalid);
      endrule
      rule rl_done if (axiMaster.bready() == 1);
	 let tag <- toGet(bfifo).get();
	 let awtag <- toGet(wtagfifo).get();
	 axiMaster.bid(awtag);
	 axiMaster.bresp(0); //okay
	 // where is b_resp?
      endrule

      interface PhysMemReadClient read_client;
	 interface Get readReq = toGet(arfifo);
	 interface Put readData = toPut(rfifo);
      endinterface
      interface PhysMemWriteClient write_client;
	 interface Get writeReq = toGet(awfifo);
	 interface Get writeData = toGet(wfifo);
	 interface Put writeDone = toPut(bfifo);
      endinterface
   endmodule
endinstance: MkPhysMemMaster

instance MkPhysMemSlave#(Axi4SlaveLiteBits#(axiAddrWidth,dataWidth),addrWidth,dataWidth)
      provisos (Add#(axiAddrWidth,a__,addrWidth));
   module mkPhysMemSlave#(Axi4SlaveLiteBits#(axiAddrWidth,dataWidth) axiSlave)(PhysMemSlave#(addrWidth,dataWidth));
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
      endrule
      rule rl_wdata if (axiSlave.wready() == 1);
	 let wdata = wfifo.first.data;
	 wfifo.deq();
	 axiSlave.wdata(wdata);
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
endinstance

`ifdef BLUECHECK
import BlueCheck::*;
import StmtFSM::*;

module [BlueCheck] mkPhysMemSlaveSpec();
   /* This function allows us to make assertions in the properties */
   Ensure ensure <- getEnsure;
   Ensure ensure1 <- getEnsure;
   Bit#(BurstLenSize) bytesPerBeat = 16;
   let dataSizeMask = bytesPerBeat-1;

   function Stmt checkLen(Bit#(8) burstLen8) =
   seq
      action
	 Bit#(BurstLenSize) burstLen = extend(burstLen8);
	 PhysMemRequest#(16,128) pmr = PhysMemRequest { addr: 0, burstLen: burstLen };
	 Axi4ReadRequest#(16,6) amr = toAxi4ReadRequest(pmr);
	 Bit#(8) expectedValue = truncate((burstLen + dataSizeMask) / bytesPerBeat - 1);
	 //$display("burstLen=%d arm.len=%x bytesPerBeat=%x dataSizeMask=%x expectedValue=%x", burstLen, amr.len, bytesPerBeat, dataSizeMask, expectedValue);
	 ensure(extend(amr.len) == expectedValue);
	 ensure1 ((burstLen == 0) || ((extend(amr.len)+1) * bytesPerBeat >= burstLen));
      endaction
   endseq;

   function Stmt checkSize(Bit#(8) burstLen8) =
   seq
      action
	 Bit#(BurstLenSize) burstLen = extend(burstLen8);
	 PhysMemRequest#(16,128) pmr = PhysMemRequest { addr: 0, burstLen: burstLen };
	 Axi4ReadRequest#(16,6) amr = toAxi4ReadRequest(pmr);
	 Bit#(3) expectedValue = axiBusSizeBytes(16);
	 //$display("burstLen=%d amr.size=%x expectedValue=%x", burstLen, amr.size, expectedValue);
	 ensure((burstLen == 0) || (extend(amr.size) == expectedValue));
      endaction
   endseq;

   prop("checkLen", checkLen);
   prop("checkSize", checkSize);
endmodule

module [Module] mkMkPhysMemSlaveChecker();
   blueCheck(mkPhysMemSlaveSpec);
endmodule

`endif


`ifdef FOOBAR
//FIXME burst transfers
instance MkPhysMemSlave#(Axi4SlaveBits#(axiAddrWidth,dataWidth,tagWidth,Empty),addrWidth,dataWidth)
      provisos (Add#(axiAddrWidth,a__,addrWidth),
		Add#(b__, tagWidth, 6));
   module mkPhysMemSlave#(Axi4SlaveBits#(axiAddrWidth,dataWidth,tagWidth,Empty) axiSlave)(PhysMemSlave#(addrWidth,dataWidth));
      FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) arfifo <- mkAxiFifoF();
      FIFOF#(MemData#(dataWidth)) rfifo <- mkAxiFifoF();
      FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) awfifo <- mkAxiFifoF();
      FIFOF#(MemData#(dataWidth)) wfifo <- mkAxiFifoF();
      FIFOF#(Bit#(TDiv#(dataWidth,8))) wstrbfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MemTagSize)) bfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MemTagSize)) rtagfifo <- mkAxiFifoF();
      FIFOF#(Bit#(MemTagSize)) wtagfifo <- mkAxiFifoF();

      let dataWidthBytes = valueOf(TDiv#(dataWidth,8));
      let dataSizeMask = dataWidthBytes-1;

      rule rl_arvalid;
	 axiSlave.arvalid(pack(arfifo.notEmpty && rtagfifo.notFull));
      endrule
      rule rl_araddr if (arfifo.notEmpty);
	 let req = arfifo.first;
	 Axi4ReadRequest#(axiAddrWidth,tagWidth) axireq = toAxi4ReadRequest(req);
	 axiSlave.araddr(axireq.address);
	 axiSlave.arid(axireq.id);
	 axiSlave.arlen(axireq.len);
	 axiSlave.arsize(axireq.size);
	 axiSlave.arburst(2'b01);
	 axiSlave.arprot(3'b000);
	 axiSlave.arcache(4'b1111); // was 4'b0011
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

      rule rl_awvalid;
	 axiSlave.awvalid(pack(awfifo.notEmpty && wtagfifo.notFull));
      endrule
      rule rl_awaddr if (awfifo.notEmpty);
	 let req = awfifo.first;

	 let dataWidthBytes = valueOf(TDiv#(dataWidth,8));
	 let dataSizeMask = dataWidthBytes-1;
	 let reqsize = req.burstLen & fromInteger(dataSizeMask);
	 Axi4WriteRequest#(axiAddrWidth,tagWidth) axireq = toAxi4WriteRequest(req);
	 axiSlave.awaddr(axireq.address);
	 axiSlave.awid(axireq.id);
	 axiSlave.awlen(axireq.len);
	 axiSlave.awsize(axireq.size);
	 axiSlave.awburst(2'b01);
	 axiSlave.awprot(3'b000);
	 axiSlave.awcache(4'b0011);
	 //FIXME should go in toAxi4WriteRequest
	 Bit#(TDiv#(dataWidth,8)) wstrb = (1 << reqsize) - 1;
	 wstrbfifo.enq(wstrb);
      endrule   
      rule rl_awfifo if (axiSlave.awready() == 1);
	 let req <- toGet(awfifo).get();
	 wtagfifo.enq(req.tag);
      endrule
      rule rl_wvalid;
	 axiSlave.wvalid(pack(wfifo.notEmpty));
      endrule
      rule rl_wdata if (axiSlave.wready() == 1);
	 let md <- toGet(wfifo).get();
	 let wdata = md.data;
	 axiSlave.wdata(wdata);
	 axiSlave.wlast(pack(wfifo.first.last));
	 axiSlave.wstrb(wstrbfifo.first);
	 if (wfifo.first.last)
	    wstrbfifo.deq();
      endrule
      rule rl_bready;
	 axiSlave.bready(pack(wtagfifo.notEmpty && bfifo.notFull));
      endrule   
      rule rl_done if (axiSlave.bvalid() == 1);
	 let tag <- toGet(wtagfifo).get();
	 bfifo.enq(extend(axiSlave.bid()));
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
endinstance
`endif // FOOBAR

typeclass AxiToMemReadClient#(type objIdType, numeric type axiAddrWidth, numeric type dataWidth);
   module mkMemReadClient#(objIdType objId, Axi4MasterBits#(axiAddrWidth,dataWidth,MemTagSize,Empty) m)(MemReadClient#(dataWidth));
   module mkMemWriteClient#(objIdType objId, Axi4MasterBits#(axiAddrWidth,dataWidth,MemTagSize,Empty) m)(MemWriteClient#(dataWidth));
endtypeclass
typeclass AxiToPhysMemReadClient#(numeric type axiAddrWidth, numeric type dataWidth, numeric type idWidth, type extra);
   module mkPhysMemReadClient#(Axi4MasterBits#(axiAddrWidth,dataWidth,idWidth,extra) m)(PhysMemReadClient#(axiAddrWidth,dataWidth));
   module mkPhysMemWriteClient#(Axi4MasterBits#(axiAddrWidth,dataWidth,idWidth,extra) m)(PhysMemWriteClient#(axiAaddrWidth,dataWidth));
endtypeclass

instance AxiToMemReadClient#(Bit#(32),32,dataWidth);
   module mkMemReadClient#(Bit#(32) objId, Axi4MasterBits#(32,dataWidth,MemTagSize,Empty) m)(MemReadClient#(dataWidth));

      let clock <- exposeCurrentClock();
      let mClock = clockOf(m);
      let reset <- exposeCurrentReset();
      let mReset = resetOf(m);

      Wire#(Bit#(1)) arready <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) rvalid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(MemTagSize)) rid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(2)) rresp <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(dataWidth)) rdata <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) rlast <- mkDWire(0, clocked_by mClock, reset_by mReset);

      FIFOF#(MemRequest)          arfifo;
      FIFOF#(MemData#(dataWidth))  rfifo;
      if ( isAncestor(clock, mClock)) begin
	 arfifo <- mkCFFIFOF();
	 rfifo  <- mkCFFIFOF();
      end
      else begin
	 arfifo <- mkDualClockBramFIFOF(mClock, mReset, clock, reset);
	 rfifo  <- mkDualClockBramFIFOF(clock, reset, mClock, mReset);
      end

      rule rl_araddr if (m.arvalid() == 1);
	 let addr = m.araddr();   
	 let burstLenBytes = (extend(m.arlen())+1)*fromInteger(valueOf(TDiv#(dataWidth,8)));
	 arfifo.enq(MemRequest { sglId: objId, offset: extend(addr), burstLen: burstLenBytes, tag: extend(m.arid()) });
      endrule
      rule handshake_ar;
	   m.arready(pack(arfifo.notFull()));
      endrule

      rule rl_rdata if (m.rready() == 1);
	 let md <- toGet(rfifo).get();
	 rdata <= md.data;
	 rlast <= pack(md.last);
	 rresp <= 0;
	 rid <= truncate(md.tag);
      endrule
      rule handshake_rdata;
	 m.rvalid(pack(rfifo.notEmpty()));
	 m.rid(rid);
	 m.rresp(rresp);
	 m.rdata(rdata);
	 m.rlast(rlast);
      endrule

      interface Get readReq = toGet(arfifo);
      interface Put readData = toPut(rfifo);
   endmodule

   module mkMemWriteClient#(Bit#(32) objId, Axi4MasterBits#(32,dataWidth,MemTagSize,Empty) m)(MemWriteClient#(dataWidth));

      let clock <- exposeCurrentClock();
      let mClock = clockOf(m);
      let reset <- exposeCurrentReset();
      let mReset = resetOf(m);

      Wire#(Bit#(1)) awready <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) wready <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) bvalid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(MemTagSize)) bid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(2)) bresp <- mkDWire(0, clocked_by mClock, reset_by mReset);

      FIFOF#(MemRequest)       awfifo;
      FIFOF#(MemData#(dataWidth)) wfifo;
      FIFOF#(Bit#(MemTagSize))    bfifo;
      if ( isAncestor(clock, mClock)) begin
	 awfifo   <- mkCFFIFOF();
	 wfifo <- mkCFFIFOF();
	 bfifo <- mkCFFIFOF();
      end
      else begin
	 awfifo   <- mkDualClockBramFIFOF(mClock, mReset, clock, reset);
	 wfifo <- mkDualClockBramFIFOF(mClock, mReset, clock, reset);
	 bfifo <- mkDualClockBramFIFOF(clock, reset, mClock, mReset);
      end

      rule rl_awaddr if (m.awvalid() == 1);
	 let addr = m.awaddr();
	 let burstLenBytes = (extend(m.awlen())+1)*fromInteger(valueOf(TDiv#(dataWidth,8)));
	 awfifo.enq(MemRequest { sglId: objId, offset: extend(addr), burstLen: burstLenBytes, tag: extend(m.awid()) });
      endrule
      rule handshake_awaddr;
	 m.awready(pack(awfifo.notFull()));
      endrule

      rule rl_wdata if (m.wvalid() == 1);
	 wfifo.enq(MemData { data: m.wdata(), last: unpack(m.wlast()), tag: extend(m.wid()) });
      endrule
      rule handshake_wdata;
	 m.wready(pack(wfifo.notFull()));
      endrule

      rule rl_bresp if (m.bready() == 1);
	 let tag <- toGet(bfifo).get();
	 bresp <= 0;
	 bid <= truncate(tag);
      endrule
      rule handshake_b;
	   m.bvalid(pack(bfifo.notEmpty()));
	   m.bid(bid);
	   m.bresp(bresp);
      endrule

      interface Get writeReq = toGet(awfifo);
      interface Get writeData = toGet(wfifo);
      interface Put writeDone = toPut(bfifo);
   endmodule
endinstance

interface GetObjId#(numeric type addrWidth);
   method SGLId objId(Bit#(addrWidth) axiAddr);
   method Bit#(MemOffsetSize) addr(Bit#(addrWidth) axiAddr);
endinterface
instance AxiToMemReadClient#(GetObjId#(32),32,dataWidth);
   module mkMemReadClient#(GetObjId#(32) objId, Axi4MasterBits#(32,dataWidth,MemTagSize,Empty) m)(MemReadClient#(dataWidth));

      let clock <- exposeCurrentClock();
      let mClock = clockOf(m);
      let reset <- exposeCurrentReset();
      let mReset = resetOf(m);

      Wire#(Bit#(1)) arready <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) rvalid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(MemTagSize)) rid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(2)) rresp <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(dataWidth)) rdata <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) rlast <- mkDWire(0, clocked_by mClock, reset_by mReset);

      FIFOF#(MemRequest)          arfifo;
      FIFOF#(MemData#(dataWidth))  rfifo;
      if ( isAncestor(clock, mClock)) begin
	 arfifo <- mkCFFIFOF();
	 rfifo  <- mkCFFIFOF();
      end
      else begin
	 arfifo <- mkDualClockBramFIFOF(mClock, mReset, clock, reset);
	 rfifo  <- mkDualClockBramFIFOF(clock, reset, mClock, mReset);
      end

      rule rl_araddr if (m.arvalid() == 1);
	 let addr = m.araddr();
	 let burstLenBytes = (extend(m.arlen())+1)*fromInteger(valueOf(TDiv#(dataWidth,8)));
	 arfifo.enq(MemRequest { sglId: objId.objId(addr), offset: objId.addr(addr), burstLen: burstLenBytes, tag: extend(m.arid()) });
      endrule
      rule handshake_ar;
	   m.arready(pack(arfifo.notFull()));
      endrule

      rule rl_rdata if (m.rready() == 1);
	 let md <- toGet(rfifo).get();
	 rdata <= md.data;
	 rlast <= pack(md.last);
	 rresp <= 0;
	 rid <= truncate(md.tag);
      endrule
      rule handshake_rdata;
	 m.rvalid(pack(rfifo.notEmpty()));
	 m.rid(rid);
	 m.rresp(rresp);
	 m.rdata(rdata);
	 m.rlast(rlast);
      endrule

      interface Get readReq = toGet(arfifo);
      interface Put readData = toPut(rfifo);
   endmodule

   module mkMemWriteClient#(GetObjId#(32) objId, Axi4MasterBits#(32,dataWidth,MemTagSize,Empty) m)(MemWriteClient#(dataWidth));

      let clock <- exposeCurrentClock();
      let mClock = clockOf(m);
      let reset <- exposeCurrentReset();
      let mReset = resetOf(m);

      Wire#(Bit#(1)) awready <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) wready <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(1)) bvalid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(MemTagSize)) bid <- mkDWire(0, clocked_by mClock, reset_by mReset);
      Wire#(Bit#(2)) bresp <- mkDWire(0, clocked_by mClock, reset_by mReset);

      FIFOF#(MemRequest)       awfifo;
      FIFOF#(MemData#(dataWidth)) wfifo;
      FIFOF#(Bit#(MemTagSize))    bfifo;
      if ( isAncestor(clock, mClock)) begin
	 awfifo   <- mkCFFIFOF();
	 wfifo <- mkCFFIFOF();
	 bfifo <- mkCFFIFOF();
      end
      else begin
	 awfifo   <- mkDualClockBramFIFOF(mClock, mReset, clock, reset);
	 wfifo <- mkDualClockBramFIFOF(mClock, mReset, clock, reset);
	 bfifo <- mkDualClockBramFIFOF(clock, reset, mClock, mReset);
      end

      rule rl_awaddr if (m.awvalid() == 1);
	 let addr = m.awaddr();
	 let burstLenBytes = (extend(m.awlen())+1)*fromInteger(valueOf(TDiv#(dataWidth,8)));
	 awfifo.enq(MemRequest { sglId: objId.objId(addr), offset: objId.addr(addr), burstLen: burstLenBytes, tag: extend(m.awid()) });
      endrule
      rule handshake_awaddr;
	 m.awready(pack(awfifo.notFull()));
      endrule

      rule rl_wdata if (m.wvalid() == 1);
	 wfifo.enq(MemData { data: m.wdata(), last: unpack(m.wlast()), tag: extend(m.wid()) });
      endrule
      rule handshake_wdata;
	 m.wready(pack(wfifo.notFull()));
      endrule

      rule rl_bresp if (m.bready() == 1);
	 let tag <- toGet(bfifo).get();
	 bresp <= 0;
	 bid <= truncate(tag);
      endrule
      rule handshake_b;
	   m.bvalid(pack(bfifo.notEmpty()));
	   m.bid(bid);
	   m.bresp(bresp);
      endrule

      interface Get writeReq = toGet(awfifo);
      interface Get writeData = toGet(wfifo);
      interface Put writeDone = toPut(bfifo);
   endmodule
endinstance

typedef AxiMasterBits#(32,32,12,Empty) Pps7Maxigp;
typedef AxiSlaveBits#(32,32,6,Empty) Pps7Saxigp;
typedef AxiSlaveBits#(32,64,6,HPType) Pps7Saxihp;
typedef AxiSlaveBits#(32,64,3,ACPType) Pps7Saxiacp;
