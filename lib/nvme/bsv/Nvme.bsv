// Copyright (c) 2016 Connectal Project

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

import Arbitrate::*;
import BRAM::*;
import BuildVector::*;
import Clocks::*;
import Connectable::*;
import FIFOF::*;
import Gearbox::*;
import GetPut::*;
import Probe::*;
import StmtFSM::*;
import Vector::*;

import AddressGenerator::*;
import AxiBits::*;
import AxiStream::*;
import ConnectalClocks::*;
import ConnectalConfig::*;
import DefaultValue::*;
import GearboxGetPut::*;
import HostInterface::*;
import MemReadEngine::*;
import MemTypes::*;
import PhysMemSlaveFromBram::*;
import Pipe::*;
import TraceMemClient::*;
import XilinxCells::*;

`ifndef PCIE3
import AxiPcieRootPort::*;
`else
import AxiPcie3RootPort::*;
`endif
import NvmeIfc::*;
import NvmePins::*;

typedef struct {
   Bit#(8)  opcode;
   Bit#(8)  flags;
   Bit#(16) requestId;
   Bit#(64) startBlock;
   Bit#(32) numBlocks;
   Bit#(32) dsm;
   } NvmeIoCommand deriving (Bits);

`ifndef TOP_SOURCES_PORTAL_CLOCK
import ConnectalBramFifo::*;
`else
import BRAMFIFO::*;
module mkDualClockBramFIFOF#(Clock clock1, Reset reset1, Clock clock2, Reset reset2)(FIFOF#(a))
   provisos (Bits#(a, asz), Add#(1, a__, asz));
   FIFOF#(a) fifo <- mkSizedBRAMFIFOF(512, clocked_by clock1, reset_by reset1);
   return fifo;
endmodule
`endif


function PipeIn#(t) sinkPipe();
   return (interface PipeIn#(a);
	      method Action enq(t v); endmethod
	      method Bool notFull(); return False; endmethod
	   endinterface);
endfunction

instance ArbRequestTC#(BRAMRequest#(a,b));
   function Bool isReadRequest(BRAMRequest#(a,b) x); return !x.write; endfunction
   function Bool isWriteRequest(BRAMRequest#(a,b) x); return x.write; endfunction
endinstance

interface Nvme;
   interface NvmeRequest request;
   interface NvmeDriverRequest driverRequest;
   interface MemServerPortalRequest bramRequest;
   interface NvmeTrace trace;
   interface NvmePins pins;
   interface PipeOut#(MemData#(PcieDataBusWidth)) dataOut;
   interface Vector#(1, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) dmaWriteClient;
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource;
`endif
endinterface

module mkNvme#(NvmeIndication ind, NvmeDriverIndication driverInd, NvmeTrace trace, MemServerPortalIndication bramIndication)(Nvme);
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   let refclk_p <- mkB2C1();
   let refclk_n <- mkB2C1();
   let pcie_clk_100mhz_buf <- mkClockIBUFDS_GTE2(
`ifdef ClockDefaultParam
       defaultValue,
`endif
      True, refclk_p.c, refclk_n.c);
`ifndef TOP_SOURCES_PORTAL_CLOCK
   let axiClockB2C    <- mkB2C1();
   let axiCtlClockB2C <- mkB2C1();
   let axiClock = axiClockB2C.c;
   let axiCtlClock = axiCtlClockB2C.c;
   let axiReset <- mkSyncReset(10, reset, axiClock);
   let axiCtlReset <- mkSyncReset(10, reset, axiCtlClock);
`else
   let axiClock = clock;
   let axiCtlClock = clock;
   let axiReset = reset;
   let axiCtlReset = reset;
`endif

`ifndef PCIE3
   let axiRootPort <- mkAPRP(pcie_clk_100mhz_buf, reset, axiClock, axiReset, axiCtlClock, axiCtlReset);
`else
   let axiRootPort <- mkAPRP(axiCtlClock, pcie_clk_100mhz_buf, reset);
`endif
`ifndef TOP_SOURCES_PORTAL_CLOCK
   let axiClockC2B <- mkC2B(axiRootPort.axi.aclk_out);
   let axiCtlClockC2B <- mkC2B(axiRootPort.axi.ctl_aclk_out);
   rule rl_connect_clocks;
      axiClockB2C.inputclock(axiClockC2B.o);
      axiCtlClockB2C.inputclock(axiClockC2B.o);
   endrule
`endif

   FIFOF#(Bit#(32)) dfifoCtl <- mkFIFOF();
   Axi4SlaveBits#(32,PcieDataBusWidth,4,Empty) axiRootPortSlave = toAxi4SlaveBits(axiRootPort.s_axi);
   Axi4SlaveLiteBits#(32,32)                axiRootPortSlaveCtl = toAxi4SlaveBits(axiRootPort.s_axi_ctl);
   PhysMemSlave#(32,PcieDataBusWidth)       axiRootPortMemSlave <- mkPhysMemSlave(axiRootPortSlave, clocked_by axiClock, reset_by axiReset);
   PhysMemSlave#(32,32)                  axiRootPortMemSlaveCtl <- mkPhysMemSlave(axiRootPortSlaveCtl, clocked_by axiCtlClock, reset_by axiCtlReset);

   FIFOF#(PhysMemRequest#(32,PcieDataBusWidth)) araddrFifo <- mkFIFOF();
   FIFOF#(PhysMemRequest#(32,PcieDataBusWidth)) awaddrFifo <- mkFIFOF();
   FIFOF#(MemData#(PcieDataBusWidth))           rdataFifo <- mkFIFOF();
   FIFOF#(MemData#(PcieDataBusWidth))           wdataFifo <- mkFIFOF();
   FIFOF#(Bit#(6))                           doneFifo <- mkFIFOF();

   let araddrCnx <- mkConnection(toGet(araddrFifo), axiRootPortMemSlave.read_server.readReq);
   let awaddrCnx <- mkConnection(toGet(awaddrFifo), axiRootPortMemSlave.write_server.writeReq);
   let rdataCnx  <- mkConnection(axiRootPortMemSlave.read_server.readData, toPut(rdataFifo));
   let wdataCnx  <- mkConnection(toGet(wdataFifo), axiRootPortMemSlave.write_server.writeData);
   let doneCnx   <- mkConnection(axiRootPortMemSlave.write_server.writeDone, toPut(doneFifo));

   rule rl_rdata;
      let rdata <- toGet(rdataFifo).get();
      if (rdata.tag == 0)
	 driverInd.readDone(truncate(rdata.data));
   endrule

   rule rl_writeDone;
      let tag <- toGet(doneFifo).get();
      if (tag == 0)
	 driverInd.writeDone();
   endrule

   FIFOF#(PhysMemRequest#(32,32)) araddrFifoCtl <- mkFIFOF();
   FIFOF#(PhysMemRequest#(32,32)) awaddrFifoCtl <- mkFIFOF();
   FIFOF#(MemData#(32))           rdataFifoCtl <- mkFIFOF();
   FIFOF#(MemData#(32))           wdataFifoCtl <- mkFIFOF();
   FIFOF#(Bit#(6))                doneFifoCtl <- mkFIFOF();

   let araddrCtlCnx <- mkConnection(toGet(araddrFifoCtl), axiRootPortMemSlaveCtl.read_server.readReq);
   let awaddrCtlCnx <- mkConnection(toGet(awaddrFifoCtl), axiRootPortMemSlaveCtl.write_server.writeReq);
   let rdataCtlCnx  <- mkConnection(axiRootPortMemSlaveCtl.read_server.readData, toPut(rdataFifoCtl));
   let wdataCtlCnx  <- mkConnection(toGet(wdataFifoCtl), axiRootPortMemSlaveCtl.write_server.writeData);
   let doneCtlCnx   <- mkConnection(axiRootPortMemSlaveCtl.write_server.writeDone, toPut(doneFifoCtl));

   Reg#(Bool) inSetup <- mkReg(False);

   rule rl_rdata_ctl if (!inSetup);
      let rdata <- toGet(rdataFifoCtl).get();
      driverInd.readDone(extend(rdata.data));
   endrule

   rule rl_writeDone_ctl if (!inSetup);
      let tag <- toGet(doneFifoCtl).get();
      driverInd.writeDone();
   endrule

   Vector#(12,Tuple2#(Bit#(32),Bit#(32))) initValues = vec( 
      tuple2(32'h00000004, 32'h00000147)
      ,tuple2(32'h00000018, 32'h00070100)
      ,tuple2(32'h00000010, 32'h00000000) // Bridge BAR0
      ,tuple2(32'h00000014, 32'h00000000) // Bridge BAR1
      ,tuple2(32'h00100004, 32'h00000147) // enable card I/O, Memory, bus master, parity and SERR
      ,tuple2(32'h00100010, 32'h00000000) // Card BAR0
      ,tuple2(32'h00100014, 32'h00000000) // Card BAR1
      ,tuple2(32'h00100018, 32'h02200000) // Card BAR2
      ,tuple2(32'h0010001c, 32'h00000000) // Card BAR3
      ,tuple2(32'h00000148, 32'h00000001) // enable bridge
      ,tuple2(32'h00000140, 32'h00010000) // enable bridge
      ,tuple2(0, 0)
      );

   let index <- mkReg(0);
   let setupFsm <- mkFSMWithPred(seq
      index <= 0;
      while (tpl_1(initValues[index]) != 32'h0) seq
	 awaddrFifoCtl.enq(PhysMemRequest {addr: tpl_1(initValues[index]), burstLen: 4, tag: index });
	 wdataFifoCtl.enq(MemData {data: tpl_2(initValues[index]), tag: index, last: True });
	 action
	    let t <- toGet(doneFifoCtl).get();
	    index <= index + 1;
	 endaction
      endseq
      driverInd.setupDone();
      inSetup <= False;
      endseq,
      inSetup);

   Axi4MasterBits#(32,PcieDataBusWidth,MemTagSize,Empty) m_axi_mm = toAxi4MasterBits(axiRootPort.m_axi);
   let getObjId = (interface GetObjId;
		   method SGLId objId(Bit#(32) addr); return extend(addr[31:24]); endmethod
		   method Bit#(MemOffsetSize) addr(Bit#(32) axiAddr); return extend(axiAddr[23:0]); endmethod
		   endinterface);
   let memReadClient  <- mkMemReadClient(getObjId, m_axi_mm);
   let memWriteClient <- mkMemWriteClient(getObjId, m_axi_mm);

   Reg#(Bool) traceEnabled <- mkReg(False);

   FIFOF#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) traceFifo <- mkSizedBRAMFIFOF(128);
   PipeIn#(Tuple4#(DmaChannel,Bool,MemRequest,Bit#(32))) tracePipe = traceEnabled ? toPipeIn(traceFifo) : sinkPipe();
   FIFOF#(Tuple4#(DmaChannel,Bool,MemData#(PcieDataBusWidth),Bit#(32))) traceDataFifo <- mkSizedBRAMFIFOF(2048);
   PipeIn#(Tuple4#(DmaChannel,Bool,MemData#(PcieDataBusWidth),Bit#(32))) traceDataPipe = traceEnabled ? toPipeIn(traceDataFifo) : sinkPipe();
   FIFOF#(Tuple2#(DmaChannel,Bit#(32)))                              traceDoneFifo <- mkSizedBRAMFIFOF(128);
   PipeIn#(Tuple2#(DmaChannel,Bit#(32)))                             traceDonePipe = traceEnabled ? toPipeIn(traceDoneFifo) : sinkPipe();

   rule rl_trace1;
      match { .chan, .write, .req, .timestamp } <- toGet(traceFifo).get();
      trace.traceDmaRequest(chan, write, truncate(req.sglId), extend(req.offset), extend(req.burstLen), extend(req.tag), timestamp);
   endrule
   rule rl_trace_data;
      match { .chan, .write, .md, .timestamp } <- toGet(traceDataFifo).get();
      trace.traceDmaData(chan, write, unpack(md.data), md.last, extend(md.tag), timestamp);
   endrule
   rule rl_trace_done;
      match { .chan, .timestamp } <- toGet(traceDoneFifo).get();
      trace.traceDmaDone(chan, 0, timestamp);
   endrule

   let traceReadClient <- mkTraceReadClient(tracePipe,traceDataPipe,DMA_TX,memReadClient);
   let traceWriteClient <- mkTraceWriteClient(tracePipe,traceDataPipe,traceDonePipe,DMA_RX,memWriteClient);
   let traceClient = (interface MemClient#(PcieDataBusWidth);
			 interface readClient = traceReadClient;
			 interface writeClient = traceWriteClient;
		      endinterface);

   SplitMemServer#(PcieDataBusWidth) splitter <- mkSplitMemServer();
   MemServerGearbox#(PcieDataBusWidth,DataBusWidth) axiGearbox <- mk1toNMemServerGearbox();
   let gearboxCnx <- mkConnection(splitter.busClient, axiGearbox.server);

   let requestSize = 64;
   let responseSize = 16;
   let bytesPerEntry = valueOf(TDiv#(PcieDataBusWidth,8));
   let wordsPerEntry = valueOf(TDiv#(PcieDataBusWidth,32));

   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency = 2;
   bramConfig.memorySize = 4096*4/bytesPerEntry; // 4 pages
   BRAM2Port#(Bit#(32),Bit#(PcieDataBusWidth)) bram <- mkBRAM2Server(bramConfig);

   let arbIfc <- mkFixedPriority();
   Arbiter#(3, BRAMRequest#(Bit#(32),Bit#(PcieDataBusWidth)),Bit#(PcieDataBusWidth)) arbiter <- mkArbiter(arbIfc,2);
   let arbCnx <- mkConnection(arbiter.master, bram.portB);

   MemServer#(PcieDataBusWidth)            bramMemA <- mkMemServerFromBram(bram.portA);
   PhysMemSlave#(32,PcieDataBusWidth)      bramMemB <- mkPhysMemSlaveFromBram(arbiter.users[0]);
   MemServerPortal          bramMemServerPortal <- mkPhysMemSlavePortal(bramMemB,bramIndication);

   let portB1 = arbiter.users[1];
   let portB2 = arbiter.users[2];
   Reg#(Bit#(16)) requestId <- mkReg(0);
   Reg#(Bit#(16)) responseId <- mkReg(0);
   Reg#(Bit#(16)) requestQueueEntryCount <- mkReg(8);
   Reg#(Bool) requestSlotAvailable <- mkReg(True);
   Reg#(Bool) requestInProgress <- mkReg(True);
   Reg#(Vector#(16,Bit#(32))) ioCommand <- mkReg(unpack(0));
   Reg#(Bit#(32)) requestStartTimestamp <- mkReg(0);

   FIFOF#(NvmeIoCommand) ioCommandFifo <- mkFIFOF();
   FIFOF#(NvmeIoCommand) ioSegmentFifo <- mkFIFOF(); // max request size 32

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule rl_cycles;
      cycles <= cycles + 1;
   endrule

   let commandStartProbe <- mkProbe();
   let commandNumBlocksProbe <- mkProbe();
   let segmentStartProbe <- mkProbe();
   let segmentNumBlocksProbe <- mkProbe();
   let completedRequestProbe <- mkProbe();

   Reg#(NvmeIoCommand) ioCommandReg <- mkReg(unpack(0));
   IteratorWithContext#(Bit#(32),NvmeIoCommand) ioIterator <- mkIteratorWithContext();
   let segmenterFsm <- mkAutoFSM(seq
      while (True) seq
	 action
	    let command <- toGet(ioCommandFifo).get();
	    ioIterator.start(IteratorConfig {xbase: 0,
					     xlimit: command.numBlocks,
					     xstep: `BlocksPerRequest},
			     command);
	    commandStartProbe <= command.startBlock;
	    commandNumBlocksProbe <= command.numBlocks;
	 endaction
         while (ioIterator.ivpipe.notEmpty()) seq
	    action
	       let v <- toGet(ioIterator.ivpipe).get();
	       let command = v.ctxt;
	       if (v.last) begin
		  command.numBlocks = command.numBlocks - v.value; //fixme
	       end
	       else begin
		  command.numBlocks = `BlocksPerRequest;
	       end
	       command.startBlock = command.startBlock + extend(v.value);
	       ioSegmentFifo.enq(command);

	       segmentStartProbe <= truncate(command.startBlock) + v.value;
	       segmentNumBlocksProbe <= command.numBlocks;
	    endaction
	 endseq
         completedRequestProbe <= True;
      endseq // while True
      endseq);

   Reg#(Bit#(32)) i <- mkReg(0);

   let bramQueryAddress <- mkProbe();
   let bramQueryResponse <- mkProbe();
   let requestCompleted <- mkProbe();

   let requestFsm <- mkAutoFSM(seq
      while (True) seq
	 action
	    let req <- toGet(ioSegmentFifo).get();
	    Vector#(16,Bit#(32)) command = unpack(0);
	    command[0] = { requestId, req.flags, req.opcode };
	    command[1] = 1; // nsid
	    // prp1: send data to fifo
	    command[6] = 32'h30000000;
	    // p2p2: read PRP list from BRAM at offset 0x2000
	    command[8] = 32'h20002000;
	    command[10] = req.startBlock[31:0];
	    command[11] = req.startBlock[63:32];
	    command[12] = req.numBlocks-1;
	    command[13] = req.dsm;
	    //requestId <= req.requestId;
	    ioCommand <= command;

	    requestSlotAvailable <= False;
	 endaction

	 while (!requestSlotAvailable) seq // wait for open request slot
	    portB1.request.put(BRAMRequest {address: (extend(requestId[2:0]) * fromInteger(responseSize/bytesPerEntry)) + fromInteger(12/bytesPerEntry),
					    write: False, responseOnWrite: False, datain: 0});
	    action
	       let response <- portB1.response.get();
	       let phase = ~requestId[3];
	       if (response[16+(3*32 % valueOf(PcieDataBusWidth))] == ~phase) begin
		  requestSlotAvailable <= True;
	       end
	    endaction
	 endseq // wait for open request slot

	 // write a IO read request to BRAM
         for (i <= 0; i < fromInteger(requestSize/bytesPerEntry); i <= i + 1) seq
	    portB1.request.put(BRAMRequest {address: 'h1000/fromInteger(bytesPerEntry) + (extend(requestId[2:0]) * fromInteger(requestSize/bytesPerEntry)) + i,
					    write: True, responseOnWrite: False,
					    datain: truncate(pack(ioCommand) >> (i*fromInteger(valueOf(PcieDataBusWidth)))) });
         endseq

	 // tell the NVME the new submission queue tail pointer
	 action
	    awaddrFifo.enq(PhysMemRequest { addr: 'h1000 + (2*2+0)*(4<<0), burstLen: 4, tag: 1 });
	    wdataFifo.enq(MemData{data: zeroExtend((requestId+1)[2:0]), tag: 1, last: True});
	    requestInProgress <= True;
	    requestStartTimestamp <= cycles;
	    trace.traceData(unpack(0), False, truncate(requestId), cycles);
	    requestId <= requestId + 1;
	 endaction
      endseq // while True
      endseq);

   let responseFsm <- mkAutoFSM(seq
	 // wait for response queue to be updated
      while (True) seq
	 requestInProgress <= True;
	 while (requestInProgress) seq
	    portB2.request.put(BRAMRequest {address: (extend(responseId[2:0]) * fromInteger(responseSize/bytesPerEntry)) + fromInteger(12/bytesPerEntry),
					    write: False, responseOnWrite: False, datain: 0});
	    bramQueryAddress <= (responseId * fromInteger(responseSize/bytesPerEntry)) + fromInteger(12/bytesPerEntry);
	    action
	       let response <- portB2.response.get();
	       bramQueryResponse <= response;
	       let phase = ~responseId[3];
	       if (response[16+(3*32 % valueOf(PcieDataBusWidth))] == phase) begin
		  requestCompleted <= response;
		  // if status field written by NVME
		  ind.transferCompleted(responseId, truncate(response), cycles - requestStartTimestamp);
		  requestInProgress <= False;
	       end
	    endaction
	 endseq // while requestInProgress

	 // tell the NVME the new response queue head pointer
	 action
	    let nextRequestId = (responseId + 1);
	    responseId <= nextRequestId;
	    awaddrFifo.enq(PhysMemRequest { addr: 'h1000 + (2*2+1)*(4<<0), burstLen: 4, tag: 1 });
	    wdataFifo.enq(MemData{data: zeroExtend((nextRequestId)[2:0]), tag: 1, last: True});
	 endaction
      endseq // while True
      endseq);

   let traceMemCnx <- mkConnection(traceClient, splitter.server);
   let bramMemCnx  <- mkConnection(splitter.bramClient, bramMemA);

`ifdef NVME_ACCELERATOR_INTERFACE
   FIFOF#(Bit#(32)) msgInFifo <- mkFIFOF();
   FIFOF#(Bit#(32)) msgOutFifo <- mkFIFOF();
   FIFOF#(Bit#(PcieDataBusWidth)) dataOutFifo <- mkFIFOF();
   AxiStreamSlave#(32)                msgInStream <- mkAxiStream(msgInFifo);
   AxiStreamMaster#(32)               msgOutStream <- mkAxiStream(msgOutFifo);
   AxiStreamMaster#(PcieDataBusWidth) dataOutStream <- mkAxiStream(dataOutFifo);
`endif

   interface MemServerPortalRequest bramRequest = bramMemServerPortal.request;
   interface NvmeDriverRequest driverRequest;
      method Action setup();
	 inSetup <= True;
         setupFsm.start();
      endmethod
      method Action status();
`ifndef PCIE3
	 let mmcmLock = axiRootPort.mmcm.lock();
`else
	 let mmcmLock = 1;
`endif
         driverInd.status(mmcmLock, 0);
      endmethod
      method Action trace(Bool enabled);
	 traceEnabled <= enabled;
      endmethod
      method Action read32(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
      endmethod
      method Action write32(Bit#(32) addr, Bit#(32) value);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
	 wdataFifo.enq(MemData {data: extend(value), tag: 0, last: True});
      endmethod
      method Action read(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(DataBusWidth,8))), tag: 0 });
      endmethod
      method Action write(Bit#(32) addr, Bit#(DataBusWidth) value);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(DataBusWidth,8))), tag: 0 });
	 wdataFifo.enq(MemData {data: extend(value), tag: 0, last: True});
      endmethod

      method Action readCtl(Bit#(32) addr) if (!inSetup);
	 araddrFifoCtl.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
      endmethod
      method Action writeCtl(Bit#(32) addr, Bit#(DataBusWidth) value) if (!inSetup);
	 awaddrFifoCtl.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
	 wdataFifoCtl.enq(MemData {data: truncate(value), tag: 0, last: True});
      endmethod
   endinterface
   interface NvmeRequest request;
      method Action startTransfer(Bit#(8) opcode, Bit#(8) flags, Bit#(16) requestId, Bit#(64) startBlock, Bit#(32) numBlocks, Bit#(32) dsm);
	 ioCommandFifo.enq(NvmeIoCommand{opcode: opcode, flags: flags, requestId: requestId, startBlock: startBlock, numBlocks: numBlocks, dsm: dsm });
      endmethod
   endinterface
`ifndef PCIE3
   interface Clock portalClockSource = axiRootPort.axi.aclk_out;
`else
   interface Clock portalClockSource = axiRootPort.axi.aclk;
`endif
   interface PipeOut dataOut = splitter.data;
   interface NvmePins pins;
      interface deleteme_unused_clock = clock;
      interface pcie_sys_reset_n = reset;
      interface pcie = axiRootPort.pci;
      method Action pcie_refclk(Bit#(1) p, Bit#(1) n);
         refclk_p.inputclock(p);
         refclk_n.inputclock(n);
      endmethod
`ifdef NVME_ACCELERATOR_INTERFACE
      interface NvmeAccelerator accel;
	 interface msgIn = msgInStream;
	 interface msgOut = msgOutStream;
	 interface dataOut = dataOutStream;
      endinterface
`endif
   endinterface
   interface Vector dmaReadClient = vec(axiGearbox.client.readClient);
   interface Vector dmaWriteClient = vec(axiGearbox.client.writeClient);
endmodule

// these ports exposed to a verilog wrapper module
interface NvmeAccelerator;
   interface AxiStreamMaster#(32) msgOut;
   interface AxiStreamSlave#(32) msgIn;
   interface AxiStreamMaster#(PcieDataBusWidth) dataOut;
   interface NvmePins pins;
endinterface

(* synthesize *)
module mkNvmeAccelerator(NvmeAccelerator);
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   interface NvmePins pins;
      interface Clock deleteme_unused_clock = clock;
      interface Reset pcie_sys_reset_n = reset;
   endinterface
endmodule


instance ToAxi4SlaveBits#(Axi4SlaveBits#(32,PcieDataBusWidth,4,Empty), AprpS_axi);
   function Axi4SlaveBits#(32,PcieDataBusWidth,4,Empty) toAxi4SlaveBits(AprpS_axi s);
      return (interface Axi4SlaveBits#(32,PcieDataBusWidth,4,Empty);
	 method araddr = compose(s.araddr, extend);
	 method arburst = s.arburst;
	 //method arcache = s.arcache;
	 method arid = s.arid;
	 method arlen = s.arlen;
	 //method arlock = s.arlock;
	 //method arprot = s.arprot;
	 //method arqos = s.arqos;
	 method arready = s.arready;
	 method arsize = s.arsize;
	 method arvalid = s.arvalid;
	 
	 method awaddr = compose(s.awaddr, extend);
	 method awburst = s.awburst;
	 //method awcache = s.awcache;
	 method awid = s.awid;
	 method awlen = s.awlen;
	 //method awlock = s.awlock;
	 //method awprot = s.awprot;
	 //method awqos = s.awqos;
	 method awready = s.awready;
	 method awsize = s.awsize;
	 method awvalid = s.awvalid;

	 method bid = s.bid;
	 method bready = s.bready;
	 method bresp = s.bresp;
	 method bvalid = s.bvalid;
	 method rdata = s.rdata;
	 method rid = s.rid;
	 method rlast = s.rlast;
	 method rready = s.rready;
	 method rresp = s.rresp;
	 method rvalid = s.rvalid;
	 method wdata = s.wdata;
	 method wlast = s.wlast;
	 method wready = s.wready;
	 method wvalid = s.wvalid;
	 method wstrb = s.wstrb;
	 endinterface);
   endfunction
endinstance

instance ToAxi4SlaveBits#(Axi4SlaveLiteBits#(32,32), AprpS_axi_ctl);
   function Axi4SlaveLiteBits#(32,32) toAxi4SlaveBits(AprpS_axi_ctl s);
      return (interface Axi4SlaveLiteBits#(32,32);
	 method araddr = compose(s.araddr, truncate);
	 method arready = s.arready;
	 method arvalid = s.arvalid;

	 method awaddr = compose(s.awaddr, truncate);
	 method awready = s.awready;
	 method awvalid = s.awvalid;

	 method bready = s.bready;
	 method bresp = s.bresp;
	 method bvalid = s.bvalid;
	 method rdata = s.rdata;
	 method rready = s.rready;
	 method rresp = s.rresp;
	 method rvalid = s.rvalid;
	 method wdata = s.wdata;
	 method wready = s.wready;
	 method Action      wvalid(Bit#(1) v);
	    s.wvalid(v);
	    s.wstrb(pack(replicate(v)));
	 endmethod
	 endinterface);
   endfunction
endinstance

instance ToAxi4MasterBits#(Axi4MasterBits#(32,PcieDataBusWidth,tagWidth,Empty), AprpM_axi);
function Axi4MasterBits#(32,PcieDataBusWidth,tagWidth,Empty) toAxi4MasterBits(AprpM_axi m);
   return (interface Axi4MasterBits#(32,PcieDataBusWidth,tagWidth,Empty);
	   method araddr = m.araddr;
	   method arburst = m.arburst;
	   method arcache = m.arcache;
	   method arlen = m.arlen;
	   method arlock = extend(m.arlock);
	   method arready = m.arready;
	   method arsize = m.arsize;
	   method arvalid = m.arvalid;
	   method Bit#(1) aresetn(); return 1; endmethod
	   method Bit#(tagWidth)     arid(); return 0; endmethod
	   method arprot = m.arprot;
	   method arqos = 0;
	   method awaddr = m.awaddr;
	   method awburst = m.awburst;
	   method awcache = m.awcache;
	   method Bit#(tagWidth)     awid(); return 0; endmethod
	   method awlen = m.awlen;
	   method awlock = extend(m.awlock);
	   method awprot = m.awprot;
	   method awready = m.awready;
	   method Bit#(4)     awqos(); return 0; endmethod
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

interface SplitMemServer#(numeric type dataBusWidth);
   interface MemServer#(dataBusWidth) server;
   interface MemClient#(dataBusWidth) busClient;
   interface MemClient#(dataBusWidth) bramClient;
   interface PipeOut#(MemData#(dataBusWidth)) data;
endinterface

module mkSplitMemServer(SplitMemServer#(dataBusWidth));
   let readReqFifo   <- mkFIFOF();
   let readDataFifo  <- mkFIFOF();
   let writeReqFifo  <- mkFIFOF();
   let writeDataFifo <- mkFIFOF();
   let writeDoneFifo <- mkFIFOF();

   let busReadReqFifo   <- mkFIFOF();
   let busReadDataFifo  <- mkSizedBRAMFIFOF(16);
   let busWriteReqFifo  <- mkFIFOF();
   let busWriteDataFifo <- mkSizedBRAMFIFOF(16);
   let busWriteDoneFifo <- mkFIFOF();

   let bramReadReqFifo   <- mkFIFOF();
   let bramReadDataFifo  <- mkSizedBRAMFIFOF(16);
   let bramWriteReqFifo  <- mkFIFOF();
   let bramWriteDataFifo <- mkSizedBRAMFIFOF(16);
   let bramWriteDoneFifo <- mkFIFOF();

   let doneFifo <- mkFIFOF();

   let dataFifo <- mkSizedBRAMFIFOF(4096);
   let readDestFifo <- mkFIFOF();
   let writeDestFifo <- mkFIFOF();

   rule rl_rd_req;
      MemRequest req <- toGet(readReqFifo).get();
      let dest = req.sglId[5:4];
      if (dest == 2)
	 bramReadReqFifo.enq(req);
      else
	 busReadReqFifo.enq(req);
      readDestFifo.enq(dest);
   endrule

   rule rl_rd_data;
      let dest = readDestFifo.first();
      MemData#(dataBusWidth) md;
      if (dest == 2)
	 md <- toGet(bramReadDataFifo).get();
      else
	 md <- toGet(busReadDataFifo).get();
      if (md.last)
	 readDestFifo.deq();
      readDataFifo.enq(md);
   endrule

   rule rl_wr_req;
      MemRequest req <- toGet(writeReqFifo).get();
      Bit#(2) dest = req.sglId[5:4];
      if (dest == 2)
	 bramWriteReqFifo.enq(req);
      else if (dest == 3) begin
	 // no need to send the request
      end else
	 busWriteReqFifo.enq(req);
      writeDestFifo.enq(dest);
   endrule
   
   rule rl_wr_data;
      let dest = writeDestFifo.first();
      MemData#(dataBusWidth) md <- toGet(writeDataFifo).get();
      if (dest == 2)
	 bramWriteDataFifo.enq(md);
      else if (dest == 3)
	 dataFifo.enq(md);
      else
	 busWriteDataFifo.enq(md);
      if (md.last) begin
	 writeDestFifo.deq();
	 doneFifo.enq(tuple2(dest, md.tag));
      end
   endrule

   rule rl_wr_done;
      match { .dest, .tag } <- toGet(doneFifo).get();
      Bit#(MemTagSize) doneTag;
      if (dest == 2)
	 doneTag <- toGet(bramWriteDoneFifo).get();
      else if (dest == 3)
	 doneTag = 0;
      else
	 doneTag <- toGet(busWriteDoneFifo).get();
      writeDoneFifo.enq(doneTag);
   endrule

   interface MemServer server;
      interface MemReadServer readServer;
	 interface readReq  = toPut(readReqFifo);
	 interface readData = toGet(readDataFifo);
      endinterface
      interface MemWriteServer writeServer;
	 interface writeReq  = toPut(writeReqFifo);
	 interface writeData = toPut(writeDataFifo);
	 interface writeDone = toGet(writeDoneFifo);
      endinterface
   endinterface
   interface MemClient busClient;
      interface MemReadClient readClient;
	 interface readReq  = toGet(busReadReqFifo);
	 interface Put readData;
	    method Action put(MemData#(dataBusWidth) md);
	       busReadDataFifo.enq(md);
	    endmethod
	 endinterface
      endinterface
      interface MemWriteClient writeClient;
	 interface writeReq  = toGet(busWriteReqFifo);
	 interface writeData = toGet(busWriteDataFifo);
	 interface writeDone = toPut(busWriteDoneFifo);
      endinterface
   endinterface
   interface MemClient bramClient;
      interface MemReadClient readClient;
	 interface readReq  = toGet(bramReadReqFifo);
	 interface readData = toPut(bramReadDataFifo);
      endinterface
      interface MemWriteClient writeClient;
	 interface writeReq  = toGet(bramWriteReqFifo);
	 interface writeData = toGet(bramWriteDataFifo);
	 interface writeDone = toPut(bramWriteDoneFifo);
      endinterface
   endinterface
   interface PipeOut data = toPipeOut(dataFifo);
endmodule

interface MemServerGearbox#(numeric type serverDataBusWidth, numeric type clientDataBusWidth);
   interface MemServer#(serverDataBusWidth) server;
   interface MemClient#(clientDataBusWidth) client;
endinterface

module mk1toNMemServerGearbox(MemServerGearbox#(serverDataBusWidth, clientDataBusWidth))
   provisos (Div#(serverDataBusWidth,clientDataBusWidth,k)
	     ,Mul#(clientDataBusWidth,k,serverDataBusWidth)
	     ,Add#(1, a__, TMul#(2, k))
	     ,Add#(k, b__, TMul#(2, k))
	     ,Add#(1, c__, k)
	     );
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   let readReqFifo   <- mkFIFOF();
   let writeReqFifo  <- mkFIFOF();
   let writeDoneFifo <- mkFIFOF();

   Gearbox#(1,k,MemData#(clientDataBusWidth)) readDataGearbox <- mk1toNGearbox(clock, reset, clock, reset);
   Gearbox#(k,1,MemData#(clientDataBusWidth)) writeDataGearbox <- mkNto1Gearbox(clock, reset, clock, reset);

   FIFOF#(MemData#(clientDataBusWidth)) busReadDataFifo  <- mkSizedBRAMFIFOF(16);
   FIFOF#(MemData#(clientDataBusWidth)) busWriteDataFifo <- mkSizedBRAMFIFOF(16);

   rule readDataCnx;
      let md <- toGet(busReadDataFifo).get();
      readDataGearbox.enq(vec(md));
   endrule
   rule writeDataCnx;
      let md = writeDataGearbox.first[0];
      writeDataGearbox.deq();
      busWriteDataFifo.enq(md);
   endrule

   interface MemServer server;
      interface MemReadServer readServer;
	 interface readReq  = toPut(readReqFifo);
	 interface Get readData;
	    method ActionValue#(MemData#(serverDataBusWidth)) get();
	       let mds = readDataGearbox.first();
	       readDataGearbox.deq();
	       let md = MemData { data: pack(map(memDataData, mds)), tag: mds[0].tag, last: mds[valueOf(k)-1].last };
	       return md;
	    endmethod
	 endinterface
      endinterface
      interface MemWriteServer writeServer;
	 interface writeReq  = toPut(writeReqFifo);
	 interface Put writeData;
	    method Action put(MemData#(serverDataBusWidth) md);
	       Vector#(k, Bit#(clientDataBusWidth)) datavec = unpack(md.data);
	       Vector#(k, MemData#(clientDataBusWidth)) mds = newVector;
	       for (Integer i = 0; i < valueOf(k); i = i + 1)
		  mds[i] = MemData { data: datavec[i], tag: md.tag, last: (i == valueOf(k)-1) && md.last };
	       writeDataGearbox.enq(mds);
	    endmethod
	 endinterface
	 interface writeDone = toGet(writeDoneFifo);
      endinterface
   endinterface
   interface MemClient client;
      interface MemReadClient readClient;
	 interface readReq  = toGet(readReqFifo);
	 interface Put readData;
	    method Action put(MemData#(clientDataBusWidth) md);
	       busReadDataFifo.enq(md);
	       //busReadDataData <= md.data;
	       //busReadDataLast <= md.last;
	    endmethod
	 endinterface
      endinterface
      interface MemWriteClient writeClient;
	 interface writeReq  = toGet(writeReqFifo);
	 interface writeData = toGet(busWriteDataFifo);
	 interface writeDone = toPut(writeDoneFifo);
      endinterface
   endinterface

endmodule


interface MemServerPortal;
   interface MemServerPortalRequest request;
endinterface

module mkPhysMemSlavePortal#(PhysMemSlave#(32,dataBusWidth) ms, MemServerPortalIndication ind)(MemServerPortal)
   provisos (Add#(dataBusWidth,7,a__)
	     ,Add#(b__,64,dataBusWidth)
	     ,Bits#(MemTypes::MemData#(dataBusWidth), a__));

   FIFOF#(PhysMemRequest#(32,dataBusWidth)) araddrFifo <- mkFIFOF();
   FIFOF#(PhysMemRequest#(32,dataBusWidth)) awaddrFifo <- mkFIFOF();
   FIFOF#(MemData#(dataBusWidth))           rdataFifo <- mkFIFOF();
   FIFOF#(MemData#(dataBusWidth))           wdataFifo <- mkFIFOF();
   FIFOF#(Bit#(6))                doneFifo <- mkFIFOF();

   let araddrCnx <- mkConnection(toGet(araddrFifo), ms.read_server.readReq);
   let awaddrCnx <- mkConnection(toGet(awaddrFifo), ms.write_server.writeReq);
   let rdataCnx  <- mkConnection(ms.read_server.readData, toPut(rdataFifo));
   let wdataCnx  <- mkConnection(toGet(wdataFifo), ms.write_server.writeData);
   let doneCnx   <- mkConnection(ms.write_server.writeDone, toPut(doneFifo));

   rule rl_rdata;
      let rdata <- toGet(rdataFifo).get();
      ind.readDone(truncate(rdata.data));
   endrule

   rule rl_writeDone;
      let tag <- toGet(doneFifo).get();
      ind.writeDone();
   endrule

   interface MemServerPortalRequest request;
      method Action read(Bit#(32) addr);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(dataBusWidth,8))), tag: 0 });
      endmethod
      method Action write(Bit#(32) addr, Bit#(DataBusWidth) value);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(dataBusWidth,8))), tag: 0 });
	 wdataFifo.enq(MemData {data: extend(value), tag: 0, last: True});
      endmethod
   endinterface
endmodule
