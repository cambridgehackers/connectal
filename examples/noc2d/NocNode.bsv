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
import Arbiter::*;

typedef struct {
   Vector(2, Bit#(4)) address;
   Bit#(32) payload;
   } DataMessage deriving(Bits);

interface NocNode#(numeric type dim);
   interface PipeIn#(DataMessage) hosttonode;
   interface PipeOut#(DataMessage) nodetohost;
   interface Vector#(dim, PipeIn#(Bit#(width))) linkupin;
   interface Vector#(dim, PipeOut#(Bit#(width))) linkupout;
   interface Vector#(dim, PipeIn#(Bit#(width))) linkdownin;
   interface Vector#(dim, PipeOut#(Bit#(width))) linkdownout;
endinterface
	 
function PipeOut#(Bit#(1)) selectoutput(SerialFIFOTX#(DataMessage) x);
   return x.out;
endfunction

function PipeIn#(Bit#(1)) selectinput(SerialFIFORX#(DataMessage) x);
   return x.in;
endfunction

function Action move(PipeOut#(DataMessage) from, PipeIn#(DataMessage) to);
   return action
	     $display("move %x", from.first);
	     to.enq(from.first);
	     from.deq();
	  endaction;
endfunction


module mkNocArbitrate#(Vector#(n, Bit#(4)) id, Vector#(n, PipeOut#(a)) in, PipeIn#(a) out)(Empty);
   Arbiter_IFC#(n) arb <- mkArbiter(False);   
   for (Integer i = 0; i < valueOf(n); i = i + 1)
      rule send_request (out.notFull && in[i].notEmpty);
	 arb.clients[i].request();
      endrule
   
   rule move;
      if (out.notFull && in[arb.grant_id].notEmpty)
	 action
	    $display("arb id [%d,%d] from %d", id[0], id[1], arb.grant_id);
	    out.enq(in[arb.grant_id].first());
	    in[arb.grant_id].deq();
	 endaction
   endrule
endmodule

module mkDistribute#(Vector(n, Bit#(4)) id, PipeOut#(a) in, Vector#(n, PipeIn#(a)) out)(Empty);
   rule move;
      $display("distrib [%d,%d] to [%d,%d] v %x",
	 name, id[0], id[1], in.first.address[0], in.first.address[1],
	 in.first.payload);
      if (in.address[0] < id[0]) 
	 move(in.first, out[0]);
      else if (in.address[0] > id[0]) 
	 move(in.first, out[1]);
      else /* in.address[0] == id[0] */
	 begin
	    if (in.address[1] < id[1]) 
	       move (in.first, out[2]);
	    else if (in.address[1] > id[1]) 
	       move (in.first, out[3]);
	    else
	       move(in.first, out[4]);
	 end
      end

   endrule
endmodule

// This makes a FIFO which throws away data and is never ready to read
module mkDiscard(FIFOF#(DataMessage));
   interface
      method Action enq(DataMessage d);
      endmethod
      method Bool notFull;
         return True;
      endmethod
      method DataMessage first() = ?;
      method Bool notEmpty();
         return False;
      endmethod
      method Action deq;
	 if (False) noAction;
      endmethod
endmodule


module mkNocNode#(Vector(dim, Bit#(4)) id)(NocNode#(dim));
   Bit#(4) radix = (ValueOf(dim) * 2) + 1;
   
   // host Links
   FIFOF#(msg) fifofromhost <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) fifotohost <- mkSizedFIFOF(4);
   PipeIn#(DataMessage) tohost = toPipeIn(fifotohost);
   PipeOut#(DataMessage) fromhost = toPipeOut(fifofromhost); 
  
   Vector#(dim, SerialFIFOTX#(DataMessage)) txup <- replicateM(mkSerialFIFOTX);
   Vector#(dim, SerialFIFORX#(DataMessage)) rxup <- replicateM(mkSerialFIFORX);
   Vector#(dim, SerialFIFOTX#(DataMessage)) txdown <- replicateM(mkSerialFIFOTX);
   Vector#(dim, SerialFIFORX#(DataMessage)) rxdown <- replicateM(mkSerialFIFORX);
	 
	 
   // sources
   Vector#(radix, PipeOut#(DataMessage)) switchin = newVector;
   Vector#(radix, PipeOut#(DataMessage)) switchout = newVector;
   for (Bit#(4) i = 0; i < ValueOf(dim); i = i + 1)
      begin
	 switchin[(2*i) + 0] = rxup[i].out;
	 switchin[(2*i) + 1] = rxdown[i].out;
	 switchout[(2*i) + 0] = txup[i].in;
	 switchout[(2*i) + 1] = txdown[i].out;
      end
   switchin[radix - 1] = fromhost;
   switchout[radix - 1] = tohost;
   
   // buffers for crossbar switch
   Vector#(radix, Vector#(radix, FIFOF#(DataMessage))) xp = replicate(newVector);

   for (Bit#(4) x = 0; x < radix; x = x + 1)
      for (Bit#(4) y = 0; y < radix; y = y + 1)
	 if (x != y) xp[x][y] <- mkSizedFIFOF(4);

   for (Bit#(4) x = 0; x < (radix - 1); x = x + 1)
      xp[x][x] <- mkDiscard();
   
   xp[radix - 1][radix - 1] < mkSizedFIFOF(4);
   
   // create distributors
   
   for (Bit#(4) x = 0; x < radix; x = x + 1)
      mkdistributor(id, linkin[x], map(toPipeOut, xp[x]));

   // create arbiters
   for (Bit#(4) y = 0; y < radix; y = y + 1)
      begin
	 Vector(radix, PipeOut#(DataMessage)) o = newVector;
	 for (Bit#(4) x = 0; x < radix; x = x + 1)
	    o[x] = xp[x][y];
	 mkNocArbitrate(id, o, linkout[y]);
      end

  // interface wiring

   interface PipeIn hosttonode = toPipeIn(fifofromhost);
   interface PipeOut nodetohost = toPipeOut(fifotohost);
   interface Vector linkupin = map(selectinput, rxup)
   interface Vector linkupout = map(selectoutput, txup);
   interface Vector linkdownin = map(selectinput, rxdown)
   interface Vector linkdownout = map(selectoutput, txdown);

endmodule

