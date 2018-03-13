// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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
import Clocks::*;
import Vector::*;
import BuildVector::*;
import GetPut::*;
import Connectable::*;
import ClientServer::*;
import ConnectalMemory::*;
import FIFOF::*;
import Gearbox::*;
import GearboxGetPut::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import Pipe::*;
import AvalonDdr3Controller::*;
import GetPutWithClocks::*;
import AxiMasterSlave::*;
import Axi4MasterSlave::*;
import ALTERA_DDR3_WRAPPER::*;
import AxiDma::*;
import ConnectalConfig::*;
import ConnectalClocks::*;
import HostInterface::*;

interface Ddr3TestRequest;
   method Action startWriteDram(Bit#(32) sglId);
   method Action startReadDram(Bit#(32) sglId);
endinterface

interface Ddr3TestIndication;
   method Action writeDone(Bit#(32) v);
   method Action readDone(Bit#(32) v);
endinterface

interface Ddr3Test;
   interface Ddr3TestRequest request;
   interface Vector#(1, MemReadClient#(DataBusWidth)) readClient;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) writeClient;
   interface Ddr3Pins pins;
endinterface

typedef TDiv#(Ddr3DataWidth,DataBusWidth) BusRatio;

module mkDdr3Test#(HostInterface host, Ddr3TestIndication indication)(Ddr3Test);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   B2C1 iclock_50 <- mkB2C1();

   let ddr3Controller <- mkDdr3(iclock_50.c);
//   MemReadEngine#(DataBusWidth,DataBusWidth,1,1)  re <- mkMemReadEngine();
//   MemWriteEngine#(DataBusWidth,DataBusWidth,1,1)  ddr3we <- mkMemWriteEngine();
//   MemWriteEngine#(DataBusWidth,DataBusWidth,1,1)  we <- mkMemWriteEngine();
//   MemReadEngine#(DataBusWidth,DataBusWidth,1,1)  ddr3re <- mkMemReadEngine();
//
//   FIFOF#(Bit#(32))   writeReqFifo <- mkFIFOF();
//   FIFOF#(Bit#(32))   readReqFifo <- mkFIFOF();
//
//   Gearbox#(1,BusRatio,MemData#(DataBusWidth)) dramWriteGearbox <- mk1toNGearbox(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);
//   SyncFIFOIfc#(Axi4WriteRequest#(Ddr3AddrWidth,6)) awfifo <- mkSyncFIFO(4, clock, reset, ddr3Controller.uiClock);
//   SyncFIFOIfc#(Axi4WriteResponse#(6)) bfifo <- mkSyncFIFO(4, ddr3Controller.uiClock, ddr3Controller.uiReset, clock);
//   mkConnection(toGet(awfifo), ddr3Controller.slave.req_aw);
//   mkConnection(ddr3Controller.slave.resp_b, toPut(bfifo));
//
//   rule rl_req_aw;
//      let req <- ddr3we.dmaClient.writeReq.get();
//      awfifo.enq(Axi4WriteRequest {
//	 address: truncate(req.offset),
//	 len: 1,
//	 size: axiBusSize(valueOf(Ddr3DataWidth)),
//	 id: req.tag,
//	 burst: 2'b01,
//	 prot: 3'b000,   //ignored
//	 cache: 4'b0011, //ignored
//	 lock: 2'b00,    //ignored
//	 qos: 4'b0000    //ignored
//	 });
//   endrule
//
//   mkConnection(ddr3we.dmaClient.writeData, toPut(dramWriteGearbox));
//   rule rl_wdata;
//      let mds <- toGet(dramWriteGearbox).get();
//      function Bit#(DataBusWidth) md_data(Integer i); return mds[i].data; endfunction
//      Vector#(BusRatio, Bit#(DataBusWidth)) data = genWith(md_data);
//      ddr3Controller.slave.resp_write.put(Axi4WriteData {
//	 data: pack(data),
//	 byteEnable: maxBound,
//	 last: 1,
//	 id: mds[0].tag
//	 });
//   endrule
//
//   rule rl_b;
//      let b <- toGet(bfifo).get();
//      ddr3we.dmaClient.writeDone.put(b.id);
//   endrule
//
//   rule rl_write_start;
//      let sglId <- toGet(writeReqFifo).get();
//      re.readServers[0].request.put(MemengineCmd { sglId: sglId,
//						  base: 0,
//						  burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
//						  len: 1024,
//						  tag: 0
//						  });
//      ddr3we.writeServers[0].request.put(MemengineCmd { sglId: 0,
//						       base: 0,
//						       burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
//						       len: 1024,
//						       tag: 0
//						       });
//   endrule
//
//   Gearbox#(BusRatio,1,MemData#(DataBusWidth)) dramReadGearbox <- mkNto1Gearbox(ddr3Controller.uiClock, ddr3Controller.uiReset, clock, reset);
//   SyncFIFOIfc#(Axi4ReadRequest#(Ddr3AddrWidth,6)) arfifo <- mkSyncFIFO(4, clock, reset, ddr3Controller.uiClock);
//   mkConnection(toGet(arfifo), ddr3Controller.slave.req_ar);
//
//   rule rl_req_ar;
//      let req <- ddr3re.dmaClient.readReq.get();
//      arfifo.enq(Axi4ReadRequest {
//	 address: truncate(req.offset),
//	 len: 1,
//	 size: axiBusSize(valueOf(Ddr3DataWidth)),
//	 id: req.tag,
//	 burst: 2'b01,
//	 prot: 3'b000,   //ignored
//	 cache: 4'b0011, //ignored
//	 lock: 2'b00,    //ignored
//	 qos: 4'b0000    //ignored
//	 });
//   endrule
//
//   rule rl_rdata;
//      let resp <- ddr3Controller.slave.resp_read.get();
//      Vector#(BusRatio, Bit#(DataBusWidth)) datavec = unpack(resp.data);
//
//      function MemData#(DataBusWidth) to_md_data(Integer i);
//	 return MemData { data: datavec[i], last: True, tag: resp.id };
//      endfunction
//      Vector#(BusRatio, MemData#(DataBusWidth)) data = genWith(to_md_data);
//      dramReadGearbox.enq(data);
//   endrule
//   mkConnection(toGet(dramReadGearbox), ddr3re.dmaClient.readData);
//
//   rule rl_read_start;
//      let sglId <- toGet(readReqFifo).get();
//      we.writeServers[0].request.put(MemengineCmd { sglId: sglId,
//						   base: 0,
//						   burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
//						   len: 1024,
//						   tag: 0
//						   });
//      ddr3re.readServers[0].request.put(MemengineCmd { sglId: 0,
//						      base: 0,
//						      burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
//						      len: 1024,
//						      tag: 0
//						      });
//   endrule

//   interface Ddr3TestRequest request;
//      method Action startWriteDram(Bit#(32) sglId);
//	 writeReqFifo.enq(sglId);
//      endmethod
//      method Action startReadDram(Bit#(32) sglId);
//	 readReqFifo.enq(sglId);
//      endmethod
//   endinterface
//   interface MemReadClient readClient = vec(re.dmaClient);
//   interface MemWriteClient writeClient = vec(we.dmaClient);

   interface `PinType pins;
      method Action osc_50(Bit#(1) b3d, Bit#(1) b4a, Bit#(1) b4d, Bit#(1) b7a, Bit#(1) b7d, Bit#(1) b8a, Bit#(1) b8d);
         iclock_50.inputclock(b7a);
      endmethod
      interface ddr3 = (interface Ddr3;
         interface rzq_4 = ddr3Controller.rzq_4;
         interface ddr3b = ddr3Controller.ddr3b;
         interface sysclk_deleteme_unused_clock = ddr3Controller.sysclk_deleteme_unused_clock;
         interface sysrst_deleteme_unused_reset = ddr3Controller.sysrst_deleteme_unused_reset;
      endinterface);
   endinterface
endmodule
