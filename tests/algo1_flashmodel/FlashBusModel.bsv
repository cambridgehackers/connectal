import FIFOF::*;
import FIFO::*;
import BRAMFIFO::*;
import BRAM::*;
import GetPut::*;
import ClientServer::*;
import Vector::*;
import RegFile::*;

import ControllerTypes::*;

//For SIMULATION: use hashed read data (so we don't have to write before read)
typedef 1 SIMULATION_USE_HASHED_DATA; 

typedef enum {
	ST_CMD,
	ST_OP_DELAY,
	ST_BUS_RESERVE,
	ST_WRITE_BUS_RESERVE,
	ST_WRITE_REQ,
	ST_ERASE,
	ST_ERROR,
	ST_READ_TRANSFER,
	ST_WRITE_DATA,
	ST_WRITE_ACK,
	ST_READ_DATA
} ChipState deriving (Bits, Eq);


function Bit#(TLog#(WordsPerChip)) getRegAddr (Bit#(16) block, Bit#(8) page, Bit#(16) burstCnt);
	Bit#(64) blockExt = zeroExtend(block);
	Bit#(64) pageExt = zeroExtend(page);
	Bit#(64) burstCntExt = zeroExtend(burstCnt);
	Bit#(64) regAddr = (blockExt<<(log2(pageWords*pagesPerBlock))) + (pageExt<<log2(pageWords)) + burstCntExt;
	return truncate(regAddr);
endfunction



function Bit#(128) getDataHash (Bit#(16) dataCnt, Bit#(8) page, Bit#(16) block, ChipT chip, BusT bus);
	/*
	Bit#(8) dataCntTrim = truncate(dataCnt << 3);
	Bit#(8) blockTrim = truncate(block);
	Bit#(8) chipTrim = zeroExtend(chip);
	Bit#(8) busTrim = zeroExtend(bus);

	Vector#(8, Bit#(16)) dataAggr = newVector();
	for (Integer i=7; i >= 0; i=i-1) begin
		Bit#(8) dataHi = truncate(dataCntTrim + fromInteger(i) + 8'hA0 + (blockTrim<<4)+ (chipTrim<<2) + (busTrim<<6));
		Bit#(8) dataLow = truncate( (~dataHi) + blockTrim );
		dataAggr[i] = {dataHi, dataLow};
	end
	return pack(dataAggr);
	*/
	//FIXME tmp hashing for debug
	Bit#(128) busEx = zeroExtend(bus);
	Bit#(128) chipEx = zeroExtend(chip);
	Bit#(128) blockEx = zeroExtend(block);
	Bit#(128) pageEx = zeroExtend(page);
	Bit#(128) dataCntEx = zeroExtend(dataCnt);
	Bit#(128) dataRet = zeroExtend( (busEx<<64) + (chipEx<<48) + (blockEx<<32) + (pageEx<<16) + dataCntEx );
	return dataRet;


endfunction


interface FlashBusModelIfc;
	method Action sendCmd(FlashCmd cmd);
	method Action writeWord (Tuple2#(Bit#(128), TagT) taggedData);
	method ActionValue#(Tuple2#(Bit#(128), TagT)) readWord ();
	method ActionValue#(TagT) writeDataReq();
	method ActionValue#(Tuple2#(TagT, StatusT)) ackStatus ();
endinterface

(* synthesize *)
(* descending_urgency = "chipWriteAck, chipWriteAck_1, chipWriteAck_2, chipWriteAck_3, chipWriteAck_4, chipWriteAck_5, chipWriteAck_6, chipWriteAck_7" *) 
module mkFlashBusModel(FlashBusModelIfc);
	
	Integer t_Read = 750; //read delay
	Integer t_Write = 5000; //write delay
	Integer t_Erase = 15000; //erase delay
	Integer burstDelay = 7; //read bursts 128 bits every 8 cycles //TODO adjust this 

	//Create a regfile per chip
	Vector#(ChipsPerBus, RegFile#(Bit#(TLog#(WordsPerChip)), Bit#(128))) flashArr <- replicateM(mkRegFileFull());

	
	//enq commands to each chip (emulated sb)
	Vector#(ChipsPerBus, FIFO#(FlashCmd)) flashChipCmdQs <- replicateM(mkSizedFIFO(16));
	FIFO#(Tuple2#(Bit#(WordSz), TagT)) busReadQ <- mkFIFO();
	Reg#(Bool) busInUse <- mkReg(False);
	Reg#(ChipT) busReservedChipIdx <- mkReg(0);
	FIFO#(Tuple2#(TagT, StatusT)) ackQ <- mkSizedFIFO(valueOf(NumTags));
	FIFOF#(TagT) writeReqQ <- mkSizedFIFOF(3); 
	Reg#(Bit#(4)) writeDataReqIssued <- mkReg(0);
	Reg#(Bit#(4)) writeDataReqProcessed <- mkReg(0);
	//2 page buffer
	FIFOF#(Tuple2#(Bit#(WordSz), TagT)) writeBuffer <- mkSizedFIFOF(pageWords*2+1);
	//simulate the round robin sb using a counter
	Reg#(Bit#(16)) chipSel <- mkReg(0);
	Reg#(Bit#(64)) cycleCnt <- mkReg(0);
	
	rule incCycleCnt;
		cycleCnt <= cycleCnt + 1;
	endrule

	rule checkWriteReqFull if (!writeReqQ.notFull);
		$display("**ERROR: FlashBusModel: Write data request buffer should never be full");
	endrule

	rule checkWriteBufferFull if (!writeBuffer.notFull);
		$display("**ERROR: FlashBusModel: Write buffer should never be full");
	endrule

	rule chipSelIncr;
		if (chipSel == fromInteger(chipsPerBus-1)) begin
			chipSel <= 0;
		end
		else begin
			chipSel <= chipSel + 1;
		end
		//$display("chipSel=%d", chipSel);
	endrule


	for (Integer c=0; c<chipsPerBus; c=c+1) begin
		Reg#(ChipState) chipSt <- mkReg(ST_CMD);
		Reg#(ChipState) chipStReturn <- mkReg(ST_CMD);
		Reg#(Bit#(32)) delayCnt <- mkReg(0);
		Reg#(Bit#(16)) readDlyCnt <- mkReg(fromInteger(burstDelay));
		Reg#(Bit#(16)) wrDlyCnt <- mkReg(fromInteger(burstDelay));
		Reg#(Bit#(16)) readBurstCnt <- mkReg(0);
		Reg#(Bit#(16)) writeBurstCnt <-  mkReg(0);

		rule chipHandleCmd if (chipSt==ST_CMD);
			let cmd = flashChipCmdQs[c].first;
			if (cmd.page > fromInteger(pagesPerBlock-1)) begin
				$display("**ERROR: cmd page exceeds simulation pages available. Sim pages=%d", pagesPerBlock);
				chipSt <= ST_ERROR;
			end
			else if (cmd.block > fromInteger(blocksPerCE-1)) begin
				$display("**ERROR: cmd block exceeds simulation blocks available. Sim blocks=%d", blocksPerCE);
				chipSt <= ST_ERROR;
			end
			else begin
				case (cmd.op) 
					READ_PAGE: 
						begin
							delayCnt <= fromInteger(t_Read);
							chipSt <= ST_OP_DELAY;
							chipStReturn <= ST_BUS_RESERVE;
							$display("@%d %m FlashBus chip[%d] starting READ cmd...", cycleCnt, cmd.chip);
						end
					WRITE_PAGE:
						begin
							chipSt <= ST_WRITE_REQ;
							delayCnt <= fromInteger(t_Write);
							$display("@%d %m FlashBus chip[%d] starting WRITE cmd...", cycleCnt, cmd.chip);
						end
					ERASE_BLOCK:
						begin
							chipSt <= ST_OP_DELAY;
							chipStReturn <= ST_ERASE;
							delayCnt <= fromInteger(t_Erase);
							$display("@%d %m FlashBus chip[%d] starting ERASE cmd...", cycleCnt, cmd.chip);
						end
					default: 
						begin
							chipSt <= ST_ERROR;//throw error TODO
							$display("**ERROR: FlashBusModel invalid op");
						end
				endcase
			end
		endrule

			

		//wait rule (tRead, tWrite, tErase)
		rule chipOpDelay if (chipSt==ST_OP_DELAY);
			if (delayCnt==0) begin
				chipSt <= chipStReturn;
				$display("%m FlashBus chip[%d] op delay done", c);
			end
			else begin
				delayCnt <= delayCnt-1;
			end
		endrule

		//READ: take control of bus
		rule chipReadBusReserve if (chipSt==ST_BUS_RESERVE && !busInUse && chipSel==fromInteger(c));
			busReservedChipIdx <= fromInteger(c);
			busInUse <= True;
			chipSt <= ST_READ_TRANSFER;
			$display("@%d %m FlashBus reserved bus for chip = %d", cycleCnt, c);
		endrule

		//READ: transfer read only if selected and bus is reserved
		rule chipReadTransfer if (chipSt==ST_READ_TRANSFER && busInUse && busReservedChipIdx==fromInteger(c));
			let cmd = flashChipCmdQs[c].first;
			//transfer 128bits every 8 cycles (to emulate flash behavior)
			if (readDlyCnt > 0) begin
				readDlyCnt <= readDlyCnt - 1;
			end
			else begin
				readDlyCnt <= fromInteger(burstDelay);
				if (valueOf(BSIM_USE_HASHED_DATA)==1) begin
					let dataHashed = getDataHash (readBurstCnt, cmd.page, cmd.block, cmd.chip, cmd.bus);
					busReadQ.enq(tuple2(dataHashed, cmd.tag));
					$display("@%d %m FlashBus chip[%d] read data tag=%d @ [%d][%d][%d] = %x", cycleCnt, c, cmd.tag, cmd.block, cmd.page, readBurstCnt, dataHashed);
				end
				else begin
					//compute addr in regfile
					let regAddr = getRegAddr(cmd.block, cmd.page, readBurstCnt); 
					let rdata = flashArr[c].sub(regAddr);

					busReadQ.enq(tuple2(rdata, cmd.tag));
					$display("@%d %m FlashBus chip[%d] read data tag=%d @ regAddr=%d [%d][%d][%d] = %x", cycleCnt, c, regAddr, cmd.tag, cmd.block, cmd.page, readBurstCnt, rdata);
				end
				if (readBurstCnt==fromInteger(pageWords-1)) begin
					flashChipCmdQs[c].deq;
					readBurstCnt <= 0;
					chipSt <= ST_CMD;
					busInUse <= False;
					$display("@%d %m FlashBus chip[%d] done read", cycleCnt, cmd.chip);
				end
				else begin
					readBurstCnt <= readBurstCnt + 1;
				end
			end

		endrule

		//write request for data; when selected and have enough page buffers
		rule chipWriteDataReq if (chipSt==ST_WRITE_REQ && chipSel==fromInteger(c) 
											&& (writeDataReqIssued - writeDataReqProcessed) < 2);
			let cmd = flashChipCmdQs[c].first;
			writeReqQ.enq(cmd.tag);
			chipSt <= ST_WRITE_BUS_RESERVE;
			writeDataReqIssued <= writeDataReqIssued + 1;
			$display("@%d %m FlashBus chip[%d] writeDataReq issued, tag=%d", cycleCnt, c, cmd.tag);
		endrule

		//write data reserve bus
		rule chipWriteBusReserve if (chipSt==ST_WRITE_BUS_RESERVE && !busInUse 
												&& flashChipCmdQs[c].first.tag==tpl_2(writeBuffer.first)
												&& chipSel==fromInteger(c)	);
			busReservedChipIdx <= fromInteger(c);
			busInUse <= True;
			chipSt <= ST_WRITE_DATA;
			$display("@%d %m FlashBus chip[%d] write bus reserved", cycleCnt, c);
		endrule
	
		//write data every 8 cycles
		rule chipWriteData if (chipSt==ST_WRITE_DATA && busInUse && busReservedChipIdx==fromInteger(c));
			let cmd = flashChipCmdQs[c].first;
			if (wrDlyCnt > 0) begin
				wrDlyCnt <= wrDlyCnt - 1;
			end
			else begin
				wrDlyCnt <= fromInteger(burstDelay);
				if (cmd.tag==tpl_2(writeBuffer.first)) begin
					let regAddr = getRegAddr(cmd.block, cmd.page, writeBurstCnt); 
					flashArr[c].upd(regAddr, tpl_1(writeBuffer.first));
					writeBuffer.deq;
					$display("@%d %m FlashBus chip[%d] wrote data @ regAddr=%d [%d][%d][%d] = %x", cycleCnt, c,regAddr, cmd.block, cmd.page, writeBurstCnt, tpl_1(writeBuffer.first));
				end
				else begin
					$display("**ERROR: FlashBusModel incorrect burst received. Cmd tag=%d, burst tag=%d",
								flashChipCmdQs[c].first.tag, tpl_2(writeBuffer.first));
				end

				if (writeBurstCnt==fromInteger(pageWords-1)) begin //done transfer
					$display("@%d %m FlashBus chip[%d] write done transfer", cycleCnt, c);
					//wait tWrite
					chipSt <= ST_OP_DELAY;
					chipStReturn <= ST_WRITE_ACK;
					writeDataReqProcessed <= writeDataReqProcessed + 1;
					busInUse <= False;
					writeBurstCnt <= 0;
				end
				else begin
					writeBurstCnt <= writeBurstCnt + 1;
				end
			end
		endrule

		//write ack
		rule chipWriteAck if (chipSt==ST_WRITE_ACK);
			let cmd = flashChipCmdQs[c].first;
			flashChipCmdQs[c].deq;
			ackQ.enq(tuple2(cmd.tag, WRITE_DONE));
			chipSt <= ST_CMD;
			$display("%m FlashBus chip[%d] write ack tag=%d", c, cmd.tag);
		endrule

		//erase
		Reg#(Bit#(16)) eraseWordCnt <- mkReg(0);
		Reg#(Bit#(8)) erasePageCnt <- mkReg(0);
		rule chipErase if (chipSt==ST_ERASE);
			let cmd = flashChipCmdQs[c].first;
			//erase entire block
			let regAddr = getRegAddr(cmd.block, erasePageCnt, eraseWordCnt);
			flashArr[c].upd(regAddr, -1);
			$display("%m FlashBus chip[%d] erasing tag=%d, blk = %d, pageCnt = %d, wordCnt = %d", c, cmd.tag, cmd.block, erasePageCnt, eraseWordCnt);

			if (eraseWordCnt == fromInteger(pageWords-1)) begin //done page
				eraseWordCnt <= 0;
				if (erasePageCnt == fromInteger(pagesPerBlock-1)) begin //done block
					flashChipCmdQs[c].deq;
					erasePageCnt <= 0;
					ackQ.enq(tuple2(cmd.tag, ERASE_DONE));
					chipSt <= ST_CMD;
				end
				else begin
					erasePageCnt <= erasePageCnt + 1;
				end
			end
			else begin
				eraseWordCnt <= eraseWordCnt + 1;
			end
		endrule

		rule errorState if (chipSt==ST_ERROR);
			$display("**ERROR: FlashBusModel chip[%d] in error state", c);
		endrule
	end //chipsPerBus

	method Action sendCmd(FlashCmd cmd);
		flashChipCmdQs[cmd.chip].enq(cmd);
	endmethod

	method Action writeWord (Tuple2#(Bit#(128), TagT) taggedData);
		writeBuffer.enq(taggedData);
	endmethod

	method ActionValue#(Tuple2#(Bit#(128), TagT)) readWord ();
		busReadQ.deq;
		return busReadQ.first;
	endmethod

	method ActionValue#(TagT) writeDataReq();
		writeReqQ.deq;
		return writeReqQ.first;
	endmethod

	method ActionValue#(Tuple2#(TagT, StatusT)) ackStatus ();
		ackQ.deq;
		return ackQ.first;
	endmethod



endmodule
