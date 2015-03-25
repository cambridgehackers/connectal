// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import Vector            :: *;
import Clocks          :: *;
import GetPut            :: *;
import Connectable    :: *;
import FIFO              :: *;
import FIFOF        :: *;
import PCIE               :: *;
import BRAM         :: *;
import BramMux        :: *;

typedef 11 TlpTraceAddrSize;
typedef TAdd#(TlpTraceAddrSize,1) TlpTraceAddrSize1;

typedef struct {
    Bit#(32) timestamp;
    Bit#(7) source;   // 4==frombus 8=tobus
    TLPData#(16) tlp; // 153 bits
} TimestampedTlpData deriving (Bits);
typedef SizeOf#(TimestampedTlpData) TimestampedTlpDataSize;
typedef SizeOf#(TLPData#(16)) TlpData16Size;
typedef SizeOf#(TLPCompletionHeader) TLPCompletionHeaderSize;
interface TlpTrace;
   interface Get#(TimestampedTlpData) tlp;
endinterface

interface TlpTraceData;
   interface Reg#(Bool)     tlpTracing;
   interface Reg#(Bit#(TlpTraceAddrSize)) tlpTraceLimit;
   interface Reg#(Bit#(TlpTraceAddrSize)) pcieTraceBramWrAddr;
   interface BRAMServer#(Bit#(TAdd#(TlpTraceAddrSize,1)), TimestampedTlpData) bramServer;
   interface BRAMServer#(Bit#(TAdd#(TlpTraceAddrSize,1)), TimestampedTlpData) bscanBramServer;
endinterface
interface PcieTracer;
   interface Client#(TLPData#(16), TLPData#(16)) pci;
   interface Put#(TimestampedTlpData) trace;
   interface Server#(TLPData#(16), TLPData#(16)) bus;
   interface TlpTraceData tlpdata;
endinterface: PcieTracer

// The PCIe-to-AXI bridge puts all of the elements together
(* synthesize *)
module mkPcieTracer(PcieTracer);
   // Trace Support
   Reg#(Bool) tlpTracingReg        <- mkReg(False);
   Reg#(Bit#(TlpTraceAddrSize)) tlpTraceLimitReg <- mkReg(0);
   FIFOF#(Bit#(TlpTraceAddrSize)) pcieTraceBramWrAddrFifo <- mkFIFOF();
   Reg#(Bit#(TlpTraceAddrSize)) pcieTraceBramWrAddrReg <- mkReg(0);
   Integer memorySize = 2**valueOf(TlpTraceAddrSize);

   BRAM_Configure bramCfg = defaultValue;
   bramCfg.memorySize = memorySize;
   bramCfg.latency = 1;
   bramCfg.allowWriteResponseBypass = True;
   BRAM2Port#(Bit#(TlpTraceAddrSize), TimestampedTlpData) fromPcieTraceBram <- mkBRAM2Server(bramCfg);
   BRAM2Port#(Bit#(TlpTraceAddrSize), TimestampedTlpData) toPcieTraceBram <- mkBRAM2Server(bramCfg);
   Vector#(2, BRAMServer#(Bit#(TlpTraceAddrSize), TimestampedTlpData)) bramServers;
   bramServers[0] = fromPcieTraceBram.portA;
   bramServers[1] =   toPcieTraceBram.portA;
   BramServerMux#(TAdd#(TlpTraceAddrSize,1), TimestampedTlpData) bramMuxReg <- mkBramServerMux(bramServers);

//`ifndef BSIM ????? jca
   Vector#(2, BRAMServer#(Bit#(TlpTraceAddrSize), TimestampedTlpData)) bscanBramServers;
   bscanBramServers[0] = fromPcieTraceBram.portB;
   bscanBramServers[1] =   toPcieTraceBram.portB;
   BramServerMux#(TAdd#(TlpTraceAddrSize,1), TimestampedTlpData) bscanBramMux <- mkBramServerMux(bscanBramServers);
//`endif

   Reg#(Bit#(32)) timestamp <- mkReg(0);
   rule incTimestamp;
       timestamp <= timestamp + 1;
   endrule
//   rule endTrace if (tlpTracingReg && tlpTraceLimitReg != 0 && tlpTraceBramWrAddr > truncate(tlpTraceLimitReg));
//       tlpTracingReg <= False;
//   endrule

   FIFO#(TLPData#(16)) tlpFromBusFifo <- mkFIFO();
   FIFO#(TLPData#(16)) tlpToBusFifo <- mkFIFO();
   FIFO#(TLPData#(16)) tlpBusResponseFifo <- mkFIFO();

   Reg#(Bool) skippingIncomingTlps <- mkReg(False);
   FIFO#(Bool) isRootBroadcastMessage <- mkFIFO();
   PulseWire fromPcie <- mkPulseWire;
   PulseWire   toPcie <- mkPulseWire;
   Wire#(TLPData#(16)) fromPcieTlp <- mkDWire(unpack(0));
   Wire#(TLPData#(16))   toPcieTlp <- mkDWire(unpack(0));

   rule sniffTlpFromBus;
      let tlp <- toGet(tlpFromBusFifo).get();
      tlpBusResponseFifo.enq(tlp);

      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      // skip root_broadcast_messages sent to tlp.hit 0
      isRootBroadcastMessage.enq(tlp.sof && tlp.hit == 0 && hdr_3dw.pkttype != COMPLETION);

   endrule

   rule doTracing if (fromPcie || toPcie);
      TimestampedTlpData fromttd = fromPcie ? TimestampedTlpData { timestamp: timestamp, source: 7'h04, tlp: fromPcieTlp } : unpack(0);
      let writeAddr = pcieTraceBramWrAddrReg;
      if (pcieTraceBramWrAddrFifo.notEmpty)
	 writeAddr <- toGet(pcieTraceBramWrAddrFifo).get();

      fromPcieTraceBram.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: writeAddr, datain: fromttd });

      TimestampedTlpData   tottd = toPcie ? TimestampedTlpData { timestamp: timestamp, source: 7'h08, tlp: toPcieTlp } : unpack(0);
      toPcieTraceBram.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: writeAddr, datain: tottd });

      pcieTraceBramWrAddrReg <= writeAddr + 1;
   endrule

   interface Server     bus;
      interface Get response;
           method ActionValue#(TLPData#(16)) get();
	      let tlp <- toGet(tlpBusResponseFifo).get();

	      if (tlpTracingReg) begin
		 if (tlp.sof && isRootBroadcastMessage.first) begin
 		    skippingIncomingTlps <= True;
		 end
		 else if (skippingIncomingTlps && !tlp.sof) begin
		    // do nothing
		 end
		 else begin
		    fromPcie.send();
		    fromPcieTlp <= tlp;
		    skippingIncomingTlps <= False;
		 end
	      end

	      isRootBroadcastMessage.deq();
	      return tlp;
	   endmethod
      endinterface

       interface Put request;
           method Action put(TLPData#(16) tlp);
           tlpToBusFifo.enq(tlp);
           if (tlpTracingReg) begin
	      toPcie.send();
	      toPcieTlp <= tlp;
           end
           endmethod
       endinterface
   endinterface

   interface Client    pci;
      interface request = toGet(tlpToBusFifo);
      interface response = toPut(tlpFromBusFifo);
   endinterface
   interface Put trace;
       method Action put(TimestampedTlpData ttd) if (!fromPcie && !toPcie);
	   if (tlpTracingReg) begin
	       ttd.timestamp = timestamp;
	       toPcieTraceBram.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(pcieTraceBramWrAddrReg), datain: ttd });
	       pcieTraceBramWrAddrReg <= pcieTraceBramWrAddrReg + 1;
	   end
       endmethod
   endinterface: trace
   interface TlpTraceData tlpdata;
      interface Reg tlpTracing    = tlpTracingReg;
      interface Reg tlpTraceLimit = tlpTraceLimitReg;
      interface Reg pcieTraceBramWrAddr;
	 method Bit#(TlpTraceAddrSize) _read(); return pcieTraceBramWrAddrReg; endmethod
	 method Action _write(Bit#(TlpTraceAddrSize) v); pcieTraceBramWrAddrFifo.enq(v); endmethod
      endinterface
      interface Server bramServer = bramMuxReg.bramServer;
      interface Server bscanBramServer = bscanBramMux.bramServer;
   endinterface
endmodule: mkPcieTracer
