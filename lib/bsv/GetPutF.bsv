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

import GetPut::*;
import FIFOF::*;
import SpecialFIFOs::*;


interface GetF#(type a);
   method ActionValue#(a) get;
   method Bool notEmpty;
endinterface

interface PutF#(type a);
   method Action put(a v);
   method Bool notFull;
endinterface

interface ServerF#(type req_type, type resp_type);
   interface PutF#(req_type)  request;
   interface GetF#(resp_type) response;
endinterface

typeclass ToGetF#(type a, type b);
   module toGetF#(a x)(GetF#(b));
endtypeclass

typeclass ToPutF#(type a, type b);
   module toPutF#(a x)(PutF#(b));
endtypeclass

instance ToGetF#(Get#(b), b)
   provisos(Bits#(b,__a));
   module toGetF#(Get#(b) g)(GetF#(b));
      let f <- mkPipelineFIFOF;
      rule xfer;
	 let rv <- g.get;
	 f.enq(rv);
      endrule
      method ActionValue#(b) get;
	 f.deq;
	 return f.first;
      endmethod
      method Bool notEmpty;
	 return f.notEmpty;
      endmethod
   endmodule
endinstance

instance ToPutF#(Put#(b), b)
   provisos(Bits#(b,__a));
   module toPutF#(Put#(b) p)(PutF#(b));
      let f <- mkPipelineFIFOF;
      rule xfer;
	 p.put(f.first);
	 f.deq;
      endrule
      method Action put(b x);
	 f.enq(x);
      endmethod
      method Bool notFull;
	 return f.notFull;
      endmethod
      endmodule
endinstance

