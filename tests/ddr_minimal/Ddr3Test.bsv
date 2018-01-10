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
   interface Ddr3Pins ddr3;
endinterface

typedef TDiv#(Ddr3DataWidth,8) Ddr3DataBytes;

// This minimal example only have one request or response flying at a time. Ensured by software.
module mkDdr3Test#(HostInterface host, Ddr3TestIndication indication)(Ddr3Test);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   Reg#(Bit#(Ddr3AddrWidth)) transferLen <- mkReg(256);

   Clock clk200 = host.tsys_clk_200mhz_buf;

   let ddr3Controller <- mkDdr3(clk200);
   let idC <- mkReg(0);

   FIFOF#(Bit#(32))   writeReqFifo <- mkFIFOF();
   FIFOF#(Bit#(32))   readReqFifo <- mkFIFOF();

   // Logic to handle writes
   Reg#(Bit#(Ddr3AddrWidth)) dramWriteOffset <- mkReg(0);
   Reg#(Bit#(Ddr3AddrWidth)) dramWriteLimit <- mkReg(0);
   FIFOF#(Bit#(Ddr3DataWidth)) dramWriteFifo <- mkDualClockBramFIFOF(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);
   FIFOF#(Axi4WriteRequest#(Ddr3AddrWidth,6)) awfifo <- mkDualClockBramFIFOF(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);
   FIFOF#(Axi4WriteResponse#(6)) bfifo <- mkDualClockBramFIFOF(ddr3Controller.uiClock, ddr3Controller.uiReset, clock, reset);

   rule rl_write_start;
      let dummy <- toGet(writeReqFifo).get();
      dramWriteOffset <= 0;
      dramWriteLimit <= transferLen;
   endrule

   rule rl_req_aw if (dramWriteOffset < dramWriteLimit);
      Axi4WriteRequest#(Ddr3AddrWidth,6) req = Axi4WriteRequest {
	 address: truncate(dramWriteOffset),
	 len: 0, // indicates 1 beat of data
	 size: axiBusSize(valueOf(Ddr3DataWidth)),
	 id: idC,
	 burst: 2'b01,
	 prot: 3'b000,   //ignored
	 cache: 4'b0011, //ignored
	 lock: 2'b00,    //ignored
	 qos: 4'b0000    //ignored
	 };
      idC <= idC + 1;
      awfifo.enq(req);
      dramWriteFifo.enq(zeroExtend(dramWriteOffset));
      dramWriteOffset <= dramWriteOffset + fromInteger(valueOf(Ddr3DataBytes));
   endrule

////////// Begin DDR clock domain 
   rule rl_awfifo;
      let req <- toGet(awfifo).get();
      ddr3Controller.slave.req_aw.put(req);
   endrule

   rule rl_writeDataFifo;
      let mds <- toGet(dramWriteFifo).get();
      ddr3Controller.slave.resp_write.put(Axi4WriteData {
	 data: pack(mds),
	 byteEnable: maxBound,
	 last: 1,
	 id: 0
	 });
   endrule

// Response from the DDR 
  rule rl_bfifo;
      let b <- ddr3Controller.slave.resp_b.get();
      bfifo.enq(b);
   endrule
/////////// End clock domain DDR

   rule rl_b;
      let b <- toGet(bfifo).get();
      indication.writeDone(extend(b.id));
   endrule

   // Logic to handle read
   Reg#(Bit#(Ddr3AddrWidth)) dramReadOffset <- mkReg(0);
   Reg#(Bit#(Ddr3AddrWidth)) dramReadLimit <- mkReg(0);
   FIFOF#(Bit#(Ddr3DataWidth)) dramReadFifo <- mkDualClockBramFIFOF(ddr3Controller.uiClock, ddr3Controller.uiReset, clock, reset);
   FIFOF#(Axi4ReadRequest#(Ddr3AddrWidth,6)) arfifo <- mkDualClockBramFIFOF(clock, reset, ddr3Controller.uiClock, ddr3Controller.uiReset);

   rule rl_read_start;
      let sglId <- toGet(readReqFifo).get();
      dramReadOffset <= 0;
      dramReadLimit <= transferLen;
   endrule

   rule rl_req_ar if (dramReadOffset < dramReadLimit);
      Axi4ReadRequest#(Ddr3AddrWidth,6) req = Axi4ReadRequest {
	 address: truncate(dramReadOffset),
	 len: 0, // indicates one beat of data
	 size: axiBusSize(valueOf(Ddr3DataWidth)),
	 id: idC,
	 burst: 2'b01,
	 prot: 3'b000,   //ignored
	 cache: 4'b0011, //ignored
	 lock: 2'b00,    //ignored
	 qos: 4'b0000    //ignored
	 };
      arfifo.enq(req);
      idC <= idC + 1;
      dramReadOffset <= dramReadOffset + fromInteger(valueOf(Ddr3DataBytes));
   endrule

/////// Begin DDR clock domain 

   rule rl_arfifo;
      let req <- toGet(arfifo).get();
      ddr3Controller.slave.req_ar.put(req);
   endrule

   rule rl_rdata;
      let resp <- ddr3Controller.slave.resp_read.get();
      Bit#(Ddr3DataWidth) data = resp.data;
      dramReadFifo.enq(data);
   endrule

////// End DDR clock domain 

   rule rl_read_done;
      let res <- toGet(dramReadFifo).get();
      indication.readDone(res[31:0]); // Lazy here
   endrule

   interface Ddr3TestRequest request;
      method Action startWriteDram(Bit#(32) sglId, Bit#(32) transferBytes);
	 transferLen <= truncate(transferBytes);
	 writeReqFifo.enq(sglId);
      endmethod
      method Action startReadDram(Bit#(32) sglId, Bit#(32) transferBytes);
	 transferLen <= truncate(transferBytes);
	 readReqFifo.enq(sglId);
      endmethod
   endinterface
   interface AxiDdr3 ddr3 = ddr3Controller.ddr3;
endmodule
