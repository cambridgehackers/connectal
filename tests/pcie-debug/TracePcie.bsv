// Copyright (c) 2013 Nokia, Inc.
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

import FIFO::*;
import FIFOF::*;
import Vector::*;
`ifdef PCIE_CHANGES_HOSTIF
import BuildVector::*;
import ClientServer::*;
import BRAM::*;
import Clocks::*;
import GetPut::*;
import Pipe::*;
import Probe::*;
import HostInterface::*;
import Gearbox::*;
import RS232::*;
import TestPins::*;
import PcieTracer::*;
`ifdef PCIE3
import Pcie3EndpointX7::*;
`else
import PcieStateChanges::*;
`endif

interface ChangeRequest;
   method Action setDivisor(Bit#(16) v);
   method Action putchar(Bit#(8) c);
endinterface

interface ChangeIndication;
   method Action change(Bit#(32) timestamp, Bit#(8) src, Bit#(24) value);
   method Action changeByte(Bit#(8) c);
endinterface
`endif

// these are here so the app can drive some traffic
interface EchoIndication;
    method Action heard(Bit#(32) v);
    method Action heard2(Bit#(16) a, Bit#(16) b);
endinterface

interface EchoRequest;
   method Action say(Bit#(32) v);
   method Action say2(Bit#(16) a, Bit#(16) b);
   method Action setLeds(Bit#(8) v);
endinterface

interface TracePcie;
   interface EchoRequest request;
   interface ChangeRequest changeRequest;
`ifdef PCIE_CHANGES_UART
   interface TestPins pins;
`endif
endinterface

typedef struct {
	Bit#(16) a;
	Bit#(16) b;
} EchoPair deriving (Bits);


(* synthesize *)
module mkTraceGearbox(Gearbox#(TAdd#(TMul#(2,TDiv#(SizeOf#(TimestampedTlpData),8)),2), 1, Bit#(8)));
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   let gb <- mkNto1Gearbox(clock, reset, clock, reset);
   return gb;
endmodule


module mkTracePcie#(
`ifdef PCIE_CHANGES_HOSTIF
   HostInterface host, ChangeIndication changeIndication,
`endif
   EchoIndication indication
)(TracePcie);
    FIFO#(Bit#(32)) delay <- mkSizedFIFO(8);
    FIFO#(EchoPair) delay2 <- mkSizedFIFO(8);

    rule heard;
        delay.deq;
        indication.heard(delay.first);
    endrule

    rule heard2;
        delay2.deq;
        indication.heard2(delay2.first.b, delay2.first.a);
    endrule
   
`ifdef PCIE_CHANGES_HOSTIF
`ifdef PCIE_CHANGES_SERIAL
   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   Gearbox#(18, 1, Bit#(8)) serializeGearbox <- mkNto1Gearbox(clock, reset, clock, reset); 

`ifdef PCIE_CHANGES_UART
    Reg#(Bit#(16)) uartDivisor <- mkReg(136);
    UART#(128) uart <- mkUART(8, NONE, STOP_1, uartDivisor);
`endif

   function Bit#(8) toHex(Bit#(4) v);
       if (v >= 0 && v <= 9)
	  return 48 + zeroExtend(v);
       else
	  return 97 + zeroExtend(v) - 10;
   endfunction

   function Vector#(TMul#(2,len),Bit#(8)) toHexVector(Vector#(len, Bit#(8)) bytes);
      Vector#(TMul#(2,len),Bit#(8)) chars;
      for (Integer i = 0; i < valueOf(len); i = i + 1) begin
	 chars[2 * i + 0] = toHex(bytes[i][3:0]);
	 chars[2 * i + 1] = toHex(bytes[i][7:4]);
      end
      return chars;
   endfunction

   Vector#(2, Bit#(8)) endl = vec(10, 13);

   rule rl_changes;
      Bit#(64) bits <- toGet(host.tchanges).get();
      Vector#(8, Bit#(8)) bytes = unpack(bits);
      Vector#(18, Bit#(8)) chars = append(reverse(toHexVector(bytes)), endl);
      serializeGearbox.enq(chars);
   endrule

`ifdef DISABLE
   rule rl_serial;
      Bit#(8) char = serializeGearbox.first()[0];
      serializeGearbox.deq();
`ifndef PCIE_CHANGES_UART
      changeIndication.changeByte(char);
`else
	 uart.rx.put(char);
`endif
   endrule
`endif

   Reg#(Bit#(12)) traceAddrReg <- mkReg(0);
   Reg#(Bool) requested <- mkReg(False);
   Gearbox#(TAdd#(TMul#(2,TDiv#(SizeOf#(TimestampedTlpData),8)),2), 1, Bit#(8)) testGearbox <- mkTraceGearbox();
   Gearbox#(TAdd#(TMul#(2,TDiv#(SizeOf#(TimestampedTlpData),8)),2), 1, Bit#(8)) traceGearbox <- mkTraceGearbox();
   FIFOF#(Bit#(8)) testFifo <- mkFIFOF();
   FIFOF#(Bit#(8)) traceFifo <- mkFIFOF();

   Reg#(Bool) testPattern <- mkReg(False);
   rule rl_testpattern if (!testPattern);
      testPattern <= True;
      Vector#(TDiv#(SizeOf#(TimestampedTlpData),8), Bit#(8)) tracebytes;
      for (Integer i = 0; i < valueOf(TDiv#(SizeOf#(TimestampedTlpData),8)); i = i + 1) begin
	 tracebytes[i]= fromInteger(i);
      end
      let bytes = append(reverse(toHexVector(tracebytes)), endl);
      testGearbox.enq(bytes);
   endrule
   rule rl_test_pipeline;
      let char = testGearbox.first()[0];
      testGearbox.deq();
      testFifo.enq(char);
   endrule

   rule rl_trace_from_pcie_req if (!requested && testPattern);
      if (traceAddrReg < extend(host.tpciehost.tlpTraceBramWrAddr)) begin
	 host.tpciehost.traceBramServer.request.put(BRAMRequest {
								 write: False,
								 responseOnWrite: False,
								 address: traceAddrReg,
								 datain: ? });
	 requested <= True;
      end
   endrule
   rule rl_trace_from_pcie_resp if (requested);
      let resp <- host.tpciehost.traceBramServer.response.get();
      Bit#(SizeOf#(TimestampedTlpData)) tracebits = pack(resp);
      Vector#(TDiv#(SizeOf#(TimestampedTlpData),8), Bit#(8)) tracebytes = unpack(tracebits);
      let bytes = append(reverse(toHexVector(tracebytes)), endl);
      // wait until there is a valid entry
      if (True) begin
	 traceGearbox.enq(bytes);
	 traceAddrReg <= traceAddrReg + 1;
      end
      requested <= False;
   endrule
   rule rl_trace_pipeline;
      let char = traceGearbox.first()[0];
      traceGearbox.deq();
      traceFifo.enq(char);
   endrule
   rule rl_trace_serial;
      if (testFifo.notEmpty()) begin
	 Bit#(8) char = testFifo.first();
	 testFifo.deq();
	 uart.rx.put(char);
      end
      else if (traceFifo.notEmpty()) begin
	 Bit#(8) char = traceFifo.first();
	 traceFifo.deq();
	 uart.rx.put(char);
      end
   endrule

`else
   rule rl_changes;
      Bit#(64) bits <- toGet(host.tchanges).get();
      RegChange change = unpack(bits);
      changeIndication.change(change.timestamp, change.src, change.value);
   endrule
`endif


`endif

`ifdef PCIE_CHANGES_UART
   interface TestPins pins;
      interface UartPins uart;
	 method sin = uart.rs232.sin;
	 method sout = uart.rs232.sout;
	 interface Clock deleteme_unused_clock = clock;
      endinterface
   endinterface

   interface ChangeRequest changeRequest;
      method Action setDivisor(Bit#(16) v);
         uartDivisor <= v;
      endmethod
      method Action putchar(Bit#(8) c);
	 uart.rx.put(c);
      endmethod
   endinterface

`endif

   interface EchoRequest request;
      method Action say(Bit#(32) v);
	 delay.enq(v);
      endmethod
      
      method Action say2(Bit#(16) a, Bit#(16) b);
	 delay2.enq(EchoPair { a: a, b: b});
      endmethod
      
      method Action setLeds(Bit#(8) v);
      endmethod
   endinterface
endmodule
