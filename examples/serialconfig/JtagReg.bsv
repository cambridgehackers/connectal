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

// The Jtag state machine is copied from the Bluespec Small Examples Tap.bsv

interface JtagReg#(type a);
   method Action update();
   method Action capture();
   method Action shift(bit d);
   interface Reg#(a) r;
   interface ReadOnly#(bit) tdo;
endinterface

// can I pass in an initial value for the register?

module mkJtagReg(JtagReg#(a))
   provisos(Bits#(a,asize), Add#(1,__a,asize));
   
   Reg#(a) dreg <- mkReg(?);
   Reg#(a) sreg <- mkReg(?);
   Reg#(bit) oreg <- mkReg(?);
   
   method Action update ();
      dreg <= sreg;
   endmethod

   method Action capture ();
      sreg <= dreg;
   endmethod
   
   method Action shift (bit d);
      Bit#(asize) svalue = pack(sreg);
      svalue = {d, svalue[(valueof(asize)-1):1]};
      sreg <= unpack(svalue);
      oreg <= svalue[0];
   endmethod
   
   interface r = dreg;
   interface tdo = regToReadOnly(oreg);
      
endmodule


module mkReadOnlyJtagReg#(a v)(JtagReg#(a))
   provisos(Bits#(a,asize), Add#(1,__a,asize));
   
   Reg#(a) dreg <- mkReg(v);
   Reg#(a) sreg <- mkReg(?);
   Reg#(bit) oreg <- mkReg(?);
   
   method Action update ();

   endmethod

   method Action capture ();
      sreg <= dreg;
   endmethod
   
   method Action shift (bit d);
      Bit#(asize) svalue = pack(sreg);
      svalue = {d, svalue[(valueof(asize)-1):1]};
      sreg <= unpack(svalue);
      oreg <= svalue[0];
   endmethod
   
   interface r = dreg;
   interface tdo = regToReadOnly(oreg);
      
endmodule
