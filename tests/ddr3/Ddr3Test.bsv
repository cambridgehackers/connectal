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
import MemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import Pipe::*;
import AxiDdr3Controller::*;
import GetPutWithClocks::*;
import AxiMasterSlave::*;
import Axi4MasterSlave::*;
import AxiDdr3Wrapper  ::*;
import AxiDma::*;
import ConnectalConfig::*;
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
   interface Ddr3Pins ddr3;
endinterface

typedef TDiv#(Ddr3DataWidth,DataBusWidth) BusRatio;

module mkDdr3Test#(HostInterface host, Ddr3TestIndication indication)(Ddr3Test);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   Clock clk200 = host.tsys_clk_200mhz_buf;

   let ddr3Controller <- mkDdr3(clk200);
   MemReadEngine#(DataBusWidth,DataBusWidth,1,1)  re <- mkMemReadEngine();
   MemWriteEngine#(DataBusWidth,DataBusWidth,1,1)  we <- mkMemWriteEngine();

   FIFOF#(Bit#(32))   writeReqFifo <- mkFIFOF();
   FIFOF#(Bit#(32))   readReqFifo <- mkFIFOF();

   Gearbox#(1,BusRatio,Bit#(DataBusWidth)) dramWriteGearbox <- mk1toNGearbox(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);
   SyncFIFOIfc#(Axi4WriteRequest#(Ddr3AddrWidth,6)) awfifo <- mkSyncFIFO(8, clock, reset, ddr3Controller.uiClock);
   SyncFIFOIfc#(Axi4WriteResponse#(6)) bfifo <- mkSyncFIFO(8, ddr3Controller.uiClock, ddr3Controller.uiReset, clock);
   mkConnection(toGet(awfifo), ddr3Controller.slave.req_aw);
   mkConnection(ddr3Controller.slave.resp_b, toPut(bfifo));

   Reg#(Bit#(Ddr3AddrWidth)) dramWriteOffset <- mkReg(0);
   Reg#(Bit#(Ddr3AddrWidth)) dramWriteLimit <- mkReg(0);
   rule rl_req_aw if (dramWriteOffset < dramWriteLimit);
      awfifo.enq(Axi4WriteRequest {
	 address: truncate(dramWriteOffset),
	 len: 1,
	 size: axiBusSize(valueOf(Ddr3DataWidth)),
	 id: 0,
	 burst: 2'b01,
	 prot: 3'b000,   //ignored
	 cache: 4'b0011, //ignored
	 lock: 2'b00,    //ignored
	 qos: 4'b0000    //ignored
	 });
      dramWriteOffset <= dramWriteOffset + 1;
   endrule

   rule rl_wdata_gb;
      let rdata <- toGet(re.readServers[0].data).get();
      dramWriteGearbox.enq(vec(rdata.data));
   endrule
   rule rl_wdata;
      let mds <- toGet(dramWriteGearbox).get();
      ddr3Controller.slave.resp_write.put(Axi4WriteData {
	 data: pack(mds),
	 byteEnable: maxBound,
	 last: 1,
	 id: 0
	 });
   endrule

   rule rl_b;
      let b <- toGet(bfifo).get();
      // let's see an indication, but we should be counting how many words were sent
      indication.writeDone(extend(b.id));
   endrule

   rule rl_write_start;
      let sglId <- toGet(writeReqFifo).get();
      dramWriteOffset <= 0;
      dramWriteLimit <= 1024/fromInteger(valueOf(Ddr3DataWidth));
      re.readServers[0].request.put(MemengineCmd { sglId: sglId,
						  base: 0,
						  burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
						  len: 1024,
						  tag: 0
						  });
   endrule

   Gearbox#(BusRatio,1,Bit#(DataBusWidth)) dramReadGearbox <- mkNto1Gearbox(ddr3Controller.uiClock, ddr3Controller.uiReset, clock, reset);
   SyncFIFOIfc#(Axi4ReadRequest#(Ddr3AddrWidth,6)) arfifo <- mkSyncFIFO(8, clock, reset, ddr3Controller.uiClock);
   mkConnection(toGet(arfifo), ddr3Controller.slave.req_ar);

   Reg#(Bit#(Ddr3AddrWidth)) dramReadOffset <- mkReg(0);
   Reg#(Bit#(Ddr3AddrWidth)) dramReadLimit <- mkReg(0);
   rule rl_req_ar if (dramReadOffset < dramReadLimit);
      arfifo.enq(Axi4ReadRequest {
	 address: truncate(dramReadOffset),
	 len: 1,
	 size: axiBusSize(valueOf(Ddr3DataWidth)),
	 id: 0,
	 burst: 2'b01,
	 prot: 3'b000,   //ignored
	 cache: 4'b0011, //ignored
	 lock: 2'b00,    //ignored
	 qos: 4'b0000    //ignored
	 });
      dramReadOffset <= dramReadOffset + 1;
   endrule

   rule rl_rdata;
      let resp <- ddr3Controller.slave.resp_read.get();
      Vector#(BusRatio, Bit#(DataBusWidth)) data = unpack(resp.data);
      dramReadGearbox.enq(data);
   endrule
   rule rl_rdata_gb;
      Bit#(DataBusWidth) rdata <- toGet(dramReadGearbox).get();
      //fixme last
      we.writeServers[0].data.enq(rdata);
   endrule

   rule rl_read_start;
      let sglId <- toGet(readReqFifo).get();
      dramReadOffset <= 0;
      dramReadLimit <= 1024/fromInteger(valueOf(Ddr3DataWidth));
      we.writeServers[0].request.put(MemengineCmd { sglId: sglId,
						   base: 0,
						   burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
						   len: 1024,
						   tag: 0
						   });
   endrule

   interface Ddr3TestRequest request;
      method Action startWriteDram(Bit#(32) sglId);
	 writeReqFifo.enq(sglId);
      endmethod
      method Action startReadDram(Bit#(32) sglId);
	 readReqFifo.enq(sglId);
      endmethod
   endinterface
   interface MemReadClient readClient = vec(re.dmaClient);
   interface MemWriteClient writeClient = vec(we.dmaClient);
   interface AxiDdr3 ddr3 = ddr3Controller.ddr3;
endmodule
