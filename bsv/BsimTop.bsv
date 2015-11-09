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
`include "ConnectalProjectConfig.bsv"
import ConnectalConfig   :: *;
import Clocks            :: *;
import Vector            :: *;
import FIFOF             :: *;
import FIFO              :: *;
import SpecialFIFOs      :: *;
import GetPut            :: *;
import Connectable       :: *;
import StmtFSM           :: *;
import Portal            :: *;
import Top               :: *;
import MemTypes          :: *;
import HostInterface     :: *;
import CtrlMux           :: *;
import ClientServer      :: *;
import MemToPcie    :: *;
import PcieToMem   :: *;
import PCIE              :: *;
import SimDma            :: *;
import `PinTypeInclude::*;
import Platform          :: *;

// implemented in BsimCtrl.cpp
import "BDPI" function Action                 initPortal();
import "BDPI" function Bool                   checkForRequest(Bit#(32) v);
import "BDPI" function ActionValue#(Bit#(64)) getRequest32(Bit#(32) v);
import "BDPI" function Action                 readResponse32(Bit#(32) d, Bit#(32) tag);
import "BDPI" function Action                 interruptLevel(Bit#(1) d);

module mkBsimCtrlReadWrite(PhysMemMaster#(clientAddrWidth, clientBusWidth))
   provisos(Add#(a__, 32, clientAddrWidth), Add#(b__, 32, clientBusWidth));
   FIFO#(Bit#(clientBusWidth)) wf <- mkPipelineFIFO;
   Reg#(Bit#(32)) cycles      <- mkReg(0);
   rule count;
      cycles <= cycles + 1;
   endrule
 
   let verbose = False;
   let init_fsm <- mkOnce(initPortal());
 
   rule init_rule;
      init_fsm.start;
   endrule
   interface PhysMemReadClient read_client;
     interface Get readReq;
	 method ActionValue#(PhysMemRequest#(clientAddrWidth,clientBusWidth)) get() if (checkForRequest(0));
	 //$write("req_ar: ");
	 let ra <- getRequest32(0);
	 //$display("ra=%h", ra);
	 let burstLen = fromInteger(valueOf(clientBusWidth) / 8);
	 if (verbose) $display("\n%d BsimHost.readReq addr=%h burstLen=%d", cycles, ra, burstLen);
	 return PhysMemRequest { addr: extend(ra[31:0]), burstLen: burstLen, tag: truncate(ra[63:32])
`ifdef BYTE_ENABLES
				, firstbe: maxBound, lastbe: maxBound
`endif
				};
	 endmethod
     endinterface
     interface Put readData;
	 method Action put(MemData#(clientBusWidth) rd);
	 //$display("resp_read: rd=%h", rd);
	 if (verbose) $display("%d BsimHost.readData %h", cycles, rd.data);
	 readResponse32(truncate(rd.data), extend(rd.tag));
	 endmethod
     endinterface
   endinterface
   interface PhysMemWriteClient write_client;
     interface Get writeReq;
	 method ActionValue#(PhysMemRequest#(clientAddrWidth,clientBusWidth)) get() if (checkForRequest(1));
	 let wd <- getRequest32(1);
	 wf.enq(extend(wd[63:32]));
	 let burstLen = fromInteger(valueOf(clientBusWidth) / 8);
	 if (verbose) $display("\n%d BsimHost.writeReq addr/data=%h burstLen=%d", cycles, wd, burstLen);
	 return PhysMemRequest { addr: extend(wd[31:0]), burstLen: burstLen, tag: 0
`ifdef BYTE_ENABLES
				, firstbe: maxBound, lastbe: maxBound
`endif
				};
	 endmethod
     endinterface
     interface Get writeData;
	 method ActionValue#(MemData#(clientBusWidth)) get;
	 wf.deq;
	 if (verbose) $display("%d BsimHost.writeData %h", cycles, wf.first);
	 return MemData { data: wf.first, tag: 0, last: True };
	 endmethod
     endinterface
     interface Put writeDone;
	 method Action put(Bit#(MemTagSize) resp);
	 if (verbose) $display("%d BsimHost.writeDone %d", cycles, resp);
	 endmethod
     endinterface
   endinterface
endmodule

module  mkBsimHost#(Clock derived_clock, Reset derived_reset)(BsimHost#(clientAddrWidth, clientBusWidth, clientIdWidth,
			      serverAddrWidth, serverBusWidth, serverIdWidth,
			      nSlaves))
   provisos (Add#(a__, 32, clientAddrWidth), Add#(b__, 32, clientBusWidth),
	     Mul#(TDiv#(serverBusWidth, 32), 32, serverBusWidth),
             Mul#(TDiv#(serverBusWidth, 8), 8, serverBusWidth),
	     Mul#(TDiv#(serverBusWidth, 32), 4, TDiv#(serverBusWidth, 8)),
	     Add#(c__, ByteEnableSize,TDiv#(serverBusWidth, 8)));

   Vector#(nSlaves,PhysMemSlave#(serverAddrWidth,  serverBusWidth)) servers <- replicateM(mkSimDmaDmaMaster);
   PhysMemMaster#(clientAddrWidth, clientBusWidth) crw <- mkBsimCtrlReadWrite();

   interface mem_servers = servers;
   interface PhysMemMaster mem_client = crw;
   interface derivedClock = derived_clock;
   interface derivedReset = derived_reset;
endmodule

interface BsimTop;
`ifndef SIMULATIONRESPONDER
   interface `PinType pins;
`endif
endinterface

module  mkBsimTop(BsimTop);
   let divider <- mkClockDivider(2);
   Clock derivedClock = divider.fastClock;
   Clock singleClock = divider.slowClock;
   Reset derivedReset <- exposeCurrentReset;
   let single_reset <- mkReset(2, True, singleClock);
   Reset singleReset = single_reset.new_rst;
   BsimHost#(32,32,12,PhysAddrWidth,DataBusWidth,6,NumberOfMasters) host <- mkBsimHost(clocked_by singleClock, reset_by singleReset, derivedClock, derivedReset);
   Vector#(NumberOfUserTiles,ConnectalTop) ts <- replicateM(mkConnectalTop(
`ifdef IMPORT_HOSTIF
       host,
`else
`ifdef IMPORT_HOST_CLOCKS
       host.derivedClock, host.derivedReset,
`endif
`endif
       clocked_by singleClock, reset_by singleReset));
   Platform top <- mkPlatform(ts, clocked_by singleClock, reset_by singleReset);
   mapM(uncurry(mkConnection),zip(top.masters, host.mem_servers), clocked_by singleClock, reset_by singleReset);
`ifndef SIMULATION_EXERCISE_MEM_MASTER_SLAVE
   mkConnection(host.mem_client, top.slave, clocked_by singleClock, reset_by singleReset);
`else
   PciId masterPciId = unpack(22);
   PciId slavePciId = unpack(23);
   PcieToMem masterEngine <- mkPcieToMem(masterPciId, clocked_by singleClock, reset_by singleReset);
   MemToPcie#(32) slaveEngine <- mkMemToPcie(slavePciId, clocked_by singleClock, reset_by singleReset);
   mkConnection(host.mem_client, slaveEngine.slave, clocked_by singleClock, reset_by singleReset);
   mkConnection(slaveEngine.tlp.request, masterEngine.tlp.response, clocked_by singleClock, reset_by singleReset);
   mkConnection(slaveEngine.tlp.response, masterEngine.tlp.request, clocked_by singleClock, reset_by singleReset);
   mkConnection(masterEngine.master, top.slave, clocked_by singleClock, reset_by singleReset);
`endif

   let intr_mux <- mkInterruptMux(top.interrupt);
   rule int_rule;
      interruptLevel(truncate(pack(intr_mux)));
   endrule

`ifdef SIMULATIONRESPONDER
   `SIMULATIONRESPONDER (top.pins);
`else
   interface pins = top.pins;
`endif
endmodule
