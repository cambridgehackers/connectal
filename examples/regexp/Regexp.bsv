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
import StmtFSM::*;
import ClientServer::*;
import GetPut::*;

import AxiMasterSlave::*;
import MemTypes::*;
import MemreadEngine::*;
import Pipe::*;
import Dma2BRAM::*;
import RegexpEngine::*;

interface RegexpRequest;
   method Action setup(Bit#(32) mapPointer, Bit#(32) map_len);
   method Action search(Bit#(32) haystackPointer, Bit#(32) haystack_len);
endinterface

interface RegexpIndication;
   method Action searchResult(Int#(32) v);
endinterface

interface Regexp#(numeric type busWidth);
   interface RegexpRequest request;
   interface ObjectReadClient#(busWidth) config_read_client;
   interface ObjectReadClient#(busWidth) haystack_read_client;
endinterface

module mkRegexp#(RegexpIndication indication)(Regexp#(64))
   provisos(Log#(`MAX_NUM_STATES,5),
	    Log#(`MAX_NUM_CHARS,5),
	    Div#(64,8,nc),
	    Mul#(nc,8,64)
	    );

   MemreadEngineV#(64, 1, 1) config_re <- mkMemreadEngine;
   MemreadEngineV#(64, 1, 1) haystack_re <- mkMemreadEngine;
   let ree <- mkRegexpEngine(append(config_re.read_servers,haystack_re.read_servers));
   
   rule locr;
      let rv <- toGet(ree.loc).get;
      indication.searchResult(rv);
   endrule
   
   rule doner;
      ree.done.deq;
      indication.searchResult(-1);
   endrule
      
   interface config_read_client = config_re.dmaClient;
   interface haystack_read_client = haystack_re.dmaClient;

   interface RegexpRequest request;
      method Action setup(Bit#(32) pointer, Bit#(32) len);
	 ree.setup.enq(tuple2(pointer,len));
      endmethod
      method Action search(Bit#(32) pointer, Bit#(32) len);
	 ree.search.enq(tuple2(pointer,len));
      endmethod
   endinterface

endmodule

