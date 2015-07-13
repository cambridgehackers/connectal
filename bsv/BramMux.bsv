
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

import ClientServer ::*;
import BRAM         ::*;
import Vector       ::*;
import FIFO         ::*;
import SpecialFIFOs :: *;

interface BramServerMux#(numeric type aszn, type dtype);
   interface BRAMServer#(Bit#(aszn), dtype) bramServer;
endinterface

module mkBramServerMux#(Vector#(numServers, BRAMServer#(Bit#(asz),dtype)) bramServers)(BramServerMux#(aszn,dtype))
   provisos (Add#(1,a__,numServers),
	     Log#(numServers,csz),
	     Add#(asz,csz,aszn),
	     Bits#(dtype,dsz),
	     Bits#(Tuple2#(Bit#(csz), BRAM::BRAMRequest#(Bit#(asz), dtype)), c__)
	     );
   let numServers = valueOf(numServers);
   FIFO#(dtype) responseFifo <- mkPipelineFIFO();
   for (Integer i = 0; i < numServers; i = i + 1) begin
      (* descending_urgency = "respond" *)
      rule respond;
         let response <- bramServers[i].response.get();
         responseFifo.enq(response);
      endrule
   end
   interface BRAMServer bramServer;
      interface Put request;
	 method Action put(BRAMRequest#(Bit#(aszn), dtype) request);
	    Bit#(csz) clientNumber = request.address[valueOf(aszn)-1:valueOf(asz)];
            bramServers[clientNumber].request.put( BRAMRequest {
					    write: request.write,
					    responseOnWrite: request.responseOnWrite,
					    address: truncate(request.address),
					    datain: request.datain });
	 endmethod
      endinterface
      interface Get response;
	 method ActionValue#(dtype) get();
	    responseFifo.deq();
	    return responseFifo.first();
	 endmethod
      endinterface
   endinterface
endmodule

module mkGatedBramServerMux#(Reg#(Bool) gate, Vector#(numServers, BRAMServer#(Bit#(asz),dtype)) bramServers)(BramServerMux#(aszn,dtype))
   provisos (Add#(1,a__,numServers),
	     Log#(numServers,csz),
	     Add#(asz,csz,aszn),
	     Bits#(dtype,dsz),
	     Bits#(Tuple2#(Bit#(csz), BRAM::BRAMRequest#(Bit#(asz), dtype)), c__)
	     );
   let numServers = valueOf(numServers);
   FIFO#(dtype) responseFifo <- mkPipelineFIFO();
   for (Integer i = 0; i < numServers; i = i + 1) begin
      (* descending_urgency = "respond" *)
      rule respond if (gate);
         let response <- bramServers[i].response.get();
         responseFifo.enq(response);
      endrule
   end
   interface BRAMServer bramServer;
      interface Put request;
	 method Action put(BRAMRequest#(Bit#(aszn), dtype) request) if (gate);
	    Bit#(csz) clientNumber = request.address[valueOf(aszn)-1:valueOf(asz)];
            bramServers[clientNumber].request.put( BRAMRequest {
					    write: request.write,
					    responseOnWrite: request.responseOnWrite,
					    address: truncate(request.address),
					    datain: request.datain });
	 endmethod
      endinterface
      interface Get response;
	 method ActionValue#(dtype) get();
	    responseFifo.deq();
	    return responseFifo.first();
	 endmethod
      endinterface
   endinterface
endmodule
