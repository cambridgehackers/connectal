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
import MIMO::*;
import DefaultValue::*;

interface PipeIn#(type a);
   method Action enq(a v);
   method Bool notFull();
endinterface

interface PipeOut#(type a);
   method a first();
   method Action deq();
   method Bool notEmpty();
endinterface


typeclass ToPipeIn#(type a, type b);
   function PipeIn#(a) toPipeIn(b in);
endtypeclass

typeclass ToPipeOut#(type a, type b);
   function PipeOut#(a) toPipeOut(b in);
endtypeclass

typeclass MkPipeOut#(type a, type b);
   module mkPipeOut#(b in)(PipeOut#(a));
endtypeclass

instance ToPipeIn#(a, FIFOF#(a));
   function PipeIn#(a) toPipeIn(FIFOF#(a) in);
      return (interface PipeIn#(a);
		 method enq = in.enq;
		 method notFull = in.notFull;
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

instance Connectable#(PipeOut#(a),Put#(a));
   module mkConnection#(PipeOut#(a) in, Put#(a) out)(Empty);
      rule connect;
	 let v = in.first;
	 in.deq();
	 out.put(v);
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
	     Bits#(a, asz),
	     Add#(1, b__, asz)
	     );
   let m = fromInteger(valueOf(m));
   let k = fromInteger(valueOf(k));
   let mk = fromInteger(valueOf(mk));

   Vector#(mk, FIFOF#(a)) fifos <- replicateM(mkFIFOF);
   for (Integer i = 0; i < m; i = i + 1) begin
      Reg#(Bit#(asz)) which <- mkReg(0);
      rule consumer;
	 let index = (which << valueOf(ksz)) + fromInteger(i);
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
      function Bool getNotEmpty(PipeOut#(a) pipein); return pipein.notEmpty(); endfunction	 
      function Bool myand(Bool a, Bool b); return a && b; endfunction
      return foldl(myand, True, map(getNotEmpty, apipes));
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

module mkMap#(function b f(a av), PipeOut#(a) apipe)(PipeOut#(b));
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
endmodule

typedef (function Module #(PipeOut #(tb)) mkPipeOut(PipeOut#(ta) ifc)) PipeOutConstructor#(type ta, type tb);

typeclass ReducePipe#( numeric type n, type a);
   module [Module] mkReducePipe (PipeOutConstructor#(Tuple2#(a,a), a) combinepipe,
				 PipeOut#(Vector#(n,a)) inpipe,
				 PipeOut#(a) ifc);
   module [Module] mkReducePipes (PipeOutConstructor#(Tuple2#(a,a), a) combinepipe,
				  Vector#(n,PipeOut#(a)) inpipe,
				  PipeOut#(a) ifc);
endtypeclass
instance ReducePipe#(1, a);
   module [Module] mkReducePipe (PipeOutConstructor#(Tuple2#(a,a), a) combinepipe,
				 PipeOut#(Vector#(1,a)) inpipe,
				 PipeOut#(a) ifc);
      let pipe <- mkMap(head, inpipe);
      return pipe;
   endmodule
endinstance
instance ReducePipe#(2, a);
   module [Module] mkReducePipe (PipeOutConstructor#(Tuple2#(a,a), a) combinepipe,
				 PipeOut#(Vector#(2,a)) inpipe,
				 PipeOut#(a) ifc);
      function Tuple2#(a,a) foo(Vector#(2,a) invec); return tuple2(invec[0], invec[1]); endfunction
      PipeOut#(Tuple2#(a,a)) zippipe <- mkMap(foo, inpipe);
      let pipe <- combinepipe(zippipe);
      return pipe;
   endmodule
   module [Module] mkReducePipes (PipeOutConstructor#(Tuple2#(a,a), a) combinepipe,
				  Vector#(2,PipeOut#(a)) inpipes,
				  PipeOut#(a) ifc);
      PipeOut#(Tuple2#(a,a)) zippipe = (interface PipeOut#(Tuple2#(a,a));
				       method Tuple2#(a,a) first(); return tuple2(inpipes[0].first(), inpipes[1].first()); endmethod
				       method Action deq(); inpipes[0].deq(); inpipes[1].deq(); endmethod
				       method Bool notEmpty(); return inpipes[0].notEmpty && inpipes[1].notEmpty(); endmethod
				       endinterface);
      let pipe <- combinepipe(zippipe);
      return pipe;
   endmodule
endinstance

instance ReducePipe#(n, a)
   provisos (Add#(TDiv#(n,2), a__, n),
	     Bits#(Vector#(TDiv#(n,2), a), b__),
	     ReducePipe#(TDiv#(n,2),a));
   module [Module] mkReducePipe (PipeOutConstructor#(Tuple2#(a,a), a) combinepipe,
				 PipeOut#(Vector#(n,a)) inpipe,
				 PipeOut#(a) ifc);
      FIFOF#(Vector#(TDiv#(n,2),a)) infifo0 <- mkFIFOF;
      FIFOF#(Vector#(TDiv#(n,2),a)) infifo1 <- mkFIFOF;
      rule splitinput;
	 let v = inpipe.first();
	 inpipe.deq();
	 infifo0.enq(takeAt(0, v));
	 infifo1.enq(takeAt(valueOf(TDiv#(n,2)), v));
      endrule
      PipeOut#(Vector#(TDiv#(n,2),a)) inpipe0 = toPipeOut(infifo0);
      PipeOut#(Vector#(TDiv#(n,2),a)) inpipe1 = toPipeOut(infifo1);
   
      PipeOut#(a) p0 <- mkReducePipe(combinepipe, inpipe0);
      PipeOut#(a) p1 <- mkReducePipe(combinepipe, inpipe1);

      PipeOut#(Tuple2#(a,a)) tplpipe = (interface PipeOut;
					method Tuple2#(a,a) first(); return tuple2(p0.first, p1.first); endmethod
					method Action deq();
					   p0.deq();
					   p1.deq();
					endmethod
					method notEmpty(); return p0.notEmpty() && p1.notEmpty(); endmethod
					endinterface);
      PipeOut#(a) outpipe <- combinepipe(tplpipe);
      return outpipe;
   endmodule

   module [Module] mkReducePipes (PipeOutConstructor#(Tuple2#(a,a), a) combinepipe,
				  Vector#(n, PipeOut#(a)) inpipes,
				 PipeOut#(a) ifc);
      Vector#(TDiv#(n,2),PipeOut#(a)) pipes0 = takeAt(0, inpipes);
      Vector#(TDiv#(n,2),PipeOut#(a)) pipes1 = takeAt(valueOf(TDiv#(n,2)), inpipes);

      PipeOut#(a) p0 <- mkReducePipes(combinepipe, pipes0);
      PipeOut#(a) p1 <- mkReducePipes(combinepipe, pipes1);

      PipeOut#(a) outpipe <- combinepipe(zipPipeOut(p0, p1));
      return outpipe;
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
