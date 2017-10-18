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
import FIFOF::*;
import FIFO::*;
import FIFOLevel::*;
import BRAMFIFO::*;
import BRAM::*;
import GetPut::*;
import ClientServer::*;
import Vector::*;
import BuildVector::*;
import List::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import Pipe::*;
import Clocks :: *;
import Xilinx       :: *;
`ifndef SIMULATION
import XilinxCells ::*;
`endif
import AuroraImportFmc1::*;
import AuroraCommon::*;
import ControllerTypes::*;
import ControllerTypes::*;
import FlashCtrlModel::*;
import PageBuffers::*;

interface FlashRequest;
	method Action readPage(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) page, Bit#(32) tag);
	method Action writePage(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) page, Bit#(32) tag);
	method Action eraseBlock(Bit#(32) bus, Bit#(32) chip, Bit#(32) block, Bit#(32) tag);
	method Action addDmaReadRefs(Bit#(32) sglId, Bit#(32) offset, Bit#(32) tag);
	method Action addDmaWriteRefs(Bit#(32) sglId, Bit#(32) offset, Bit#(32) tag);
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
	interface Vector#(1, MemWriteClient#(WordSz)) hostMemWriteClient;
	interface Vector#(1, MemReadClient#(WordSz)) hostMemReadClient;
        interface PhysMemSlave#(FlashAddrWidth, 128) memSlave;    
	interface Aurora_Pins#(4) aurora_fmc1;
	interface Aurora_Clock_Pins aurora_clk_fmc1;
endinterface

module mkFlashTop#(FlashIndication indication, Clock clk250, Reset rst250)(FlashTop);

	Clock curClk <- exposeCurrentClock;
	Reset curRst <- exposeCurrentReset;


	Reg#(Bool) started <- mkReg(False);
	Reg#(Bit#(64)) cycleCnt <- mkReg(0);

	FIFO#(Tuple2#(FlashCmd, SourceT)) flashCmdQ <- mkSizedFIFO(valueOf(NumTags));
	Vector#(NumTags, Reg#(Tuple2#(BusT, SourceT))) tag2busNsrcTable <- replicateM(mkRegU());
	Vector#(NumTags, Reg#(Tuple2#(Bit#(32),Bit#(32)))) dmaWriteRefs <- replicateM(mkRegU());
	Vector#(NumTags, Reg#(Tuple2#(Bit#(32),Bit#(32)))) dmaReadRefs <- replicateM(mkRegU());
	Vector#(NUM_BUSES, FIFO#(Tuple2#(Bit#(WordSz), TagT))) dmaWriteBuf <- replicateM(mkSizedBRAMFIFO(dmaBurstWords*2));
	//FIFO#(Tuple3#(Bit#(WordSz), TagT, Bool)) memSlaveReadBuf <- mkSizedBRAMFIFO(128); //doesn't matter size?
	Vector#(NUM_BUSES, FIFO#(Tuple2#(Bit#(WordSz), TagT))) dmaWriteBufOut <- replicateM(mkFIFO());

	GtxClockImportIfc gtx_clk_fmc1 <- mkGtxClockImport;
	`ifdef SIMULATION
		FlashCtrlVirtexIfc flashCtrl <- mkFlashCtrlModel(gtx_clk_fmc1.gtx_clk_p_ifc, gtx_clk_fmc1.gtx_clk_n_ifc, clk250);
	`else
		FlashCtrlVirtexIfc flashCtrl <- mkFlashCtrlVirtex(gtx_clk_fmc1.gtx_clk_p_ifc, gtx_clk_fmc1.gtx_clk_n_ifc, clk250);
	`endif

	//Page Buffers for MemSlave
	PageBuffers pageBufs <- mkPageBuffers();


	//Create read/write engines with NUM_BUSES memservers
	MemReadEngine#(WordSz,WordSz,1, NUM_BUSES) re <- mkMemReadEngine;
	MemWriteEngine#(WordSz,WordSz,1, NUM_BUSES) we <- mkMemWriteEngine;

	Vector#(NUM_BUSES, Reg#(Bit#(16))) dmaWBurstCnts <- replicateM(mkReg(0));
	Vector#(NUM_BUSES, Reg#(Bit#(16))) memSlaveCnts <- replicateM(mkReg(0));
	Vector#(NUM_BUSES, FIFO#(TagT)) dmaReqQs <- replicateM(mkSizedFIFO(valueOf(NumTags)));//TODO make bigger?
	Vector#(NUM_BUSES, FIFO#(Tuple2#(TagT, Bit#(32)))) dmaReq2RespQ <- replicateM(mkSizedFIFO(valueOf(NumTags))); //TODO make bigger?
	Vector#(NUM_BUSES, Reg#(Bit#(32))) dmaWrReqCnts <- replicateM(mkReg(0));
	Vector#(NUM_BUSES, Reg#(TagT)) currTags <- replicateM(mkReg(0));
	FIFO#(Tuple2#(Bit#(WordSz), TagT)) dataFlash2DmaQ <- mkFIFO();

	rule incCycle;
		cycleCnt <= cycleCnt + 1;
	endrule

	rule driveFlashCmd/* (started)*/;
		let cmdNsrc = flashCmdQ.first;
		flashCmdQ.deq;
		let cmd = tpl_1(cmdNsrc);
		let src = tpl_2(cmdNsrc);
		tag2busNsrcTable[cmd.tag] <= tuple2(cmd.bus, src);
		flashCtrl.user.sendCmd(cmd); //forward cmd to flash ctrl FIXME DEBUG
		$display("@%d: Main.bsv: received cmd tag=%d @%x %x %x %x", 
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
		let busNsrc = tag2busNsrcTable[tag];
		let bus = tpl_1(busNsrc);
		let src = tpl_2(busNsrc);
		if (src==SRC_HOST) begin
			dmaWriteBuf[bus].enq(taggedRdata);
		end
		else if (src==SRC_USER_HW) begin
			pageBufs.readResp.put(taggedRdata);
			/*
			Bool last = False;
			if (memSlaveCnts[bus]==fromInteger(pageWords-1)) begin
				memSlaveCnts[bus] <= 0;
				last = True;
			end
			else begin
				memSlaveCnts[bus] <= memSlaveCnts[bus] + 1;
			end
			memSlaveReadBuf.enq(tuple3(data, tag, last));
			*/
		end
		else begin
			$display("ERROR: flashTop: incorrect source");
		end

		$display("@%d Main.bsv: rdata tag=%d, bus=%d, data[%d]=%x", cycleCnt, tag, bus, dmaWBurstCnts[bus], data);
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
			let sglId = tpl_1(dmaWriteRefs[tag]);
			let offset = tpl_2(dmaWriteRefs[tag]);
			Bit#(32) burstOffset = (dmaWrReqCnts[b]<<log2(dmaBurstBytes)) + offset;
			let dmaCmd = MemengineCmd {
								tag: 0, //TODO: this was added in the new connectal
								sglId: sglId, 
								base: zeroExtend(burstOffset),
								len:fromInteger(dmaBurstBytes), 
								burstLen:fromInteger(dmaBurstBytes)
							};
			we.writeServers[b].request.put(dmaCmd);
			dmaReq2RespQ[b].enq(tuple2(tag, dmaWrReqCnts[b]));
			
			$display("@%d Main.bsv: init dma write tag=%d, bus=%d, addr=0x%x 0x%x", 
							cycleCnt, tag, b, sglId, burstOffset);
			if (dmaWrReqCnts[b] == fromInteger(dmaBurstsPerPage-1)) begin
				dmaWrReqCnts[b] <= 0;
			end
			else begin
				dmaWrReqCnts[b] <= dmaWrReqCnts[b] + 1;
			end
		endrule

		//send data
		rule sendDmaWriteData;
			//TODO: is it safe to send this data right away, before the request
			//looks ok?
			let taggedRdata = dmaWriteBufOut[b].first;
			let data = tpl_1(taggedRdata);
			dmaWriteBufOut[b].deq;
			we.writeServers[b].data.enq(data);
		endrule

		//dma response.get done; when enough has accumulated, send ack to sw
		rule dmaWriterGetResponse;
			let dummy <- we.writeServers[b].done.get;
			let tagCnt = dmaReq2RespQ[b].first;
			dmaReq2RespQ[b].deq;
			$display("@%d Main.bsv: dma resp [%d] tag=%d", cycleCnt, tpl_2(tagCnt), tpl_1(tagCnt));
			if (tpl_2(tagCnt)==fromInteger(dmaBurstsPerPage-1)) begin
				indication.readDone(zeroExtend(tpl_1(tagCnt)));
			end
		endrule
	end //for each bus



	//--------------------------------------------
	// Writes to Flash (DMA Reads)
	//--------------------------------------------

	FIFO#(Tuple2#(TagT, BusT)) wrToDmaReqQ <- mkFIFO();
	Vector#(NUM_BUSES, FIFO#(TagT)) dmaRdReq2RespQ <- replicateM(mkSizedFIFO(valueOf(NumTags))); //TODO sz
	Vector#(NUM_BUSES, Reg#(Bit#(32))) dmaReadBurstCount <- replicateM(mkReg(0));
	Vector#(NUM_BUSES, FIFO#(TagT)) dmaReadReqQ <- replicateM(mkSizedFIFO(valueOf(NumTags)));
	Vector#(NUM_BUSES, Reg#(Bit#(32))) dmaRdReqCnts <- replicateM(mkReg(0));

	//Handle write data requests from controller
	rule handleWriteDataRequestFromFlash;
		TagT tag <- flashCtrl.user.writeDataReq();
		//check which bus it's from
		let bus = tpl_1(tag2busNsrcTable[tag]);
		wrToDmaReqQ.enq(tuple2(tag, bus));
	endrule

	rule distrDmaReadReq;
		wrToDmaReqQ.deq;
		let r = wrToDmaReqQ.first;
		let tag = tpl_1(r);
		let bus = tpl_2(r);
		dmaReadReqQ[bus].enq(tag);
		dmaRdReq2RespQ[bus].enq(tag);
	endrule

	for (Integer b=0; b<valueOf(NUM_BUSES); b=b+1) begin
		rule initDmaRead;
			let tag = dmaReadReqQ[b].first;
			let sglId = tpl_1(dmaReadRefs[tag]);
			let offset = tpl_2(dmaReadRefs[tag]);
			Bit#(32) burstOffset = (dmaRdReqCnts[b]<<log2(dmaBurstBytes)) + offset;
			let dmaCmd = MemengineCmd {
								tag: 0, //TODO: this was added in the new connectal
								sglId: sglId, 
								base: zeroExtend(burstOffset),
								len:fromInteger(dmaBurstBytes), 
								burstLen:fromInteger(dmaBurstBytes)
							};
			re.readServers[b].request.put(dmaCmd);
			$display("Main.bsv: dma read cmd issued: sglId=%x, burstOffset=%d", sglId, burstOffset);

			if (dmaRdReqCnts[b] == fromInteger(dmaBurstsPerPage-1)) begin
				dmaRdReqCnts[b] <= 0;
				dmaReadReqQ[b].deq; //done with this req
			end
			else begin
				dmaRdReqCnts[b] <= dmaRdReqCnts[b] + 1;
			end
		endrule

		//forward data
		rule forwardDmaRdData;
			let d <- toGet(re.readServers[b].data).get;
			let tag = dmaRdReq2RespQ[b].first;
			flashCtrl.user.writeWord(tuple2(d.data, tag));
			$display("Main.bsv: forwarded dma read data [%d]: tag=%d, data=%x", dmaReadBurstCount[b],
							tag, d.data);

			if (dmaReadBurstCount[b] == fromInteger(pageWords-1)) begin
				dmaRdReq2RespQ[b].deq;
				dmaReadBurstCount[b] <= 0;
			end
			else begin
				dmaReadBurstCount[b] <= dmaReadBurstCount[b] + 1;
			end
		endrule
	end //for each bus

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
	// PageBuffer flash cmd requests
	//--------------------------------------------
	rule pageBufFlashReq; 
		let cmd <- pageBufs.flashReq.get;
		$display("FlashTop: page buf cmd received");
		flashCmdQ.enq(tuple2(cmd, SRC_USER_HW));
	endrule



	//--------------------------------------------
	// Debug
	//--------------------------------------------

	FIFO#(Bit#(1)) debugReqQ <- mkFIFO();
	rule doDebugDump;
		$display("Main.bsv: debug dump request received");
		debugReqQ.deq;
		let debugCnts = flashCtrl.debug.getDebugCnts(); 
		let gearboxSendCnt = tpl_1(debugCnts);         
		let gearboxRecCnt = tpl_2(debugCnts);   
		let auroraSendCntCC = tpl_3(debugCnts);     
		let auroraRecCntCC = tpl_4(debugCnts);  
		indication.debugDumpResp(gearboxSendCnt, gearboxRecCnt, auroraSendCntCC, auroraRecCntCC);
	endrule



	//--------------------------------------------
	// Interfaces
	//--------------------------------------------
	//Vector#(1, MemWriteClient#(WordSz)) dmaWriteClientVec;
	//Vector#(1, MemReadClient#(WordSz)) dmaReadClientVec;
	//dmaWriteClientVec[0] = we.dmaClient;
	//dmaReadClientVec[0] = re.dmaClient;
	
	/*
	Reg#(Bit#(1)) getPhase <- mkReg(0);

   interface PhysMemSlave memSlave;
		interface PhysMemReadServer read_server;
			interface Put readReq;
				method Action put(PhysMemRequest#(FlashAddrWidth) req);
					//req.addr; //bus, chip, blk, page
					//req.burstLen; //should always be 8k
					//req.tag; //6 bit (64 tags)
					Bit#(8) page = req.addr[7:0];
					Bit#(16) block = req.addr[23:8];
					ChipT chip = truncate(req.addr>>(16+8));
					BusT bus = truncate(req.addr>>(16+8+valueOf(TLog#(ChipsPerBus))));
					TagT tag = zeroExtend(req.tag);

					FlashCmd fcmd = FlashCmd{
						tag: tag,
						op: READ_PAGE,
						bus: bus,
						chip: chip,
						block: block,
						page: page
						};
					flashCmdQ.enq(tuple2(fcmd, SRC_USER_HW));
				endmethod
			endinterface
			interface Get readData;
				method ActionValue#(MemData#(128)) get();
					let taggedRdataLast = memSlaveReadBuf.first;
					Bit#(WordSz) data = tpl_1(taggedRdataLast);
					TagT tag = tpl_2(taggedRdataLast);
					Bool last = tpl_3(taggedRdataLast);

					memSlaveReadBuf.deq;
					MemData#(128) memData = MemData { 
							data: data, 
							tag: truncate(tag), 	//FIXME DANGEROUS
							last: last				
						};
					return memData;
				endmethod
			endinterface
		endinterface
		interface PhysMemWriteServer write_server = ?;
	endinterface
	*/

	interface PhysMemSlave memSlave = pageBufs.memSlave;

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

			flashCmdQ.enq(tuple2(fcmd, SRC_HOST));
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

			flashCmdQ.enq(tuple2(fcmd, SRC_HOST));
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
			flashCmdQ.enq(tuple2(fcmd, SRC_HOST));
		endmethod

		method Action addDmaReadRefs(Bit#(32) sglId, Bit#(32) offset, Bit#(32) tag);
			dmaReadRefs[tag] <= tuple2(sglId, offset);
		endmethod

		method Action addDmaWriteRefs(Bit#(32) sglId, Bit#(32) offset, Bit#(32) tag);
			dmaWriteRefs[tag] <= tuple2(sglId, offset);
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

   interface MemWriteClient hostMemWriteClient = vec(we.dmaClient);
   interface MemReadClient hostMemReadClient = vec(re.dmaClient);
   interface Aurora_Pins aurora_fmc1 = flashCtrl.aurora;
   interface Aurora_Clock_Pins aurora_clk_fmc1 = gtx_clk_fmc1.aurora_clk;
endmodule
