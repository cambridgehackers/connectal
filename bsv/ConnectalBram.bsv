
import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAM::*;
import BRAMCore::*;
import GetPut::*;
import ClientServer::*;
import EHR::*;
import ConfigCounter::*;

interface BRAMServers#(numeric type numServers, type addr, type data);
   interface Vector#(numServers, BRAM1Port#(addr,data)) ports;
endinterface

module mkBRAMServers#(BRAM_Configure bramConfig)(BRAMServers#(numServers, addr, data))
   provisos (Bits#(addr,asz),
	     Bits#(data,dsz));
   BRAM_DUAL_PORT#(addr,data) bram <- mkBRAMCore2(bramConfig.memorySize, True); // latency 2
   Vector#(2, FIFOF#(data)) responseFifo <- replicateM(mkSizedFIFOF(2));
   // EHR did not work here, CReg doesn't seem to go into a vector, so using Wire. -Jamey
   Vector#(2, Wire#(Maybe#(Tuple2#(Bool,data)))) data0 <- replicateM(mkDWire(tagged Invalid));
   Vector#(2, Reg#(Maybe#(Tuple2#(Bool,data)))) data1 <- replicateM(mkReg(tagged Invalid));
   Vector#(2, Reg#(Maybe#(Tuple2#(Bool,data)))) data2 <- replicateM(mkReg(tagged Invalid));
   Vector#(2, ConfigCounter#(2)) counter <- replicateM(mkConfigCounter(2));

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

   function BRAM1Port#(addr,data) server(Integer i);
      return (interface BRAM1Port#(addr,data);
	 interface BRAMServer portA;
	 interface Put request;
	    method Action put(BRAMRequest#(addr,data) req) if (counter[i].positive());
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
   BRAMServers#(2,addr,data) bram <- mkBRAMServers(bramConfig);
   
   interface portA = bram.ports[0].portA;
   interface portB = bram.ports[1].portA;
   method portAClear = bram.ports[0].portAClear;
   method portBClear = bram.ports[1].portAClear;
endmodule

module mkBRAM1Server#(BRAM_Configure bramConfig)(BRAM1Port#(addr, data))
   provisos (Bits#(addr, a__),
	     Bits#(data, b__));
   BRAMServers#(1,addr,data) bram <- mkBRAMServers(bramConfig);
   
   interface portA = bram.ports[0].portA;
   method portAClear = bram.ports[0].portAClear;
endmodule

export mkBRAM1Server;
export mkBRAM2Server;