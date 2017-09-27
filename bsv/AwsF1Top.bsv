// Copyright (c) 2017 Connectal Project

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

import ConnectalConfig::*;
import Vector            :: *;
import GetPut::*;
import Connectable::*;
import Portal            :: *;
import Top               :: *;
import HostInterface     :: *;
import Pipe::*;
import CnocPortal::*;
import MemTypes:: *;
import MMU:: *;
import MemServer:: *;
import MMURequest::*;
import MMUIndication::*;
import MemServerIndication::*;
import MemServerRequest::*;
import SimDma::*;
import IfcNames::*;
import BuildVector::*;
import AxiBits::*;
import FIFOF::*;
import CFFIFO::*;

`include "ConnectalProjectConfig.bsv"

`ifdef PinTypeInclude
import `PinTypeInclude::*;
`endif
`ifdef PinType
typedef `PinType PinType;
`else
typedef Empty PinType;
`endif

(* always_enabled, always_ready *)
interface AwsF1ClSh;
   method Bit#(1) flr_done();
   method Bit#(32) status0();
   method Bit#(32) status1();
   method Bit#(32) id0();
   method Bit#(32) id1();
   method Bit#(16) status_vled();
endinterface

(* always_enabled, always_ready *)
interface AwsF1ShCl;
   (* prefix="" *)
   method Action flr_assert(Bit#(1) flr_assert);
   (* prefix="" *)
   method Action ctl0(Bit#(32) ctl0);
   (* prefix="" *)
   method Action ctl1(Bit#(32) ctl1);
   (* prefix="" *)
   method Action status_vdip(Bit#(16) status_vdip);
   (* prefix="" *)
   method Action pwr_state(Bit#(2) pwr_state);
endinterface

(* always_ready, always_enabled *)
interface AwsF1Top;
   interface PinType pins;
   interface AwsF1ShCl sh_cl;
   interface AwsF1ClSh cl_sh;
   interface Axi4SlaveBits#(64,512,6,Empty) dmasink;
   interface Axi4SlaveLiteBits#(32,32) ocl;
   interface Axi4SlaveLiteBits#(32,32) sda;
   interface Axi4SlaveLiteBits#(32,32) bar1;
endinterface

module mkAxi4SlaveLiteBitsFromPhysMemSlave#(PhysMemSlave#(addrWidth,dataWidth) slave)
       (Axi4SlaveLiteBits#(axiaddrWidth,dataWidth)) provisos (Div#(dataWidth,8,burstLen),Add#(addrWidth,a__,axiaddrWidth));

    let burstLen = fromInteger(valueOf(burstLen));

    Wire#(Bit#(addrWidth)) araddrWire <- mkDWire(0);
    Wire#(Bit#(1)) arvalidWire <- mkDWire(0);
    Wire#(Bit#(1)) rreadyWire <- mkDWire(0);
    Wire#(Bit#(dataWidth)) rdataWire <- mkDWire(0);

    Wire#(Bit#(addrWidth)) awaddrWire <- mkDWire(0);
    Wire#(Bit#(1)) awvalidWire <- mkDWire(0);
    Wire#(Bit#(1)) wvalidWire <- mkDWire(0);
    Wire#(Bit#(dataWidth)) wdataWire <- mkDWire(0);
    Wire#(Bit#(1)) breadyWire <- mkDWire(0);

    FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) arFifo <- mkCFFIFOF();
    FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) awFifo <- mkCFFIFOF();
    FIFOF#(MemData#(dataWidth)) rdataFifo <- mkCFFIFOF();
    FIFOF#(MemData#(dataWidth)) wdataFifo <- mkCFFIFOF();
    FIFOF#(Bit#(MemTagSize)) brespFifo <- mkCFFIFOF();

    rule ar_rule if (arvalidWire == 1 && arFifo.notFull());
       let req = PhysMemRequest {addr: araddrWire, burstLen: burstLen, tag: 0 };
       arFifo.enq(req);
    endrule
    rule ar_to_slave;
       let req <- toGet(arFifo).get();
       slave.read_server.readReq.put(req);
    endrule

    rule aw_rule if (awvalidWire == 1 && awFifo.notFull());
       let req = PhysMemRequest {addr: awaddrWire, burstLen: burstLen, tag: 0 };
       awFifo.enq(req);
    endrule
    rule aw_to_slave;
       let req <- toGet(awFifo).get();
       slave.write_server.writeReq.put(req);
    endrule

    rule r_rule if (rreadyWire == 1 && rdataFifo.notEmpty());
       rdataFifo.deq();
    endrule
    rule rdata_rule;
       rdataWire <= rdataFifo.first.data;
    endrule
    rule rdata_from_slave;
       let mdata <- slave.read_server.readData.get();
       rdataFifo.enq(mdata);
    endrule

    rule wdata_rule if (wvalidWire == 1 && wdataFifo.notFull());
       wdataFifo.enq(MemData { data: wdataWire, tag: 0, last: True });
    endrule
    rule wdata_to_slave;
       let mdata <- toGet(wdataFifo).get();
       slave.write_server.writeData.put(mdata);
    endrule

    rule b_rule if (breadyWire == 1 && brespFifo.notEmpty());
       brespFifo.deq();
    endrule
    rule bresp_from_slave;
       let done <- slave.write_server.writeDone.get();
       brespFifo.enq(done);
    endrule

    method Action      araddr(Bit#(axiaddrWidth) v);
       araddrWire <= truncate(v);
    endmethod
    method Bit#(1)     arready();
       return pack(arFifo.notFull());
    endmethod
    method Action      arvalid(Bit#(1) v);
       arvalidWire <= v;
    endmethod
    method Action      awaddr(Bit#(axiaddrWidth) v);
       awaddrWire <= truncate(v);
    endmethod
    method Bit#(1)     awready();
       return pack(awFifo.notFull());
    endmethod
    method Action      awvalid(Bit#(1) v);
       awvalidWire <= v;
    endmethod
    method Action      bready(Bit#(1) v);
       breadyWire <= v;
    endmethod
    method Bit#(2)     bresp();
       return 0; // brespFifo.first();
    endmethod
    method Bit#(1)     bvalid();
       return pack(brespFifo.notEmpty());
    endmethod
    method Bit#(dataWidth)     rdata();
       return rdataWire;
    endmethod
    method Action      rready(Bit#(1) v);
       rreadyWire <= v;
    endmethod
    method Bit#(2)     rresp();
       return 0;
    endmethod
    method Bit#(1)     rvalid();
      return pack(rdataFifo.notEmpty);
    endmethod
    method Action      wdata(Bit#(dataWidth) v);
       wdataWire <= v;
    endmethod
    method Bit#(1)     wready();
       return pack(wdataFifo.notFull());
    endmethod
    method Action      wvalid(Bit#(1) v);
       wvalidWire <= v;
    endmethod
endmodule


(* no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkAwsF1Top#(Clock clk_main_a0, Clock clk_extra_a1, Clock clk_extra_a2, Clock clk_extra_a3,
       Clock  clk_extra_b0, Clock clk_extra_b1, Clock clk_extra_c0, Clock clk_extra_c1,
       Reset kernel_rst_n, Reset rst_main_n
       )(AwsF1Top);

   Clock defaultClock = clk_main_a0;
   Reset defaultReset = rst_main_n;
   Clock derivedClock = clk_main_a0;
   Reset derivedReset = rst_main_n;

   XsimHost host <- mkXsimHost(clk_main_a0, rst_main_n, clk_main_a0);
   let top <- mkConnectalTop(
`ifdef IMPORT_HOSTIF
       host,
`else
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
       derivedClock, derivedReset,
`else
// otherwise no params
`endif
`endif
	clocked_by defaultClock, reset_by defaultReset
       );

   MMUIndicationOutput lMMUIndicationOutput <- mkMMUIndicationOutput(clocked_by defaultClock, reset_by defaultReset);
   MMURequestInput lMMURequestInput <- mkMMURequestInput(clocked_by defaultClock, reset_by defaultReset);
   MMU#(PhysAddrWidth) lMMU <- mkMMU(0,True, lMMUIndicationOutput.ifc, clocked_by defaultClock, reset_by defaultReset);
   mkConnection(lMMURequestInput.pipes, lMMU.request, clocked_by defaultClock, reset_by defaultReset);

   MemServerIndicationOutput lMemServerIndicationOutput <- mkMemServerIndicationOutput(clocked_by defaultClock, reset_by defaultReset);
   MemServerRequestInput lMemServerRequestInput <- mkMemServerRequestInput(clocked_by defaultClock, reset_by defaultReset);
   MemServer::MemServer#(PhysAddrWidth,DataBusWidth,NumberOfMasters) lMemServer <- mkMemServer(top.readers, top.writers, cons(lMMU,nil), lMemServerIndicationOutput.ifc, clocked_by defaultClock, reset_by defaultReset);
   mkConnection(lMemServerRequestInput.pipes, lMemServer.request, clocked_by defaultClock, reset_by defaultReset);

   let lMMUIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(PlatformIfcNames_MMUIndicationH2S)), lMMUIndicationOutput.portalIfc.indications, lMMUIndicationOutput.portalIfc.messageSize, clocked_by defaultClock, reset_by defaultReset);
   let lMMURequestInputNoc <- mkPortalMsgRequest(extend(pack(PlatformIfcNames_MMURequestS2H)), lMMURequestInput.portalIfc.requests, clocked_by defaultClock, reset_by defaultReset);
   let lMemServerIndicationOutputNoc <- mkPortalMsgIndication(extend(pack(PlatformIfcNames_MemServerIndicationH2S)), lMemServerIndicationOutput.portalIfc.indications, lMemServerIndicationOutput.portalIfc.messageSize, clocked_by defaultClock, reset_by defaultReset);
   let lMemServerRequestInputNoc <- mkPortalMsgRequest(extend(pack(PlatformIfcNames_MemServerRequestS2H)), lMemServerRequestInput.portalIfc.requests, clocked_by defaultClock, reset_by defaultReset);

   Axi4SlaveLiteBits#(32,32) oclSlave <- mkAxi4SlaveLiteBitsFromPhysMemSlave(top.slave, clocked_by defaultClock, reset_by defaultReset);

   interface AwsF1ClSh cl_sh;
      method id0 = 32'hF000_1D0F; // 32'hc100_1be7;
      method id1 = 32'h1D51_FEDD; // 32'hc101_1be7;
   endinterface

   interface ocl = oclSlave;

`ifdef PinType
   interface pins = top.pins;
`endif
endmodule
