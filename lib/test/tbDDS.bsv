/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
import DDS::*;
import FixedPoint::*;
import Pipe::*;

(* synthesize *)
module mkTb(Empty);
   
   DDS dds <- mkDDS();
   
   Reg#(Bit#(1)) started <- mkReg(0);
   Reg#(Bit#(12)) count <- mkReg(0);

   
   rule showoutput;
      DDSOutType y = dds.osc.first();
      $write("%4d ", count);
      $display(fshow(y));
      count <= count + 1;
      dds.osc.deq();
      if (count >= 1032) $finish;
   endrule
   
   rule start (started == 0);
      Int#(10) v = 1;
      FixedPoint#(10,23) pa = fromInt(v);
      dds.setPhaseAdvance(pa);
      started <= 1;
      $display("started");
   endrule
   
 endmodule

