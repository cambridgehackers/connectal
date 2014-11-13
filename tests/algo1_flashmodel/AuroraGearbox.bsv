import FIFO::*;
import FIFOF::*;
import Clocks :: *;

typedef 8 HeaderSz;
typedef TSub#(128,8) BodySz;
typedef TMul#(2,TSub#(128,HeaderSz)) DataIfcSz;
typedef Bit#(DataIfcSz) DataIfc;
typedef Bit#(6) PacketType;
typedef 128 AuroraWidth;


interface AuroraGearboxIfc;
	method Action send(DataIfc data, PacketType ptype);
	method ActionValue#(Tuple2#(DataIfc, PacketType)) recv;

	method Action auroraRecv(Bit#(AuroraWidth) word);
	method ActionValue#(Bit#(AuroraWidth)) auroraSend;

	//method Action resetLink;
endinterface

module mkAuroraGearbox#(Clock aclk, Reset arst) (AuroraGearboxIfc);
	SyncFIFOIfc#(Tuple2#(DataIfc,PacketType)) sendQ <- mkSyncFIFOFromCC(4, aclk);

	Integer recvQDepth = 128;
	Integer windowSize = 64;
	SyncFIFOIfc#(Tuple2#(DataIfc,PacketType)) recvQ <- mkSyncFIFOToCC(4, aclk, arst);
	FIFO#(Tuple2#(DataIfc,PacketType)) recvBufferQ <- mkSizedFIFO(recvQDepth, clocked_by aclk, reset_by arst);
	Reg#(Bit#(16)) maxInFlightUp <- mkReg(0, clocked_by aclk, reset_by arst);
	Reg#(Bit#(16)) maxInFlightDown <- mkReg(0, clocked_by aclk, reset_by arst);
	Reg#(Bit#(16)) curInQUp <- mkReg(0, clocked_by aclk, reset_by arst);
	Reg#(Bit#(16)) curInQDown <- mkReg(0, clocked_by aclk, reset_by arst);
	FIFOF#(Bit#(8)) flowControlQ <- mkFIFOF(clocked_by aclk, reset_by arst);
	rule emitFlowControlPacket
		((maxInFlightUp-maxInFlightDown)
		+(curInQUp-curInQDown)
		+fromInteger(windowSize) < fromInteger(recvQDepth));

		flowControlQ.enq(fromInteger(windowSize));
		maxInFlightUp <= maxInFlightUp + fromInteger(windowSize);
	endrule

	Reg#(Bit#(16)) curSendBudgetUp <- mkReg(0, clocked_by aclk, reset_by arst);
	Reg#(Bit#(16)) curSendBudgetDown <- mkReg(0, clocked_by aclk, reset_by arst);

	FIFO#(Bit#(AuroraWidth)) auroraOutQ <- mkFIFO(clocked_by aclk, reset_by arst);
	Reg#(Maybe#(Tuple2#(Bit#(BodySz), PacketType))) packetSendBuffer <- mkReg(tagged Invalid, clocked_by aclk, reset_by arst);
	rule sendPacketPart;
		let curSendBudget = curSendBudgetUp - curSendBudgetDown;
		if ( flowControlQ.notEmpty ) begin
			flowControlQ.deq;
			PacketType ptype = 0;
			auroraOutQ.enq({2'b01, ptype, zeroExtend(flowControlQ.first)});
			$display("AuroraOutQ: flowControl packet: %d", flowControlQ.first);
			$display("send budget = %d", curSendBudget);
		end else
		if ( curSendBudget > 0 ) begin
			if ( isValid(packetSendBuffer) ) begin
				let btpl = fromMaybe(?, packetSendBuffer);
				//auroraIntraImport.user.send({2'b10,
				auroraOutQ.enq({2'b10,
					tpl_2(btpl), tpl_1(btpl)
					});
				packetSendBuffer <= tagged Invalid;
				curSendBudgetDown <= curSendBudgetDown + 1;
				$display("AuroraOutQ: data packet VALID: data=%x, type=%x", tpl_1(btpl), tpl_2(btpl));
			end else begin
				sendQ.deq;
				let data = sendQ.first;
				packetSendBuffer <= tagged Valid 
					tuple2(
						truncate(tpl_1(data)>>valueOf(BodySz)),
						tpl_2(data)
					);
				auroraOutQ.enq({2'b00, tpl_2(data),truncate(tpl_1(data))});
				$display("AuroraOutQ: data packet INVALID: data=%x, type=%x", tpl_1(data), tpl_2(data));
			end
			$display("send budget = %d", curSendBudget);
		end
	endrule

	FIFO#(Bit#(AuroraWidth)) auroraInQ <- mkFIFO(clocked_by aclk, reset_by arst);
	Reg#(Maybe#(Bit#(BodySz))) packetRecvBuffer <- mkReg(tagged Invalid, clocked_by aclk, reset_by arst);
	Reg#(Bit#(1)) curRecvOffset <- mkReg(0, clocked_by aclk, reset_by arst);
	rule recvPacketPart;
		let crdata = auroraInQ.first;
		auroraInQ.deq;
		Bit#(BodySz) cdata = truncate(crdata);
		Bit#(8) header = truncate(crdata>>valueOf(BodySz));
		Bit#(1) idx = header[7];
		Bit#(1) control = header[6];
		PacketType ptype = truncate(header);

		if ( control == 1 ) begin
			curSendBudgetUp <= curSendBudgetUp + truncate(cdata);
		end 
		else if ( isValid(packetRecvBuffer) ) begin
			let pdata = fromMaybe(0, packetRecvBuffer);
			if ( idx == 1 ) begin
				packetRecvBuffer <= tagged Invalid;
				recvBufferQ.enq( tuple2({cdata, pdata}, ptype) );

				maxInFlightDown <= maxInFlightDown + 1;
				curInQUp <= curInQUp + 1;
			end
			else begin
				packetRecvBuffer <= tagged Valid cdata;
			end
		end
		else begin
			if ( idx == 0 ) 
				packetRecvBuffer <= tagged Valid cdata;
		end
	endrule
	rule flushReadBuffer;
		curInQDown <= curInQDown + 1;

		recvBufferQ.deq;
		recvQ.enq(recvBufferQ.first);
	endrule

	method Action send(DataIfc data, PacketType ptype);
		sendQ.enq(tuple2(data, ptype));
	endmethod
	method ActionValue#(Tuple2#(DataIfc, PacketType)) recv;

		recvQ.deq;
		return recvQ.first;
	endmethod

	method Action auroraRecv(Bit#(AuroraWidth) word);
		auroraInQ.enq(word);
	endmethod
	method ActionValue#(Bit#(AuroraWidth)) auroraSend;
		auroraOutQ.deq;
		return auroraOutQ.first;
	endmethod
	
	/*
	method Action resetLink;
		maxInFlightUp <= 0;
		maxInFlightDown <= 0;
		curInQUp <= 0;
		curInQDown <= 0;
	endmethod
	*/
endmodule
