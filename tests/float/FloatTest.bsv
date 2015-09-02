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
import FloatingPoint::*;
import StmtFSM::*;
import FShow::*;

module mkFloatTestBench(Empty);
   let once <- mkOnce(action
      Real re = 3.14159;
      $display("Real 0x%x %f", fromReal(re), re);
      //not supported: $display(fshow(re));
      Float fl = 3.14159;
      //not supported: $display("Float 0x%x %f", pack(fl), $bitstoreal(pack(fl)));
      $display("Float 0x%x %f", pack(fl), fl);
      $display(fshow(fl));
      Double doub = 3.14159;
      $display("Double 0x%x %f", pack(doub), $bitstoreal(pack(doub)));
      $display(fshow(doub));
      $finish;
      endaction);

   rule foobar;
      once.start();
   endrule

endmodule
