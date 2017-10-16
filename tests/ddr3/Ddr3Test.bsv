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
import ConnectalBramFifo::*;
import FIFOF::*;
import Gearbox::*;
import GearboxGetPut::*;
import ConnectalMemTypes::*;
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
import Probe::*;

interface Ddr3TestRequest;
   method Action startWriteDram(Bit#(32) sglId, Bit#(32) transferBytes);
   method Action startReadDram(Bit#(32) sglId, Bit#(32) transferBytes);
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
typedef TDiv#(Ddr3DataWidth,8) Ddr3DataBytes;

module mkDdr3Test#(HostInterface host, Ddr3TestIndication indication)(Ddr3Test);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   Reg#(Bit#(Ddr3AddrWidth)) transferLen <- mkReg(256);

   Clock clk200 = host.tsys_clk_200mhz_buf;

   let ddr3Controller <- mkDdr3(clk200);
   MemReadEngine#(DataBusWidth,DataBusWidth,1,1)  re <- mkMemReadEngine();
   MemWriteEngine#(DataBusWidth,DataBusWidth,1,1)  we <- mkMemWriteEngine();

   FIFOF#(Bit#(32))   writeReqFifo <- mkFIFOF();
   FIFOF#(Bit#(32))   readReqFifo <- mkFIFOF();

   Probe#(Bit#(Ddr3AddrWidth)) aw_req_probe <- mkProbe();
   Reg#(Bit#(Ddr3AddrWidth)) dramWriteLimitProbe <- mkReg(0);
   Reg#(Bit#(Ddr3AddrWidth)) dramReadLimitProbe <- mkReg(0);

   Probe#(Bit#(Ddr3AddrWidth)) awAddrProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Bit#(8)) awLenProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Bit#(3)) awSizeProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Vector#(BusRatio,Bit#(DataBusWidth))) wdataProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Axi4WriteResponse#(6)) bProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Bit#(Ddr3AddrWidth)) arAddrProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Bit#(8)) arLenProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Bit#(3)) arSizeProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   Probe#(Vector#(BusRatio,Bit#(DataBusWidth))) rdataProbe <- mkProbe(clocked_by ddr3Controller.uiClock, reset_by ddr3Controller.uiReset);
   let sglWriteProbe <- mkProbe();
   let sglReadProbe <- mkProbe();

   Gearbox#(1,BusRatio,Bit#(DataBusWidth)) dramWriteGearbox <- mk1toNGearbox(clock, reset, clock, reset);
   FIFOF#(Vector#(BusRatio,Bit#(DataBusWidth))) dramWriteFifo <- mkDualClockBramFIFOF(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);
   FIFOF#(Axi4WriteRequest#(Ddr3AddrWidth,6)) awfifo <- mkDualClockBramFIFOF(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);
   FIFOF#(Axi4WriteResponse#(6)) bfifo <- mkDualClockBramFIFOF(ddr3Controller.uiClock, ddr3Controller.uiReset, clock, reset);
   //mkConnection(toGet(awfifo), ddr3Controller.slave.req_aw);
   //mkConnection(ddr3Controller.slave.resp_b, toPut(bfifo));
   rule rl_awfifo;
      let req <- toGet(awfifo).get();
      awAddrProbe <= req.address;
      awLenProbe <= req.len;
      awSizeProbe <= req.size;
      ddr3Controller.slave.req_aw.put(req);
   endrule
   rule rl_bfifo;
      let b <- ddr3Controller.slave.resp_b.get();
      bProbe <= b;
      bfifo.enq(b);
   endrule

   Reg#(Bit#(Ddr3AddrWidth)) dramWriteOffset <- mkReg(0);
   Reg#(Bit#(Ddr3AddrWidth)) dramWriteLimit <- mkReg(0);
   rule rl_req_aw if (dramWriteOffset < dramWriteLimit);
      Axi4WriteRequest#(Ddr3AddrWidth,6) req = Axi4WriteRequest {
	 address: truncate(dramWriteOffset),
	 len: 0, // indicates 1 beat of data
	 size: axiBusSize(valueOf(Ddr3DataWidth)),
	 id: 0,
	 burst: 2'b01,
	 prot: 3'b000,   //ignored
	 cache: 4'b0011, //ignored
	 lock: 2'b00,    //ignored
	 qos: 4'b0000    //ignored
	 };
      awfifo.enq(req);
      aw_req_probe <= req.address;
      dramWriteOffset <= dramWriteOffset + fromInteger(valueOf(Ddr3DataBytes));
   endrule

   rule rl_wdata_gb;
      let rdata <- toGet(re.readServers[0].data).get();
      dramWriteGearbox.enq(vec(rdata.data));
   endrule
   rule rl_wdata;
      let mds <- toGet(dramWriteGearbox).get();
      dramWriteFifo.enq(mds);
   endrule
   rule rl_writeDataFifo;
      let mds <- toGet(dramWriteFifo).get();
      wdataProbe <= mds;
      ddr3Controller.slave.resp_write.put(Axi4WriteData {
	 data: pack(mds),
	 byteEnable: maxBound,
	 last: 1,
	 id: 0
	 });
   endrule

   rule rl_b;
      // consume the writeDone
      let b <- toGet(bfifo).get();
      // let's see an indication, but we should be counting how many words were sent
      indication.writeDone(extend(b.id));
   endrule

   rule rl_write_start;
      let sglId <- toGet(writeReqFifo).get();
      dramWriteOffset <= 0;
      dramWriteLimit <= transferLen;
      dramWriteLimitProbe <= transferLen;
      re.readServers[0].request.put(MemengineCmd { sglId: sglId,
						  base: 0,
						  burstLen: 128,
						  len: extend(transferLen),
						  tag: 0
						  });
   endrule

   Gearbox#(BusRatio,1,Bit#(DataBusWidth)) dramReadGearbox <- mkNto1Gearbox(ddr3Controller.uiClock, ddr3Controller.uiReset, ddr3Controller.uiClock, ddr3Controller.uiReset);
   FIFOF#(Bit#(DataBusWidth)) dramReadFifo <- mkDualClockBramFIFOF(ddr3Controller.uiClock, ddr3Controller.uiReset, clock, reset);
   FIFOF#(Axi4ReadRequest#(Ddr3AddrWidth,6)) arfifo <- mkDualClockBramFIFOF(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);
   //mkConnection(toGet(arfifo), ddr3Controller.slave.req_ar);
   rule rl_arfifo;
      let req <- toGet(arfifo).get();
      arAddrProbe <= req.address;
      arLenProbe <= req.len;
      arSizeProbe <= req.size;
      ddr3Controller.slave.req_ar.put(req);
   endrule

   Reg#(Bit#(Ddr3AddrWidth)) dramReadOffset <- mkReg(0);
   Reg#(Bit#(Ddr3AddrWidth)) dramReadLimit <- mkReg(0);
   rule rl_req_ar if (dramReadOffset < dramReadLimit);
      Axi4ReadRequest#(Ddr3AddrWidth,6) req = Axi4ReadRequest {
	 address: truncate(dramReadOffset),
	 len: 0, // indicates one beat of data
	 size: axiBusSize(valueOf(Ddr3DataWidth)),
	 id: 0,
	 burst: 2'b01,
	 prot: 3'b000,   //ignored
	 cache: 4'b0011, //ignored
	 lock: 2'b00,    //ignored
	 qos: 4'b0000    //ignored
	 };
      arfifo.enq(req);
      dramReadOffset <= dramReadOffset + fromInteger(valueOf(Ddr3DataBytes));
   endrule

   rule rl_rdata;
      let resp <- ddr3Controller.slave.resp_read.get();
      Vector#(BusRatio, Bit#(DataBusWidth)) data = unpack(resp.data);
      rdataProbe <= data;
      dramReadGearbox.enq(data);
   endrule
   rule rl_rdata_gb;
      Bit#(DataBusWidth) rdata <- toGet(dramReadGearbox).get();
      dramReadFifo.enq(rdata);
   endrule
   rule rl_rdata_slack;
      let rdata <- toGet(dramReadFifo).get();
      //fixme last field
      we.writeServers[0].data.enq(rdata);
   endrule

   rule rl_read_start;
      let sglId <- toGet(readReqFifo).get();
      dramReadOffset <= 0;
      dramReadLimit <= transferLen;
      dramReadLimitProbe <= transferLen;
      we.writeServers[0].request.put(MemengineCmd { sglId: sglId,
						   base: 0,
						   burstLen: 128,
						   len: extend(transferLen),
						   tag: 0
						   });
   endrule

   rule rl_read_done;
      let done <- we.writeServers[0].done.get();
      indication.readDone(0);
   endrule

   interface Ddr3TestRequest request;
      method Action startWriteDram(Bit#(32) sglId, Bit#(32) transferBytes);
	 sglWriteProbe <= sglId;
	 transferLen <= truncate(transferBytes);
	 writeReqFifo.enq(sglId);
      endmethod
      method Action startReadDram(Bit#(32) sglId, Bit#(32) transferBytes);
	 sglReadProbe <= sglId;
	 transferLen <= truncate(transferBytes);
	 readReqFifo.enq(sglId);
      endmethod
   endinterface
   interface MemReadClient readClient = vec(re.dmaClient);
   interface MemWriteClient writeClient = vec(we.dmaClient);
   interface AxiDdr3 ddr3 = ddr3Controller.ddr3;
endmodule
