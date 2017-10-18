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
import BRAMFIFO::*;
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
import GetPutWithClocks::*;
import HostInterface::*;
import MemReadEngine::*;
import ConnectalMemTypes::*;
import PhysMemSlaveFromBram::*;
import Pipe::*;
import TraceMemClient::*;
import XilinxCells::*;

`include "ConnectalProjectConfig.bsv"

`ifndef PCIE3
import AxiPcieRootPort::*;
`else
import AxiPcie3RootPort::*;
`endif
import NvmeIfc::*;
import NvmePins::*;

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
`ifndef NVME_ACCELERATOR_INTERFACE
   interface PipeIn#(MemData#(PcieDataBusWidth)) dataToNvme;
   interface PipeOut#(MemData#(PcieDataBusWidth)) dataFromNvme;
`endif
   interface Vector#(1, MemReadClient#(DataBusWidth)) dmaReadClient;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) dmaWriteClient;
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource;
`endif
endinterface

module mkNvme#(NvmeIndication nvmeInd, NvmeDriverIndication driverInd, NvmeTrace trace, MemServerPortalIndication bramIndication)(Nvme);
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
   let axiCtlClock = axiClock; //axiCtlClockB2C.c;
   let axiReset <- mkSyncReset(10, reset, axiClock);
   let axiCtlReset = axiReset; //mkSyncReset(10, reset, axiCtlClock);
`else
   let axiClock = clock;
   let axiCtlClock = clock;
   let axiReset = reset;
   let axiCtlReset = reset;
`endif

   Reg#(Bool) inSetup <- mkReg(False);

   Reg#(Bit#(8)) sysResetCount <- mkReg(0);
   Reg#(Bit#(8)) nvmeResetCount <- mkReg(0);
`ifndef PCIE3
   let axiRootPort <- mkAPRP(pcie_clk_100mhz_buf, reset, axiClock, axiReset, axiCtlClock, axiCtlReset);
`ifndef TOP_SOURCES_PORTAL_CLOCK
   let axiClockC2B <- mkC2B(axiRootPort.axi.aclk_out);
   rule rl_connect_clocks;
      axiClockB2C.inputclock(axiClockC2B.o);
      axiCtlClockB2C.inputclock(axiClockC2B.o);
   endrule
`endif
`else
   let sys_rst_n <- mkReset(10, True, clock);
   let nvme_rst_n <- mkReset(10, True, clock);
   let axiRootPort <- mkAPRP(axiClock, axiReset, pcie_clk_100mhz_buf, sys_rst_n.new_rst);
   let axiClockC2B <- mkC2B(axiRootPort.axi.aclk);
   rule rl_connect_clocks;
      axiClockB2C.inputclock(axiClockC2B.o);
      axiCtlClockB2C.inputclock(axiClockC2B.o);
   endrule
   rule rl_sys_reset if (sysResetCount > 0);
      sys_rst_n.assertReset();
      sysResetCount <= sysResetCount - 1;
   endrule
   rule rl_nvme_reset if (nvmeResetCount > 0);
      nvme_rst_n.assertReset();
      nvmeResetCount <= nvmeResetCount - 1;
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

`ifndef PCIE
   let axiRootArAddrCnx <- mkConnection(toGet(araddrFifo), axiRootPortMemSlave.read_server.readReq);
   let axiRootAwAddrCnx <- mkConnection(toGet(awaddrFifo), axiRootPortMemSlave.write_server.writeReq);
   let axiRootRDataCnx  <- mkConnection(axiRootPortMemSlave.read_server.readData, toPut(rdataFifo));
   let axiRootWDataCnx  <- mkConnection(toGet(wdataFifo), axiRootPortMemSlave.write_server.writeData);
   let axiRootWDoneCnx   <- mkConnection(axiRootPortMemSlave.write_server.writeDone, toPut(doneFifo));
`else
   let axiRootArAddrCnx <- GetPutWithClocks::mkConnectionWithClocks(clock, reset, axiClock, axiReset, toPipeOut(araddrFifo), axiRootPortMemSlave.read_server.readReq);
   let axiRootAwAddrCnx <- GetPutWithClocks::mkConnectionWithClocks(clock, reset, axiClock, axiReset, toPipeOut(awaddrFifo), axiRootPortMemSlave.write_server.writeReq);
   let axiRootRDataCnx  <- GetPutWithClocks::mkConnectionWithClocks(axiClock, axiReset, clock, reset, axiRootPortMemSlave.read_server.readData, toPipeIn(rdataFifo));
   let axiRootWDataCnx  <- GetPutWithClocks::mkConnectionWithClocks(clock, reset, axiClock, axiReset, toPipeOut(wdataFifo), axiRootPortMemSlave.write_server.writeData);
   let axiRootWDoneCnx   <- GetPutWithClocks::mkConnectionWithClocks(axiClock, axiReset, clock, reset, axiRootPortMemSlave.write_server.writeDone, toPipeIn(doneFifo));
`endif

   rule rl_rdata if (!inSetup);
      let rdata <- toGet(rdataFifo).get();
      if (rdata.tag == 0)
	 driverInd.readDone(truncate(rdata.data));
   endrule

   rule rl_writeDone if (!inSetup);
      let tag <- toGet(doneFifo).get();
      if (tag == 0)
	 driverInd.writeDone();
   endrule

   FIFOF#(PhysMemRequest#(32,32)) araddrFifoCtl <- mkFIFOF();
   FIFOF#(PhysMemRequest#(32,32)) awaddrFifoCtl <- mkFIFOF();
   FIFOF#(MemData#(32))           rdataFifoCtl <- mkFIFOF();
   FIFOF#(MemData#(32))           wdataFifoCtl <- mkFIFOF();
   FIFOF#(Bit#(6))                doneFifoCtl <- mkFIFOF();

`ifndef PCIE
   let axiCtlArAddrCnx <- mkConnection(toGet(araddrFifoCtl), axiRootPortMemSlaveCtl.read_server.readReq);
   let axiCtlAwAddrCnx <- mkConnection(toGet(awaddrFifoCtl), axiRootPortMemSlaveCtl.write_server.writeReq);
   let axiCtlRDataCnx  <- mkConnection(axiRootPortMemSlaveCtl.read_server.readData, toPut(rdataFifoCtl));
   let axiCtlWDataCnx  <- mkConnection(toGet(wdataFifoCtl), axiRootPortMemSlaveCtl.write_server.writeData);
   let axiCtlDoneCnx   <- mkConnection(axiRootPortMemSlaveCtl.write_server.writeDone, toPut(doneFifoCtl));
`else
   let axiCtlArAddrCnx <- GetPutWithClocks::mkConnectionWithClocks(clock, reset, axiClock, axiReset, toPipeOut(araddrFifoCtl), axiRootPortMemSlaveCtl.read_server.readReq);
   let axiCtlAwAddrCnx <- GetPutWithClocks::mkConnectionWithClocks(clock, reset, axiClock, axiReset, toPipeOut(awaddrFifoCtl), axiRootPortMemSlaveCtl.write_server.writeReq);
   let axiCtlRDataCnx  <- GetPutWithClocks::mkConnectionWithClocks(axiClock, axiReset, clock, reset, axiRootPortMemSlaveCtl.read_server.readData, toPipeIn(rdataFifoCtl));
   let axiCtlWDataCnx  <- GetPutWithClocks::mkConnectionWithClocks(clock, reset, axiClock, axiReset, toPipeOut(wdataFifoCtl), axiRootPortMemSlaveCtl.write_server.writeData);
   let axiCtlWDoneCnx   <- GetPutWithClocks::mkConnectionWithClocks(axiClock, axiReset, clock, reset, axiRootPortMemSlaveCtl.write_server.writeDone, toPipeIn(doneFifoCtl));
`endif

   rule rl_rdata_ctl if (!inSetup);
      let rdata <- toGet(rdataFifoCtl).get();
      driverInd.readDone(extend(rdata.data));
   endrule

   rule rl_writeDone_ctl if (!inSetup);
      let tag <- toGet(doneFifoCtl).get();
      driverInd.writeDone();
   endrule

   let requestSize = 64;
   let responseSize = 16;
   let bytesPerEntry = valueOf(TDiv#(PcieDataBusWidth,8));
   let wordsPerEntry = valueOf(TDiv#(PcieDataBusWidth,32));

   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency = 2;
   bramConfig.memorySize = 4096*4/bytesPerEntry; // 4 pages
   BRAM2Port#(Bit#(32),Bit#(PcieDataBusWidth)) bram <- mkBRAM2Server(bramConfig);

   let arbIfc <- mkFixedPriority();
   Arbiter#(4, BRAMRequest#(Bit#(32),Bit#(PcieDataBusWidth)),Bit#(PcieDataBusWidth)) arbiter <- mkArbiter(arbIfc,2);
   let arbCnx <- mkConnection(arbiter.master, bram.portB);

   MemServer#(PcieDataBusWidth)            bramMemA <- mkMemServerFromBram(bram.portA);
   PhysMemSlave#(32,PcieDataBusWidth)      bramMemB <- mkPhysMemSlaveFromBram(arbiter.users[0]);
   MemServerPortal          bramMemServerPortal <- mkPhysMemSlavePortal(bramMemB,bramIndication);

   let portB1 = arbiter.users[1];
   let portB2 = arbiter.users[2];
   let portB3 = arbiter.users[3];

// was 18
   Vector#(1,Tuple3#(Bit#(2), Bit#(32),Bit#(PcieDataBusWidth))) initCtlValues = vec( 
      //  tuple3(0, 32'h00000004, 'h00000147)
      // ,tuple3(0, 32'h00000018, 'h00070100)
      // ,tuple3(0, 32'h00000010, 'h00000000) // Bridge BAR0
      // ,tuple3(0, 32'h00000014, 'h00000000) // Bridge BAR1
      // ,tuple3(0, 32'h00100004, 'h00000147) // enable card I/O, Memory, bus master, parity and SERR
      // ,tuple3(0, 32'h00100010, 'h00000000) // Card BAR0
      // ,tuple3(0, 32'h00100014, 'h00000000) // Card BAR1
      // ,tuple3(0, 32'h00100018, 'h02200000) // Card BAR2
      // ,tuple3(0, 32'h0010001c, 'h00000000) // Card BAR3
      // ,tuple3(0, 32'h00000148, 'h00000001) // enable bridge
      // ,tuple3(0, 32'h00000140, 'h00010000) // enable bridge

      // ,tuple3(1, 32'h00000014, 'h00460000)
      // ,tuple3(1, 0, 0) // skip the rest for now
      // ,tuple3(1, 32'h00000028, 'h00000000) // admin submission queue in BRAM
      // ,tuple3(1, 32'h00000030, 'h00000000) // admin response queue in BRAM
      // ,tuple3(1, 32'h00000024, 'h003f003f) // queue sizes?
      // ,tuple3(1, 32'h00000014, 'h00460001) // enable the admin queues
      //,
      tuple3(1, 0, 0));

   let index <- mkReg(0);
   let kindReg <- mkReg(0);
   let addrReg <- mkReg(0);
   let dataReg <- mkReg(0);
   let setupFsm <- mkFSMWithPred(seq
      index <= 0;
      while (tpl_2(initCtlValues[index]) != 32'h0) seq
	 action
	    match { .kind, .addr, .data } = initCtlValues[index];
	    kindReg <= kind;
	    addrReg <= addr;
	    dataReg <= data;
	 endaction
	 action
	    let kind = kindReg;
	    let addr = addrReg;
	    let data = dataReg;
      
	    if (kind == 0) awaddrFifoCtl.enq(PhysMemRequest {addr: addr, burstLen: 4, tag: index });
	    if (kind == 1) awaddrFifo.enq(PhysMemRequest {addr: addr, burstLen: 4, tag: index });
	    if (kind == 2) portB3.request.put(BRAMRequest { address: addr, write: True, responseOnWrite: True, datain: data });
	 endaction
	 action
	    //match { .kind, .addr, .data } = initCtlValues[index];
	    let kind = kindReg;
	    let addr = addrReg;
	    let data = dataReg;
	    if (kind == 0) wdataFifoCtl.enq(MemData {data: truncate(data), tag: index, last: True });
	    if (kind == 1) wdataFifo.enq(MemData {data: data, tag: index, last: True });
	 endaction
	 action
	    //match { .kind, .addr, .data } = initCtlValues[index];
	    let kind = kindReg;
	    let addr = addrReg;
	    let data = dataReg;
	    let tag = 0;
	    if (kind == 0) doneFifoCtl.deq();
	    if (kind == 1) doneFifo.deq();
	    if (kind == 2) 
	       tag <- portB3.response.get();
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
   FIFOF#(Tuple4#(DmaChannel,Bool,MemData#(PcieDataBusWidth),Bit#(32))) traceDataFifo <- mkSizedBRAMFIFOF(128);
   PipeIn#(Tuple4#(DmaChannel,Bool,MemData#(PcieDataBusWidth),Bit#(32))) traceDataPipe = traceEnabled ? toPipeIn(traceDataFifo) : sinkPipe();
   FIFOF#(Tuple2#(DmaChannel,Bit#(32)))                              traceDoneFifo <- mkSizedBRAMFIFOF(128);
   PipeIn#(Tuple2#(DmaChannel,Bit#(32)))                             traceDonePipe = traceEnabled ? toPipeIn(traceDoneFifo) : sinkPipe();

   rule rl_trace1;
      match { .chan, .write, .req, .timestamp } <- toGet(traceFifo).get();
      trace.traceDmaRequest(chan, write, truncate(req.sglId), truncate(req.offset), extend(req.burstLen), extend(req.tag), timestamp);
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

   Reg#(Bit#(16)) requestId <- mkReg(0);
   Reg#(Bit#(16)) responseId <- mkReg(0);
   Reg#(Bit#(16)) requestQueueEntryCount <- mkReg(8);
   Reg#(Bool) requestSlotAvailable <- mkReg(True);
   Reg#(Bool) requestInProgress <- mkReg(True);
   Reg#(Vector#(16,Bit#(32))) ioCommand <- mkReg(unpack(0));
   Reg#(Bit#(32)) requestStartTimestamp <- mkReg(0);

   FIFOF#(NvmeIoCommand) ioCommandFifo <- mkFIFOF();
   FIFOF#(NvmeIoCommand) ioSegmentFifo <- mkFIFOF(); // max request size 32
`ifdef NVME_ACCELERATOR_INTERFACE
   FIFOF#(NvmeIoCommand) ioCommandFifoAccel <- mkFIFOF();
   FIFOF#(NvmeIoResponse) ioResponseFifoAccel <- mkFIFOF();
`endif

   FIFOF#(Bit#(1)) ioCommandSourceFifo <- mkFIFOF();
   FIFOF#(Bit#(1)) ioSegmentSourceFifo <- mkFIFOF();
   FIFOF#(Bit#(1)) ioResponseSourceFifo <- mkSizedFIFOF(8);

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule rl_cycles;
      cycles <= cycles + 1;
   endrule

   IteratorWithContext#(Bit#(32),NvmeIoCommand) ioIterator <- mkIteratorWithContext();
   let segmenterFsm <- mkAutoFSM(seq
      while (True) seq
	 action
	    NvmeIoCommand command = unpack(0);
	    Bit#(1) commandSource = 0;
	    Bool commandValid = False;
	    if (ioCommandFifo.notEmpty) begin
	       command <- toGet(ioCommandFifo).get();
	       commandValid = True;
	       commandSource = 0;
	    end
`ifdef NVME_ACCELERATOR_INTERFACE
	    else if (ioCommandFifoAccel.notEmpty) begin
	       command <- toGet(ioCommandFifoAccel).get();
	       commandValid = True;
	       commandSource = 1;
	    end
`endif
	    if (commandValid) begin
	       ioIterator.start(IteratorConfig {xbase: 0,
						xlimit: command.numBlocks,
						xstep: `BlocksPerRequest},
				command);
	       ioCommandSourceFifo.enq(commandSource);
	    end
	 endaction
         while (ioIterator.ivpipe.notEmpty()) seq
	    action
	       let v <- toGet(ioIterator.ivpipe).get();
	       let command = v.ctxt;
	       if (v.last) begin
		  command.numBlocks = command.numBlocks - v.value; //fixme
		  ioCommandSourceFifo.deq();
	       end
	       else begin
		  command.numBlocks = `BlocksPerRequest;
	       end
	       command.startBlock = command.startBlock + extend(v.value);
	       ioSegmentFifo.enq(command);
	       ioSegmentSourceFifo.enq(ioCommandSourceFifo.first);

	    endaction
	 endseq
      endseq // while True
      endseq);

   Reg#(Bit#(32)) i <- mkReg(0);

   let requestFsm <- mkAutoFSM(seq
      while (True) seq
	 action
	    let req <- toGet(ioSegmentFifo).get();
	    let source <- toGet(ioSegmentSourceFifo).get();
	    Vector#(16,Bit#(32)) command = unpack(0);
	    command[0] = { requestId, req.flags, req.opcode };
	    command[1] = 1; // nsid
	    // prp1: send data to fifo
	    command[6] = 32'h30000000;
	    // p2p2: read PRP list from BRAM at offset 0x2000
	    command[8] = 32'h20002000;
	    command[10] = req.startBlock[31:0];
	    command[11] = 0; //req.startBlock[63:32];
	    command[12] = req.numBlocks-1;
	    command[13] = req.dsm;
	    //requestId <= req.requestId;
	    ioCommand <= command;

	    requestSlotAvailable <= False;
	    ioResponseSourceFifo.enq(source);
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
	    action
	       let response <- portB2.response.get();
	       let phase = ~responseId[3];
	       if (response[16+(3*32 % valueOf(PcieDataBusWidth))] == phase) begin
		  // if status field written by NVME
		  let source <- toGet(ioResponseSourceFifo).get();
`ifdef NVME_ACCELERATOR_INTERFACE
		  if (source == 1)
		     ioResponseFifoAccel.enq(NvmeIoResponse {requestId: responseId, statusCode: 'h5a5a, statusCodeType: 'h5a5a });
		  else
`endif
		     nvmeInd.transferCompleted(responseId, truncate(response), cycles - requestStartTimestamp);
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
   FIFOF#(MemData#(32)) msgToSoftwareFifo <- mkSizedFIFOF(128);
   FIFOF#(MemData#(32)) msgFromSoftwareFifo <- mkSizedFIFOF(16);
   AxiStreamSlave#(32)                msgToSoftwareStream <- mkAxiStream(msgToSoftwareFifo);
   AxiStreamMaster#(32)               msgFromSoftwareStream <- mkAxiStream(msgFromSoftwareFifo);
   AxiStreamMaster#(PcieDataBusWidth) dataFromNvmeStream <- mkAxiStream(splitter.dataFromNvme);
   AxiStreamSlave#(PcieDataBusWidth)  dataToNvmeStream   <- mkAxiStream(splitter.dataToNvme);
   AxiStreamSlave#(SizeOf#(NvmeIoCommand))     requestStream      <- mkAxiStream(mapPipeIn(unpack,toPipeIn(ioCommandFifoAccel)));
   AxiStreamMaster#(SizeOf#(NvmeIoResponse))   responseStream     <- mkAxiStream(mapPipe(pack,toPipeOut(ioResponseFifoAccel)));

   rule rl_msgToSoftware;
      let msg <- toGet(msgToSoftwareFifo).get();
      nvmeInd.msgToSoftware(msg.data, pack(msg.last));
   endrule
`endif

   let ltssm <- mkProbe();
   let userLinkUp <- mkProbe();
   rule rl_probe;
      ltssm <= axiRootPort.cfg.ltssm_state();
      userLinkUp <= axiRootPort.user.link_up();
   endrule

   //let pcie_sys_reset_n <- mkResetInverter(axiRootPort.axi.aresetn, clocked_by axiClock);
   let pcie_sys_reset_n <- mkResetInverter(nvme_rst_n.new_rst, clocked_by axiClock);

   interface MemServerPortalRequest bramRequest = bramMemServerPortal.request;
   interface NvmeDriverRequest driverRequest;
      method Action reset(Bit#(8) count) if (sysResetCount == 0);
	 sysResetCount <= count;
      endmethod
      method Action nvmeReset(Bit#(8) count) if (nvmeResetCount == 0);
	 nvmeResetCount <= count;
      endmethod
      method Action setup();
	 inSetup <= True;
         setupFsm.start();
      endmethod
      method Action status();
`ifndef PCIE3
	 let mmcmLock = axiRootPort.mmcm.lock();
	 let ltssm_state = 1'd0;
`else
	 let mmcmLock = axiRootPort.user.link_up();
	 let ltssm_state = axiRootPort.cfg.ltssm_state();
`endif
         driverInd.status(mmcmLock, extend(ltssm_state));
      endmethod
      method Action trace(Bool enabled);
	 traceEnabled <= enabled;
      endmethod
      method Action read32(Bit#(32) addr) if (!inSetup);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
      endmethod
      method Action write32(Bit#(32) addr, Bit#(32) value) if (!inSetup);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
	 wdataFifo.enq(MemData {data: extend(value), tag: 0, last: True});
      endmethod
      method Action read64(Bit#(32) addr) if (!inSetup);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 8, tag: 0 });
      endmethod
      method Action write64(Bit#(32) addr, Bit#(64) value) if (!inSetup);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 8, tag: 0 });
	 wdataFifo.enq(MemData {data: extend(value), tag: 0, last: True});
      endmethod
      method Action write128(Bit#(32) addr, Bit#(64) uvalue, Bit#(64) lvalue) if (!inSetup);
	 awaddrFifo.enq(PhysMemRequest { addr: addr, burstLen: 16, tag: 0 });
	 wdataFifo.enq(MemData {data: {uvalue,lvalue}, tag: 0, last: True});
      endmethod
      method Action read(Bit#(32) addr) if (!inSetup);
	 araddrFifo.enq(PhysMemRequest { addr: addr, burstLen: fromInteger(valueOf(TDiv#(DataBusWidth,8))), tag: 0 });
      endmethod
      method Action write(Bit#(32) addr, Bit#(DataBusWidth) value) if (!inSetup);
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
      method Action startTransfer(Bit#(8) opcode, Bit#(8) flags, Bit#(16) requestId, Bit#(32) startBlock, Bit#(32) numBlocks, Bit#(32) dsm);
	 ioCommandFifo.enq(NvmeIoCommand{opcode: opcode, flags: flags, requestId: requestId, startBlock: startBlock, numBlocks: numBlocks, dsm: dsm });
      endmethod
      method Action msgFromSoftware(Bit#(32) value, Bit#(1) last);
`ifdef NVME_ACCELERATOR_INTERFACE
	 msgFromSoftwareFifo.enq(MemData { data:value, last: unpack(last), tag: 0 });
`endif
      endmethod
   endinterface
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface Clock portalClockSource = axiRootPort.axi.aclk_out;
`endif
`ifndef NVME_ACCELERATOR_INTERFACE
   interface PipeOut dataFromNvme = splitter.dataFromNvme;
   interface PipeOut dataToNvme  = splitter.dataToNvme;
`endif
   interface NvmePins pins;
      interface deleteme_unused_clock = clock;
      interface pcie_sys_reset_n = pcie_sys_reset_n;
      interface pcie = axiRootPort.pci;
      method Action pcie_refclk(Bit#(1) p, Bit#(1) n);
         refclk_p.inputclock(p);
         refclk_n.inputclock(n);
      endmethod
`ifdef NVME_ACCELERATOR_INTERFACE
      interface NvmeAccelerator accel;
	 interface msgToSoftware = msgToSoftwareStream;
	 interface msgFromSoftware = msgFromSoftwareStream;
	 interface dataFromNvme = dataFromNvmeStream;
         interface dataToNvme = dataToNvmeStream;
         interface request = requestStream;
         interface response = responseStream;
         interface clock = clock;
         interface reset = reset;
      endinterface
`endif
   endinterface
   interface Vector dmaReadClient = vec(axiGearbox.client.readClient);
   interface Vector dmaWriteClient = vec(axiGearbox.client.writeClient);
endmodule

interface NvmeAcceleratorModule;
   interface NvmeAccelerator accelerator;
   interface NvmePins pins;
endinterface

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
   interface PipeOut#(MemData#(dataBusWidth)) dataFromNvme;
   interface PipeIn#(MemData#(dataBusWidth))  dataToNvme;
endinterface

`ifndef DATA_FIFO_DEPTH
typedef 16 DataFifoDepth;
`else
typedef `DATA_FIFO_DEPTH DataFifoDepth;
`endif

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

   let dataFromNvmeFifo <- mkSizedBRAMFIFOF(valueOf(DataFifoDepth));
   let dataToNvmeFifo <- mkSizedBRAMFIFOF(valueOf(DataFifoDepth));
   let readDestFifo <- mkFIFOF();
   let writeDestFifo <- mkFIFOF();

   rule rl_rd_req;
      MemRequest req <- toGet(readReqFifo).get();
      let dest = req.sglId[5:4];
      if (dest == 2)
	 bramReadReqFifo.enq(req);
      else if (dest == 3) begin
	 // reading from dataToNvmeFifo
      end
      else
	 busReadReqFifo.enq(req);
      readDestFifo.enq(dest);
   endrule

   rule rl_rd_data;
      let dest = readDestFifo.first();
      MemData#(dataBusWidth) md;
      if (dest == 2)
	 md <- toGet(bramReadDataFifo).get();
      else if (dest == 3)
	 md <- toGet(dataToNvmeFifo).get();
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
	 dataFromNvmeFifo.enq(md);
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
   interface PipeOut dataFromNvme = toPipeOut(dataFromNvmeFifo);
   interface PipeOut dataToNvme  = toPipeIn(dataToNvmeFifo);
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
	     ,Bits#(ConnectalMemTypes::MemData#(dataBusWidth), a__));

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
