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

import FIFOF::*;
import FIFO::*;
import FIFOLevel::*;
import BRAMFIFO::*;
import BRAM::*;
import GetPut::*;
import ClientServer::*;

import Vector::*;
import List::*;

import PortalMemory::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import Pipe::*;

import Clocks :: *;
import Xilinx       :: *;
`ifndef BSIM
import XilinxCells ::*;
`endif

import AuroraImportFmc1::*;

import ControllerTypes::*;
//import AuroraExtArbiter::*;
//import AuroraExtImport::*;
//import AuroraExtImport117::*;
import AuroraCommon::*;

//import PageCache::*;
import DMABurstHelper::*;
import ControllerTypes::*;
import FlashCtrlVirtex::*;
import FlashCtrlModel::*;

interface FlashRequest;
	method Action readPage(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) page, Bit#(32) tag);
	method Action writePage(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) page, Bit#(32) tag);
	method Action eraseBlock(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) tag);
	method Action addDmaReadRefs(Bit#(32) pointer, Bit#(32) offset, Bit#(32) tag);
	method Action addDmaWriteRefs(Bit#(32) pointer, Bit#(32) offset, Bit#(32) tag);
	method Action start(Bit#(32) dummy);
	method Action debugDumpReq(Bit#(32) dummy);
	method Action setDebugVals (Bit#(32) flag, Bit#(32) debugDelay); 
endinterface

interface FlashIndication;
	method Action readDone(Bit#(32) tag);
	method Action writeDone(Bit#(32) tag);
	method Action eraseDone(Bit#(32) tag, Bit#(32) status);
	method Action debugDumpResp(Bit#(32) debug0, Bit#(32) debug1, Bit#(32) debug2, Bit#(32) debug3);
endinterface

// NumDmaChannels each for flash i/o and emualted i/o
//typedef TAdd#(NumDmaChannels, NumDmaChannels) NumObjectClients;
//typedef NumDmaChannels NumObjectClients;
typedef 128 DmaBurstBytes; 
Integer dmaBurstBytes = valueOf(DmaBurstBytes);
Integer dmaBurstWords = dmaBurstBytes/wordBytes; //128/16 = 8
Integer dmaBurstsPerPage = pageSizeUser/dmaBurstBytes;

interface FlashTop;
   interface FlashRequest request;
   interface Vector#(1, ObjectWriteClient#(WordSz)) hostMemWriteClient;
   interface Vector#(1, ObjectReadClient#(WordSz)) hostMemReadClient;
   interface PhysMemSlave#(30, 64) memSlave;    
   interface Aurora_Pins#(4) aurora_fmc1;
   interface Aurora_Clock_Pins aurora_clk_fmc1;
endinterface

module mkFlashTop#(FlashIndication indication, Clock clk250, Reset rst250)(FlashTop);

	Clock curClk <- exposeCurrentClock;
	Reset curRst <- exposeCurrentReset;


	Reg#(Bool) started <- mkReg(False);
	Reg#(Bit#(64)) cycleCnt <- mkReg(0);

	FIFO#(FlashCmd) flashCmdQ <- mkSizedFIFO(valueOf(NumTags));
	Vector#(NumTags, Reg#(BusT)) tag2busTable <- replicateM(mkRegU());
	Vector#(NumTags, Reg#(Tuple2#(Bit#(32),Bit#(32)))) dmaWriteRefs <- replicateM(mkRegU());
	Vector#(NUM_BUSES, FIFO#(Tuple2#(Bit#(WordSz), TagT))) dmaWriteBuf <- replicateM(mkSizedBRAMFIFO(dmaBurstWords*2));
	Vector#(NUM_BUSES, FIFO#(Tuple2#(Bit#(WordSz), TagT))) dmaWriteBufOut <- replicateM(mkFIFO());

	GtxClockImportIfc gtx_clk_fmc1 <- mkGtxClockImport;
	`ifdef BSIM
		FlashCtrlVirtexIfc flashCtrl <- mkFlashCtrlModel(gtx_clk_fmc1.gtx_clk_p_ifc, gtx_clk_fmc1.gtx_clk_n_ifc, clk250);
	`else
		FlashCtrlVirtexIfc flashCtrl <- mkFlashCtrlVirtex(gtx_clk_fmc1.gtx_clk_p_ifc, gtx_clk_fmc1.gtx_clk_n_ifc, clk250);
	`endif

	//Create read/write engines with NUM_BUSES memservers
	MemreadEngineV#(WordSz, 1, NUM_BUSES) re <- mkMemreadEngine;
	MemwriteEngineV#(WordSz, 1, NUM_BUSES) we <- mkMemwriteEngine;

	Vector#(NUM_BUSES, Reg#(Bit#(16))) dmaWBurstCnts <- replicateM(mkReg(0));
	Vector#(NUM_BUSES, FIFO#(TagT)) dmaReqQs <- replicateM(mkSizedFIFO(valueOf(NumTags)));//TODO make bigger?
	Vector#(NUM_BUSES, FIFO#(Tuple2#(TagT, Bit#(32)))) dmaReq2RespQ <- replicateM(mkSizedFIFO(valueOf(NumTags))); //TODO make bigger?
	Vector#(NUM_BUSES, Reg#(Bit#(32))) dmaReqCnts <- replicateM(mkReg(0));
	Vector#(NUM_BUSES, Reg#(Bit#(32))) dmaRespCnts <- replicateM(mkReg(0));
	Vector#(NUM_BUSES, Reg#(TagT)) currTags <- replicateM(mkReg(0));
	FIFO#(Tuple2#(Bit#(WordSz), TagT)) dataFlash2DmaQ <- mkFIFO();

	rule incCycle;
		cycleCnt <= cycleCnt + 1;
	endrule

	rule driveFlashCmd (started);
		let cmd = flashCmdQ.first;
		flashCmdQ.deq;
		tag2busTable[cmd.tag] <= cmd.bus;
		flashCtrl.user.sendCmd(cmd); //forward cmd to flash ctrl
		$display("@%d: FlashTop.bsv: received cmd tag=%d @%x %x %x %x", 
						cycleCnt, cmd.tag, cmd.bus, cmd.chip, cmd.block, cmd.page);
	endrule

	Reg#(Bit#(32)) delayRegSet <- mkReg(0);
	Reg#(Bit#(32)) delayReg <- mkReg(0);
	Reg#(Bit#(32)) debugFlag <- mkReg(0);


	//--------------------------------------------
	// Reads from Flash (DMA Write)
	//--------------------------------------------

	rule doEnqReadFromFlash;
		if (delayReg==0) begin
			let taggedRdata <- flashCtrl.user.readWord();
			if (debugFlag==0) begin
				dataFlash2DmaQ.enq(taggedRdata);
			end
			delayReg <= delayRegSet;
		end
		else begin
			delayReg <= delayReg - 1;
		end
	endrule


	rule doDistributeReadFromFlash;
		let taggedRdata = dataFlash2DmaQ.first;
		dataFlash2DmaQ.deq;
		let tag = tpl_2(taggedRdata);
		let data = tpl_1(taggedRdata);
		BusT bus = tag2busTable[tag];
		dmaWriteBuf[bus].enq(taggedRdata);
		$display("@%d FlashTop.bsv: rdata tag=%d, bus=%d, data[%d]=%x", cycleCnt, tag, bus, dmaWBurstCnts[bus], data);
	endrule

	for (Integer b=0; b<valueOf(NUM_BUSES); b=b+1) begin
		rule doReqDMAStart;
			dmaWriteBuf[b].deq;
			let taggedRdata = dmaWriteBuf[b].first;
			dmaWriteBufOut[b].enq(taggedRdata);
			let tag = tpl_2(taggedRdata);
			//for each bus, every dmaBurstWords bursts, request for init DMA
			if (dmaWBurstCnts[b]==0) begin
				dmaReqQs[b].enq(tag);
				currTags[b] <= tag;
				dmaWBurstCnts[b] <= dmaWBurstCnts[b] + 1;
			end
			else if (dmaWBurstCnts[b]==fromInteger(dmaBurstWords-1)) begin
				if (tag != currTags[b]) begin
					$display("main.bsv: **ERROR: tag bursts do not match!");
				end
				dmaWBurstCnts[b] <= 0;
			end
			else begin
				if (tag != currTags[b]) begin
					$display("main.bsv: **ERROR: tag bursts do not match!");
				end
				dmaWBurstCnts[b] <= dmaWBurstCnts[b] + 1;
			end
		endrule


		//initiate dma
		rule initiateDmaWrite;
			dmaReqQs[b].deq;
			let tag = dmaReqQs[b].first;
			let base = tpl_1(dmaWriteRefs[tag]);
			let offset = tpl_2(dmaWriteRefs[tag]);
			Bit#(32) burstOffset = (dmaReqCnts[b]<<log2(dmaBurstBytes)) + offset;
			let dmaCmd = MemengineCmd {
								sglId: base, 
								base: zeroExtend(burstOffset),
								len:fromInteger(dmaBurstBytes), 
								burstLen:fromInteger(dmaBurstBytes)
							};
			we.writeServers[b].request.put(dmaCmd);
			dmaReq2RespQ[b].enq(tuple2(tag, dmaReqCnts[b]));
			
			$display("@%d FlashTop.bsv: init dma write tag=%d, bus=%d, addr=0x%x 0x%x", 
							cycleCnt, tag, b, base, burstOffset);
			if (dmaReqCnts[b] == fromInteger(dmaBurstsPerPage-1)) begin
				dmaReqCnts[b] <= 0;
			end
			else begin
				dmaReqCnts[b] <= dmaReqCnts[b] + 1;
			end
		endrule

		//send data
		rule sendDmaWriteData;
			//TODO: is it safe to send this data right away, before the request
			//looks ok?
			let taggedRdata = dmaWriteBufOut[b].first;
			let data = tpl_1(taggedRdata);
			dmaWriteBufOut[b].deq;
			we.dataPipes[b].enq(data);
		endrule

		//dma response.get done; when enough has accumulated, send ack to sw
		rule dmaWriterGetResponse;
			let dummy <- we.writeServers[b].response.get;
			let tagCnt = dmaReq2RespQ[b].first;
			dmaReq2RespQ[b].deq;
			$display("@%d FlashTop.bsv: dma resp [%d] tag=%d", cycleCnt, tpl_2(tagCnt), tpl_1(tagCnt));
			if (tpl_2(tagCnt)==fromInteger(dmaBurstsPerPage-1)) begin
				indication.readDone(zeroExtend(tpl_1(tagCnt)));
			end
		endrule
	end //for each bus



	//--------------------------------------------
	// Writes to Flash (DMA Reads)
	//--------------------------------------------

	//Instantiate dma readers (in DMABurstHelper)
	Vector#(NUM_BUSES, DMAReadEngineIfc#(WordSz)) dmaReaders;
	for (Integer b=0; b<valueOf(NUM_BUSES); b=b+1) begin
		DMAReadEngineIfc#(WordSz) reader <- mkDmaReadEngine(re.readServers[b], re.dataPipes[b]);
		dmaReaders[b] = reader; 
	end //For NUM_BUSES

	//Handle write data requests from controller
	FIFO#(Tuple2#(TagT, BusT)) wrToDmaReqQ <- mkFIFO();
	rule handleWriteDataRequestFromFlash;
		TagT tag <- flashCtrl.user.writeDataReq();
		//check which bus it's from
		let bus = tag2busTable[tag];
		wrToDmaReqQ.enq(tuple2(tag, bus));
	endrule

	rule startDmaRead;
		wrToDmaReqQ.deq;
		let r = wrToDmaReqQ.first;
		let tag = tpl_1(r);
		let bus = tpl_2(r);
		dmaReaders[bus].startRead(tag, fromInteger(pageWords));
	endrule

	//Handle read data/done from each DMA reader port
	for (Integer b=0; b<valueOf(NUM_BUSES); b=b+1) begin
		rule dmaReadDone;
			let trashTag <- dmaReaders[b].done; //ignore this return tag
		endrule

		rule dmaReadData;
			let r <- dmaReaders[b].read;
			let data = tpl_1(r);
			let tag = tpl_2(r);
			flashCtrl.user.writeWord(tuple2(data, tag));
		endrule
	end



	//--------------------------------------------
	// Writes/Erase Acks
	//--------------------------------------------

	//Handle acks from controller
	FIFO#(Tuple2#(TagT, StatusT)) ackQ <- mkFIFO;
	rule handleControllerAck;
		let ackStatus <- flashCtrl.user.ackStatus();
		ackQ.enq(ackStatus);
	endrule

	rule indicateControllerAck;
		ackQ.deq;
		TagT tag = tpl_1(ackQ.first);
		StatusT st = tpl_2(ackQ.first);
		case (st)
			WRITE_DONE: indication.writeDone(zeroExtend(tag));
			ERASE_DONE: indication.eraseDone(zeroExtend(tag), 0);
			ERASE_ERROR: indication.eraseDone(zeroExtend(tag), 1);
		endcase
	endrule




	//--------------------------------------------
	// Debug
	//--------------------------------------------

	FIFO#(Bit#(1)) debugReqQ <- mkFIFO();
	rule doDebugDump;
		$display("FlashTop.bsv: debug dump request received");
		debugReqQ.deq;
		let debugCnts = flashCtrl.debug.getDebugCnts(); 
		let gearboxSendCnt = tpl_1(debugCnts);         
		let gearboxRecCnt = tpl_2(debugCnts);   
		let auroraSendCntCC = tpl_3(debugCnts);     
		let auroraRecCntCC = tpl_4(debugCnts);  
		indication.debugDumpResp(gearboxSendCnt, gearboxRecCnt, auroraSendCntCC, auroraRecCntCC);
	endrule



	Vector#(1, ObjectWriteClient#(WordSz)) dmaWriteClientVec;
	Vector#(1, ObjectReadClient#(WordSz)) dmaReadClientVec;
	dmaWriteClientVec[0] = we.dmaClient;
	dmaReadClientVec[0] = re.dmaClient;
		

   interface FlashRequest request;
		method Action readPage(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) page, Bit#(32) tag);
			FlashCmd fcmd = FlashCmd{
				tag: truncate(tag),
				op: READ_PAGE,
				bus: truncate(bus),
				chip: truncate(chip),
				block: truncate(block),
				page: truncate(page)
				};

			flashCmdQ.enq(fcmd);
		endmethod
		
		method Action writePage(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) page, Bit#(32) tag);
			FlashCmd fcmd = FlashCmd{
				tag: truncate(tag),
				op: WRITE_PAGE,
				bus: truncate(bus),
				chip: truncate(chip),
				block: truncate(block),
				page: truncate(page)
				};

			flashCmdQ.enq(fcmd);
		endmethod

		method Action eraseBlock(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) tag);
			FlashCmd fcmd = FlashCmd{
				tag: truncate(tag),
				op: ERASE_BLOCK,
				bus: truncate(bus),
				chip: truncate(chip),
				block: truncate(block),
				page: 0
				};
			flashCmdQ.enq(fcmd);
		endmethod

		method Action addDmaReadRefs(Bit#(32) pointer, Bit#(32) offset, Bit#(32) tag);
			for (Integer b=0; b<valueOf(NUM_BUSES); b=b+1) begin
				dmaReaders[b].addBuffer(truncate(tag), offset, pointer);
			end
		endmethod

		method Action addDmaWriteRefs(Bit#(32) pointer, Bit#(32) offset, Bit#(32) tag);
			dmaWriteRefs[tag] <= tuple2(pointer, offset);
		endmethod

		method Action start(Bit#(32) dummy);
			started <= True;
		endmethod

		method Action debugDumpReq(Bit#(32) dummy);
			debugReqQ.enq(1);
		endmethod

		method Action setDebugVals (Bit#(32) flag, Bit#(32) debugDelay); 
			delayRegSet <= debugDelay;
			debugFlag <= flag;
		endmethod

	endinterface //FlashRequest

   interface ObjectWriteClient dmaWriteClient = dmaWriteClientVec;
   interface ObjectReadClient dmaReadClient = dmaReadClientVec;

   interface Aurora_Pins aurora_fmc1 = flashCtrl.aurora;
   interface Aurora_Clock_Pins aurora_clk_fmc1 = gtx_clk_fmc1.aurora_clk;

endmodule

