//----------------------------------------------------------------------//
// The MIT License 
// 
// Copyright (c) 2008 Myron King, Nirav Dave
// 
// Permission is hereby granted, free of charge, to any person 
// obtaining a copy of this software and associated documentation 
// files (the "Software"), to deal in the Software without 
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//----------------------------------------------------------------------//

//
// Neither of these two modules (mkEHR or mkEHRF) should be used
// without being enclosed immediately in a synthesize boundry.
// This is due to bug in the Bluespec compiler which really
// screws things up.  Finding this out was painful.  Avoid the
// pain and follow this warning.  (I'm not sure if this is still
// the case (mdk))
//
// Second point: These two EHR implementations are close to what
// Dan Rosenband outlined in his thesis.  What they lack is
// scheduling constraints between read/write pairs.  That is to
// say that read_1 and write_1 are conflict free whereas they
// should be FORCED to schedule read_1 < write_1 ...

import Vector ::*;
import RWire  ::*;
import Probe  ::*;

typedef  Vector#(n_sz, Reg#(alpha)) EHR#(type n_sz, type alpha);

/*********************************************************************/
// mkVirtualReg adds one level of ephemeralness to 'base'.  'state'
// is the concrete interface underlying the virtual register (the 
// register itself).  With state and base as input, mkVirtualReg 
// connects them with Rwires and probes so as to enforce the proper 
// rule scheduling and behavior:
//             ... < read_n < write_n < read_n+1 < write_n+1 < ...
/*********************************************************************/

module mkVirtualReg#(Reg#(alpha) state, Reg#(alpha) base) 
   (Tuple2#(Reg#(alpha), Reg#(alpha))) provisos(Bits#(alpha,asz));

   // enforce ordering and data forewarding using wires and probes
   RWire#(alpha) w  <- mkRWire(); 
   Probe#(alpha) probe <- mkProbe; 

   Reg#(alpha) i0 = interface Reg
		       method _read();
			  return base._read();
                       endmethod
		       method Action _write(x);
			  w.wset(x);
			  probe <= base._read();
                       endmethod
		    endinterface;

   Reg#(alpha) i1 = interface Reg
		       method _read() = fromMaybe(base._read, w.wget());
                       method _write(x) = noAction; // never used
		    endinterface;   

   return (tuple2(i0,i1));

endmodule

/*********************************************************************/
// Creates an EHR module by layering virtual registers
// .idx[i] holds read_i and write_i methods.  reg.read_n
// is expressec as reg[n]._read();
/*********************************************************************/

module mkEHRF#(alpha init)(EHR#(n,alpha)) provisos(Bits#(alpha, asz),
						   Add#(li, 1, n));

   Reg#(alpha) r <- mkReg(init);

   Vector#(n,Reg#(alpha)) vidx = newVector();

   // 'old' is a placeholder which also ensures that the last-written value 
   // won't get dropped since r and old are both the initial register during 
   // the first iteration of the 'for' loop.
   Reg #(alpha) old = r;
   Tuple2#(Reg#(alpha),Reg#(alpha)) tinf;
   
   // make interfaces
   for(Integer i = 0; i < valueOf(n); i = i + 1)
      begin
	 tinf <- mkVirtualReg(r,old);
	 vidx[i] = tinf.fst();
	 old = tinf.snd();
      end   
   
   rule do_stuff(True);
      r <= tinf.snd._read();
   endrule
   
   return vidx;      

endmodule

/*********************************************************************/
// alternate implementation, not quite as cool as the functional 
// version, but less code and possibly easier to understand
/*********************************************************************/

module mkEHR#(alpha init) (EHR#(n,alpha)) provisos(Bits#(alpha, asz),
						   Add#(li, 1, n));
   
   Reg#(alpha)  r <- mkReg(init);
   Vector#(n, RWire#(alpha)) wires  <- replicateM(mkRWire);
   Vector#(n, RWire#(alpha)) probes <- replicateM(mkRWire);
   Vector#(n, Reg#(alpha)) vidx = newVector();
   Vector#(n, alpha) chain = newVector();
   
   for(Integer i = 0; i < valueOf(n); i = i + 1)
      begin
	 if(i==0) chain[i] = r;
	 else chain[i] = fromMaybe(chain[i-1], wires[i-1].wget());
      end
   
   for(Integer j = 0; j < valueOf(n); j = j + 1)
      begin
	 vidx[j] = interface Reg
		      method _read();
			 return chain[j];
		      endmethod
		      method Action _write(x);
			 wires[j].wset(x);
			 probes[j].wset(chain[j]);
		      endmethod
		   endinterface;
      end
   
   
   (*fire_when_enabled, no_implicit_conditions *)
   rule do_stuff(True);
      r <= fromMaybe(chain[valueOf(li)], wires[valueOf(li)].wget());
   endrule
   
   return  vidx;
   
endmodule

interface EHR2BSV#(type t);
   interface Reg#(t) r1;
   interface Reg#(t) r2;
endinterface

(* synthesize *)
module mkEHR2BSV (EHR2BSV#(Bit#(32)));
   EHR#(2,Bit#(32)) ehr <- mkEHR(0);
   interface r1 = ehr[0];
   interface r2 = ehr[1];
endmodule
