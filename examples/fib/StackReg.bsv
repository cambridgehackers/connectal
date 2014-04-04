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
   method Action docall(pctype jumpto, pctype returnto, argtype args);
   method Action nextpc(pctype jumpto);
   method Bit#(16) setjmp();
   method Action longjump(Bit#(16) where);
   interface Reg#(pctype) pc;
   interface Reg#(argstype) args;
   interface Reg#(varstype) vars;
endinterface

module mkStackReg#(int stackSize, pctype initialpc)(StackReg#(stackSize, pctype, argstype, varstype))
   provisos(Log#(stackSize, addressBits),
      Literal#(pctype),
      Literal#(argstype),
      Literal#(varstype),
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
   
   rule poppc;
     let v = ?;
      v <- pcstack.portA.response.get();
      pcnext <= v;
   endrule

   rule popargs;
     let v = ?;
      v <- argsstack.portA.response.get();
      argsnext <= v;
   endrule
   
   rule popvars;
     let v = ?;
      v <- varsstack.portA.response.get();
      varsnext <= v;
   endrule


   method Action docall(pctype jumpto, pctype returnto, argtype args);
      fp <= min(fp+1, maxBound);
      pcstack.portA.request.put(BRAMRequest{write: True, 
	 responseOnWrite: False, 
	 address: fp, datain: pcnext});
      argsstack.portA.request.put(BRAMRequest{write: True, 
	 responseOnWrite: False, 
	 address: fp, datain: argsnext});
      varsstack.portA.request.put(BRAMRequest{write: True, 
	 responseOnWrite: False, 
	 address: fp, datain: varsnext});
      pcnext <= returnto;
      pctop <= jumpto;
      argsnext <= argstop;
      varsnext <= varstop;
   endmethod

   method Action doreturn();
      fp <= max(fp-1, 0);
      pcstack.portA.request.put(BRAMRequest{write: False, 
	 responseOnWrite: False, 
	 address: fp-1, datain: 0});
      argsstack.portA.request.put(BRAMRequest{write: False, 
	 responseOnWrite: False, 
	 address: fp-1, datain: 0});
      varsstack.portA.request.put(BRAMRequest{write: False, 
	 responseOnWrite: False, 
	 address: fp-1, datain: 0});
      pctop <= pcnext;
      argstop <= argsnext;
      varstop <= varsnext;
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
