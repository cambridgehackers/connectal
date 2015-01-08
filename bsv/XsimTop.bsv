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

   method Action read(Bit#(32) addr);
      $display("read addr=%h", addr);
      top.slave.read_server.readReq.put(PhysMemRequest { addr: addr, burstLen: 4, tag: 0 });
   endmethod

   method ActionValue#(Bit#(32)) readData();
      let memData <- top.slave.read_server.readData.get();
      $display("read data=%h", memData.data);
      return memData.data;
   endmethod

   method Action write(Bit#(32) addr, Bit#(32) data);
      top.slave.write_server.writeReq.put(PhysMemRequest { addr: addr, burstLen: 4, tag: 0});
      top.slave.write_server.writeData.put(MemData { data: data, tag: 0, last: True });
   endmethod
   
`ifdef BSIMRESPONDER
   `BSIMRESPONDER (top.pins);
`endif
   interface Clock singleClock = single_clock;
   interface Reset singleReset = single_reset;
endmodule
