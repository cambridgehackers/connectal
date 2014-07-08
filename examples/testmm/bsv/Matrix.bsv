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

import FIFO::*;
import FIFOF::*;
import MIMO::*;
import DefaultValue::*;
import SpecialFIFOs::*;
import Vector::*;
import BRAM::*;
import DmaVector::*;
import PortalMemory::*;
import MemTypes::*;
import MemreadEngine::*;
import MemwriteEngine::*;
import FloatingPoint::*;
import Pipe::*;
import FloatOps::*;
import Timer::*;
import RbmTypes::*;
import Assert::*;
import Connectable::*;

interface SharedDotProdDebug#(numeric type k);
   interface PipeOut#(Bit#(32)) macCount;
   method    Bit#(TLog#(k)) chan();
endinterface


typedef struct {
`define TAGGED_TOKENS
`ifdef TAGGED_TOKENS
   UInt#(32) row;
   UInt#(32) col;
`endif
   Float v;
   Bool first;
   Bool last;
   } Token deriving (Eq,Bits);

interface SharedDotProdServer#(numeric type k);
   interface Put#(Token)                 aInput;
   interface Put#(Token)                 bInput;
   interface Vector#(k, PipeOut#(Token)) pipes;
   interface SharedDotProdDebug#(k) debug;
endinterface

interface RowColSource#(numeric type dsz, type a);
   interface PipeOut#(a) pipe;
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l, UInt#(32) tag);
   method ActionValue#(Bool) finish();
endinterface

interface RowColSink#(numeric type dsz, type a);
   interface PipeIn#(a) pipe;
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
   method ActionValue#(Bool) finish();
endinterface

function Put#(a) toCountedPut(Reg#(Bit#(n)) r, Put#(a) p);
   return (interface Put#(a);
      method Action put(a v);
	 r <= r+1;
	 p.put(v);
      endmethod
      endinterface);
endfunction
function PipeOut#(dtype) vsp(RowColSource#(dsz,dtype) vs); return vs.pipe; endfunction

module mkRowColSink#(VectorSink#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSink#(TMul#(N,32), Vector#(N,Token)));
   function Float foo(Token v) = v.v;
   method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
      vs.start(p,a,l);
   endmethod
   method finish = vs.finish;
   interface PipeIn pipe;
      method Action enq(Vector#(N,Token) v);
	 vs.pipe.enq(map(foo,v));
      endmethod
      method Bool notFull = vs.pipe.notFull;
   endinterface
endmodule

module mkRowSource#(VectorSource#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSource#(TMul#(N,32), Vector#(N,Token)));
`ifdef TAGGED_TOKENS
   Reg#(UInt#(32)) col <- mkReg(0);
   FIFOF#(UInt#(32)) tagFifo <- mkFIFOF;
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(ObjectOffsetSize)) countReg <- mkReg(0);
   FIFOF#(Bit#(ObjectOffsetSize)) cmdFifo <- mkFIFOF;

   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l, UInt#(32) tag);
`ifdef TAGGED_TOKENS
      tagFifo.enq(tag);
`endif
      vs.start(h,a,l);
      cmdFifo.enq(l);
   endmethod 
   method ActionValue#(Bool) finish;
      let rv <- vs.finish;
      return rv;
   endmethod
   interface PipeOut pipe;
      method Vector#(N,Token) first;
	 Vector#(N,Token) rv;
`ifdef TAGGED_TOKENS
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = Token{row:tagFifo.first, col:col+fromInteger(i), v:vs.pipe.first[i], first:False, last:False};
`else
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = Token{v:vs.pipe.first[i], first:False, last:False};
`endif
	 if (countReg==0)
	    rv[0].first = True;
	 if (countReg+1==cmdFifo.first)
	    rv[valueOf(N)-1].last = True;
	 return rv;
      endmethod
      method Action deq;
	 vs.pipe.deq;
	 //$display("mkRowSource count=%d first=%d last=%d", countReg, firstReg, lastReg);
	 if(countReg+1==cmdFifo.first) begin
	    countReg <= 0;
	    cmdFifo.deq;
`ifdef TAGGED_TOKENS
	    tagFifo.deq;
	    col <= 0;
`endif      
	 end
	 else begin
`ifdef TAGGED_TOKENS
	    col <= col+fromInteger(valueOf(N));
`endif
	    countReg <= countReg + 1;
	 end
      endmethod
      method Bool notEmpty;
`ifdef TAGGED_TOKENS
	 return (tagFifo.notEmpty && vs.pipe.notEmpty);
`else
	 return (vs.pipe.notEmpty);
`endif
      endmethod
   endinterface
endmodule

module mkColSource#(VectorSource#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSource#(TMul#(N,32), Vector#(N,Token)));
`ifdef TAGGED_TOKENS
   Reg#(UInt#(32)) row <- mkReg(0);
   FIFOF#(UInt#(32)) tagFifo <- mkFIFOF;
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(ObjectOffsetSize)) countReg <- mkReg(0);
   FIFOF#(Bit#(ObjectOffsetSize)) cmdFifo <- mkFIFOF;

   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l, UInt#(32) tag);
`ifdef TAGGED_TOKENS
      tagFifo.enq(tag);
`endif
      vs.start(h,a,l);
      cmdFifo.enq(l);
   endmethod
   method ActionValue#(Bool) finish;
      let rv <- vs.finish;
      return rv;
   endmethod
   interface PipeOut pipe;
      method Vector#(N,Token) first;
	 Vector#(N,Token) rv;
`ifdef TAGGED_TOKENS
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = Token{row:row+fromInteger(i), col:tagFifo.first, v:vs.pipe.first[i], first:False, last:False};
`else
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = Token{v:vs.pipe.first[i], first:False, last:False};
`endif
	 if (countReg==0)
	    rv[0].first = True;
	 if (countReg+1==cmdFifo.first)
	    rv[valueOf(N)-1].last = True;
	 return rv;
      endmethod
      method Action deq;
	 vs.pipe.deq;
	 if(countReg+1==cmdFifo.first) begin
	    countReg <= 0;
	    cmdFifo.deq;
`ifdef TAGGED_TOKENS
	    tagFifo.deq;
	    row <= 0;
`endif      
	 end
	 else begin
`ifdef TAGGED_TOKENS
	    row <= row+fromInteger(valueOf(N));
`endif
	    countReg <= countReg+1;
	 end
      endmethod
      method Bool notEmpty;
`ifdef TAGGED_TOKENS
	 return (tagFifo.notEmpty && vs.pipe.notEmpty);
`else
	 return (vs.pipe.notEmpty);
`endif
      endmethod
   endinterface
endmodule

		   
(* synthesize *)
module  mkSharedDotProdServer#(UInt#(TLog#(TMul#(J,K))) label)(SharedDotProdServer#(K))
   provisos(Div#(8,K,gatherSz));
 
   
   let ub_MulLat = 16; // upper bound on MUL latency?
   let ub_AddLat = 16; // upper bound on ADD latency?
   
   let n = valueOf(N);
   Bool verbose = False; //label == 0;

   Reg#(UInt#(20)) countReg     <- mkReg(0);

   FloatAlu mul   <- mkFloatMultiplier(defaultValue);
   FloatAlu adder <- mkFloatAdder(defaultValue);
   
`ifdef TAGGED_TOKENS
   Vector#(2,FIFO#(Tuple2#(UInt#(32),UInt#(32)))) tag_fifos <- replicateM(mkSizedFIFO(max(ub_MulLat,ub_AddLat))); 
   Vector#(K,Reg#(Tuple2#(UInt#(32),UInt#(32)))) tag_regs <- replicateM(mkRegU);
   Vector#(K,Reg#(Bool)) tag_regs_valid <- replicateM(mkReg(False)); 
`endif   
   
   FIFOF#(Token)                          afifo   <- mkFIFOF();
   PipeOut#(Token)                        aFunnel = toPipeOut(afifo);

   FIFOF#(Token)                          bfifo <- mkFIFOF();
   PipeOut#(Token)                        bFunnel = toPipeOut(bfifo);

   FIFOF#(Bool) firstFifo  <- mkSizedFIFOF(ub_MulLat);
   FIFOF#(Bool) lastFifoA  <- mkSizedFIFOF(ub_MulLat);
   FIFOF#(Bool) lastFifoB  <- mkSizedFIFOF(ub_AddLat); 

   Vector#(K,Vector#(gatherSz,FIFOF#(Float))) accumFifos <- replicateM(replicateM(mkFIFOF1));
   Vector#(K,Reg#(Bit#(TLog#(gatherSz)))) accumFifosEnqIdxs <- replicateM(mkReg(0));
   Vector#(K,Reg#(Bit#(TLog#(gatherSz)))) accumFifosDeqIdxs <- replicateM(mkReg(0));
   Vector#(K,Reg#(Bit#(32))) firstCnts <- replicateM(mkReg(0));

   Reg#(Bit#(32)) lastCntA   <- mkReg(0);
   Reg#(Bit#(32)) lastCntB   <- mkReg(0);
   Reg#(Bit#(32)) gatherCntA <- mkReg(0);
   Reg#(Bit#(32)) gatherCntB <- mkReg(0);
   Vector#(K,FIFOF#(Token)) dotfifos   <- replicateM(mkFIFOF1);
   
   Vector#(2,Reg#(Bit#(TLog#(K)))) chanRegs <- replicateM(mkReg(0));
   Vector#(3,FIFO#(Bit#(TLog#(K)))) chanFifos <- replicateM(mkSizedFIFO(valueOf(TMul#(gatherSz,K))));

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule countCycles;
      cycles <= cycles + 1;
   endrule

   Reg#(Bit#(32)) lastMulin <- mkReg(0);
   Reg#(Bit#(32)) lastAccin <- mkReg(0);
   Reg#(Bit#(32)) lastAccout <- mkReg(0);
   Reg#(Bit#(32)) macs <- mkReg(0);
   
   let gather_phaseA = lastCntA == fromInteger(valueOf(K));
   let gather_phaseB = lastCntB == fromInteger(valueOf(K));
      
   rule mulin;
      lastMulin <= cycles;

      let chan = chanRegs[0];
      chanFifos[0].enq(chan);
      chanRegs[0] <= (chan + 1);
      let a <- toGet(aFunnel).get();
      let b <- toGet(bFunnel).get();
            
      let first = a.first;
      let last = a.last;
      firstFifo.enq(first);
      lastFifoA.enq(last);
      if (a.first != b.first)
	 $display("****\n    Warning: a.first=%d != b.first=%d\n****", a.first, b.first);
      if (a.last != b.last)
	 $display("****\n    Warning: a.last=%d != b.last=%d\n****", a.last, b.last);
      if (verbose) $display("%08d label=%d mulin chan=%d first=%d last=%d", cycles-lastMulin, label, chan, first, last);
      mul.request.put(tuple2(a.v, b.v));
`ifdef TAGGED_TOKENS
      tag_fifos[0].enq(tuple2(a.row,b.col));
`endif
   endrule

   rule mulout if (!gather_phaseA);
      let chan <- toGet(chanFifos[0]).get();
      let first <- toGet(firstFifo).get();
      let last <- toGet(lastFifoA).get;
      lastFifoB.enq(last);
      chanFifos[1].enq(chan);
      lastAccin <= cycles;
      if (verbose) $display("%08d label=%d mulout chan=%d first=%d", cycles-lastAccin, label, chan, first);
      match {.resp,.*} <- mul.response.get();
      let acc = unpack(0);
      if (!first && firstCnts[chan] == fromInteger(valueOf(gatherSz))) begin
	 acc <- toGet(accumFifos[chan][accumFifosDeqIdxs[chan]]).get();
	 accumFifosDeqIdxs[chan] <= accumFifosDeqIdxs[chan]+1;
	 //if (verbose) $display("accumFifos[%d][%d].deq", chan,accumFifosDeqIdxs[chan]);
      end
      else begin
	 if (first) firstCnts[chan] <= 1;
	 else firstCnts[chan] <= firstCnts[chan]+1;
	 //if (verbose) $display("firstCnts[%d] = %d", chan, firstCnts[chan]);
      end
      adder.request.put(tuple2(resp,acc));
`ifdef TAGGED_TOKENS
      let t <- toGet(tag_fifos[0]).get;
      tag_fifos[1].enq(t);
`endif
      if(last) begin
	 lastCntA <= lastCntA+1;
	 if (verbose) $display("mulout lastCntA=%d, K=%d", lastCntA, valueOf(K));
      end
   endrule

   rule accout if (!gather_phaseB);
      let chan <- toGet(chanFifos[1]).get();
      let last <- toGet(lastFifoB).get;
      macs <= macs + 1;
      lastAccout <= cycles;
      match {.acc,.*} <- adder.response.get();
      if (verbose) $display("%08d label=%d accout chan=%d acc=%x last=%d macs=%d", cycles-lastAccout, label, chan, pack(acc), last, macs+1);
      accumFifos[chan][accumFifosEnqIdxs[chan]].enq(acc);
      accumFifosEnqIdxs[chan] <= accumFifosEnqIdxs[chan]+1;
`ifdef TAGGED_TOKENS
      match {.row, .col} <- toGet(tag_fifos[1]).get;
      tag_regs[chan] <= tuple2(row,col);
      tag_regs_valid[chan] <= !last;
      if (tag_regs_valid[chan]) begin
	 match {.r,.c} = tag_regs[chan];
	 if (r != row || c != col) 
	    $display("mkSharedDotProdServer:row/col mismatch");
      end
`endif
      if (last) begin
	 lastCntB <= lastCntB+1;
	 if (verbose) $display("accout lastCntB=%d, K=%d", lastCntB, valueOf(K));
      end
   endrule
   
   rule gatherA if (gather_phaseA);
      let chan = chanRegs[1];
      chanRegs[1] <= chan+1;
      let last_chan = chan == fromInteger(valueOf(K)-1);
      let last_pass = gatherCntA+1 == fromInteger(valueOf(gatherSz));
      if (!last_pass) begin
	 chanFifos[2].enq(chan);
	 let x <- toGet(accumFifos[chan][gatherCntA+0]).get;
	 let y <- toGet(accumFifos[chan][gatherCntA+1]).get;
	 adder.request.put(tuple2(x,y));
	 //if (verbose) $display("gatherA=%d chan=%d, gatherSz=%d", gatherCntA, chanReg, valueOf(gatherSz));
	 //if (verbose) $display("gatherA: accumFifos[%d][%d].deq", chan, gatherCntA+0);
	 //if (verbose) $display("         accumFifos[%d][%d].deq", chan, gatherCntA+1);
	 if (last_chan)
	    gatherCntA <= gatherCntA+1; 
      end
      else begin
	 let x <- toGet(accumFifos[chan][gatherCntA+0]).get;
`ifdef TAGGED_TOKENS
      	 let row = tpl_1(tag_regs[chan]);
      	 let col = tpl_2(tag_regs[chan]);
	 dotfifos[chan].enq(Token{row:row, col:col, v:x});
`else
	 dotfifos[chan].enq(Token{v:x});
`endif      
	 if (last_chan) begin
	    gatherCntA <= 0;
	    lastCntA <= 0;
	    if(verbose) $display("gatherA reset");
	 end
      end
   endrule

   rule gatherB if (gather_phaseB);
      if (valueOf(gatherSz)==1) begin
	 gatherCntB <= 0;
	 lastCntB <= 0;
	 if(verbose) $display("gatherB reset");
      end
      else begin
	 let chan <- toGet(chanFifos[2]).get;
	 let last_chan = chan == fromInteger(valueOf(K)-1);
	 let last_pass = gatherCntB+2 == fromInteger(valueOf(gatherSz));
	 if (last_chan && !last_pass)
	    gatherCntB <= gatherCntB+1;
	 else if (last_chan && last_pass) begin
	    gatherCntB <= 0;
	    lastCntB <= 0;
	    if(verbose) $display("gatherB reset");
	 end
	 match {.acc, .*} <- adder.response.get;
	 accumFifos[chan][gatherCntB+1].enq(acc);
	 //if (verbose) $display("gatherB=%d chan=%d last_chan=%d last_pass=%d", gatherCntB, chan, last_chan, last_pass);
	 //if (verbose) $display("gatherB: accumFifos[%d][%d].enq %d", chan, gatherCntB+1, last_pass);
      end
   endrule
   

   Vector#(K,PipeOut#(Token)) dotpipes = map(toPipeOut, dotfifos);

   interface Put aInput;
      method Action put(Token a);
   	 afifo.enq(a);
	 countReg <= countReg+1;
      endmethod
   endinterface
   interface Put bInput   = toPut(bfifo);
   interface Vector pipes = dotpipes;
   interface SharedDotProdDebug debug;
      interface PipeOut  macCount = toPipeOut(macs._read);
      method    Bit#(TLog#(K)) chan(); return chanRegs[0]; endmethod
   endinterface
endmodule : mkSharedDotProdServer

interface MmTileDebug;
   interface PipeOut#(Bit#(32)) macCount;
   method Bit#(RowsPerTile) aNotEmpty;
   method Bit#(RowsPerTile) bNotEmpty;
   method Bit#(32) aBytesPut();
   method Bit#(32) bBytesPut();
   method Bit#(32) aBytesRead();
   method Bit#(32) bBytesRead();
   method Vector#(RowsPerTile, Bit#(TLog#(K))) dotProdChan();
endinterface

interface MmTile;
   interface Vector#(RowsPerTile, Put#(Token)) aInputs;
   interface Vector#(RowsPerTile, Put#(Token)) bInputs;
   interface Vector#(RowsPerTile, PipeOut#(Vector#(N, Token))) fxPipes;
   interface MmTileDebug debug;
endinterface

(* synthesize *)
module  mkMmTile#(UInt#(TLog#(T)) tile)(MmTile);

   let rowsPerTile = valueOf(RowsPerTile);
   let kk = valueOf(K);

   Vector#(RowsPerTile, Reg#(Bit#(32))) aTokensPutRegs <- replicateM(mkReg(0));
   Vector#(RowsPerTile, Reg#(Bit#(32))) bTokensPutRegs <- replicateM(mkReg(0));
   Vector#(RowsPerTile, Reg#(Bit#(32))) aTokensReadRegs <- replicateM(mkReg(0));
   Vector#(RowsPerTile, Reg#(Bit#(32))) bTokensReadRegs <- replicateM(mkReg(0));

   Vector#(RowsPerTile, FIFOF#(Token))   aFifos <- replicateM(mkFIFOF);
   Vector#(RowsPerTile, PipeOut#(Token)) aPipes = zipWith(toCountedPipeOut, aTokensReadRegs, map(toPipeOut, aFifos));
   Vector#(RowsPerTile,  FIFOF#(Token))   bFifos <- replicateM(mkFIFOF);
   Vector#(RowsPerTile,  PipeOut#(Token)) bPipes = zipWith(toCountedPipeOut, bTokensReadRegs, map(toPipeOut, bFifos));

   function Vector#(k,PipeOut#(Token)) getDotProdServerPipes(SharedDotProdServer#(k) s); return s.pipes; endfunction
   Vector#(RowsPerTile, SharedDotProdServer#(K)) fxdotprods <- mapM(mkSharedDotProdServer, map(fromInteger,genVector));
   Vector#(RowsPerTile, Vector#(K, PipeOut#(Token))) fxpipes = map(getDotProdServerPipes, fxdotprods);
`define USE_MIMO_DFIFOS // this version is faster
`ifndef USE_MIMO_DFIFOS
   Vector#(RowsPerTile, PipeOut#(Vector#(K, Float))) fxPipesK <- mapM(mkJoinVector(id), fxpipes);
   Vector#(RowsPerTile, PipeOut#(Vector#(N, Float))) fxPipesN <- mapM(mkFunnel, fxPipesK);
`else
   MIMOConfiguration mimoCfg = defaultValue;
   Vector#(RowsPerTile, MIMO#(K,N,TAdd#(K,N),Token)) dfifos <- replicateM(mkMIMO(mimoCfg));
   Vector#(RowsPerTile, PipeOut#(Vector#(N, Token))) fxPipesN = map(toPipeOut, dfifos);
`endif
   FirstLastPipe#(UInt#(MMSize)) firstLastPipe          <- mkFirstLastPipe();
   Vector#(2, PipeOut#(Tuple2#(Bool,Bool))) firstLastPipes <- mkForkVector(firstLastPipe.pipe);

   for (Integer j = 0; j < rowsPerTile; j = j + 1) begin
      //mkConnection(toGet(aPipes[j]), fxdotprods[j].aInput);
      //mkConnection(toGet(bPipes[j]), fxdotprods[j].bInput);
      (* fire_when_enabled *)
      rule connectA;
	 let x <- toGet(aPipes[j]).get;
	 fxdotprods[j].aInput.put(x);
      endrule
      (* fire_when_enabled *)
      rule connectB;
	 let x <- toGet(bPipes[j]).get;
	 fxdotprods[j].bInput.put(x);
      endrule
   end

`ifdef USE_MIMO_DFIFOS
   for (Integer j = 0; j < rowsPerTile; j = j + 1) begin
      rule dotProdValue;
	 Vector#(K,Token) vs;
	 for (Integer k = 0; k < kk; k = k + 1) begin
	    let v <- toGet(fxpipes[j][k]).get();
	    vs[k] = v;
	 end	    
	 dfifos[j].enq(fromInteger(kk), vs);
      endrule
   end
`endif

   function Bool fifofNotEmpty(FIFOF#(a) fifof); return fifof.notEmpty(); endfunction
   function Bit#(32) my_add(Tuple2#(Bit#(32),Bit#(32)) ab); match { .a, .b } = ab; return a+b; endfunction
   function Bit#(TLog#(K)) getDotProdChan(SharedDotProdServer#(K) dotprodserver); return dotprodserver.debug.chan; endfunction
   function PipeOut#(Bit#(32)) dotProdMacCount(SharedDotProdServer#(K) dotprodserver); return dotprodserver.debug.macCount; endfunction
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(my_add, map(dotProdMacCount, fxdotprods));

   interface Vector aInputs = zipWith(toCountedPut, aTokensPutRegs, map(toPut, aFifos));
   interface Vector bInputs = zipWith(toCountedPut, bTokensPutRegs, map(toPut, bFifos));
   interface Vector fxPipes = fxPipesN;
   interface MmTileDebug debug;
      interface PipeOut macCount = macCountPipe;
      method Bit#(RowsPerTile) aNotEmpty(); return pack(map(fifofNotEmpty, aFifos)); endmethod
      method Bit#(RowsPerTile) bNotEmpty(); return pack(map(fifofNotEmpty, bFifos)); endmethod
      method Bit#(32) aBytesPut(); return aTokensPutRegs[0] * 4; endmethod
      method Bit#(32) bBytesPut(); return bTokensPutRegs[0] * 4; endmethod
      method Bit#(32) aBytesRead(); return aTokensReadRegs[0] * 4; endmethod
      method Bit#(32) bBytesRead(); return bTokensReadRegs[0] * 4; endmethod
      method Vector#(RowsPerTile, Bit#(TLog#(K))) dotProdChan(); return map(getDotProdChan, fxdotprods); endmethod
   endinterface
endmodule : mkMmTile

function Vector#(TMul#(j,k), etype) flattenMatrix(Vector#(j, Vector#(k, etype)) mat);
   function etype flatten(Integer i); return mat[i/valueOf(k)][i%valueOf(k)]; endfunction
   return genWith(flatten);
endfunction

typedef struct {
   a xbase;
   a xlimit;
   a xstep;
   a ybase;
   a ylimit;
   a ystep;
} XYRangeConfig#(type a) deriving (Bits, FShow);

interface XYRangePipeIfc#(type a);
   interface PipeOut#(Tuple2#(a,a)) pipe;
   method Action start(XYRangeConfig#(a) cfg);
   method Action display();
endinterface

module mkXYRangePipeOut(XYRangePipeIfc#(a)) provisos (Arith#(a), Bits#(a,awidth), Eq#(a), Ord#(a));
   Reg#(a) x <- mkReg(0);
   Reg#(a) y <- mkReg(0);
   Reg#(a) xbase <- mkReg(0);
   Reg#(a) ybase <- mkReg(0);
   Reg#(a) xstep <- mkReg(0);
   Reg#(a) ystep <- mkReg(0);
   Reg#(a) xlimit <- mkReg(0);
   Reg#(a) ylimit <- mkReg(0);

   interface PipeOut pipe;
      method Tuple2#(a,a) first() if (x < xlimit && y < ylimit);
	 return tuple2(x,y);
      endmethod
      method Action deq if (x < xlimit && y < ylimit);
	 let newx = x;
	 let newy = y+ystep;
	 if (newy >= ylimit && x < xlimit) begin
	    newy = ybase;
	    newx = newx + xstep;
	 end
	 x <= newx;
	 y <= newy;
      endmethod
      method Bool notEmpty();
	 return (x < xlimit && y < ylimit);
      endmethod
   endinterface
   method Action start(XYRangeConfig#(a) cfg) if (x >= xlimit);
      //$display("XYRangePipe x=%d xlimit=%d xstep=%d y=%d ylimit=%d ystep=%d", cfg.xbase, cfg.xlimit, cfg.xstep, cfg.ybase, cfg.ylimit, cfg.ystep);
      x <= cfg.xbase;
      y <= cfg.ybase;
      xbase <= cfg.xbase;
      ybase <= cfg.ybase;
      xstep <= cfg.xstep;
      ystep <= cfg.ystep;
      xlimit <= cfg.xlimit;
      ylimit <= cfg.ylimit;
   endmethod
   method Action display();
      $display("XYRangePipe x=%d xlimit=%d y=%d ylimit=%d xstep=%d ystep=%d", x, xlimit, xstep, y, ylimit, ystep);
   endmethod
endmodule: mkXYRangePipeOut

typedef struct {
   ObjectPointer pointer;
   addrtype base;
   addrtype numRows;
   addrtype numColumns;
} MatrixDescriptor#(type addrtype) deriving (Bits);

interface DmaMatrixMultiplyDebug;
   method Bit#(J) aNotEmpty();
   method Bit#(K) bNotEmpty();
   method Bit#(32) macCount();
   method Bit#(J) mmtilesANotEmpty();
   method Bit#(J) mmtilesBNotEmpty();
   method Bit#(32) aBytesPut();
   method Bit#(32) bBytesPut();
   method Bit#(32) aBytesRead();
   method Bit#(32) bBytesRead();
endinterface
   
// row major layout
interface DmaMatrixMultiplyIfc#(numeric type addrwidth, numeric type dsz);
   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface

typedef enum {
   Idle, Ready, Running, Done
   } MMState deriving (Bits, Eq);

/*!
 * Multiplies two matrices A and B and writes the result to memory.
 * Fetches J rows at a time from A and K rows at a time from B.
 * Each cycle, it can fetch N elements of a row or column.
 *
 * Just considering memory bandwidth, every J+K cycles it is ready to perform J*K*N multiply accumulates.
 *
 */
module  mkDmaMatrixMultiply#(Vector#(J, VectorSource#(dsz, Vector#(N, Float))) sA,
				     Vector#(K, VectorSource#(dsz, Vector#(N, Float))) sB,
				     Vector#(J, VectorSink#(dsz, Vector#(N,Float)))    ss
				     )(DmaMatrixMultiplyIfc#(addrwidth, dsz))
   provisos (// Add#(N,n__,K)
	     //, Mul#(N,m__,K)
	     //,
                Add#(1,o__,J)
	     , Log#(N,nshift)
	     , FShow#(Float)
	     , Arith#(Float)
	     , Bits#(Vector#(N, Float), dsz)
	     , Bits#(MatrixDescriptor#(UInt#(addrwidth)), mdsz)
	     , Bits#(Tuple2#(UInt#(addrwidth), UInt#(addrwidth)), tplsz)
	     , Add#(b__, 20, addrwidth)
	     , Add#(a__, addrwidth, 40)
	     , Add#(c__, addrwidth, 32)
      );

   let n = valueOf(N);
   let jj = valueOf(J);
   let kk = valueOf(K);
   let tt = valueOf(T);
   let nshift = valueOf(nshift);
   Bool verbose = False;
   Bool verbose1 = False;
   Bool timing = False;

   Reg#(UInt#(32)) cycles <- mkReg(0);
   Reg#(Bool) doneReg <- mkReg(False);
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorA <- mkReg(unpack(0));
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorB <- mkReg(unpack(0));
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorC <- mkReg(unpack(0));
   Reg#(UInt#(addrwidth)) dotprodCount <- mkReg(0);
   
   Vector#(J, RowColSource#(TMul#(N,32), Vector#(N,Token))) sourceA <- mapM(mkRowSource, sA);
   Vector#(K, RowColSource#(TMul#(N,32), Vector#(N,Token))) sourceB <- mapM(mkColSource, sB);
   Vector#(J, RowColSink#(TMul#(N,32),   Vector#(N,Token))) sinks   <- mapM(mkRowColSink,ss);
   Vector#(J, PipeOut#(Token))       aPipes <- mapM(mkFunnel1, map(vsp, sourceA));
   Vector#(K, PipeOut#(Token))       bPipes <- mapM(mkFunnel1, map(vsp, sourceB));
   PipeOut#(Token)                  bFunnel <- mkFunnelPipes1(bPipes);
   Vector#(J, PipeOut#(Token)) bFunnelPipes <- mkForkVector(bFunnel);

   rule countCycles;
      cycles <= cycles+1;
   endrule

   UInt#(TAdd#(TLog#(K),1)) repetitions = fromInteger(valueOf(K));
   Vector#(J, PipeOut#(Token)) aRepeaters <- mapM(mkRepeat(repetitions), aPipes);

   Vector#(T, MmTile) mmTiles <- mapM(mkMmTile,map(fromInteger,genVector));
   Vector#(J, PipeOut#(Vector#(N,Token))) fxpipes;
   for (Integer t = 0; t < valueOf(T); t = t+1) begin
      for (Integer i = 0; i < valueof(RowsPerTile); i = i+1) begin
	 let j = t*valueOf(RowsPerTile) + i;
	 mkConnection(toGet(aRepeaters[j]), mmTiles[t].aInputs[i]);
	 mkConnection(toGet(bFunnelPipes[j]), mmTiles[t].bInputs[i]);
	 fxpipes[j] = mmTiles[t].fxPipes[i];
      end
   end
   
   function PipeIn#(a) getPipe(RowColSink#(n,a) vs) = vs.pipe;
   zipWithM(mkConnection, fxpipes, map(getPipe, sinks));
   
   XYRangePipeIfc#(UInt#(addrwidth)) indexpipeifc <- mkXYRangePipeOut();
   XYRangePipeIfc#(UInt#(addrwidth)) offsetpipeA <- mkXYRangePipeOut();
   XYRangePipeIfc#(UInt#(addrwidth)) offsetpipeB <- mkXYRangePipeOut();
   XYRangePipeIfc#(UInt#(addrwidth)) offsetpipeC <- mkXYRangePipeOut();

   Vector#(TAdd#(J,K), PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth)))) indexpipes <- mkForkVector(indexpipeifc.pipe);
   Vector#(J, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth))))        offsetpipesA <- mkForkVector(offsetpipeA.pipe);
   Vector#(K, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth))))        offsetpipesB <- mkForkVector(offsetpipeB.pipe);
   Vector#(J, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth))))        offsetpipesC <- mkForkVector(offsetpipeC.pipe);
   
   Vector#(J, Reg#(UInt#(32))) lastStartAs <- replicateM(mkReg(0));
   Vector#(K, Reg#(UInt#(32))) lastStartBs <- replicateM(mkReg(0));
   Vector#(K, Reg#(UInt#(32))) lastStartCs <- replicateM(mkReg(0));
      
   Reg#(Bool) running <- mkReg(False);
   FIFOF#(Bool) doneFifo <- mkFIFOF();
   
   Vector#(J, Reg#(UInt#(addrwidth))) startAOffset <- replicateM(mkReg(0));
   Vector#(K, Reg#(UInt#(addrwidth))) startBOffset <- replicateM(mkReg(0));
   Vector#(J, Reg#(UInt#(addrwidth))) startCOffset <- replicateM(mkReg(0));

   Vector#(K, FIFO#(void)) bar <- replicateM(mkFIFO);
   for (Integer k = 0; k < kk; k = k + 1) begin
      rule startSourceB;

	 if(k > 0)
	    bar[k-1].deq;
	 if(k < kk-1)
	    bar[k].enq(?);

	 Tuple2#(UInt#(addrwidth),UInt#(addrwidth)) index <- toGet(indexpipes[k]).get();
	 match { .unusedB, .startBBase } <- toGet(offsetpipesB[k]).get();

	 int kint = fromInteger(k);

	 let row = tpl_1(index);
	 let col = tpl_2(index)+fromInteger(k);

	 let startB = startBBase + startBOffset[k];
	 
	 lastStartBs[k] <= cycles;
	 let interval = cycles-lastStartBs[k];

	 if (timing || verbose) $display($format(fshow(interval)+fshow("    startB index=")+fshow(tuple2(row,col))
	    +fshow(" startB=")+fshow(startB)
	    +fshow(" k=")+fshow(kint)));

	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceB[")+fshow(kint)+fshow("].start")+fshow(startB)));

	 sourceB[k].start(descriptorB.pointer, pack(extend(startB>>nshift)), pack(extend(descriptorB.numColumns>>nshift)), extend(col));

      endrule
      rule finishSourceB;
	 UInt#(TLog#(K)) in = fromInteger(k);
	 int kint = fromInteger(k);
	 if (timing || verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceB[")+fshow(kint)+fshow("].finish")));
	 let b <- sourceB[k].finish();
      endrule
   end
   Vector#(J, FIFO#(void)) foo <- replicateM(mkFIFO);
   for (Integer j = 0; j < jj; j = j + 1) begin

      int jint = fromInteger(j);

      rule startSourceAndSink;
	 
	 if(j > 0)
	    foo[j-1].deq;
	 if(j < jj-1)
	    foo[j].enq(?);
	 
	 Tuple2#(UInt#(addrwidth),UInt#(addrwidth)) index <- toGet(indexpipes[j+kk]).get();
	 
	 let row = tpl_1(index)+fromInteger(j);
	 let col = tpl_2(index);
	 
	 match { .startABase, .unusedA } <- toGet(offsetpipesA[j]).get();
	 match { .startCBase, .offsetC } <- toGet(offsetpipesC[j]).get();
	 let startA = startABase + startAOffset[j];
	 let startC = startCBase + startCOffset[j] + offsetC;
	 
	 int jint = fromInteger(j);
	 if (timing || verbose) $display($format(fshow(cycles)+fshow("    start A index=")+fshow(tuple2(row,col))
						 +fshow(" startA=")+fshow(startA)
						 +fshow(" startC=")+fshow(startC)
						 +fshow(" j=")+fshow(jint)));
	 
	 sourceA[j].start(descriptorA.pointer, pack(extend(startA>>nshift)), pack(extend(descriptorA.numColumns>>nshift)), extend(row));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].start")+fshow(startA)));
	 sinks[j].start(descriptorC.pointer, pack(extend(startC>>nshift)), fromInteger(kk/n));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("      sinks[")+fshow(jint)+fshow("].start")+fshow(startC)));
	 
      endrule

      rule finishSourceA;
	 if (timing || verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].finish ")));
	 let b <- sourceA[j].finish();
      endrule

      rule finishSink;
	 $dumpoff();
	 // each time we write a burst of k values via sinks
	 //let index <- toGet(indexpipes[jj+kk+1]).get();
	 let b <- sinks[j].finish();
	 let c = dotprodCount-fromInteger(kk);
	 int jint = fromInteger(j);
	 if (timing || verbose1) $display($format(fshow(cycles)+fshow("    finishSink c")+fshow(c)+fshow(" j=")+fshow(jint)));
	 dotprodCount <= c;
	 if (c == 0) begin
	    running <= False;
	    doneFifo.enq(?);
	 end
      endrule
   end

   FIFO#(Bool) initNumEltsFifo <- mkFIFO();
   rule dotProdsNumElts;
      initNumEltsFifo.deq();
      let numColumnsA = descriptorA.numColumns;
      let numColumnsB = descriptorB.numColumns;
      let numRowsB    = descriptorB.numRows;
      for (Integer j = 0; j < jj; j = j + 1) begin
	 startAOffset[j] <= fromInteger(j)*numColumnsA;
	 startCOffset[j] <= fromInteger(j)*numRowsB;
      end
      for (Integer k = 0; k < kk; k = k + 1) begin
	 startBOffset[k] <= fromInteger(k)*numColumnsB;
      end
  endrule

   function Bit#(32) my_add(Tuple2#(Bit#(32),Bit#(32)) ab); match { .a, .b } = ab; return a+b; endfunction
   function PipeOut#(Bit#(32)) mmTileMacCount(MmTile mmtile); return mmtile.debug.macCount; endfunction
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(my_add, map(mmTileMacCount, mmTiles));
   Reg#(Bit#(32)) macCountReg <- mkReg(0);
   rule updateMacCount;
      let mc <- toGet(macCountPipe).get();
      macCountReg <= mc;
   endrule

   function Vector#(RowsPerTile, Bit#(TLog#(K))) getMmTileChans(MmTile mmtile); return mmtile.debug.dotProdChan; endfunction
   function Bit#(RowsPerTile) getMmTilesANotEmpty(MmTile mmtile); return mmtile.debug.aNotEmpty; endfunction
   function Bit#(RowsPerTile) getMmTilesBNotEmpty(MmTile mmtile); return mmtile.debug.bNotEmpty; endfunction
   function Bool pipeNotEmpty(RowColSource#(asz, a) vs); return vs.pipe.notEmpty(); endfunction

   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC) if (!running);
      XYRangeConfig#(UInt#(addrwidth)) indexcfg  = XYRangeConfig {xbase: 0, xlimit: numRowsA, xstep: fromInteger(jj),
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgA = XYRangeConfig {xbase: 0, xlimit: numRowsA*numColumnsA, xstep: numColumnsA*fromInteger(jj),
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgB = XYRangeConfig {xbase: 0, xlimit: numRowsA, xstep: fromInteger(jj),
								  ybase: 0, ylimit: numRowsB*numColumnsB, ystep: fromInteger(kk)*numColumnsB };
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgC = XYRangeConfig {xbase: 0, xlimit: numRowsA*numRowsB, xstep: numRowsB*fromInteger(jj),
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      descriptorA <= MatrixDescriptor { pointer: pointerA, base: 0, numRows: numRowsA, numColumns: numColumnsA};
      descriptorB <= MatrixDescriptor { pointer: pointerB, base: 0, numRows: numRowsB, numColumns: numColumnsB};
      descriptorC <= MatrixDescriptor { pointer: pointerC, base: 0, numRows: numRowsA, numColumns: numRowsB};
      dotprodCount <= numRowsA*numRowsB;
      running <= True;

      if (verbose) $display("mm pointerA=%d pointerB=%d pointerC=%d\n", pointerA, pointerB, pointerC);
      if (verbose) $display("mm.start ra=%d ca=%d rb=%d cb=%d dotprodCount=%d", numRowsA, numColumnsA, numRowsB, numColumnsB, dotprodCount);
      if (verbose) $display($format(fshow("mm.start ")+fshow(indexcfg)));
      indexpipeifc.start(indexcfg);
      offsetpipeA.start(offsetcfgA);
      offsetpipeB.start(offsetcfgB);
      offsetpipeC.start(offsetcfgC);

      $display("initNumElts");
      initNumEltsFifo.enq(True);

      //$dumpfile("test.vcd");
      //$dumpvars();
   endmethod
   method ActionValue#(Bool) finish();
      if (verbose) $display("mm.finish()");
      doneFifo.deq();
      return True;
   endmethod
   interface DmaMatrixMultiplyDebug debug;
      method Bit#(32) macCount(); return macCountReg; endmethod
      method Bit#(J) aNotEmpty(); return pack(map(pipeNotEmpty, sourceA)); endmethod
      method Bit#(K) bNotEmpty(); return pack(map(pipeNotEmpty, sourceB)); endmethod
      method Bit#(J) mmtilesANotEmpty(); return pack(map(getMmTilesANotEmpty, mmTiles)); endmethod
      method Bit#(J) mmtilesBNotEmpty(); return pack(map(getMmTilesBNotEmpty, mmTiles)); endmethod
//FIXME multiple tiles
       method Bit#(32) aBytesPut();
          return mmTiles[0].debug.aBytesPut();
       endmethod
       method Bit#(32) bBytesPut();
          return mmTiles[0].debug.bBytesPut();
       endmethod
       method Bit#(32) aBytesRead();
          return mmTiles[0].debug.aBytesRead();
       endmethod
       method Bit#(32) bBytesRead();
          return mmTiles[0].debug.bBytesRead();
       endmethod
    endinterface
endmodule : mkDmaMatrixMultiply

interface DramMatrixMultiply#(numeric type n, numeric type dmasz);
   interface Vector#(2, ObjectReadClient#(dmasz)) readClients;
   interface ObjectWriteClient#(dmasz) writeClient;
   method Action start(ObjectPointer pointerA, UInt#(MMSize) numRowsA, UInt#(MMSize) numColumnsA,
		       ObjectPointer pointerB, UInt#(MMSize) numRowsB, UInt#(MMSize) numColumnsB,
		       ObjectPointer pointerC);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface

//(* synthesize *)
module  mkDramMatrixMultiply(DramMatrixMultiply#(N,TMul#(N,32)));
   
   MemreadEngineV#(TMul#(N,32), 2, J) rowReadEngine <- mkMemreadEngine();
   MemreadEngineV#(TMul#(N,32), 2, K) colReadEngine <- mkMemreadEngine();
   MemwriteEngineV#(TMul#(N,32),2, J)   writeEngine <- mkMemwriteEngine();

   Vector#(J, VectorSource#(DmaSz, Vector#(N,Float))) xvfsources <- mapM(uncurry(mkMemreadVectorSource), zip(rowReadEngine.readServers, rowReadEngine.dataPipes));
   Vector#(K, VectorSource#(DmaSz, Vector#(N,Float))) yvfsources <- mapM(uncurry(mkMemreadVectorSource), zip(colReadEngine.readServers, colReadEngine.dataPipes));
   Vector#(J,   VectorSink#(DmaSz, Vector#(N,Float)))      sinks <- mapM(uncurry(mkMemwriteVectorSink),   zip(writeEngine.writeServers,   writeEngine.dataPipes));

   DmaMatrixMultiplyIfc#(MMSize,DmaSz) dmaMMF <- mkDmaMatrixMultiply(xvfsources, yvfsources, sinks);
   interface Vector readClients = cons(rowReadEngine.dmaClient, cons(colReadEngine.dmaClient, nil));
   interface writeClient = writeEngine.dmaClient;
   method start = dmaMMF.start;
   method finish = dmaMMF.finish;
   interface DmaMatrixMultiplyDebug debug = dmaMMF.debug;
endmodule


interface Mm#(numeric type n);
   interface MmRequest mmRequest;
   interface MmDebugRequest mmDebug;
   interface TimerRequest timerRequest;
   interface Vector#(2, ObjectReadClient#(TMul#(32,N))) readClients;
   interface ObjectWriteClient#(TMul#(32,n)) writeClient;
endinterface

module  mkMm#(MmIndication ind, TimerIndication timerInd, MmDebugIndication mmDebugIndication)(Mm#(N))
   provisos (Add#(1,a__,N),
	     Add#(N,0,n),
	     Mul#(N,32,DmaSz)
      );

   let n = valueOf(n);

   DramMatrixMultiply#(N, TMul#(N,32)) dmaMMF <- mkDramMatrixMultiply();

   Reg#(Bit#(64)) mmfCycles <- mkReg(0);
   rule countMmfCycles;
      mmfCycles <= mmfCycles + 1;
   endrule

   FIFOF#(Bool) busyFifo <- mkFIFOF();
   rule mmfDone;
      let d <- dmaMMF.finish();
      busyFifo.deq();
      ind.mmfDone(mmfCycles);
   endrule

`ifdef DPS_TESTBENCH
   let dps <- mkSharedDotProdServer;
   FIFOF#(Vector#(K, Token)) dpsAFifo <- mkSizedFIFO(32);
   FIFOF#(Vector#(K, Token)) dpsBFifo <- mkSizedFIFO(32);
   mkConnection(toGet(dpsAFifo), dps.aInput);
   mkConnection(toGet(dpsBFifo), dps.bInput);
   rule dpsdebug;
      let v <- toGet(dps.debug.macCount()).get();
   endrule
`endif

   FIFOF#(Bool) timerRunning <- mkFIFOF();
   Reg#(Bit#(64)) cycleCount <- mkReg(0);
   Reg#(Bit#(64)) idleCount <- mkReg(0);
   rule countCycles if (timerRunning.notEmpty());
      cycleCount <= cycleCount + 1;
      if (!busyFifo.notEmpty())
	 idleCount <= idleCount + 1;
   endrule

   interface TimerRequest timerRequest;
      method Action startTimer() if (!timerRunning.notEmpty());
	 cycleCount <= 0;
	 idleCount <= 0;
	 timerRunning.enq(True);
      endmethod
      method Action stopTimer();
	 timerRunning.deq();
	 timerInd.elapsedCycles(cycleCount, idleCount);
      endmethod
   endinterface

   interface MmRequest mmRequest;
      method Action mmf(Bit#(32) h1, Bit#(32) r1, Bit#(32) c1,
			Bit#(32) h2, Bit#(32) r2, Bit#(32) c2,
			Bit#(32) h3);
	 dmaMMF.start(h1, unpack(truncate(r1)), unpack(truncate(c1)),
		      h2, unpack(truncate(r2)), unpack(truncate(c2)),
		      h3);
	 mmfCycles <= 0;
	 busyFifo.enq(True);
      endmethod
      method Action dpsCount(Bit#(32) count);
`ifdef DPS_TESTBENCH
	 dps.numElts <= count;
`endif
      endmethod
      method Action dpsA(Bit#(32) aval);
`ifdef DPS_TESTBENCH
	 aFifo.enq(aval);
`endif
      endmethod
      method Action dpsB(Bit#(32) bval);
`ifdef DPS_TESTBENCH
	 aFifo.enq(bval);
`endif
      endmethod
   endinterface
   interface MmDebugRequest mmDebug;
      method Action debug();
	 let aNotEmpty = dmaMMF.debug.aNotEmpty();
	 let bNotEmpty = dmaMMF.debug.bNotEmpty();
	 let macCount = dmaMMF.debug.macCount();
	 let mmTilesANE = dmaMMF.debug.mmtilesANotEmpty();
	 let mmTilesBNE = dmaMMF.debug.mmtilesBNotEmpty();
	 mmDebugIndication.debug(extend(aNotEmpty), extend(bNotEmpty), macCount, extend(mmTilesANE), extend(mmTilesBNE), 0);
	 mmDebugIndication.bytesRead(
				     dmaMMF.debug.aBytesPut(), dmaMMF.debug.aBytesPut(),
				     dmaMMF.debug.aBytesRead(), dmaMMF.debug.aBytesRead()
				     );
      endmethod
   endinterface

   interface Vector readClients = dmaMMF.readClients;
   interface writeClient =  dmaMMF.writeClient;

endmodule

