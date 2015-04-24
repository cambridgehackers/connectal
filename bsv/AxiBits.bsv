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

interface AxiSlaveBits#(numeric type addrWidth, numeric type dataWidth, numeric type tagWidth,
    type extraType);
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

typedef AxiMasterBits#(32,32,12,Empty) Pps7Maxigp;
typedef AxiSlaveBits#(32,32,6,Empty) Pps7Saxigp;
typedef AxiSlaveBits#(32,64,6,HPType) Pps7Saxihp;
typedef AxiSlaveBits#(32,64,3,ACPType) Pps7Saxiacp;
