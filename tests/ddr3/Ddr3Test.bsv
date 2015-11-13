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
import Ddr3::*;
import GetPutWithClocks::*;
import AxiMasterSlave::*;
import Axi4MasterSlave::*;
import AxiDma::*;
import ConnectalConfig::*;

interface Ddr3TestRequest;
   method Action startWriteDram(Bit#(32) sglId);
endinterface

interface Ddr3TestIndication;
   method Action writeDone(Bit#(32) v);
endinterface

interface Ddr3Test;
   interface Ddr3TestRequest request;
   interface Vector#(1, MemReadClient#(DataBusWidth)) readClient;
endinterface

module mkDdr3Test#(Ddr3TestIndication indication)(Ddr3Test);
   
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   let ddr3 <- mkDdr3(clock); // fixme clocks
   MemReadEngine#(DataBusWidth,DataBusWidth,1,1)  re <- mkMemReadEngine();
   MemWriteEngine#(DataBusWidth,DataBusWidth,1,1)  ddr3we <- mkMemWriteEngine();
      
   FIFOF#(MemRequest) readReqFifo <- mkFIFOF();
   FIFOF#(MemData#(DataBusWidth)) readDataFifo <- mkSizedFIFOF(32);
   
   Gearbox#(1,4,MemData#(DataBusWidth)) gearbox <- mk1toNGearbox(clock, reset, ddr3.uiClock, ddr3.uiReset);
   SyncFIFOIfc#(Axi4WriteRequest#(Ddr3AddrWidth,6)) awfifo <- mkSyncFIFO(4, clock, reset, ddr3.uiClock);
   SyncFIFOIfc#(Axi4WriteResponse#(6)) bfifo <- mkSyncFIFO(4, ddr3.uiClock, ddr3.uiReset, clock);
   mkConnection(toGet(awfifo), ddr3.slave.req_aw);
   mkConnection(ddr3.slave.resp_b, toPut(bfifo));

   rule rl_req_aw;
      let req <- ddr3we.dmaClient.writeReq.get();
      awfifo.enq(Axi4WriteRequest {
	 address: truncate(req.offset),
	 len: 1,
	 size: axiBusSize(valueOf(Ddr3DataWidth)),
	 id: req.tag,
	 burst: 2'b01,
	 prot: 3'b000,   //ignored
	 cache: 4'b0011, //ignored
	 lock: 2'b00,    //ignored
	 qos: 4'b0000    //ignored
	 });
   endrule

   mkConnection(ddr3we.dmaClient.writeData, toPut(gearbox));
   rule rl_wdata;
      let mds <- toGet(gearbox).get();
      function Bit#(DataBusWidth) md_data(Integer i); return mds[i].data; endfunction
      Vector#(4, Bit#(DataBusWidth)) data = genWith(md_data);
      ddr3.slave.resp_write.put(Axi4WriteData {
	 data: pack(data),
	 byteEnable: maxBound,
	 last: 1,
	 id: mds[0].tag
	 });
   endrule

   rule rl_b;
      let b <- toGet(bfifo).get();
      ddr3we.dmaClient.writeDone.put(b.id);
   endrule

   interface Ddr3TestRequest request;
      method Action startWriteDram(Bit#(32) sglId);
	 re.readServers[0].request.put(MemengineCmd { sglId: sglId, 
						     base: 0,
						     burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,DataBusWidth))),
						     len: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
						     tag: 0
						     });
	 ddr3we.writeServers[0].request.put(MemengineCmd { sglId: 0,
							  base: 0,
							  burstLen: fromInteger(valueOf(TDiv#(Ddr3DataWidth,DataBusWidth))),
							  len: fromInteger(valueOf(TDiv#(Ddr3DataWidth,8))),
							  tag: 0
							  });
      endmethod
   endinterface
   interface MemReadClient readClient = vec(re.dmaClient);
endmodule
