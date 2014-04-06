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

/*
 * Implementation of:
 *    simple stack for a type
 * 
 * Single cycle push and pop, provided that consecutive pops aren't
 * too far apart
 */

import BRAM::*;

interface StackReg#(numeric type stackSize, type pctype, type argstype, type varstype);
   method Action doreturn();
   method Action docall(pctype jumpto, pctype returnto, argstype args, varstype vars);
   method Action nextpc(pctype jumpto);
   method Bit#(16) setjmp();
   method Action longjump(Bit#(16) where);
   interface Reg#(pctype) pc;
   interface Reg#(argstype) args;
   interface Reg#(varstype) vars;
endinterface

module mkStackReg#(int stackSize, pctype initialpc)(StackReg#(stackSize, pctype, argstype, varstype))
   provisos(Log#(stackSize, addressBits),
      Bits#(pctype, a__),
      Bits#(argstype, b__),
      Bits#(varstype, c__));

   BRAM1Port#(Bit#(addressBits), pctype) pcstack  <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(addressBits), argstype) argsstack  <- mkBRAM1Server(defaultValue);
   BRAM1Port#(Bit#(addressBits), varstype) varsstack  <- mkBRAM1Server(defaultValue);
   Reg#(pctype) pctop <- mkReg(initialpc);
   Reg#(pctype) pcnext <- mkReg(?);
   Reg#(argstype) argstop <- mkReg(?);
   Reg#(argstype) argsnext <- mkReg(?);
   Reg#(varstype) varstop <- mkReg(?);
   Reg#(varstype) varsnext <- mkReg(?);
   Reg#(Bit#(addressBits)) fp <- mkReg(0);
   PulseWire calling <- mkPulseWire();
   PulseWire returning <- mkPulseWire();
   Reg#(Bool) returningd1 <- mkReg(False);

/* The "next" registers are there to compensate for the pipelined reads
 * of the BRAMs.  
 * A return in isolation pops next to top, and then replaces the contents of
 * next the following cycle when the BRAM read completes.
 * In the event that there are multiple returns in consecutive cycles, the
 * first return values are fed from the next registers into top, and the
 * following values are bypassed from the BRAMs direct to TOP.
 * Once return cycles stop happening, the final pending BRAM read data is
 * loaded into next
 * 
 * If a call happens in the cycle after a return, the BRAM read <into> next and
 * the bram write <from> next are both supressed, and next is pushed from top
 * 
 * The wire calling says there is a call in the current cycle. The signal
 * returning says there is a return in the current cycle. The signal returningd1
 * says there was a return in the previous cycle.
 */

/*
   Reg#(Bit#(8)) cyc <- mkReg(0);
   
   rule cc;
      cyc <= cyc + 1;
   endrule
  */ 
   
   /* The pop rules fire exactly when returningd1 is true */
   rule poppc;
     let v = ?;
      //$display("%d poppc (c %d)", cyc, calling);
      v <- pcstack.portA.response.get();
      if (!calling) pcnext <= v;
      if (returning) pctop <= v;
   endrule

   rule popargs;
     let v = ?;
      v <- argsstack.portA.response.get();
      if (!calling) argsnext <= v;
      if (returning) argstop <= v;
   endrule
   
   rule popvars;
     let v = ?;
      v <- varsstack.portA.response.get();
      if (!calling) varsnext <= v;
      if (returning) varstop <= v;
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule returning_delay;
      returningd1 <= returning;
   endrule

   method Action docall(pctype jumpto, pctype returnto, argstype args, varstype vars);
      fp <= min(fp+1, maxBound);
      calling.send();
      //$display("%d docall jumpto %d returnto %d (d1 %d)", cyc, jumpto, returnto, returningd1);
      if (! returningd1) 
	 begin
	    pcstack.portA.request.put(BRAMRequest{write: True, 
	       responseOnWrite: False, 
	       address: fp, datain: pcnext});
	    argsstack.portA.request.put(BRAMRequest{write: True, 
	       responseOnWrite: False, 
	       address: fp, datain: argsnext});
	    varsstack.portA.request.put(BRAMRequest{write: True, 
	       responseOnWrite: False, 
	       address: fp, datain: varsnext});
	 end
      pcnext <= returnto;
      pctop <= jumpto;
      argsnext <= argstop;
      argstop <= args;
      varsnext <= vars;
      varstop <= vars;
   endmethod

   method Action doreturn();
      fp <= max(fp-1, 0);
      returning.send();
      
      pcstack.portA.request.put(BRAMRequest{write: False, 
	 responseOnWrite: False, 
	 address: fp-1, datain: ?});
      argsstack.portA.request.put(BRAMRequest{write: False, 
	 responseOnWrite: False, 
	 address: fp-1, datain: ?});
      varsstack.portA.request.put(BRAMRequest{write: False, 
	 responseOnWrite: False, 
	 address: fp-1, datain: ?});
      //$display("%d doreturn pctop getting %d", cyc, pcnext);
     if (!returningd1)
	begin
	   pctop <= pcnext;
	   argstop <= argsnext;
	   varstop <= varsnext;
	end
   endmethod

   method Action nextpc(pctype jumpto);
      pctop <= jumpto;
   endmethod

   method Bit#(16) setjmp();
      return 0;
   endmethod

   method Action longjump(Bit#(16) where);
   // set fp <= where and pop? something like that
   endmethod

   
interface pc = pctop;
interface args = argstop;
interface vars = varstop;
   
   

endmodule
