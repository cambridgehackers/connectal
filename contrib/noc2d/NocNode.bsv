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
   Vector#(2, Bit#(4)) address;
   Bit#(32) payload;
   } DataMessage deriving(Bits);

interface NocNode#(numeric type dim);
   interface PipeIn#(DataMessage) hosttonode;
   interface PipeOut#(DataMessage) nodetohost;
   interface Vector#(dim, PipeIn#(Bit#(1))) linkupin;
   interface Vector#(dim, PipeOut#(Bit#(1))) linkupout;
   interface Vector#(dim, PipeIn#(Bit#(1))) linkdownin;
   interface Vector#(dim, PipeOut#(Bit#(1))) linkdownout;
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


module mkNocArbitrate#(Vector#(n, Bit#(4)) id, Bit#(4) outlink, Vector#(r, PipeOut#(a)) in, PipeIn#(a) out)(Empty)
/*   provisos(
      Add#(0,n,2),
      Add#(0,r,5)
      ) */ ;
   Arbiter_IFC#(r) arb <- mkArbiter(False);   
   for (Integer i = 0; i < valueOf(r); i = i + 1)
      rule send_request (out.notFull && in[i].notEmpty);
	 arb.clients[i].request();
      endrule
   
   rule move;
      if (out.notFull && in[arb.grant_id].notEmpty)
	 action
	    $display("arb id [%d,%d] link %d from %d", id[0], id[1], outlink, arb.grant_id);
	    out.enq(in[arb.grant_id].first());
	    in[arb.grant_id].deq();
	 endaction
   endrule
endmodule

module mkDistributor#(Vector#(n, Bit#(4)) id, PipeOut#(DataMessage) in, Vector#(r, PipeIn#(DataMessage)) out)(Empty)
/*    provisos(
      Add#(0,n,2),
      Add#(0,r,5)
      ) */
;
   rule move;
      $display("distrib [%d,%d] to [%d,%d] v %x",
	 id[0], id[1], in.first.address[0], in.first.address[1],
	 in.first.payload);
      if (in.first.address[0] < id[0]) 
	 begin
	    $display(" to link 1");
	    move(in, out[1]);
	 end
      else if (in.first.address[0] > id[0]) 
	 begin
	    $display(" to link 0");
	    move(in, out[0]);
	 end
      else /* in.first.address[0] == id[0] */
	 begin
	    if (in.first.address[1] < id[1]) 
	       begin
		  $display(" to link 3");
		  move (in, out[3]);
	       end
	    else if (in.first.address[1] > id[1]) 
	       begin
		  $display(" to link 2");
		  move (in, out[2]);
	       end
	    else
	       begin
		  $display(" to link 4");
		  move(in, out[4]);
	       end
	 end
   endrule
endmodule

// This makes a FIFO which throws away data and is never ready to read
module mkDiscard(FIFOF#(DataMessage));
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
   method Action clear = ?;
endmodule

typedef 2 NumDims;
(* synthesize *)
module mkNocNode#(Vector#(NumDims, Bit#(4)) id)(NocNode#(NumDims));
   Integer radix = (valueOf(NumDims) * 2) + 1;

   // host Links
   FIFOF#(DataMessage) fifofromhost <- mkSizedFIFOF(4);
   FIFOF#(DataMessage) fifotohost <- mkSizedFIFOF(4);
   PipeIn#(DataMessage) tohost = toPipeIn(fifotohost);
   PipeOut#(DataMessage) fromhost = toPipeOut(fifofromhost); 
  
   Vector#(NumDims, SerialFIFOTX#(DataMessage)) txup <- replicateM(mkSerialFIFOTX);
   Vector#(NumDims, SerialFIFORX#(DataMessage)) rxup <- replicateM(mkSerialFIFORX);
   Vector#(NumDims, SerialFIFOTX#(DataMessage)) txdown <- replicateM(mkSerialFIFOTX);
   Vector#(NumDims, SerialFIFORX#(DataMessage)) rxdown <- replicateM(mkSerialFIFORX);
	 
	 
   // sources
   Vector#(TAdd#(TMul#(NumDims, 2), 1), PipeOut#(DataMessage)) switchin = newVector;
   Vector#(TAdd#(TMul#(NumDims, 2), 1), PipeIn#(DataMessage)) switchout = newVector;
   // buffers for crossbar switch
   Vector#(TAdd#(TMul#(NumDims, 2), 1), Vector#(TAdd#(TMul#(NumDims, 2), 1), FIFOF#(DataMessage))) xp = replicate(newVector);
   // temps for building switch
   Vector#(TAdd#(TMul#(NumDims, 2), 1), PipeIn#(DataMessage)) tmpin = newVector;
   Vector#(TAdd#(TMul#(NumDims, 2), 1), PipeOut#(DataMessage)) tmpout = newVector;


   for (Integer i = 0; i < valueOf(NumDims); i = i + 1)
      begin
	 switchin[(2*i) + 0] = rxup[i].out;
	 switchin[(2*i) + 1] = rxdown[i].out;
	 switchout[(2*i) + 0] = txup[i].in;
	 switchout[(2*i) + 1] = txdown[i].in;
      end
   switchin[radix - 1] = fromhost;
   switchout[radix - 1] = tohost;
   

   for (Integer x = 0; x < radix; x = x + 1)
      for (Integer y = 0; y < radix; y = y + 1)
	 if (x != y) xp[x][y] <- mkSizedFIFOF(4);

   for (Integer x = 0; x < (radix - 1); x = x + 1)
      xp[x][x] <- mkDiscard();
   
   xp[radix - 1][radix - 1] <- mkSizedFIFOF(4);
   
   // create distributors
   
   for (Integer x = 0; x < radix; x = x + 1)
      begin
	 for (Integer y = 0; y < radix; y = y + 1)
	    tmpin[y] = toPipeIn(xp[x][y]);
	 mkDistributor(id, switchin[x], tmpin);
      end
   // create arbiters
   for (Integer y = 0; y < radix; y = y + 1)
      begin
	 for (Integer x = 0; x < radix; x = x + 1)
	    tmpout[x] = toPipeOut(xp[x][y]);
	 mkNocArbitrate(id, fromInteger(y), tmpout, switchout[y]);
      end

  // interface wiring

   interface PipeIn hosttonode = toPipeIn(fifofromhost);
   interface PipeOut nodetohost = toPipeOut(fifotohost);
   interface Vector linkupin = map(selectinput, rxup);
   interface Vector linkupout = map(selectoutput, txup);
   interface Vector linkdownin = map(selectinput, rxdown);
   interface Vector linkdownout = map(selectoutput, txdown);

endmodule

