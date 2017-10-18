// Copyright (c) 2015 Connectal Project

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

import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAM::*;
import BRAMCore::*;
import GetPut::*;
import ClientServer::*;
import OldEHR::*;
import ConfigCounter::*;

interface BRAMServers#(numeric type numServers, type addr, type data);
   interface Vector#(numServers, BRAM1Port#(addr,data)) ports;
endinterface

module mkBRAMServers#(BRAM_Configure bramConfig)(BRAMServers#(numServers, addr, data))
   provisos (Bits#(addr,asz),
	     Bits#(data,dsz));
   let memorySize = bramConfig.memorySize == 0 ? 2**valueOf(asz) : bramConfig.memorySize;
   BRAM_DUAL_PORT#(addr,data) bram <- mkBRAMCore2(memorySize, True); // latency 2
   Vector#(2, FIFOF#(data)) responseFifo <- replicateM(mkSizedFIFOF(2));
   // EHR did not work here, CReg doesn't seem to go into a vector, so using Wire. -Jamey
   Vector#(2, Wire#(Maybe#(Tuple2#(Bool,data)))) data0 <- replicateM(mkDWire(tagged Invalid));
   Vector#(2, Reg#(Maybe#(Tuple2#(Bool,data)))) data1 <- replicateM(mkReg(tagged Invalid));
   Vector#(2, Reg#(Maybe#(Tuple2#(Bool,data)))) data2 <- replicateM(mkReg(tagged Invalid));
   Vector#(2, ConfigCounter#(2)) counter <- replicateM(mkConfigCounter(2));

   let verbose = False;

   function BRAM_PORT#(addr, data) portsel(Integer port);
      return (port == 0) ? bram.a : bram.b;
   endfunction
   
   for (Integer i = 0; i < 2; i = i + 1) begin
      rule bramRule;
	 // zeroth stage
	 let d0 = data0[i];
	 data1[i] <= d0;

	 // first stage // address register
	 let d1 = data1[i];
	 data2[i] <= d1;

	 // second stage
	 let d2 = data2[i];
	 if (d2 matches tagged Valid .tpl) begin
	    match { .write, .data } = tpl;
	    if (!write)
	       data = portsel(i).read();
	    if (responseFifo[i].notFull())
	       responseFifo[i].enq(data);
	    else
	       $display("Error: responseFifo is unexpectedly full");
	 end
      endrule
   end

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule cyclesRule if (verbose);
      cycles <= cycles + 1;
   endrule

   function BRAM1Port#(addr,data) server(Integer i);
      return (interface BRAM1Port#(addr,data);
	 interface BRAMServer portA;
	 interface Put request;
	    method Action put(BRAMRequest#(addr,data) req) if (counter[i].positive());
	      if (verbose) $display("%d %d addr %h data %h write %d counter %d", memorySize, cycles, req.address, req.datain, req.write, counter[i].read());
	      portsel(i).put(req.write, req.address, req.datain);
	      if (!req.write || req.responseOnWrite) begin
		 counter[i].decrement(1);
		 data0[i] <= tagged Valid tuple2(req.write, req.datain);
	      end
	    endmethod
	 endinterface
	 interface Get response;
	    method ActionValue#(data) get();
	      let v <- toGet(responseFifo[i]).get();
	      if (verbose) $display("%d %d data %h counter %d", memorySize, cycles, v, counter[i].read());
	      counter[i].increment(1);
	      return v;
	    endmethod
	 endinterface: response
	 endinterface: portA
	      method Action portAClear();
		 //FIXME
	      endmethod
	 endinterface);
   endfunction

   interface ports = genWith(server);
endmodule

module mkBRAM2Server#(BRAM_Configure bramConfig)(BRAM2Port#(addr, data))
   provisos (Bits#(addr, a__),
	     Bits#(data, b__));
   BRAMServers#(2,addr,data) cbram <- mkBRAMServers(bramConfig);
   
   interface portA = cbram.ports[0].portA;
   interface portB = cbram.ports[1].portA;
   method portAClear = cbram.ports[0].portAClear;
   method portBClear = cbram.ports[1].portAClear;
endmodule

module mkBRAM1Server#(BRAM_Configure bramConfig)(BRAM1Port#(addr, data))
   provisos (Bits#(addr, a__),
	     Bits#(data, b__));
   BRAMServers#(1,addr,data) cbram <- mkBRAMServers(bramConfig);
   
   interface portA = cbram.ports[0].portA;
   method portAClear = cbram.ports[0].portAClear;
endmodule

export mkBRAM1Server;
export mkBRAM2Server;