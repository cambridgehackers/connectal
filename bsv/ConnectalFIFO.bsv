
// Copyright (C) 2012

// Arvind <arvind@csail.mit.edu>
// Muralidaran Vijayaraghavan <vmurali@csail.mit.edu>
// Jamey Hicks <jamey@csail.mit.edu> changed interface to FIFOF

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FIFOF::*;
import ConnectalEHR::*;

// This Fifo2 <- mkCFFifo generates a two element FIFO where enq and deq are conflict free
// {notEmpty, first} < deq < clear < canon
// notFull < enq < clear < canon
// deq conflict free with enq

module mkCFFIFOF(FIFOF#(t)) provisos(Bits#(t, tSz));
  Ehr#(3, t) da <- mkEhr(?);
  Ehr#(3, Bool) va <- mkEhr(False);
  Ehr#(3, t) db <- mkEhr(?);
  Ehr#(3, Bool) vb <- mkEhr(False);

  rule canon if(vb[2] && !va[2]);
    da[2] <= db[2];
    va[2] <= True;
    vb[2] <= False;
  endrule

  method Bool notFull = !vb[0];

  method Action enq(t x) if(!vb[0]);
    db[0] <= x;
    vb[0] <= True;
  endmethod

  method Bool notEmpty = va[0];

  method Action deq if (va[0]);
    va[0] <= False;
  endmethod

  method t first if(va[0]);
    return da[0];
  endmethod

  method Action clear;
    vb[1] <= False;
    va[1] <= False;
  endmethod
endmodule

