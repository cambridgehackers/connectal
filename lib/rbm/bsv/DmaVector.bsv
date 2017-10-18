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
import Connectable::*;
import GetPut::*;
import ClientServer::*;
import FIFOF::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import Adapter::*;
import BRAM::*;
import Pipe::*;
import RbmTypes::*;
import ConnectalMemTypes::*;

typedef 8 BurstLen;

interface VectorSource#(numeric type dsz, type a);
   interface PipeOut#(a) pipe;
   method Action start(SGLId h, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l);
   method ActionValue#(Bool) finish();
endinterface

module  mkMemReadVectorSource#(MemReadEngineServer#(asz) memreadServer)(VectorSource#(asz, a))
   provisos (Bits#(a,asz),
	     Div#(asz,8,abytes),
	     Log#(abytes,ashift),
	     Mul#(abytes, 8, asz)
	     );
   Bool verbose = False;
   let asz = valueOf(asz);
   let ashift = valueOf(ashift);
   function Bit#(dataWidth) memData_data(MemDataF#(dataWidth) d); return d.data; endfunction

   method Action start(SGLId p, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l);
      if (verbose) $display("mkMemReadVectorSource: start h=%d a=%h l=%h ashift=%d", p, a, l, ashift);
      memreadServer.request.put(MemengineCmd { sglId: p, base: a << ashift, len: truncate(l << ashift), burstLen: (fromInteger(valueOf(BurstLen)) << ashift), tag: 0});
   endmethod
   method ActionValue#(Bool) finish();
      return memreadServer.data.first().last;
   endmethod
   interface PipeOut pipe = mapPipe(unpack, mapPipe(memData_data, memreadServer.data));
endmodule

interface VectorSink#(numeric type dsz, type a);
   interface PipeIn#(a) pipe;
   method Action start(SGLId h, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l);
   method ActionValue#(Bool) finish();
endinterface

module  mkMemWriteVectorSink#(MemWriteEngineServer#(asz) memwriteServer)(VectorSink#(asz, a))
   provisos (Bits#(a,asz),
	     Div#(asz,8,abytes),
	     Log#(abytes,ashift),
	     Mul#(abytes, 8, asz)
	     );
   Bool verbose = False;
   let asz = valueOf(asz);
   let ashift = valueOf(ashift);

   method Action start(SGLId p, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l);
      if (verbose) $display("mkMemWriteVectorSink: start h=%d a=%h l=%h ashift=%d", p, a, l, ashift);
      // I set burstLen==1 so that testmm works for all J,K,N. If we want burst writes we will need to rethink this (mdk)
      let cmd = MemengineCmd { sglId: p, base: a << ashift, len: truncate(l << ashift), burstLen: fromInteger(valueOf(abytes)), tag: 0};
      memwriteServer.request.put(cmd);
      //$display("mkMemWriteVectorSink: %d %d %d %d", cmd.sglId, cmd.base, cmd.len, cmd.burstLen);
   endmethod
   method finish = memwriteServer.done.get;
   interface PipeIn pipe = mapPipeIn(pack, memwriteServer.data);
endmodule
