import FIFOF::*;
import FIFO::*;
import FIFOLevel::*;
import BRAMFIFO::*;
import BRAM::*;
import GetPut::*;
import ClientServer::*;
import Arbiter::*;
import Vector::*;
import List::*;

import ConnectalMemTypes::*;
import ControllerTypes::*;


interface PageBuffers;
	interface PhysMemSlave#(FlashAddrWidth, 128) memSlave; //to user hw
	interface Get#(FlashCmd) flashReq;
	interface Put#(Tuple2#(Bit#(WordSz), TagT)) readResp;
endinterface

typedef TLog#(PageWords) PageOffsetSz;

typedef enum {
	ST_INIT,
	ST_CMD,
	ST_HIT,
	ST_MISS,
	ST_MISS_READDATA
} BufOpState deriving (Bits, Eq);

typedef struct {
	Bool valid;
	FlashAddr faddr;
} PageBufferEntry deriving (Bits, Eq);

typedef struct {
	FlashAddr faddr;
	Bit#(PageOffsetSz) offset;
} PageAddrOff deriving (Bits, Eq);

function PageAddrOff decodePhysMemAddr(Bit#(FlashAddrWidth) addr);
	//byte addressible
	Tuple2#(PageAddrOff, Bit#(TLog#(WordBytes))) decodedAddr = unpack(truncate(addr));
	return tpl_1(decodedAddr);
	//PageAddrOff decodedAddr = unpack(truncate(addr)); //FIXME FIXME FIXME
	//return decodedAddr;
endfunction


function TagT splitTagsByBus(Integer id, Bit#(32) cnt);
	Bit#(32) group = fromInteger(id * (valueOf(NumTags)/valueOf(NUM_BUSES)));
	return truncate(group + cnt);
endfunction

function BusT tag2bus(TagT tag);
	return truncate( tag>>(log2(num_tags/num_buses)) );
endfunction

//TODO: for now assumes that the request does not cross page boundaries
(* synthesize *)
module mkPageBuffers(PageBuffers);

	//Page Buffers
	Vector#(NUM_BUSES, PageBuffers) pageBuffers = newVector();
	for (Integer bus=0; bus<valueOf(NUM_BUSES); bus=bus+1) begin
		pageBuffers[bus] <- mkSinglePageBuffer(bus);
	end

	//Arbiter
	Arbiter_IFC#(NUM_BUSES) arb <- mkStickyArbiter();

	FIFO#(Tuple2#(Bit#(WordSz), TagT)) flashReadAggrQ <- mkFIFO();
	FIFO#(FlashCmd) flashCmdAggrQ <- mkFIFO();
	FIFO#(MemData#(128)) slaveRespAggrQ <- mkFIFO;
	

	rule distrFlashRead;
		flashReadAggrQ.deq;
		let tdata = flashReadAggrQ.first;
		let tag = tpl_2(tdata);
		let bus = tag2bus(tag);
		pageBuffers[bus].readResp.put(tdata);
	endrule


	//Handle flash cmd and data
	for (Integer bus=0; bus<valueOf(NUM_BUSES); bus=bus+1) begin
		rule funnelFlashCmd;
			let cmd <- pageBuffers[bus].flashReq.get();
			flashCmdAggrQ.enq(cmd);
			$display("PageBufferTop: flashCmdAggrQ enq");
		endrule

		//Handle mem slave read data arbitration
		FIFOF#(MemData#(128)) slaveRespBufs <- mkFIFOF;
		rule getBuffSlaveData;
			let rd <- pageBuffers[bus].memSlave.read_server.readData.get();
			slaveRespBufs.enq(rd);
		endrule

		Reg#(Bool) granted <- mkReg(False);
		rule arbReq if (slaveRespBufs.notEmpty && !granted);
			arb.clients[bus].request();
			if (arb.clients[bus].grant) begin
				granted <= True;
			end
		endrule

		rule holdGrant if (granted);
			arb.clients[bus].request();
		endrule

		rule send if (granted);
			slaveRespBufs.deq;
			slaveRespAggrQ.enq(slaveRespBufs.first);
			if (slaveRespBufs.first.last) begin
				granted <= False;
			end
		endrule

	end //for buses


	interface PhysMemSlave memSlave;
		interface PhysMemReadServer read_server;
			interface Put readReq;
				method Action put(PhysMemRequest#(FlashAddrWidth) req);
					//distribute each request to each buffer by bus
					PageAddrOff decAddr = decodePhysMemAddr(req.addr);
					pageBuffers[decAddr.faddr.bus].memSlave.read_server.readReq.put(req);
				endmethod
			endinterface
			interface Get readData = toGet(slaveRespAggrQ);
		endinterface
		interface PhysMemWriteServer write_server = ?;
	endinterface

	interface Get flashReq = toGet(flashCmdAggrQ);
	interface Put readResp = toPut(flashReadAggrQ);
endmodule
	







module mkSinglePageBuffer#(Integer busId)(PageBuffers);

	//BRAM
	BRAM2Port#(Bit#(PageOffsetSz), Bit#(WordSz)) pageBuffer <- mkBRAM2Server(defaultValue);
	Reg#(PageBufferEntry) pageBufEntry <- mkReg(unpack(0));
	FIFO#(Tuple2#(Bit#(WordSz), TagT)) flashReadQ <- mkFIFO();
	FIFO#(FlashCmd) flashCmdQ <- mkFIFO();
	Reg#(Bit#(BurstLenSize)) reqRemain <- mkReg(0); 
	Reg#(Bit#(BurstLenSize)) respRemain <- mkReg(0); 
	Reg#(Bit#(PageOffsetSz)) writePtr <- mkReg(0);

	FIFO#(MemData#(128)) slaveRespQ <- mkFIFO;
	FIFO#(TagT) freeTagQ <- mkSizedFIFO(num_tags);
	FIFO#(PhysMemRequest#(FlashAddrWidth)) slaveReqQ <- mkSizedFIFO(valueOf(NumTags)/valueOf(NUM_BUSES));
	Reg#(BufOpState) state <- mkReg(ST_INIT);

	//split tags among these buffers
	Reg#(Bit#(32)) tagCnt <- mkReg(0); //initialize to the id of this buffer
	rule init (state==ST_INIT);
		let tag = splitTagsByBus(busId, tagCnt);
		freeTagQ.enq(tag);
		$display("FreeTag enq: %d", tag);
		if (tagCnt == fromInteger(num_tags/num_buses-1)) begin
			state <= ST_CMD;
			tagCnt <= 0;
		end
		else begin
			tagCnt <= tagCnt + 1;
		end
	endrule

	//decode address
	let currReq = slaveReqQ.first;
	PageAddrOff addrOff = decodePhysMemAddr(currReq.addr);
	rule handleSlaveReq (state==ST_CMD); 
		$display("PageBuffers: Received slave command: addr=%x, len=%d, tag=%d", currReq.addr,
			currReq.burstLen, currReq.tag);
		//slaveReqQ.deq; //FIXME: debug
		//look up in cache
		let bus = addrOff.faddr.bus;
		if (pageBufEntry.valid && pageBufEntry.faddr==addrOff.faddr) begin
			//if hit, make request to BRAM
			$display("PageBuffers: hit");
			state <= ST_HIT;
			reqRemain <= currReq.burstLen>>fromInteger(valueOf(WordBytesLog));
			respRemain <= currReq.burstLen>>fromInteger(valueOf(WordBytesLog));
		end
		else begin
			//if miss, make request to flash controller
			$display("PageBuffers: miss");
			state <= ST_MISS;
			pageBufEntry.valid <= False;
		end
		
	endrule

	rule handleHit (state==ST_HIT && reqRemain>0);
		Bit#(32) burstOffset = zeroExtend((currReq.burstLen>>fromInteger(valueOf(WordBytesLog))) - reqRemain); 
		if (burstOffset >= fromInteger(pageWords)) begin
			$display("PageBuffer: **ERROR burstOffset exceeds number of pageWords");
		end
		Bit#(PageOffsetSz) baddr = addrOff.offset + truncate(burstOffset); //safe truncation
		$display("PageBuffer: portB read req addrOff=%x, burstOffset=%x, baddr= %x", addrOff.offset, burstOffset, baddr);
		pageBuffer.portB.request.put(
			BRAMRequest{
				write: False,
				responseOnWrite: ?,
				address: baddr,
				datain: ?}
		);
		reqRemain <= reqRemain - 1;
	endrule
	
	rule handleHitData (state==ST_HIT);
		let data <- pageBuffer.portB.response.get();	
		Bool last = (respRemain==1);
		slaveRespQ.enq( MemData { data: data, tag: currReq.tag, last: last} );
		$display("PageBuffer: hit data=%x, tag=%d, last=%d", data, currReq.tag, last);
		if (respRemain==1) begin
			state <= ST_CMD;
			slaveReqQ.deq; 
		end
		else begin
			respRemain <= respRemain - 1;
		end
	endrule


	rule missFlashRequest (state==ST_MISS);
		//get free tag
		freeTagQ.deq;
		let ftag = freeTagQ.first;
		FlashCmd fcmd = FlashCmd {
			tag: ftag,
			op: READ_PAGE,
			bus: addrOff.faddr.bus,
			chip: addrOff.faddr.chip,
			block: addrOff.faddr.block,
			page: addrOff.faddr.page
		};
		flashCmdQ.enq(fcmd);
		$display("PageBuffers: missFlashRequest issued for: ftag=%d, bus=%d, chip=%d, blk=%d, page=%d", 
					ftag, addrOff.faddr.bus, addrOff.faddr.chip, addrOff.faddr.block, addrOff.faddr.page);
		state <= ST_MISS_READDATA;
	endrule

	rule missGetFlashRead (state==ST_MISS_READDATA);
		//TODO: only one buffer, so no reordering per bus
		flashReadQ.deq;
		let data = tpl_1(flashReadQ.first);
		let tag = tpl_2(flashReadQ.first);
		$display("PageBuffers: got read data from flash: tag=%d, data=%x", tag, data);
		pageBuffer.portA.request.put(
				BRAMRequest{ write:True, 
							responseOnWrite:False, 
							address:writePtr ,
							datain: data } 
						);
		if (writePtr==fromInteger(pageWords-1)) begin
			//update metadata about what's in the buffer
			pageBufEntry <= PageBufferEntry { valid: True, faddr: addrOff.faddr};
			freeTagQ.enq(tag);
			state <= ST_CMD; //reattempt command
			writePtr <= 0;
		end
		else begin
			writePtr <= writePtr + 1;
		end
	endrule

	interface PhysMemSlave memSlave;
		interface PhysMemReadServer read_server;
			interface Put readReq = toPut(slaveReqQ);
			interface Get readData = toGet(slaveRespQ);
		endinterface
		interface PhysMemWriteServer write_server = ?;
	endinterface

	interface Get flashReq = toGet(flashCmdQ);
	interface Put readResp = toPut(flashReadQ);


endmodule
