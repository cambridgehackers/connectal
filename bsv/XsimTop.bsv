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
import Vector            :: *;
import GetPut::*;
import Connectable::*;
import Portal            :: *;
import Top               :: *;
import HostInterface     :: *;
import Pipe::*;
import CnocPortal::*;
import MemTypes          :: *;
import Pareff            ::*;

`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;
typedef `NumberOfMasters NumberOfMasters;

module  mkXsimHost#(Clock derivedClock, Reset derivedReset)(XsimHost);
   interface derivedClock = derivedClock;
   interface derivedReset = derivedReset;
endmodule

interface XsimSource;
    method Action beat(Bit#(32) v);
endinterface
import "BVI" XsimSource =
module mkXsimSourceBVI#(Bit#(32) portal)(XsimSource);
    port portal = portal;
    method beat(beat) enable(en_beat);
endmodule
module mkXsimSource#(PortalMsgIndication indication)(Empty);
   let tmp <- mkXsimSourceBVI(indication.id);
   rule ind_dst_rdy;
      indication.message.deq();
      tmp.beat(indication.message.first());
   endrule
endmodule

interface MsgSinkR#(numeric type bytes_per_beat);
   method Bool src_rdy();
   method Bit#(32) beat();
endinterface

import "BVI" XsimSink =
module mkXsimSinkBVI#(Bit#(32) portal)(MsgSinkR#(4));
    port portal = portal;
    method src_rdy src_rdy();
    method beat beat();
    schedule (src_rdy, beat) CF (src_rdy, beat);
endmodule
module mkXsimSink#(PortalMsgRequest request)(MsgSinkR#(4));
   let sink <- mkXsimSinkBVI(request.id);
   rule req_src_rdy if (sink.src_rdy);
      request.message.enq(sink.beat);
   endrule
endmodule

interface XsimMemReadWrite;
   method Action write32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
   method Action write64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
   method ActionValue#(Bit#(32)) read32(Bit#(32) handle, Bit#(32) addr);
   method ActionValue#(Bit#(64)) read64(Bit#(32) handle, Bit#(32) addr);
endinterface

import "BVI" XsimMemReadWrite =
module mkXsimReadWrite(XsimMemReadWrite);
   method write32(write32_handle, write32_addr, write32_data) enable (en_write32);
   method write64(write64_handle, write64_addr, write64_data) enable (en_write64);
   method read32_data read32(read32_handle, read32_addr) enable (en_read32);
   method read64_data read64(read64_handle, read64_addr) enable (en_read64);
   schedule (write32, write64, read32, read64) CF (write32, write64, read32, read64);
endmodule

instance ModulePareffReadWrite#(32);
   module mkPareffReadWrite(PareffReadWrite#(32) ifc);
      let rw <- mkXsimReadWrite();
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
	  rw.write32(handle, addr, v);
       endmethod
       method ActionValue#(Bit#(32)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v <- rw.read32(handle, addr);
	  return v;
       endmethod
   endmodule
endinstance
instance ModulePareffReadWrite#(64);
   module mkPareffReadWrite(PareffReadWrite#(64) ifc);
      let rw <- mkXsimReadWrite();
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
	  rw.write64(handle, addr, v);
       endmethod
       method ActionValue#(Bit#(64)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v <- rw.read64(handle, addr);
	  return v;
       endmethod
   endmodule
endinstance
instance ModulePareffReadWrite#(128);
   module mkPareffReadWrite(PareffReadWrite#(128) ifc);
      let rw <- mkXsimReadWrite();
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(128) v);
	  rw.write64(handle, addr, v[63:0]);
	  rw.write64(handle, addr+8, v[127:64]);
       endmethod
       method ActionValue#(Bit#(128)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v0 <- rw.read64(handle, addr);
	  let v1 <- rw.read64(handle, addr+8);
	  return {v1,v0};
       endmethod
   endmodule
endinstance
instance ModulePareffReadWrite#(256);
   module mkPareffReadWrite(PareffReadWrite#(256) ifc);
      let rw <- mkXsimReadWrite();
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(256) v);
	  rw.write64(handle, addr, v[63:0]);
	  rw.write64(handle, addr+8, v[127:64]);
	  rw.write64(handle, addr+16, v[191:128]);
	  rw.write64(handle, addr+24, v[255:192]);
       endmethod
       method ActionValue#(Bit#(256)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v0 <- rw.read64(handle, addr);
	  let v1 <- rw.read64(handle, addr+8);
	  let v2 <- rw.read64(handle, addr+16);
	  let v3 <- rw.read64(handle, addr+24);
	  return {v3,v2,v1,v0};
       endmethod
   endmodule
endinstance

module mkXsimMemoryConnection#(PhysMemMaster#(addrWidth, dataWidth) master)(Empty)
   provisos (Mul#(TDiv#(dataWidth, 8), 8, dataWidth),
	     ModulePareffReadWrite#(dataWidth));
   PhysMemSlave#(addrWidth,dataWidth) slave <- mkPareffDmaMaster();
   mkConnection(master, slave);
endmodule

module mkXsimTop(Empty);
   Clock derivedClock <- exposeCurrentClock;
   Reset derivedReset <- exposeCurrentReset;

   Reg#(Bool) dumpstarted <- mkReg(False);
   rule startdump if (!dumpstarted);
      //$dumpfile("dump.vcd");
      //$dumpvars;
      dumpstarted <= True;
   endrule
   XsimHost host <- mkXsimHost(derivedClock, derivedReset);
   let top <- mkCnocTop(
`ifdef IMPORT_HOSTIF
       host
`endif
       );
   mapM_(mkXsimSource, top.indications);
   mapM_(mkXsimSink, top.requests);
   mapM_(mkXsimMemoryConnection, top.masters);
endmodule
