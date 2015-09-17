// Copyright (c) 2015 The Connectal Project

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
import FIFOF          ::*;

interface MemServer;
   method Action myMethod(Bool rc);
endinterface		

// Warning: "GuardTest.bsv", line 34, column 9: (G0010)
//   Rule "dbgrRule" was treated as more urgent than "toprule". Conflicts:
//     "dbgrRule" cannot fire before "toprule":
//       calls to myFlag.write vs. myFlag.read
//     "toprule" cannot fire before "dbgrRule":
//       calls to myFlag.write vs. myFlag.read
module  mkGuardTestBench(Empty);
   FIFOF#(Bool) fifo <- mkFIFOF1;

   Reg#(Bool) myFlag <- mkReg(False);
   rule dbgrRule if (myFlag);
       myFlag <= False;
   endrule
   rule toprule;
      if (fifo.first && !myFlag)
         myFlag <= fifo.first;
   endrule
endmodule

// this version does not generate the extra warning
module  mkGuardTestBenchNonAgressive(Empty);
   FIFOF#(Bool) fifo <- mkFIFOF1;

   Reg#(Bool) myFlag <- mkReg(False);
   rule dbgrRule if (myFlag);
       myFlag <= False;
   endrule
   rule toprule if (!myFlag);
      if (fifo.first)
         myFlag <= fifo.first;
   endrule
endmodule
