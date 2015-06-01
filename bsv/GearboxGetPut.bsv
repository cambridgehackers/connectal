// Copyright (c) 2015 Connectal Project.

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

import Vector::*;
import BuildVector::*;
import GetPut::*;
import Gearbox::*;

instance ToGet #(Gearbox #(m, 1, a), a);
   function Get #(a) toGet (Gearbox #(m, 1, a) gb);
      return (interface Get;
                 method ActionValue #(a) get ();
                    gb.deq ();
                    return gb.first ()[0];
                 endmethod
              endinterface);
   endfunction
endinstance

instance ToGet #(Gearbox #(m, n, a), Vector#(n, a));
   function Get #(Vector#(n,a)) toGet (Gearbox #(m, n, a) gb);
      return (interface Get;
                 method ActionValue #(Vector#(n,a)) get ();
                    gb.deq ();
                    return gb.first ();
                 endmethod
              endinterface);
   endfunction
endinstance

instance ToPut #(Gearbox #(m, n, a), Vector#(m, a));
   function Put #(Vector#(m,a)) toPut (Gearbox #(m,n,a) gb);
      return (interface Put;
		 method Action put(Vector#(m,a) v);
                    gb.enq (v);
                 endmethod
              endinterface);
   endfunction
endinstance

instance ToPut #(Gearbox #(1, n, a), a);
   function Put #(a) toPut (Gearbox #(1,n,a) gb);
      return (interface Put;
		 method Action put(a v);
                    gb.enq (vec(v));
                 endmethod
              endinterface);
   endfunction
endinstance
