// Copyright (c) 2015 Connectal Project.

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
import Connectable::*;
import ConnectalBramFifo::*;

interface AvmmMasterBits#(numeric type addrWidth, numeric type dataWidth);
    method Bit#(addrWidth) address();
    method Bit#(4)     burstcount();
    method Bit#(4)     byteenable();
    method Bit#(1)     read();
    method Action      readdata(Bit#(dataWidth) v);
    method Action      readdatavalid(Bit#(1) v);
    method Action      waitrequest(Bit#(1) v);
    method Bit#(1)     write();
    method Bit#(dataWidth) writedata();
endinterface

interface AvmmSlaveBits#(numeric type addrWidth, numeric type dataWidth);
    method Action      address(Bit#(addrWidth) v);
    method Action      burstcount(Bit#(4) v);
    method Action      byteenable(Bit#(4) v);
    method Action      read(Bit#(1) v);
    method Bit#(dataWidth) readdata();
    method Bit#(1)     readdatavalid();
    method Bit#(1)     waitrequest();
    method Action      write(Bit#(1) v);
    method Action      writedata(Bit#(dataWidth) v);
endinterface


module mkFIFOF(FIFOF#(t)) provisos(Bits#(t, tSz));
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

instance MkPhysMemSlave#(AvmmSlaveBits#(axiAddrWidth,dataWidth),addrWidth,dataWidth)
    provisos (Add#(axiAddrWidth,a__,addrWidth));
    module mkPhysMemSlave#(AvmmSlaveBits#(axiAddrWidth,dataWidth) axiSlave)(PhysMemSlave#(addrWidth,dataWidth));
    FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) arfifo <- mkFIFOF();
    FIFOF#(MemData#(dataWidth)) rfifo <- mkFIFOF();
    FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) awfifo <- mkFIFOF();
    FIFOF#(MemData#(dataWidth)) wfifo <- mkFIFOF();
    FIFOF#(Bit#(MemTagSize)) bfifo <- mkFIFOF();
    FIFOF#(Bit#(MemTagSize)) rtagfifo <- mkFIFOF();
    FIFOF#(Bit#(MemTagSize)) wtagfifo <- mkFIFOF();

//    rule rl_arvalid_araddr;
//        axiSlave.arvalid(pack(arfifo.notEmpty && rtagfifo.notFull));
//        let addr = 0;
//        if (arfifo.notEmpty)
//            addr = truncate(arfifo.first.addr);
//        axiSlave.araddr(addr);
//    endrule
//    rule rl_arfifo if (axiSlave.arready() == 1);
//        let req <- toGet(arfifo).get();
//        rtagfifo.enq(req.tag);
//    endrule
//    rule rl_rready;
//        axiSlave.rready(pack(rfifo.notFull && rtagfifo.notEmpty));
//    endrule
//    rule rl_rdata if (axiSlave.rvalid() == 1);
//        let rtag <- toGet(rtagfifo).get();
//        rfifo.enq(MemData { data: axiSlave.rdata(), tag: rtag } );
//    endrule
//
//    rule rl_awvalid_awaddr;
//        axiSlave.awvalid(pack(awfifo.notEmpty && wtagfifo.notFull));
//        let addr = 0;
//        if (awfifo.notEmpty)
//            addr = truncate(awfifo.first.addr);
//        axiSlave.awaddr(addr);
//    endrule
//    rule rl_awfifo if (axiSlave.awready() == 1);
//        let req <- toGet(awfifo).get();
//        wtagfifo.enq(req.tag);
//    endrule
//    rule rl_wvalid;
//        axiSlave.wvalid(pack(wfifo.notEmpty));
//    endrule
//    rule rl_wdata if (axiSlave.wready() == 1);
//        let wdata = wfifo.first.data;
//        wfifo.deq();
//        axiSlave.wdata(wdata);
//    endrule
//    rule rl_bready;
//        axiSlave.bready(pack(wtagfifo.notEmpty && bfifo.notFull));
//    endrule
//    rule rl_done if (axiSlave.bvalid() == 1);
//        let tag <- toGet(wtagfifo).get();
//        bfifo.enq(tag);
//    endrule

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


