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

import Connectable::*;
import SerialFIFO::*;
import FIFOF::*;
import Vector::*;
import Pipe::*;

typedef struct {
   Bit#(4) address;
   Bit#(32) payload;
   } DataMessage deriving(Bits);

      
function Action move(PipeOut#(DataMessage) from, PipeIn#(DataMessage) to);
   return action
	     $display("move %x", from.first);
	     to.enq(from.first);
	     from.deq();
	  endaction;
endfunction


module mkNocArbitrate#(Vector#(n, PipeOut#(a)) in, PipeIn#(a) out)(Empty);
   Arbiter_IFC#(n) arb <- mkArbiter(False);   
   for (int i = 0; i < n; i = i + 1)
      rule send_request (out.notFull && in[i].notEmpty);
	 arb.clients[i].request();
      endrule
   
   rule move
      if (out.notFUll && arb.clients[arb.grant_id].notEmpty)
	 begin
	    out.enq(in[arb.grant_id].first());
	    in[arb.grantid].deq();
	 end
endmodule

module mkNocNode#(Bit#(4) id, 
		  SerialFIFO#(DataMessage) west,
		  SerialFIFO#(DataMessage) east)(SerialFIFO#(DataMessage));

   // host Links
   FIFOF#(DataMessage) fifofromhost <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) fifotohost <- mkSizedFIFOF(4);
   SerialFIFO#(DataMessage) host;
   host.in = ToPipein(fifotohost);
   host.out = ToPipeOut(fifofromhost);
  
   // buffers for crossbar switch
   
   FIFOF#(DataMessage) he <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) hw <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) hh <- mkSizedFIFOF(4);
   
   FIFOF#(DataMessage) ew <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) we <- mkSizedFIFOF(4);

   FIFOF#(DataMessage) eh <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) wh <- mkSizedFIFOF(4);

   // collate for inputs to host, east, west
   Vector#(3,PipeOut#(DataMessage)) vToHost = newVector;
   Vector#(2,PipeOut#(DataMessage)) vToEast = newVector;
   Vector#(2,PipeOut#(DataMessage)) vToWest = newVector;
   
   vToHost[0] = ToPipeOut(hh);
   vToHost[1] = ToPipeOut(eh);
   vToHost[2] = ToPipeOut(wh);
   
   vToEast[0] = ToPipeOut(he);
   vToEast[1] = ToPipeOut(we);
   
   vToWest[0] = ToPipeOut(hw);
   vToWest[1] = ToPipeOut(ew);
   
   mkNocArbitrate(vToHost, host.in);
   mkNocArbitrate(vToEast, east.in);
   mkNocArbitrate(vToWest, west.in);
   
   // sort host messages to proper queue
   
   rule fromhost (host.out.notEmpty);
      if (host.out.first.address < id)
	 begin
	    $display("id %d host to west", id);
	    move(host.out, ToPipeIn(hw));
	 end
      else if (host.out.first.address == id)
	 begin
	    $display("id %d host to host", id);
	    move(host.out, ToPipeIn(hh));
	 end
      else
	 begin
	    $display("id %d host to east", id);
	    move(host.out, ToPipeIn(he));
	 end
   endrule
   
   // Handle arriving messages from East
   
   rule fromeast (east.out.notEmpty);
      if (east.out.first.address == id)
	 begin
	    $display("fromeast %d to host v %x", id, east.out.first);
	    move(east.out, eh);
	 end
      else
	 begin
	    $display("fromeast %d to west v %x", id, east.out.first);
	    move(east.out, ew);
	 end
   endrule
   
   // Handle arriving messages from West

   rule fromwest (west.out.notEmpty);
      if (west.out.first.address == id)
	 begin
	    $display("fromwest %d to host v %x", id, west.out.first);
	    move(west.out, wh);
	 end
      else
	 begin
	    $display("fromwest %d  to east v %x", id, west.out.first);
	    from(west.out, we);
	 end
      endrule
      
  // interface wiring

   interface PipeIn fromhost = ToPipeIn(fifotohost);
   interface PipeOut tohost = ToPipeOut(fifofromhost);

endmodule

