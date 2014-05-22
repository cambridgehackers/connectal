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
import FIFO              :: *;
import FIFOF        :: *;
import PCIE               :: *;
import AxiCsr            :: *;
import BRAM         :: *;

// The top-level interface of the PCIe-to-AXI bridge
interface PcieTracer;
   interface Client#(TLPData#(16), TLPData#(16)) pci;
   interface Put#(TimestampedTlpData) trace;
   interface Server#(TLPData#(16), TLPData#(16)) bus;
endinterface: PcieTracer

// The PCIe-to-AXI bridge puts all of the elements together
module mkPcieTracer#(AxiControlAndStatusRegs csr)(PcieTracer);

   Reg#(Bit#(32)) timestamp <- mkReg(0);
   rule incTimestamp;
       timestamp <= timestamp + 1;
   endrule
//   rule endTrace if (csr.tlpTracing && csr.tlpTraceLimit != 0 && csr.tlpTraceBramWrAddr > truncate(csr.tlpTraceLimit));
//       csr.tlpTracing <= False;
//   endrule

   FIFO#(TLPData#(16)) tlpFromBusFifo <- mkFIFO();
   FIFO#(TLPData#(16)) tlpToBusFifo <- mkFIFO();
   Reg#(Bool) skippingIncomingTlps <- mkReg(False);
   PulseWire fromPcie <- mkPulseWire;
   PulseWire   toPcie <- mkPulseWire;
   Wire#(TLPData#(16)) fromPcieTlp <- mkDWire(unpack(0));
   Wire#(TLPData#(16))   toPcieTlp <- mkDWire(unpack(0));

   rule doTracing if (fromPcie || toPcie);
      TimestampedTlpData fromttd = fromPcie ? TimestampedTlpData { timestamp: timestamp, source: 7'h04, tlp: fromPcieTlp } : unpack(0);
      csr.fromPcieTraceBramPort.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.fromPcieTraceBramWrAddr), datain: fromttd });
      csr.fromPcieTraceBramWrAddr <= csr.fromPcieTraceBramWrAddr + 1;

      TimestampedTlpData   tottd = toPcie ? TimestampedTlpData { timestamp: timestamp, source: 7'h08, tlp: toPcieTlp } : unpack(0);
      csr.toPcieTraceBramPort.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.toPcieTraceBramWrAddr), datain: tottd });
      csr.toPcieTraceBramWrAddr <= csr.toPcieTraceBramWrAddr + 1;
   endrule

   interface Server     bus;
       interface Get response;
           method ActionValue#(TLPData#(16)) get();
           let tlp = tlpFromBusFifo.first;
           tlpFromBusFifo.deq();
           $display("tlp in: %h\n", tlp);
           if (csr.tlpTracing) begin
               TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
               // skip root_broadcast_messages sent to tlp.hit 0
               if (tlp.sof && tlp.hit == 0 && hdr_3dw.pkttype != COMPLETION) begin
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
           return tlp;
           endmethod
       endinterface

       interface Put request;
           method Action put(TLPData#(16) tlp);
           tlpToBusFifo.enq(tlp);
           if (csr.tlpTracing) begin
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
       method Action put(TimestampedTlpData ttd);
	   if (csr.tlpTracing) begin
	       ttd.timestamp = timestamp;
	       csr.toPcieTraceBramPort.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: truncate(csr.toPcieTraceBramWrAddr), datain: ttd });
	       csr.toPcieTraceBramWrAddr <= csr.toPcieTraceBramWrAddr + 1;
	   end
       endmethod
   endinterface: trace
endmodule: mkPcieTracer
