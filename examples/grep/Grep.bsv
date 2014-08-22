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

import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;
import BRAM::*;
import Gearbox::*;

import AxiMasterSlave::*;
import MemTypes::*;
import MPEngine::*;
import MemreadEngine::*;
import Pipe::*;

interface GrepRequest;
   method Action setup(Bit#(32) mapPointer, Bit#(32) map_len);
   method Action search(Bit#(32) haystackPointer, Bit#(32) haystack_len, Bit#(32) iter_cnt);
endinterface

interface GrepIndication;
   method Action searchResult(Int#(32) v);
   method Action setupComplete();
endinterface

interface Grep#(numeric type p, numeric type busWidth);
   interface GrepRequest request;
   interface ObjectReadClient#(busWidth) config_read_client;
   interface ObjectReadClient#(busWidth) haystack_read_client;
endinterface

module mkGrep#(GrepIndication indication)(Grep#(p,busWidth))
   provisos(Add#(a__, 8, busWidth),
	    Div#(busWidth,8,nc),
	    Mul#(nc,8,busWidth));
   

   let verbose = False;
   MemreadEngineV#(busWidth, 1, 1) config_re <- mkMemreadEngine;
   MemreadEngineV#(busWidth, 1, 1) haystack_re <- mkMemreadEngine;
	          
   interface GrepRequest request;
      method Action setup(Bit#(32) pointer, Bit#(32) len);
      endmethod
      method Action search(Bit#(32) haystack_pointer, Bit#(32) haystack_len, Bit#(32) iter_cnt);
      endmethod
   endinterface
   interface config_read_client = config_re.dmaClient;
   interface haystack_read_client = haystack_re.dmaClient;
endmodule


