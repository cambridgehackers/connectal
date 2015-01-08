// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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

import Clocks            :: *;
import Vector            :: *;
import FIFOF             :: *;
import FIFO              :: *;
import SpecialFIFOs      :: *;
import GetPut            :: *;
import Connectable       :: *;
import StmtFSM           :: *;
import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import MemTypes          :: *;
import HostInterface     :: *;
import CtrlMux           :: *;
import ClientServer      :: *;
import PCIE              :: *;

`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;
typedef `NumberOfMasters NumberOfMasters;

module  mkXsimHost#(Clock derivedClock, Reset derivedReset)(XsimHost);
   interface derivedClock = derivedClock;
   interface derivedReset = derivedReset;
endmodule

interface XsimTop;
   method Bit#(1) rd();
   method ActionValue#(Bit#(32)) directoryEntry();
   method Action read(Bit#(32) addr);
   method ActionValue#(Bit#(32)) readData();
   method Action write(Bit#(32) addr, Bit#(32) data);

   interface Clock singleClock;
   interface Reset singleReset;
endinterface

module  mkXsimTop(XsimTop);
   //let divider <- mkClockDivider(2);
   Clock derivedClock <- exposeCurrentClock; //= divider.fastClock;
   Clock single_clock = derivedClock; //divider.slowClock;
   Reset derivedReset <- exposeCurrentReset;
   //let sr <- mkReset(2, True, single_clock);
   Reset single_reset = derivedReset; //sr.new_rst;

   XsimHost host <- mkXsimHost(clocked_by single_clock, reset_by single_reset, derivedClock, derivedReset);
   ConnectalTop#(PhysAddrWidth,DataBusWidth,PinType,NumberOfMasters) top <- mkConnectalTop(
`ifdef IMPORT_HOSTIF
       host,
`endif
       clocked_by single_clock, reset_by single_reset);
   //mapM(uncurry(mkConnection),zip(top.masters, host.mem_servers), clocked_by single_clock, reset_by single_reset);

   let intr_mux <- mkInterruptMux(top.interrupt);
   rule int_rule;
      //interruptLevel(truncate(pack(intr_mux)));
   endrule

   Reg#(Bool) readingDirectory <- mkReg(True);
   Reg#(Bool) token <- mkReg(True);
   Reg#(Bit#(8)) portalNumber <- mkReg(0);
   Reg#(Bit#(8)) offset <- mkReg(8'h10);
   Reg#(Bit#(32)) idReg <- mkReg(0);
   FIFO#(Bit#(32)) directoryFifo <- mkFIFO();
   rule readDirectory if (readingDirectory && portalNumber < 16 && token);
      let o = offset;
      let pn = portalNumber;
      top.slave.read_server.readReq.put(PhysMemRequest { addr: (extend(portalNumber) << 16) | extend(offset), burstLen: 4, tag: (o == 8'h10) ? 7 : 9});
      if (offset == 8'h14) begin
	 o = 8'h10;
	 pn = pn + 1;
      end
      else begin
	 o = o + 4;
      end
      offset <= o;
      portalNumber <= pn;
      token <= False;
   endrule
   rule directoryValue if (readingDirectory && !token);
      let memData <- top.slave.read_server.readData.get();
      
      let t = token;
      if (memData.tag == 7) begin
	 idReg <= memData.data;
	 t = True;
      end
      else begin
	 directoryFifo.enq((extend(memData.data[0]) << 31) | idReg);
	 // if this is not the last one, then read the next portal
	 t = (memData.data[0] == 0);
      end
      token <= t;
   endrule

   FIFO#(Bit#(32)) writeDataFifo <- mkFIFO();
   rule writedatarule;
      let data <- toGet(writeDataFifo).get();
      top.slave.write_server.writeData.put(MemData { data: data, tag: 0, last: True });
   endrule

   method Bit#(1) rd();
      return readingDirectory ? 1 : 0;
   endmethod
   method ActionValue#(Bit#(32)) directoryEntry() if (readingDirectory);
      let v <- toGet(directoryFifo).get();
      if (v[31] == 1)
	 readingDirectory <= False;
      return v;
   endmethod

   method Action read(Bit#(32) addr) if (!readingDirectory);
      $display("read addr=%h", addr);
      top.slave.read_server.readReq.put(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
   endmethod

   method ActionValue#(Bit#(32)) readData() if (!readingDirectory);
      let memData <- top.slave.read_server.readData.get();
      $display("read data=%h", memData.data);
      return memData.data;
   endmethod

   method Action write(Bit#(32) addr, Bit#(32) data);
      top.slave.write_server.writeReq.put(PhysMemRequest { addr: addr, burstLen: 4, tag: 0});
      writeDataFifo.enq(data);
   endmethod
   
`ifdef BSIMRESPONDER
   `BSIMRESPONDER (top.pins);
`endif
   interface Clock singleClock = single_clock;
   interface Reset singleReset = single_reset;
endmodule
