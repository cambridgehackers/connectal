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
import PortalMemory::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import Adapter::*;
import BRAM::*;
import Pipe::*;
import RbmTypes::*;
import MemTypes::*;

interface VectorSource#(numeric type dsz, type a);
   interface PipeOut#(a) pipe;
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
   method ActionValue#(Bool) finish();
endinterface

function PipeOut#(dtype) vectorSourcePipe(VectorSource#(dsz,dtype) vs); return vs.pipe; endfunction

interface DmaVectorSource#(numeric type dsz, type a);
   interface ObjectReadClient#(dsz) dmaClient;
   interface VectorSource#(dsz, a) vector;
endinterface

function ObjectReadClient#(asz) getSourceReadClient(DmaVectorSource#(asz,a) s); return s.dmaClient; endfunction
function ObjectWriteClient#(asz) getSinkWriteClient(DmaVectorSink#(asz,a) s); return s.dmaClient; endfunction
function VectorSource#(dsz, dtype) dmaVectorSourceVector(DmaVectorSource#(dsz,dtype) dmavs); return dmavs.vector; endfunction

module [Module] mkMemreadVectorSource#(Server#(MemengineCmd,Bool) memreadEngine, PipeOut#(Bit#(asz)) pipeOut)(VectorSource#(asz, a))
   provisos (Bits#(a,asz),
	     Div#(asz,8,abytes),
	     Log#(abytes,ashift),
	     Mul#(abytes, 8, asz)
	     );
   Bool verbose = False;
   let asz = valueOf(asz);
   let ashift = valueOf(ashift);
   method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
      if (verbose) $display("VectorSource.start h=%d a=%h l=%h ashift=%d", p, a, l, ashift);
      memreadEngine.request.put(MemengineCmd { pointer: p, base: a << ashift, len: truncate(l << ashift), burstLen: (fromInteger(valueOf(BurstLen)) << ashift) });
   endmethod
   method finish = memreadEngine.response.get;
   interface PipeOut pipe = mapPipe(unpack, pipeOut);
endmodule

module [Module] mkDmaVectorSource(DmaVectorSource#(asz, a))
   provisos (Bits#(a,asz),
	     Div#(asz,8,abytes),
	     Log#(abytes,ashift),
	     Mul#(abytes, 8, asz)
	     );

   Bool verbose = False;

   let asz = valueOf(asz);
   let abytes = valueOf(abytes);
   let ashift = valueOf(ashift);

   MemreadEngine#(asz,2) memreadEngine <- mkMemreadEngine;

   interface ObjectReadClient dmaClient = memreadEngine.dmaClient;
   interface VectorSource vector;
      method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
	 if (verbose) $display("DmaVectorSource.start h=%d a=%h l=%h ashift=%d", p, a, l, ashift);
         memreadEngine.readServers[0].request.put(MemengineCmd{pointer:p, base:a << ashift, len:truncate(l << ashift), burstLen:(fromInteger(valueOf(BurstLen)) << ashift)});
      endmethod
      method ActionValue#(Bool) finish();
	 let b <- memreadEngine.readServers[0].response.get;
	 return b;
      endmethod
      interface PipeOut pipe;
	 method first();
	    return unpack(memreadEngine.dataPipes[0].first);
	 endmethod
	 method Action deq();
	    if (verbose) $display("ObjectReadClient pipe.deq() data=%h", memreadEngine.dataPipes[0].first);
	    memreadEngine.dataPipes[0].deq;
	 endmethod
	 method notEmpty = memreadEngine.dataPipes[0].notEmpty;
      endinterface
   endinterface
endmodule

interface VectorSink#(numeric type dsz, type a);
   interface PipeIn#(a) pipe;
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
   method ActionValue#(Bool) finish();
endinterface
interface DmaVectorSink#(numeric type dsz, type a);
   interface ObjectWriteClient#(dsz) dmaClient;
   interface VectorSink#(dsz, a) vector;
endinterface

module [Module] mkMemwriteVectorSink#(Server#(MemengineCmd,Bool) memwriteEngine, PipeIn#(Bit#(asz)) pipeIn)(VectorSink#(asz, a))
   provisos (Bits#(a,asz),
	     Div#(asz,8,abytes),
	     Log#(abytes,ashift),
	     Mul#(abytes, 8, asz)
	     );
   Bool verbose = False;
   let asz = valueOf(asz);
   let ashift = valueOf(ashift);
   method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
      if (verbose) $display("VectorSink.start h=%d a=%h l=%h ashift=%d", p, a, l, ashift);
      // this is really shitty.  I set burstLen so that testmm works, but I'm not sure if this is generally usable anymore (mdk)
      memwriteEngine.request.put(MemengineCmd { pointer: p, base: a << ashift, len: truncate(l << ashift), burstLen: fromInteger(valueOf(abytes)) });
   endmethod
   method finish = memwriteEngine.response.get;
   interface PipeIn pipe = mapPipeIn(pack, pipeIn);
endmodule

module [Module] mkDmaVectorSink#(PipeOut#(a) pipe_in)(DmaVectorSink#(asz, a))
   provisos (Bits#(a,asz),
	     Div#(asz,8,abytes),
	     Log#(abytes,ashift),
	     Add#(1, a__, asz),
	     Mul#(abytes,8,asz));

   let asz = valueOf(asz);
   let abytes = valueOf(abytes);
   let ashift = valueOf(ashift);

   Bool verbose = False;
      
   MemwriteEngine#(asz,2) memwriteEngine <- mkMemwriteEngine;

   rule connect_pipes;
      let v <- toGet(pipe_in).get;
      memwriteEngine.dataPipes[0].enq(pack(v));
   endrule

   interface ObjectWriteClient dmaClient = memwriteEngine.dmaClient;
   interface VectorSink vector;
      method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
	 if (verbose) $display("DmaVectorSink.start   p=%d offset=%h l=%h", p, a, l);
	 memwriteEngine.writeServers[0].request.put(MemengineCmd{pointer:p, base:a << ashift, len:truncate(l << ashift), burstLen:fromInteger(valueOf(BurstLen)) << ashift});
      endmethod
      method ActionValue#(Bool) finish();
	 let b <- memwriteEngine.writeServers[0].response.get;
	 return b;
      endmethod
   endinterface
endmodule

interface BramVectorSource#(numeric type addrsz, numeric type dsz, type dtype);
   interface BRAMClient#(Bit#(addrsz), dtype) bramClient;
   interface VectorSource#(dsz, dtype) vector;
endinterface

module [Module] mkBramVectorSource(BramVectorSource#(addrsz, dsz, dtype))
   provisos (Bits#(dtype,dsz),
	     Add#(a__, addrsz, ObjectOffsetSize)
	     );

   Bool verbose = False;

   let dsz = valueOf(dsz);

   FIFOF#(dtype) dfifo <- mkFIFOF();
   Reg#(Bit#(addrsz)) offset <- mkReg(0);
   Reg#(Bit#(addrsz)) limit <- mkReg(0);
   Reg#(Bool) busy <- mkReg(False);

   interface BRAMClient bramClient;
      interface Get request;
	 method ActionValue#(BRAMRequest#(Bit#(addrsz),dtype)) get() if (offset < limit);
	    if (verbose) $display("BramVectorSource.readReq offset=%h limit=%h", offset, limit);
	    offset <= offset + 1;
	    return BRAMRequest { write: False, responseOnWrite: False, address: offset, datain: unpack(0) };
	 endmethod
      endinterface
      interface Put response;
	 method Action put(dtype dmaval);
	    if (verbose) $display("BramVectorSource.readData dmaval=%h", dmaval);
	    dfifo.enq(dmaval);
	 endmethod
      endinterface
   endinterface : bramClient
   interface VectorSource vector;
       method Action start(ObjectPointer pointer, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l) if (offset >= limit);
	  if (verbose) $display("BramVectorSource.start a=%h l=%h", a, l);
	  offset <= truncate(a);
	  limit <= truncate(l);
	  busy <= True;
       endmethod
      method ActionValue#(Bool) finish() if (offset >= limit && busy);
	 busy <= False;
	 return True;
      endmethod
//   method Fmt dbg();
//      return fshow("bramvectorsource");
//   endmethod
       interface PipeOut pipe;
	  method first = dfifo.first;
	  method Action deq();
	     if (verbose) $display("BramVectorSource pipe.deq() data=%h", dfifo.first);
	     dfifo.deq;
	  endmethod
	  method notEmpty = dfifo.notEmpty;
       endinterface
   endinterface
endmodule
