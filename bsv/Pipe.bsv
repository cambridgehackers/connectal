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


import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Vector::*;
import BuildVector::*;
import MIMO::*;
import DefaultValue::*;
import Gearbox::*;
import Clocks::*;

typedef Tuple3#(x,x,x) Tripple#(type x);
typedef Tuple2#(x,x)   Pair#(type x);

interface PipeIn#(type a);
   method Action enq(a v);
   method Bool notFull();
endinterface

interface PipeOut#(type a);
   method a first();
   method Action deq();
   method Bool notEmpty();
endinterface

function Bool pipeInNotFull(PipeIn#(a) pipein); return pipein.notFull(); endfunction
function Bool pipeOutNotEmpty(PipeOut#(a) pipein); return pipein.notEmpty(); endfunction

typeclass ToPipeIn#(type a, type b) dependencies (b determines a);
   function PipeIn#(a) toPipeIn(b in);
endtypeclass

typeclass ToPipeOut#(type a, type b) dependencies ( b determines a);
   function PipeOut#(a) toPipeOut(b in);
endtypeclass

typeclass MkPipeOut#(type a, type b) dependencies ( b determines a);
   module mkPipeOut#(b in)(PipeOut#(a));
endtypeclass

typeclass MkPipeIn#(type a, type b) dependencies ( b determines a);
   module mkPipeIn#(b in)(PipeIn#(a));
endtypeclass

instance ToPipeIn#(a, FIFOF#(a));
   function PipeIn#(a) toPipeIn(FIFOF#(a) in);
      return (interface PipeIn#(a);
		 method enq = in.enq;
		 method notFull = in.notFull;
	      endinterface);
   endfunction
endinstance

instance ToPipeOut#(a, function a pipefn());
   function PipeOut#(a) toPipeOut(function a pipefn());
      return (interface PipeOut#(a);
		 method first(); return pipefn(); endmethod
		 method Action deq(); endmethod
		 method Bool notEmpty(); return False; endmethod
	      endinterface);
   endfunction
endinstance

instance ToPipeOut#(a, Reg#(a));
   function PipeOut#(a) toPipeOut(Reg#(a) in);
      return (interface PipeOut#(a);
		 method first(); return in; endmethod
		 method Action deq(); endmethod
		 method Bool notEmpty(); return False; endmethod
	      endinterface);
   endfunction
endinstance

instance ToPipeIn#(a, Gearbox#(1, n, a));
   function PipeIn#(a) toPipeIn(Gearbox#(1, n, a) in);
      return (interface PipeIn#(a);
		 method Action enq(a v); in.enq(vec(v)); endmethod
		 method notFull = in.notFull;
	      endinterface);
   endfunction
endinstance

instance ToPipeIn#(Vector#(m, a), Gearbox#(m, n, a));
   function PipeIn#(Vector#(m, a)) toPipeIn(Gearbox#(m, n, a) in);
      return (interface PipeIn#(Vector#(m, a));
		 method enq = in.enq;
		 method notFull = in.notFull;
	      endinterface);
   endfunction
endinstance

instance ToPipeOut#(a, FIFOF#(a));
   function PipeOut#(a) toPipeOut(FIFOF#(a) in);
      return (interface PipeOut#(a);
		 method first = in.first;
		 method deq = in.deq;
		 method notEmpty = in.notEmpty;
	      endinterface);
   endfunction
endinstance

instance ToPipeOut#(Vector#(n,a), MIMO#(k,n,sz,a));
   function PipeOut#(Vector#(n,a)) toPipeOut(MIMO#(k,n,sz,a) in);
      return (interface PipeOut#(a);
		 method first = in.first;
		 method Action deq() if (in.deqReadyN(fromInteger(valueOf(n))));
		    in.deq(fromInteger(valueOf(n)));
		 endmethod
		 method Bool notEmpty();
		    return in.deqReadyN(fromInteger(valueOf(n)));
		 endmethod
	      endinterface);
   endfunction
endinstance

instance ToPipeOut#(Vector#(n, a), Gearbox#(m, n, a));
   function PipeOut#(Vector#(n, a)) toPipeOut(Gearbox#(m, n, a) in);
      return (interface PipeOut#(Vector#(n,a));
		 method first = in.first;
		 method deq = in.deq;
		 method notEmpty = in.notEmpty;
	      endinterface);
   endfunction
endinstance
instance ToPipeOut#(a, Gearbox#(m, 1, a));
   function PipeOut#(a) toPipeOut(Gearbox#(m, 1, a) in);
      return (interface PipeOut#(a);
		 method a first(); return in.first[0]; endmethod
		 method deq = in.deq;
		 method notEmpty = in.notEmpty;
	      endinterface);
   endfunction
endinstance

instance ToPipeIn#(a, SyncFIFOIfc#(a));
   function PipeIn#(a) toPipeIn(SyncFIFOIfc#(a) in);
      return (interface PipeIn#(a);
		 method enq = in.enq;
		 method notFull = in.notFull;
	      endinterface);
   endfunction
endinstance

instance ToPipeOut#(a, SyncFIFOIfc#(a));
   function PipeOut#(a) toPipeOut(SyncFIFOIfc#(a) in);
      return (interface PipeOut#(a);
		 method first = in.first;
		 method deq = in.deq;
		 method notEmpty = in.notEmpty;
	      endinterface);
   endfunction
endinstance

instance MkPipeOut#(a, ActionValue#(a))
   provisos (Bits#(a, asz));
   module mkPipeOut#(ActionValue#(a) in)(PipeOut#(a));
      FIFOF#(a) fifo <- mkFIFOF();
      rule connect;
	 let v <- in;
	 fifo.enq(v);
      endrule
      return toPipeOut(fifo);
   endmodule
endinstance

instance MkPipeOut#(a, Get#(a))
   provisos (Bits#(a, asz));
   module mkPipeOut#(Get#(a) in)(PipeOut#(a));
      FIFOF#(a) fifo <- mkFIFOF();
      rule connect;
	 let v <- in.get();
	 fifo.enq(v);
      endrule
      return toPipeOut(fifo);
   endmodule
endinstance

instance MkPipeIn#(a, Put#(a))
   provisos (Bits#(a, asz));
   module mkPipeIn#(Put#(a) out)(PipeIn#(a));
      FIFOF#(a) fifo <- mkFIFOF();
      rule connect;
	 let v <- toGet(fifo).get;
	 out.put(v);
      endrule
      return toPipeIn(fifo);
   endmodule
endinstance

function PipeOut#(a) toCountedPipeOut(Reg#(Bit#(n)) r, PipeOut#(a) pipe);
   return (interface PipeOut#(Vector#(n,a));
	      method first = pipe.first;
	      method Action deq(); pipe.deq; r <= r + 1; endmethod
	      method notEmpty = pipe.notEmpty;
	   endinterface);
endfunction   

instance ToGet #(PipeOut #(a), a);
   function Get #(a) toGet (PipeOut #(a) po);
      return (interface Get;
                 method ActionValue #(a) get ();
                    po.deq ();
                    return po.first ();
                 endmethod
              endinterface);
   endfunction
endinstance

instance ToPut #(PipeIn #(a), a);
   function Put #(a) toPut (PipeIn #(a) pi);
      return (interface Put;
		 method Action put(a v);
                    pi.enq (v);
                 endmethod
              endinterface);
   endfunction
endinstance

instance Connectable#(PipeOut#(a),Put#(a));
   module mkConnection#(PipeOut#(a) in, Put#(a) out)(Empty);
      rule connect;
	 let v = in.first;
	 in.deq();
	 out.put(v);
      endrule
   endmodule
endinstance

instance Connectable#(ActionValue#(a),PipeIn#(a));
   module mkConnection#(ActionValue#(a) in, PipeIn#(a) out)(Empty);
      rule connect;
	 let v <- in;
	 out.enq(v);
      endrule
   endmodule
endinstance

instance Connectable#(PipeOut#(a),PipeIn#(a));
   module mkConnection#(PipeOut#(a) in, PipeIn#(a) out)(Empty);
      rule connect;
	 let v = in.first;
	 in.deq();
	 out.enq(v);
      endrule
   endmodule
endinstance

function PipeOut#(a) unvectorPipeOut(PipeOut#(Vector#(1,a)) in);
   return (interface PipeOut#(a);
	      method first = in.first[0];
	      method deq = in.deq;
	      method notEmpty = in.notEmpty;
	   endinterface);
endfunction

function PipeOut#(Tuple2#(a,b)) zipPipeOut(PipeOut#(a) ina, PipeOut#(b) inb);
      return (interface PipeOut#(Tuple2#(a,b));
		 method Tuple2#(a,b) first(); return tuple2(ina.first, inb.first); endmethod
		 method Action deq(); ina.deq(); inb.deq(); endmethod
		 method Bool notEmpty(); return ina.notEmpty() && inb.notEmpty(); endmethod
	      endinterface);
   endfunction

module mkFunnel#(PipeOut#(Vector#(mk,a)) in)(PipeOut#(Vector#(m, a)))
   provisos (Mul#(m, k, mk),
	     Bits#(a, asz),
	     Add#(a__, TMul#(asz, m), TMul#(asz, mk)),
	     Add#(1, b__, asz),
	     Add#(2, c__, mk),
	     Add#(d__, m, mk),
	     Add#(asz, m, e__),
	     Add#(asz, mk, f__));
   let m = fromInteger(valueOf(m));
   let mk = fromInteger(valueOf(mk));

   MIMOConfiguration cfg = defaultValue();
   MIMO#(mk, m, mk, a) mimo <- mkMIMO(cfg);
   rule consumer if (mimo.enqReadyN(mk));
      Vector#(mk, a) v = in.first();
      in.deq();
      mimo.enq(mk, v);
   endrule

   method Vector#(m, a) first() if (mimo.deqReadyN(m));
      return mimo.first();
   endmethod
   method Action deq() if (mimo.deqReadyN(m));
      mimo.deq(m);
   endmethod
   method notEmpty();
      return mimo.deqReadyN(m);
   endmethod
endmodule

module mkFunnel1#(PipeOut#(Vector#(k,a)) in)(PipeOut#(a))
   provisos (Bits#(a, asz), Log#(k,ksz));

   Reg#(Bit#(ksz)) selector <- mkReg(0);

   method a first();
      return in.first[selector];
   endmethod
   method Action deq();
      if (selector == fromInteger(valueOf(k)-1)) begin
	 in.deq();
	 selector <= 0;
      end
      else
	 selector <= selector + 1;
   endmethod
   method notEmpty();
      return in.notEmpty();
   endmethod
endmodule

module mkFunnelGB1#(Clock slowClock, Reset slowReset, Clock fastClock, Reset fastReset, PipeOut#(Vector#(k,a)) in)(PipeOut#(a))
   provisos (Bits#(a, asz), Log#(k,ksz), Add#(1,a__,k));

   Gearbox#(k,1,a) gb <- mkNto1Gearbox(slowClock, slowReset, fastClock, fastReset);
   PipeIn#(Vector#(k,a)) toGb = toPipeIn(gb);
   mkConnection(in, toGb);
   PipeOut#(Vector#(1,a)) fromGb = toPipeOut(gb);
   return mapPipe(head, fromGb);
endmodule

// 'j' is the width of the narrow end, and 'k' is the width of the wide end
typedef Vector#(j,PipeOut#(a))   FunnelPipe#(numeric type j, numeric type k, type a, numeric type bitsPerCycle);
typedef Vector#(k,PipeOut#(a)) UnFunnelPipe#(numeric type j, numeric type k, type a, numeric type bitsPerCycle);

typeclass FunnelPipesPipelined#(numeric type j, numeric type k, type a, numeric type bpc);
   module mkFunnelPipesPipelined#(Vector#(k,PipeOut#(a)) in) (FunnelPipe#(j,k,a,bpc));
   module mkFunnelPipesPipelinedRR#(Vector#(k,PipeOut#(a)) in, Integer c) (FunnelPipe#(j,k,a,bpc));
   module mkUnFunnelPipesPipelined#(Vector#(j,PipeOut#(Tuple2#(Bit#(TLog#(k)),a))) in) (UnFunnelPipe#(j,k,a,bpc));
   module mkUnFunnelPipesPipelinedRR#(Vector#(j,PipeOut#(a)) in, Integer c) (UnFunnelPipe#(j,k,a,bpc));
endtypeclass

function PipeOut#(b) pipeSecond(PipeOut#(Tuple2#(a,b)) x) = 
   (interface PipeOut;
       method b first;
	  return tpl_2(x.first);
       endmethod
       method Action deq = x.deq;
       method Bool notEmpty = x.notEmpty;
    endinterface);
   
instance FunnelPipesPipelined#(1,1,a,bpc)   
   provisos (Bits#(a,a__));
   module mkFunnelPipesPipelined#(Vector#(1,PipeOut#(a)) in) (FunnelPipe#(1,1,a,bpc));
      return in;
   endmodule
   module mkFunnelPipesPipelinedRR#(Vector#(1,PipeOut#(a)) in, Integer c) (FunnelPipe#(1,1,a,bpc));
      return in;
   endmodule
   module mkUnFunnelPipesPipelined#(Vector#(1,PipeOut#(Tuple2#(Bit#(0),a))) in) (UnFunnelPipe#(1,1,a,bpc));
      return map(pipeSecond, in);
   endmodule
   module mkUnFunnelPipesPipelinedRR#(Vector#(1,PipeOut#(a)) in, Integer c) (UnFunnelPipe#(1,1,a,bpc));
      return in;
   endmodule
endinstance

module mkUnFunnelPipesPipelinedInternal#(Vector#(1, PipeOut#(Tuple2#(Bit#(TLog#(k)),a))) in) (UnFunnelPipe#(1,k,a,bpc))
   provisos (Log#(k, logk),
	     Bits#(a,a__),
	     Add#(1,b__,k),
	     Div#(k,TExp#(bpc),c__),
	     Mul#(c__,TExp#(bpc),krounded),
	     Add#(1, d__, krounded),
	     Add#(k, e__, krounded),
	     Div#(logk,bpc,stages));
   Vector#(krounded, PipeOut#(Tuple2#(Bit#(logk),a))) ins  = append(in,replicate(?));
   Vector#(krounded, PipeOut#(Tuple2#(Bit#(logk),a))) outs = newVector;
   for(Integer j = 0; j < valueOf(stages); j=j+1) begin 
      for(Integer i = 0; i < min(valueOf(krounded), 2**(j*valueOf(bpc))); i=i+1) begin
	 Integer bits = (j == valueOf(stages)-1) ? valueOf(logk)-(j*valueOf(bpc)) : valueOf(bpc);
	 function Bit#(bpc) sh(Bit#(bpc) x) = x<<(valueOf(bpc)-bits);
	 for(Integer l = 0; l < 2**bits; l=l+1)  begin
	    let buff <- mkFIFOF;
	    // extra conditional in case 'k' is not a power of 2
	    let idx = (2**bits)*i+l;
	    if (idx < valueOf(k)) begin
	       outs[idx] = toPipeOut(buff);
	       rule xfer if(tpl_1(ins[i].first)[(valueOf(logk)-1):max(0,(valueOf(logk)-valueOf(bpc)))] == sh(fromInteger(l)));
		  match{.idx, .v} <- toGet(ins[i]).get;
		  buff.enq(tuple2(idx<<valueOf(bpc), v));
	       endrule
	    end
	 end
      end
      ins = outs;
   end
   return take(map(pipeSecond,outs));
endmodule
   
module mkFunnelNode#(Vector#(n, PipeOut#(a)) inpipes, Integer numPipes, Put#(a) outpipe)(Empty);
   rule funnel;
      a v = ?;
      Bool send = False;
      for (Integer i = 0; i < valueOf(n) && i < numPipes; i = i+1)
	 if (!send && inpipes[i].notEmpty) begin
	    v <- toGet(inpipes[i]).get();
	    send = True;
	 end
      if (send)
	 outpipe.put(v);
   endrule
endmodule
   
module mkFunnelNodeRR#(Vector#(n, PipeOut#(a)) inpipes, Integer numPipes, Put#(a) outpipe)(Empty)
   provisos (Log#(n, pipeIdxSz));
   Reg#(Bit#(TAdd#(pipeIdxSz, 1))) idx <- mkReg(0);

   rule funnel;
      a v = ?;
      Bool send = False;
      Bit#(TAdd#(pipeIdxSz, 1)) curIdx = idx;
      for (Integer i = 0; i < valueOf(n) && i < numPipes; i = i+1)
         if (fromInteger(i) != curIdx && !send && inpipes[i].notEmpty) begin
            send = True;
            idx <= fromInteger(i);
            curIdx = fromInteger(i);
         end
      if (!send && inpipes[curIdx].notEmpty)
         send = True;
      if (send) begin
         v <- toGet(inpipes[curIdx]).get();
         outpipe.put(v);
      end
   endrule
endmodule

instance FunnelPipesPipelined#(1,k,a,bpc)
   provisos (Log#(k, logk),
	     Bits#(a,a__),
	     Add#(1,b__,k),
	     Div#(logk,bpc,stages),
	     Mul#(TDiv#(k, TExp#(bpc)), TExp#(bpc), krounded),
	     Add#(k, c__, krounded),
	     Add#(TExp#(bpc), d__, krounded),
	     Add#(1, e__, krounded)
	     );
   module mkFunnelPipesPipelined#(Vector#(k,PipeOut#(a)) in) (FunnelPipe#(1,k,a,bpc));
      Vector#(stages, Vector#(krounded, FIFOF#(a))) buffs  <- replicateM(replicateM(mkFIFOF));
      Vector#(krounded, PipeOut#(a)) paddedIn = append(in, replicate(?));
      Vector#(TAdd#(stages,1), Vector#(krounded, PipeOut#(a))) infss = append(map(map(toPipeOut),buffs), vec(paddedIn));
      for(Integer j = valueOf(stages); j > 0; j=j-1) begin
	 Integer width = min(valueOf(krounded),2**(j*valueOf(bpc)));
	 Integer stride = valueOf(TExp#(bpc));
	 Vector#(krounded,PipeOut#(a)) pipes = infss[j];
	 for(Integer i = 0; i < width && i < valueOf(k); i=i+stride) begin
	    Vector#(TExp#(bpc),PipeOut#(a)) inpipes = takeAt(i, pipes);
	    Integer numPipes = stride;
	    if (i + stride > valueOf(k))
	       numPipes = valueOf(k) - i;
	    mkFunnelNode(inpipes, numPipes, toPut(buffs[j-1][i/stride]));
	 end
      end
      return vec(infss[0][0]);
   endmodule
   module mkFunnelPipesPipelinedRR#(Vector#(k,PipeOut#(a)) in, Integer c) (FunnelPipe#(1,k,a,bpc));
      Vector#(stages, Vector#(k, FIFOF#(a))) buffs  <- replicateM(replicateM(mkFIFOF));
      Vector#(TAdd#(stages,1), Vector#(k, PipeOut#(a))) infss = append(map(map(toPipeOut),buffs), cons(in,nil));
      for(Integer j = valueOf(stages); j > 0; j=j-1) begin
	 Vector#(k, FIFOF#(void)) ctrl  <- replicateM(mkFIFOF1());
   	 for(Integer i = 0; i < 2**(j*valueOf(bpc)) && i < valueOf(k); i=i+1) begin
   	    let first = i==0;
   	    Reg#(Bit#(32)) cnt <- mkReg(0);
   	    let maxp = (2**((valueOf(stages)-j)*valueOf(bpc)))*c;
   	    let last = (maxp*(i+1) >= valueOf(k)*c);
   	    if (maxp*(i+1) > valueOf(k)*c) begin
   	       maxp = valueOf(k)*c-maxp*i;
	    end
   	    let xfer_guard = True;
   	    if (!first)
   	       xfer_guard = xfer_guard && ctrl[(i-1)].notEmpty;
   	    if (!last)
   	       xfer_guard = xfer_guard && (!ctrl[i].notEmpty);
   	    rule xfer if (xfer_guard);
   	       let new_cnt = cnt+1;
   	       if (new_cnt==fromInteger(maxp)) begin
   		  cnt <= 0;
   		  if (!last)
   		     ctrl[i].enq(?);
   		  if (last) 
   		     for(Integer ff = 0; ff < i; ff=ff+1)
   		     	ctrl[ff].deq;
   	       end
   	       else begin
   		  cnt <= new_cnt;
   	       end
   	       let v <- toGet(infss[j][i]).get;
   	       toPut(buffs[j-1][i/(2**valueOf(bpc))]).put(v);
   	    endrule
   	 end
      end
      return cons(infss[0][0],nil);
   endmodule
   module mkUnFunnelPipesPipelined#(Vector#(1, PipeOut#(Tuple2#(Bit#(logk),a))) in) (UnFunnelPipe#(1,k,a,bpc));
      let rv <- mkUnFunnelPipesPipelinedInternal(in);
      return rv;
   endmodule
   module mkUnFunnelPipesPipelinedRR#(Vector#(1, PipeOut#(a)) in, Integer c) (UnFunnelPipe#(1,k,a,bpc));
      Vector#(1, FIFOF#(Tuple2#(Bit#(logk),a))) tagged_in_buffers <- replicateM(mkFIFOF);
      Vector#(1, PipeOut#(Tuple2#(Bit#(logk),a))) tagged_in = map(toPipeOut, tagged_in_buffers);
      let rv <- mkUnFunnelPipesPipelinedInternal(tagged_in);
      Reg#(Bit#(TAdd#(logk,1))) dest <- mkReg(0);
      Reg#(Bit#(32)) cnt <- mkReg(0);
      rule fill;
	 let new_cnt = cnt+1;
	 let new_dest = dest;
	 if (new_cnt == fromInteger(c)) begin
	    new_cnt = 0;
	    new_dest = dest+1;
	    if(new_dest==fromInteger(valueOf(k)))
	       new_dest=0;
	 end
	 cnt <= new_cnt;
	 dest <= new_dest;
	 let v <- toGet(in[0]).get;
	 tagged_in_buffers[0].enq(tuple2(truncate(dest),v));
	 //$display("mkUnFunnelPipesPipelinedInternal::fill %d", dest);
      endrule
      return rv;
   endmodule
endinstance
   
module mkUnfunnel#(PipeOut#(Vector#(m,a)) in)(PipeOut#(Vector#(mk, a)))
   provisos (Mul#(m, k, mk),
	     Bits#(a, asz),
	     Add#(1, b__, asz),
	     Add#(2, c__, mk),
	     Add#(d__, m, mk),
	     Add#(asz, m, e__),
	     Add#(asz, mk, f__));
   let m = fromInteger(valueOf(m));
   let mk = fromInteger(valueOf(mk));

   MIMOConfiguration cfg = defaultValue();
   MIMO#(m, mk, mk, a) mimo <- mkMIMO(cfg);
   rule consumer if (mimo.enqReadyN(m));
      Vector#(m, a) v = in.first();
      in.deq();
      mimo.enq(m, v);
   endrule

   method Vector#(mk, a) first() if (mimo.deqReadyN(mk));
      return mimo.first();
   endmethod
   method Action deq() if (mimo.deqReadyN(mk));
      mimo.deq(mk);
   endmethod
   method notEmpty();
      return mimo.deqReadyN(mk);
   endmethod
endmodule

module mkUnfunnelGB#(Clock slowClock, Reset slowReset, Clock fastClock, Reset fastReset, PipeOut#(Vector#(1,a)) in)(PipeOut#(Vector#(k, a)))
   provisos (Bits#(a, asz),
	     Add#(1, a__, k),
	     Add#(1, b__, asz),
	     Add#(1, c__, TMul#(2,k)),
	     Add#(k, d__, TMul#(2,k))
      );
   let k = fromInteger(valueOf(k));

   Gearbox#(1,k,a) gb <- mk1toNGearbox(fastClock, fastReset, slowClock, slowReset);
   PipeIn#(Vector#(1,a)) toGb = toPipeIn(gb);
   PipeOut#(Vector#(k,a)) fromGb = toPipeOut(gb);
   mkConnection(in,toGb);
   return fromGb;
endmodule: mkUnfunnelGB

module mkFunnelPipes#(Vector#(mk, PipeOut#(a)) ins)(Vector#(m, PipeOut#(a)))
   provisos (Mul#(m, k, mk),
	     Bits#(a, asz),
	     Log#(k,ksz)
      );
   let k = fromInteger(valueOf(k));
   let m = fromInteger(valueOf(m));
   let mk = fromInteger(valueOf(mk));

   Vector#(m, FIFOF#(a)) fifos <- replicateM(mkFIFOF);
   for (Integer i = 0; i < m; i = i+1) begin
      Reg#(Bit#(asz)) which <- mkReg(0);
      rule consumer;
	 let index = (which << valueOf(ksz)) + fromInteger(i);
	 let v <- toGet(ins[index]).get();
	 fifos[i].enq(v);
	 which <= (which + 1) % k;
      endrule
   end

   return map(toPipeOut, fifos);
endmodule

module mkFunnelPipes1#(Vector#(k, PipeOut#(a)) ins)(PipeOut#(a))
   provisos (Bits#(a, asz),
	     Log#(k,ksz)
      );
   let k = fromInteger(valueOf(k));
   Reg#(Bit#(ksz)) selector <- mkReg(0);

   method a first();
      return ins[selector].first();
   endmethod
   method Action deq();
      ins[selector].deq();
      if (selector == fromInteger(valueOf(k)-1))
	 selector <= 0;
   else
      selector <= selector + 1;
   endmethod
   method Bool notEmpty();
      return ins[selector].notEmpty();
   endmethod
endmodule

module mkUnfunnelPipes#(Vector#(m, PipeOut#(a)) ins)(Vector#(mk, PipeOut#(a)))
   provisos (Mul#(m, k, mk),
	     Log#(k,ksz),
	     Bits#(a,asz));
   
   let m = fromInteger(valueOf(m));
   let k = fromInteger(valueOf(k));
   let mk = fromInteger(valueOf(mk));
   
   Vector#(mk, FIFOF#(a)) fifos <- replicateM(mkFIFOF);
   for (Integer i = 0; i < m; i = i + 1) begin
      Reg#(Bit#(TAdd#(1,ksz))) which <- mkReg(0);
      rule consumer;
	 let index = which + fromInteger(i)*k;
	 let v <- toGet(ins[i]).get();
	 fifos[index].enq(v);
	 which <= (which + 1) % k;
      endrule
   end
   return map(toPipeOut, fifos);
endmodule

module mkRepeat#(UInt#(n) repetitions, PipeOut#(a) inpipe)(PipeOut#(a));
   Reg#(UInt#(n)) count <- mkReg(0);
   method first = inpipe.first;
   method Action deq();
      let c = count + 1;
      if (count == (repetitions - 1)) begin
	 c = 0;
	 inpipe.deq();
      end
      count <= c;
   endmethod
   method notEmpty = inpipe.notEmpty;
endmodule

module mkForkVectorPipelined#(PipeOut#(a) inpipe)(UnFunnelPipe#(1,k,a,bpc))
   provisos ( Bits#(a,a__)
	     ,Add#(1,b__,k)
	     ,Log#(k,logk)
	     ,Div#(logk,bpc,stages));
   Vector#(k, FIFOF#(a))  buffs = newVector;
   Vector#(k, PipeOut#(a)) infs = cons(inpipe,replicate(?));
   for(Integer j = 0; j < valueOf(stages); j=j+1)begin
      for(Integer i = 0; i < 2**((j+1)*valueOf(bpc)) && i < valueOf(k); i=i+1) 
	 buffs[i] <- mkFIFOF;
      rule xfer;
      	 for(Integer i = 0; i < 2**(j*valueOf(bpc)) && i < valueOf(k); i=i+1) begin
      	    for(Integer l = 0; l < 2**valueOf(bpc) && l < valueOf(k); l=l+1) begin
	       Integer idx = (i*(2**valueOf(bpc)))+l;
      	       if (idx < valueOf(k)) 
		  buffs[idx].enq(infs[i].first);
      	    end
      	    infs[i].deq;
      	 end
      endrule
      infs = map(toPipeOut, buffs);
   end
   return infs;
endmodule

module mkForkVector#(PipeOut#(a) inpipe)(Vector#(n, PipeOut#(a)))
   provisos (Bits#(a, asz));
   Vector#(n, FIFOF#(a)) fifos <- replicateM(mkFIFOF());
   rule forkelts;
      let v = inpipe.first();
      inpipe.deq;
      for (Integer i = 0; i < valueOf(n); i = i + 1) begin
	 fifos[i].enq(v);
      end
   endrule
   return map(toPipeOut, fifos);
endmodule

module mkSizedForkVector#(Integer size, PipeOut#(a) inpipe)(Vector#(n, PipeOut#(a)))
   provisos (Bits#(a, asz));
   Vector#(n, FIFOF#(a)) fifos <- replicateM(mkSizedFIFOF(size));
   rule forkelts;
      let v = inpipe.first();
      inpipe.deq;
      for (Integer i = 0; i < valueOf(n); i = i + 1) begin
	 fifos[i].enq(v);
      end
   endrule
   return map(toPipeOut, fifos);
endmodule
   


module mkJoin#(function c f(a av, b bv), PipeOut#(a) apipe, PipeOut#(b) bpipe)(PipeOut#(c));
   method c first();
      let av = apipe.first();
      let bv = bpipe.first();
      return f(av, bv);
   endmethod
   method Action deq();
      apipe.deq();
      bpipe.deq();
   endmethod
   method Bool notEmpty();
      return apipe.notEmpty() && bpipe.notEmpty();
   endmethod
endmodule

module mkJoinBuffered#(function c f(a av, b bv), PipeOut#(a) apipe, PipeOut#(b) bpipe)(PipeOut#(c))
   provisos (Bits#(c, csz));
   FIFOF#(c) joinFifo <- mkFIFOF();
   rule joinrule;
      let av <- toGet(apipe).get();
      let bv <- toGet(bpipe).get();
      joinFifo.enq(f(av, bv));
   endrule
   return toPipeOut(joinFifo);
endmodule

module mkJoinVector#(function b f(Vector#(n, a) av), Vector#(n, PipeOut#(a)) apipes)(PipeOut#(b))
   provisos (Bits#(Vector#(n,a),vasz));
   method b first();
      function a getfirst(PipeOut#(a) pipein); return pipein.first(); endfunction
      Vector#(n,a) vec = map(getfirst, apipes);
      return f(vec);
   endmethod
   method Action deq();
      function a getfirst(PipeOut#(a) pipein); return pipein.first(); endfunction
      for (Integer i = 0; i < valueOf(n); i = i + 1)
	 apipes[i].deq();
   endmethod
   method Bool notEmpty();
      function Bool myand(Bool a, Bool b); return a && b; endfunction
      return foldl(myand, True, map(pipeOutNotEmpty, apipes));
   endmethod
endmodule

function PipeOut#(b) mapPipe(function b f(a av), PipeOut#(a) apipe);
   return (interface PipeOut#(b);
      method b first();
	 let av = apipe.first();
	 return f(av);
      endmethod
      method Action deq();
	 apipe.deq();
      endmethod
      method Bool notEmpty();
	 return apipe.notEmpty();
      endmethod
      endinterface);
endfunction
   
function PipeIn#(a) mapPipeIn(function b f(a av), PipeIn#(b) apipe);
   return (interface PipeIn#(b);
	      method Action enq(a v);
		 apipe.enq(f(v));
	      endmethod
	      method Bool notFull();
		 return apipe.notFull();
	      endmethod
	   endinterface);
endfunction

// buffered version of mapPipe
module mkMapPipe#(function b f(a av), PipeOut#(a) apipe)(PipeOut#(b))
   provisos (Bits#(b,bsz));
   FIFOF#(b) fifo <- mkFIFOF();
   rule compute;
      let v <- toGet(apipe).get();
      fifo.enq(f(v));
   endrule
   return toPipeOut(fifo);
endmodule

typedef (function tb f(ta x)) CombinePipe#(type ta, type tb);

typeclass ReducePipe#( numeric type n, type a);
   module  mkReducePipe#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
			 PipeOut#(Vector#(n,a)) inpipe)
			 (PipeOut#(a) ifc);
   module  mkReducePipes#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
			  Vector#(n,PipeOut#(a)) inpipe)
			  (PipeOut#(a) ifc);
endtypeclass
instance ReducePipe#(1, a);
   module  mkReducePipe#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
				 PipeOut#(Vector#(1,a)) inpipe)
				 (PipeOut#(a) ifc);
      let pipe = mapPipe(head, inpipe);
      return pipe;
   endmodule
   module  mkReducePipes#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
				  Vector#(1,PipeOut#(a)) inpipes)
				  (PipeOut#(a) ifc);
      return inpipes[0];
   endmodule
endinstance
instance ReducePipe#(2, a)
   provisos(Bits#(a,a__));
   module  mkReducePipe#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
			 PipeOut#(Vector#(2,a)) inpipe)
			(PipeOut#(a) ifc);
      function a foo(Vector#(2,a) invec); 
	 return combinepipe(tuple2(invec[0], invec[1])); 
      endfunction
      let pipe <- mkMapPipe(foo, inpipe);
      return pipe;
   endmodule
   module  mkReducePipes#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
			  Vector#(2,PipeOut#(a)) inpipes)
			  (PipeOut#(a) ifc);
      function a foo(Tuple2#(a,a) invec); 
	 return combinepipe(invec);
      endfunction
      let pipe <- mkMapPipe(foo, zipPipeOut(inpipes[0], inpipes[1]));
      return pipe;
   endmodule
endinstance

instance ReducePipe#(n, a)
   provisos (Add#(TDiv#(n,2), a__, n),
	     Bits#(Vector#(TDiv#(n,2), a), b__),
	     ReducePipe#(TDiv#(n,2),a),
	     ReducePipe#(TSub#(n, TDiv#(n, 2)), a)
      );
   module  mkReducePipe#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
			 PipeOut#(Vector#(n,a)) inpipe)
			(PipeOut#(a) ifc);
      FIFOF#(Vector#(TDiv#(n,2),a)) infifo0 <- mkFIFOF;
      FIFOF#(Vector#(TSub#(n,TDiv#(n,2)),a)) infifo1 <- mkFIFOF;
      rule splitinput;
	 let v = inpipe.first();
	 inpipe.deq();
	 infifo0.enq(takeAt(0, v));
	 infifo1.enq(takeAt(valueOf(TDiv#(n,2)), v));
      endrule
      PipeOut#(Vector#(TDiv#(n,2),a)) inpipe0 = toPipeOut(infifo0);
      PipeOut#(Vector#(TSub#(n,TDiv#(n,2)),a)) inpipe1 = toPipeOut(infifo1);
   
      PipeOut#(a) p0 <- mkReducePipe(combinepipe, inpipe0);
      PipeOut#(a) p1 <- mkReducePipe(combinepipe, inpipe1);

      function a foo(Tuple2#(a,a) invec); 
	 return combinepipe(invec);
      endfunction
      let pipe <- mkMapPipe(foo,zipPipeOut(p0, p1));
      return pipe;
   endmodule

   module  mkReducePipes#(CombinePipe#(Tuple2#(a,a), a) combinepipe,
			  Vector#(n, PipeOut#(a)) inpipes)
			 (PipeOut#(a) ifc);
      Vector#(TDiv#(n,2),PipeOut#(a)) pipes0 = takeAt(0, inpipes);
      Vector#(TSub#(n,TDiv#(n,2)),PipeOut#(a)) pipes1 = takeAt(valueOf(TDiv#(n,2)), inpipes);

      PipeOut#(a) p0 <- mkReducePipes(combinepipe, pipes0);
      PipeOut#(a) p1 <- mkReducePipes(combinepipe, pipes1);

      function a foo(Tuple2#(a,a) invec); 
	 return combinepipe(invec);
      endfunction
      let pipe <- mkMapPipe(foo,zipPipeOut(p0, p1));
      return pipe;
   endmodule
endinstance

interface FirstLastPipe#(type a);
   interface PipeOut#(Tuple2#(Bool,Bool)) pipe;
   method Action start(a count);
endinterface

module mkFirstLastPipe(FirstLastPipe#(a))
   provisos (Bits#(a,asz), Ord#(a), Arith#(a), Eq#(a));
   Reg#(a) countReg <- mkReg(0);
   Reg#(Bool) firstReg <- mkReg(False);
   Reg#(Bool) lastReg <- mkReg(False);
   interface PipeOut pipe;
      method Tuple2#(Bool, Bool) first();
	 return tuple2(firstReg, lastReg);
      endmethod
      method Action deq() if (countReg > 0);
	 firstReg <= False;
	 let c = countReg - 1;
	 if (c == 1)
	    lastReg <= True;
	 countReg <= c;
      endmethod
      method Bool notEmpty();
	 return countReg > 0;
      endmethod
   endinterface
   method Action start(a count) if (countReg == 0);
      firstReg <= True;
      lastReg <= False;
      countReg <= count;
   endmethod
endmodule

typedef struct {
   a xbase;
   a xlimit;
   a xstep;
} IteratorConfig#(type a) deriving (Bits, FShow);

typedef struct {
   a value;
   Bool first;
   Bool last;
   b ctxt;
} IteratorValue#(type a, type b) deriving (Bits);
function a iteratorValueData(IteratorValue#(a,b) ivd); return ivd.value; endfunction

interface IteratorWithContext#(type a, type c);
   interface PipeOut#(a) pipe;
   interface PipeOut#(IteratorValue#(a,c)) ivpipe;
   method a count();
   method Bool isFirst();
   method Bool isLast();
   method Action start(IteratorConfig#(a) cfg, c ctxt);
   method c ctxt();
endinterface

interface IteratorIfc#(type a);
   interface PipeOut#(a) pipe;
   interface PipeOut#(IteratorValue#(a,void)) ivpipe;
   method a count();
   method Bool isFirst();
   method Bool isLast();
   method Action start(IteratorConfig#(a) cfg);
endinterface

module mkIteratorWithContext(IteratorWithContext#(a,c)) provisos (Arith#(a), Bits#(a,awidth), Eq#(a), Ord#(a), Bits#(c,cwidth));
   Reg#(c) ctxtReg <- mkReg(unpack(0));
   Reg#(a) countReg <- mkReg(0);
   Reg#(a) x <- mkReg(0);
   Reg#(a) xbase <- mkReg(0);
   Reg#(a) xstep <- mkReg(0);
   // inclusive limit
   Reg#(a) xlimit <- mkReg(0);
   Reg#(a) xdown <- mkReg(0);
   Reg#(Bool) first <- mkReg(False);
   Reg#(Bool) last <- mkReg(False);
   Reg#(Bool) idle <- mkReg(True);
   Bool verbose = False;
   interface PipeOut pipe;
      method a first();
	 return x;
      endmethod
      method Action deq if (!idle);
	 let next_x = x + xstep;
	 countReg <= countReg + 1;
	 x <= x + xstep;
	 first <= False;
	 last <= (next_x+xstep >= xlimit);
	 idle <= last;
      endmethod
      method Bool notEmpty();
	 return (x < xlimit);
      endmethod
   endinterface
   interface PipeOut ivpipe;
      method IteratorValue#(a,c) first();
	 return IteratorValue { value: x, first: first, last: last, ctxt: ctxtReg };
      endmethod
      method Action deq if (!idle);
	 let next_x = x + xstep;
	 countReg <= countReg + 1;
	 x <= x + xstep;
	 xdown <= xdown - xstep;
	 first <= False;
	 last <= (xdown <= xstep);//(next_x+xstep >= xlimit);
	 idle <= last;
      endmethod
      method Bool notEmpty();
	 return (x < xlimit);
      endmethod
   endinterface
   method Action start(IteratorConfig#(a) cfg, c ctxt) if (idle);
      countReg <= 0;
      x <= cfg.xbase;
      xbase <= cfg.xbase;
      xstep <= cfg.xstep;
      xlimit <= cfg.xlimit;
      xdown <= cfg.xlimit - cfg.xbase;

      first <= True;
      last <= (cfg.xbase+cfg.xstep >= cfg.xlimit);
      idle <= False;
      ctxtReg <= ctxt;
      if (verbose) $display("mkIterator xbase=%d xstep=%d xlimit=%d last=%d notEmpty=%d", cfg.xbase, cfg.xstep, cfg.xlimit, (cfg.xbase+cfg.xstep >= cfg.xlimit),
	 (cfg.xbase < cfg.xlimit));
   endmethod
   method Bool isFirst() = first;
   method Bool isLast() = last;
   method a count() = countReg;
   method c ctxt() = ctxtReg;
endmodule: mkIteratorWithContext

module mkIterator(IteratorIfc#(a)) provisos (Arith#(a), Bits#(a,awidth), Eq#(a), Ord#(a));
   IteratorWithContext#(a,void) iter <- mkIteratorWithContext();
   interface PipeOut pipe = iter.pipe;
   interface PipeOut ivpipe = iter.ivpipe;
   method Action start(IteratorConfig#(a) cfg);
      iter.start(cfg, ?);
   endmethod
   method a count() = iter.count();
   method isFirst = iter.isFirst;
   method isLast = iter.isLast;
endmodule

typedef struct {
   a xbase;
   a xlimit;
   a xstep;
   a ybase;
   a ylimit;
   a ystep;
} XYIteratorConfig#(type a) deriving (Bits, FShow);

interface XYIteratorIfc#(type a);
   interface PipeOut#(Tuple2#(a,a)) pipe;
   method Bool isFirst();
   method Bool isLast();
   method Action start(XYIteratorConfig#(a) cfg);
   method Action display();
endinterface

module mkXYIterator(XYIteratorIfc#(a)) provisos (Arith#(a), Bits#(a,awidth), Eq#(a), Ord#(a));
   Reg#(a) x <- mkReg(0);
   Reg#(a) y <- mkReg(0);
   Reg#(a) xbase <- mkReg(0);
   Reg#(a) ybase <- mkReg(0);
   Reg#(a) xstep <- mkReg(0);
   Reg#(a) ystep <- mkReg(0);
   Reg#(a) xlimit <- mkReg(0);
   Reg#(a) ylimit <- mkReg(0);
   
   Reg#(Bool) isFirstReg <- mkReg(False);
   Reg#(Bool) isLastReg <- mkReg(False);

   let guard = x < xlimit && y < ylimit;
   
   interface PipeOut pipe;
      method Tuple2#(a,a) first() if (guard);
	 return tuple2(x,y);
      endmethod
      method Action deq if (guard);
	 let newx = x;
	 let newy = y+ystep;
	 if (newy >= ylimit && x < xlimit) begin
	    newy = ybase;
	    newx = newx + xstep;
	 end
	 x <= newx;
	 y <= newy;
	 isLastReg <= (newx+xstep >= xlimit && newy+ystep >= ylimit);
	 isFirstReg <= False;
      endmethod
      method Bool notEmpty();
	 return guard;
      endmethod
   endinterface
   method Action start(XYIteratorConfig#(a) cfg) if (!guard);
      x <= cfg.xbase;
      y <= cfg.ybase;
      xbase <= cfg.xbase;
      ybase <= cfg.ybase;
      xstep <= cfg.xstep;
      ystep <= cfg.ystep;
      xlimit <= cfg.xlimit;
      ylimit <= cfg.ylimit;
      isFirstReg <= True;
      isLastReg <= (cfg.xbase+cfg.xstep) > cfg.xlimit && (cfg.ybase+cfg.ystep) > cfg.ylimit;
   endmethod
   method Bool isFirst(); return isFirstReg; endmethod
   method Bool isLast(); return isLastReg; endmethod
   method Action display();
      $display("XYIterator x=%d xlimit=%d y=%d ylimit=%d xstep=%d ystep=%d", x, xlimit, xstep, y, ylimit, ystep);
   endmethod
endmodule: mkXYIterator
