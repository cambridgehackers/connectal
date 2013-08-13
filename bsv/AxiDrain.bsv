// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

import AxiClientServer::*;

interface Axi3ClientDrain#(type busWidth, type busWidthBytes, type idWidth);
   interface Reg#(Bool) enabled;
   interface Axi3Client#(busWidth, busWidthBytes, idWidth) m_axi;
endinterface

module mkAxiClientDrain(Axi3ClientDrain#(busWidth, busWidthBytes, idWidth));
   Reg#(Bool) enabledReg <- mkReg(False);
   interface Reg enabled = enabledReg;
   interface Axi3Client m_axi;
      interface Axi3ReadClient read;
	 method ActionValue#(Axi3ReadRequest#(idWidth)) address() if (False);
	    return ?;
	 endmethod
	 method Action data(Axi3ReadResponse#(busWidth,idWidth) __x) if (enabledReg);
	    noAction;
	 endmethod
      endinterface
      interface Axi3WriteClient write;
	 method ActionValue#(Axi3WriteRequest#(idWidth)) address() if (False);
	    return ?;
	 endmethod
	 method ActionValue#(Axi3WriteData#(busWidth, busWidthBytes, idWidth)) data() if (False);
	    return ?;
	 endmethod
	 method Action response(Axi3WriteResponse#(id) resp) if (enabledReg);
	    noAction;
	 endmethod
      endinterface
   endinterface
endmodule
