import BRAM::*;
import BRAMFIFO::*;
import ConnectalFIFO::*;
import DefaultValue::*;
import FIFOF::*;
import GetPut::*;
import ConnectalMemTypes::*;

typedef struct {
   MemRequest readReq;
   } TraceRecord deriving (Bits);

typedef struct {
   Bit#(32) timestamp;
   Bool       readReqValid;
   MemRequest readReq;
   Bool       readDataValid;
   Bit#(64) readData;
   Bit#(8) readDataTag;
   Bool readDataLast;
   } TimestampedTraceRecord deriving (Bits);

interface TraceIndication;
   method Action traceEntry(Bit#(32) timestamp,
			    Bool readReqValid, Bit#(8) sglId, Bit#(32) offset, Bit#(16) burstLen, Bit#(8) tag,
			    Bool readDataValid, Bit#(64) readData, Bit#(8) readDataTag, Bool readDataLast);
endinterface

interface TraceValue#(type a);
   interface Wire#(a) w;
   method a m();
endinterface
interface TraceAction#(type a);
   interface Wire#(a) w;
   method Action m(a v);
endinterface
interface TraceGet#(type a);
   method Bool valid();
   interface Wire#(a) w;
   interface Get#(a) get;
endinterface
interface TracePut#(type a);
   method Bool valid();
   interface Wire#(a) w;
   interface Put#(a) put;
endinterface

module mkTraceValue#(a f)(TraceValue#(a))
   provisos (Bits#(a, asz));
   Wire#(a) _w <- mkDWire(unpack(0));
   rule rl_value;
      _w <= f();
   endrule
   interface w = _w;
   method a m(); return f(); endmethod
endmodule

module mkTraceAction#(function Action f(a v))(TraceAction#(a))
   provisos (Bits#(a, asz));
   Wire#(a) _w <- mkDWire(unpack(0));
   interface w = _w;
   method Action m(a v);
      _w <= v;
      f(v);
   endmethod
endmodule

module mkTraceGet#(Get#(a) g)(TraceGet#(a))
   provisos (Bits#(a, asz));
   Wire#(Bool) _valid <- mkDWire(False);
   Wire#(a) _w <- mkDWire(unpack(0));
	 
   method valid = _valid;
   interface w = _w;
   interface Get get;
      method ActionValue#(a) get();
	 let v <- g.get();
	 _valid <= True;
	 _w <= v;
	 return v;
      endmethod
   endinterface
endmodule

module mkTracePut#(Put#(a) p)(TracePut#(a))
   provisos (Bits#(a, asz));
   Wire#(Bool) _valid <- mkDWire(False);
   Wire#(a) _w <- mkDWire(unpack(0));
	 
   method valid = _valid;
   interface w = _w;
   interface Put put;
      method Action put(a v);
	 _valid <= True;
	 _w <= v;
	 p.put(v);
      endmethod
   endinterface
endmodule

module mkTracer#(MemReadClient#(64) client, TraceIndication tind)(MemReadClient#(64));

   Reg#(Bit#(32)) cycles <- mkReg(0);
   let addrReg <- mkReg(0);

   let traceFifo <- mkSizedBRAMFIFOF(1024);
   rule rl_cycles;
      cycles <= cycles + 1;
   endrule

   let readReqTrace <- mkTraceGet(client.readReq);
   let readDataTrace <- mkTracePut(client.readData);

   rule rl_trace if (readReqTrace.valid);
      let record = TimestampedTraceRecord {
					   timestamp: cycles,

					   readReqValid: readReqTrace.valid,
					   readReq: readReqTrace.w,

					   readDataValid: readDataTrace.valid,
					   readData: truncate(readDataTrace.w.data),
					   readDataTag: extend(readDataTrace.w.tag),
					   readDataLast: readDataTrace.w.last
					   };
      if (traceFifo.notFull()) begin
	 traceFifo.enq(record);
      end
   endrule
   rule rl_upload;
      let tr <- toGet(traceFifo).get();
      tind.traceEntry(tr.timestamp,

		      tr.readReqValid,
		      truncate(tr.readReq.sglId), truncate(tr.readReq.offset), extend(tr.readReq.burstLen), extend(tr.readReq.tag),

		      tr.readDataValid,
		      tr.readData, tr.readDataTag, tr.readDataLast
		      );
   endrule

   interface readReq = readReqTrace.get;
   interface readData = readDataTrace.put;

endmodule
