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
import Clocks::*;
import Gearbox::*;
import XilinxCells::*;
import HostInterface::*;

interface SharedDotProdDebug#(numeric type k);
   interface PipeOut#(Bit#(32)) macCount;
endinterface


typedef struct {
//`define TAGGED_TOKENS
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
function PipeOut#(dtype) getRowColSourcePipe(RowColSource#(dsz,dtype) vs); return vs.pipe; endfunction
function PipeIn#(a) getRowColSinkPipe(RowColSink#(n,a) vs) = vs.pipe;

module mkRowColSink#(VectorSink#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSink#(TMul#(N,32), Vector#(N,Token)));
   function Float tokenValue(Token v) = v.v;
   method Action start(ObjectPointer p, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
      vs.start(p,a,l);
   endmethod
   method finish = vs.finish;
   interface PipeIn pipe;
      method Action enq(Vector#(N,Token) v);
	 vs.pipe.enq(map(tokenValue,v));
      endmethod
      method Bool notFull = vs.pipe.notFull;
   endinterface
endmodule

module mkRowSource#(VectorSource#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSource#(TMul#(N,32), Vector#(N,Token)));
`ifdef TAGGED_TOKENS
   Reg#(UInt#(32)) col <- mkReg(0);
   FIFOF#(UInt#(32)) tagFifo <- mkSizedFIFOF(4);
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(ObjectOffsetSize)) countReg <- mkReg(0);
   FIFOF#(Bit#(ObjectOffsetSize)) cmdFifo <- mkSizedFIFOF(4);

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
   FIFOF#(UInt#(32)) tagFifo <- mkSizedFIFOF(4);
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(ObjectOffsetSize)) countReg <- mkReg(0);
   FIFOF#(Bit#(ObjectOffsetSize)) cmdFifo <- mkSizedFIFOF(4);

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


typedef 8 UB_MulLat; // upper bound on MUL latency?
typedef 8 UB_AddLat; // upper bound on ADD latency?
	   
(* synthesize *)
module  mkSharedInterleavedDotProdServer#(UInt#(TLog#(TMul#(J,K))) label)(SharedDotProdServer#(K))
   provisos(Div#(UB_AddLat,K,gatherSz));
    
   let ub_MulLat = valueOf(UB_MulLat);
   let ub_AddLat = valueOf(UB_AddLat);
   let kk = valueOf(K);

   Bool verbose = False; //label == 0;
   
   Reg#(UInt#(20)) countReg     <- mkReg(0);

   FloatAlu mul   <- mkFloatMultiplier(defaultValue);
   FloatAlu adder <- mkFloatAdder(defaultValue);
   FIFOF#(Float) adder_buffer <- mkSizedFIFOF(valueOf(TMul#(K,gatherSz)));
   
`ifdef TAGGED_TOKENS
   FIFO#(Tuple2#(UInt#(32),UInt#(32))) tag_fifo <- mkSizedFIFO(ub_MulLat); 
   Vector#(K,Reg#(Tuple2#(UInt#(32),UInt#(32)))) tag_regs <- replicateM(mkRegU);
`endif   
   
   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule countCycles;
      cycles <= cycles + 1;
   endrule

   FIFOF#(Token)                          afifo   <- mkFIFOF();
   PipeOut#(Token)                        aFunnel = toPipeOut(afifo);

   FIFOF#(Token)                          bfifo <- mkFIFOF();
   PipeOut#(Token)                        bFunnel = toPipeOut(bfifo);

   Reg#(Bit#(16)) firstCnt <- mkReg(0);
   Reg#(Bool)         gReg <- mkReg(False);
   FIFOF#(Float)     gFifo <- mkSizedFIFOF(kk);
   Reg#(Bit#(16))  lastCnt <- mkReg(0);
   Reg#(Bit#(16))gatherCnt <- mkReg(0);

   FIFOF#(Tuple2#(Bool,Bool))    flFifo <- mkSizedFIFOF(ub_MulLat);
   Vector#(K,FIFOF#(Token))    dotfifos <- replicateM(mkFIFOF1);
   Reg#(Bit#(TAdd#(1,TLog#(K)))) rowReg <- mkReg(0);
      
   Reg#(Bit#(32)) lastMul <- mkReg(0);
   Reg#(Bit#(32)) lastAcc <- mkReg(0);
   Reg#(Bit#(32)) lastGather <- mkReg(0);
   Reg#(Bit#(32)) macs <- mkReg(0);
   
   let gather_phase = lastCnt == fromInteger(kk);
   
   (* fire_when_enabled *)
   rule connect_adder_buffer;
      match {.acc,.*} <- adder.response.get();
      adder_buffer.enq(acc);
      macs <= macs+1;
   endrule
   
   (* fire_when_enabled *)
   rule multiply;
      lastMul <= cycles;
      let a <- toGet(aFunnel).get();
      let b <- toGet(bFunnel).get();
      flFifo.enq(tuple2(a.first,a.last));
      if (a.first != b.first) 
	 $display("****\n    Warning: a.first=%d != b.first=%d\n****", a.first, b.first);
      if (a.last != b.last) 
	 $display("****\n    Warning: a.last=%d != b.last=%d\n****", a.last, b.last);
      if (verbose) 
	 $display("%08d multiply: label=%d mulin first=%d last=%d", cycles-lastMul, label, a.first, a.last);
      mul.request.put(tuple2(a.v, b.v));
`ifdef TAGGED_TOKENS
      tag_fifo.enq(tuple2(a.row,b.col));
`endif
   endrule
   
   function Action incrementRowReg = 
      (action
	  // I have to do this check (instead of relying on wrap-around) because
	  // rowReg has an extra bit to compenseate for bsc's silly Bit#(0) handling
	  if (rowReg+1 == fromInteger(kk)) rowReg <= 0;
	  else rowReg <= rowReg+1;
       endaction);

   
   (* fire_when_enabled *)
   rule accumulate if (!gather_phase);
      incrementRowReg;
      lastAcc <= cycles;
      match {.first, .last} <- toGet(flFifo).get();
      if (verbose) $display("%08d accumulate: label=%d mulout first=%d last=%d firstCnt=%d lastCnt=%d", 
			    cycles-lastAcc, label, first, last, firstCnt, lastCnt);
      match {.resp,.*} <- mul.response.get;
      let acc = unpack(0);
      if (firstCnt == fromInteger(valueOf(TMul#(K,gatherSz))))
	 acc <- toGet(adder_buffer).get;
      else begin
	 firstCnt <= firstCnt+1;
      end
      adder.request.put(tuple2(resp,acc));
      if(last) begin
	 lastCnt <= lastCnt+1;
      end
`ifdef TAGGED_TOKENS
      let row = rowReg;
      let t <- toGet(tag_fifo).get;
      tag_regs[row] <= t;
`endif
   endrule

   
   (* fire_when_enabled *)
   rule gather if (gather_phase);
      incrementRowReg;
      lastGather <= cycles;
      let row = rowReg;
      let last_row = row == fromInteger(kk-1);
      let last_pass = gatherCnt+1 == fromInteger(valueOf(gatherSz));
      if (verbose)
	 $display("%08d gather: gather=%d row=%d last_pass=%d last_row=%d, gReg=%d", 
		  cycles-lastGather, gatherCnt, row, last_pass, last_row, gReg);
      let x <- toGet(adder_buffer).get;
      if (!last_pass) begin
	 if (last_row) begin
	    if (gReg) gatherCnt <= gatherCnt+1;
	    gReg <= !gReg;
	 end
	 if(gReg) begin
	    let y <- toGet(gFifo).get;
	    adder.request.put(tuple2(x,y));
	 end
	 else begin
	    gFifo.enq(x);
	 end
      end
      else begin
`ifdef TAGGED_TOKENS
      	 let row = tpl_1(tag_regs[row]);
      	 let col = tpl_2(tag_regs[row]);
	 dotfifos[row].enq(Token{row:row, col:col, v:x});
`else
	 dotfifos[row].enq(Token{v:x});
`endif      
	 if (last_row) begin
	    gatherCnt <= 0;
	    lastCnt <= 0;
	    firstCnt <= 0;
	 end 
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
   endinterface
endmodule : mkSharedInterleavedDotProdServer

interface MmTileDebug;
   interface PipeOut#(Bit#(32)) macCount;
endinterface

interface MmTile;
   interface Vector#(RowsPerTile, Put#(Token)) aInputs;
   interface Vector#(RowsPerTile, Put#(Token)) bInputs;
   interface Vector#(RowsPerTile, PipeOut#(Vector#(N, Token))) fxPipes;
   interface MmTileDebug debug;
endinterface

(* synthesize *)
module  mkMmTile#(Clock slowClock, Reset slowReset, UInt#(TLog#(T)) tile)(MmTile);

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
   Vector#(RowsPerTile, SharedDotProdServer#(K)) fxdotprods <- mapM(mkSharedInterleavedDotProdServer, map(fromInteger,genVector));
   Vector#(RowsPerTile, Vector#(K, PipeOut#(Token))) fxpipes = map(getDotProdServerPipes, fxdotprods);
//`define USE_MIMO_DFIFOS // this version is faster
   let fastClock <- exposeCurrentClock();
   let fastReset <- exposeCurrentReset();
`ifndef USE_MIMO_DFIFOS
   Vector#(RowsPerTile, PipeOut#(Vector#(K, Token))) fxPipesK <- mapM(mkJoinVector(id), fxpipes);
   Vector#(RowsPerTile, PipeOut#(Token)) fxPipes1Token <- mapM(mkFunnel1, fxPipesK);
   Vector#(RowsPerTile, PipeOut#(Vector#(1, Token))) fxPipes1 = map(mapPipe(replicate), fxPipes1Token);
`else
   MIMOConfiguration mimoCfg = defaultValue;
   Vector#(RowsPerTile, MIMO#(K,1,TAdd#(K,1),Token)) dfifos <- replicateM(mkMIMO(mimoCfg));
   Vector#(RowsPerTile, PipeOut#(Vector#(1, Token))) fxPipes1 = map(toPipeOut, dfifos);
`endif
   Vector#(RowsPerTile, Gearbox#(1, N, Token)) gearboxes <- replicateM(mk1toNGearbox(fastClock, fastReset, slowClock, slowReset));
   Vector#(RowsPerTile, PipeIn#(Vector#(1,Token))) toGearboxes = map(toPipeIn, gearboxes);
   Vector#(RowsPerTile, PipeOut#(Vector#(N, Token))) fromGearboxes = map(toPipeOut, gearboxes);
   mapM(uncurry(mkConnection), zip(fxPipes1, toGearboxes));
   // introduce a buffer to help vivado meet timing on vc707
   Vector#(RowsPerTile, FIFOF#(Vector#(N,Token)))    tokenfifos <- replicateM(mkFIFOF(clocked_by slowClock, reset_by slowReset));
   Vector#(RowsPerTile, PipeIn#(Vector#(N,Token))) toTokenFifos = map(toPipeIn, tokenfifos);
   mapM(uncurry(mkConnection), zip(fromGearboxes, toTokenFifos), clocked_by slowClock, reset_by slowReset);
   Vector#(RowsPerTile, PipeOut#(Vector#(N, Token))) fxPipesN = map(toPipeOut, tokenfifos);

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
   function PipeOut#(Bit#(32)) dotProdMacCount(SharedDotProdServer#(K) dotprodserver); return dotprodserver.debug.macCount; endfunction
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(my_add, map(dotProdMacCount, fxdotprods));

   interface Vector aInputs = zipWith(toCountedPut, aTokensPutRegs, map(toPut, aFifos));
   interface Vector bInputs = zipWith(toCountedPut, bTokensPutRegs, map(toPut, bFifos));
   interface Vector fxPipes = fxPipesN;
   interface MmTileDebug debug;
      interface PipeOut macCount = macCountPipe;
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
   method Bit#(32) macCount();
endinterface
   
// row major layout
interface DmaMatrixMultiplyIfc#(numeric type addrwidth, numeric type dsz);
   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(addrwidth) numRowsA_x_numColumnsA, UInt#(addrwidth) numColumnsA_x_J,
		       UInt#(addrwidth) numRowsB_x_numColumnsB, UInt#(addrwidth) numColumnsB_x_K,
		       UInt#(addrwidth) numRowsA_x_numRowsB,    UInt#(addrwidth) numRowsB_x_J);
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
			     Vector#(J, VectorSink#(dsz, Vector#(N,Float)))    ss,
			     HostType host
			     )(DmaMatrixMultiplyIfc#(addrwidth, dsz))
   provisos (  Mul#(N,n__,K) // K must be an integer multiple of N
	     , Mul#(N,m__,J) // J must be an integer multiple of N
             , Add#(1,o__,J)
	     , Log#(N,nshift)
	     , FShow#(Float)
	     , Arith#(Float)
	     , Bits#(Vector#(N, Float), dsz)
	     , Bits#(MatrixDescriptor#(UInt#(addrwidth)), mdsz)
	     , Bits#(Tuple2#(UInt#(addrwidth), UInt#(addrwidth)), tplsz)
	     , Add#(b__, 20, addrwidth)
	     , Add#(a__, addrwidth, 40)
	     , Add#(c__, addrwidth, 32)
	     , Max#(1, TDiv#(TLog#(J),2), bpc_j)
	     , Max#(1, TDiv#(TLog#(K),2), bpc_k)
      );

   let n = valueOf(N);
   let jj = valueOf(J);
   let kk = valueOf(K);
   let tt = valueOf(T);
   let nshift = valueOf(nshift);
   Bool verbose = False;
   Bool verbose1 = False;
   Bool timing = False;

   let defaultClock <- exposeCurrentClock();
   let defaultReset <- exposeCurrentReset();

   let doubleClock = host.doubleClock;
   let doubleReset = host.doubleReset;

   Reg#(UInt#(32)) cycles <- mkReg(0);
   Reg#(Bool) doneReg <- mkReg(False);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoA <- mkSizedFIFOF(1);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoB <- mkSizedFIFOF(1);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoC <- mkSizedFIFOF(1);
   UnFunnelPipe#(1,J,MatrixDescriptor#(UInt#(addrwidth)),bpc_j) descriptorA <- mkPipelinedForkVector(toPipeOut(descFifoA));
   UnFunnelPipe#(1,K,MatrixDescriptor#(UInt#(addrwidth)),bpc_k) descriptorB <- mkPipelinedForkVector(toPipeOut(descFifoB));
   UnFunnelPipe#(1,J,MatrixDescriptor#(UInt#(addrwidth)),bpc_j) descriptorC <- mkPipelinedForkVector(toPipeOut(descFifoC));
   Reg#(UInt#(addrwidth)) dotprodCount <- mkReg(0);
   
   Vector#(J, RowColSource#(TMul#(N,32), Vector#(N,Token))) sourceA <- mapM(mkRowSource, sA);
   Vector#(K, RowColSource#(TMul#(N,32), Vector#(N,Token))) sourceB <- mapM(mkColSource, sB);
   Vector#(J, RowColSink#(TMul#(N,32),   Vector#(N,Token))) sinks   <- mapM(mkRowColSink,ss);
   Vector#(J, PipeOut#(Token))       aPipes <- mapM(mkFunnelGB1(defaultClock, defaultReset, doubleClock, doubleReset), map(getRowColSourcePipe, sourceA));
   Vector#(K, PipeOut#(Token))       bPipes <- mapM(mkFunnelGB1(defaultClock, defaultReset, doubleClock, doubleReset), map(getRowColSourcePipe, sourceB));
   PipeOut#(Token)                  bFunnel <- mkFunnelPipes1(bPipes, clocked_by doubleClock, reset_by doubleReset);
   Vector#(J, PipeOut#(Token)) bFunnelPipes <- mkForkVector(bFunnel, clocked_by doubleClock, reset_by doubleReset);

   rule countCycles;
      cycles <= cycles+1;
   endrule

   UInt#(TAdd#(TLog#(K),1)) repetitions = fromInteger(valueOf(K));
   Vector#(J, PipeOut#(Token)) aRepeaters <- mapM(mkRepeat(repetitions), aPipes, clocked_by doubleClock, reset_by doubleReset);

   Vector#(T, MmTile) mmTiles <- mapM(mkMmTile(defaultClock, defaultReset), map(fromInteger,genVector), clocked_by doubleClock, reset_by doubleReset);
   Vector#(J, PipeOut#(Vector#(N,Token))) fxpipes;
   for (Integer t = 0; t < valueOf(T); t = t+1) begin
      for (Integer i = 0; i < valueof(RowsPerTile); i = i+1) begin
	 let j = t*valueOf(RowsPerTile) + i;
	 mkConnection(toGet(aRepeaters[j]), mmTiles[t].aInputs[i], clocked_by doubleClock, reset_by doubleReset);
	 mkConnection(toGet(bFunnelPipes[j]), mmTiles[t].bInputs[i], clocked_by doubleClock, reset_by doubleReset);
	 fxpipes[j] = mmTiles[t].fxPipes[i];
      end
   end
   
   zipWithM(mkConnection, fxpipes, map(getRowColSinkPipe, sinks));
   
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

   Vector#(K, FIFO#(void)) controlDependenceB <- replicateM(mkFIFO);
   for (Integer k = 0; k < kk; k = k + 1) begin
      rule startSourceB;

	 if(k > 0)
	    controlDependenceB[k-1].deq;
	 if(k < kk-1)
	    controlDependenceB[k].enq(?);

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

	 sourceB[k].start(descriptorB[k].first.pointer, pack(extend(startB>>nshift)), pack(extend(descriptorB[k].first.numColumns>>nshift)), extend(col));

      endrule
      rule finishSourceB;
	 UInt#(TLog#(K)) in = fromInteger(k);
	 int kint = fromInteger(k);
	 if (timing || verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceB[")+fshow(kint)+fshow("].finish")));
	 let b <- sourceB[k].finish();
      endrule
   end
   Vector#(J, FIFO#(void)) controlDependenceA <- replicateM(mkFIFO);
   for (Integer j = 0; j < jj; j = j + 1) begin

      int jint = fromInteger(j);

      rule startSourceAndSink;
	 
	 if(j > 0)
	    controlDependenceA[j-1].deq;
	 if(j < jj-1)
	    controlDependenceA[j].enq(?);
	 
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
	 
	 sourceA[j].start(descriptorA[j].first.pointer, pack(extend(startA>>nshift)), pack(extend(descriptorA[j].first.numColumns>>nshift)), extend(row));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].start")+fshow(startA)));
	 sinks[j].start(descriptorC[j].first.pointer, pack(extend(startC>>nshift)), fromInteger(kk/n));
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
	    for(Integer i = 0; i < kk; i=i+1)
	       descriptorB[i].deq;
	    for(Integer i = 0; i < jj; i=i+1) begin
	       descriptorA[i].deq;
	       descriptorC[i].deq;
	    end
	 end
      endrule
   end

   FIFO#(Bool) initNumEltsFifo <- mkFIFO();
   rule dotProdsNumElts;
      initNumEltsFifo.deq();
      let numColumnsA = descriptorA[0].first.numColumns;
      let numColumnsB = descriptorB[0].first.numColumns;
      let numRowsB    = descriptorB[0].first.numRows;
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
   Vector#(T, PipeOut#(Vector#(2,Bit#(32)))) macCountPipes <- mapM(mkUnfunnelGB(defaultClock, defaultReset, doubleClock, doubleReset),
								   map(mapPipe(replicate),
								       map(mmTileMacCount, mmTiles)));
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(my_add, map(mapPipe(head),macCountPipes));
   Reg#(Bit#(32)) macCountReg <- mkReg(0);
   rule updateMacCount;
      let mc <- toGet(macCountPipe).get();
      macCountReg <= mc;
   endrule

   function Bool pipeNotEmpty(RowColSource#(asz, a) vs); return vs.pipe.notEmpty(); endfunction

   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(addrwidth) numRowsA_x_numColumnsA, UInt#(addrwidth) numColumnsA_x_J,
		       UInt#(addrwidth) numRowsB_x_numColumnsB, UInt#(addrwidth) numColumnsB_x_K,
		       UInt#(addrwidth) numRowsA_x_numRowsB,    UInt#(addrwidth) numRowsB_x_J
		       ) if (!running);
      XYRangeConfig#(UInt#(addrwidth)) indexcfg  = XYRangeConfig {xbase: 0, xlimit: numRowsA, xstep: fromInteger(jj),
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgA = XYRangeConfig {xbase: 0, xlimit: numRowsA_x_numColumnsA, xstep: numColumnsA_x_J,
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgB = XYRangeConfig {xbase: 0, xlimit: numRowsA, xstep: fromInteger(jj),
								  ybase: 0, ylimit: numRowsB_x_numColumnsB, ystep: numColumnsB_x_K };
      XYRangeConfig#(UInt#(addrwidth)) offsetcfgC = XYRangeConfig {xbase: 0, xlimit: numRowsA_x_numRowsB, xstep: numRowsB_x_J,
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      descFifoA.enq(MatrixDescriptor { pointer: pointerA, base: 0, numRows: numRowsA, numColumns: numColumnsA});
      descFifoB.enq(MatrixDescriptor { pointer: pointerB, base: 0, numRows: numRowsB, numColumns: numColumnsB});
      descFifoC.enq(MatrixDescriptor { pointer: pointerC, base: 0, numRows: numRowsA, numColumns: numRowsB});
      dotprodCount <= numRowsA_x_numRowsB;
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
    endinterface
endmodule : mkDmaMatrixMultiply

interface DramMatrixMultiply#(numeric type n, numeric type dmasz);
   interface Vector#(4, ObjectReadClient#(dmasz)) readClients;
   interface ObjectWriteClient#(dmasz) writeClient;
   method Action start(ObjectPointer pointerA, UInt#(MMSize) numRowsA, UInt#(MMSize) numColumnsA,
		       ObjectPointer pointerB, UInt#(MMSize) numRowsB, UInt#(MMSize) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(MMSize) numRowsA_x_numColumnsA, UInt#(MMSize) numColumnsA_x_J,
		       UInt#(MMSize) numRowsB_x_numColumnsB, UInt#(MMSize) numColumnsB_x_K,
		       UInt#(MMSize) numRowsA_x_numRowsB,    UInt#(MMSize) numRowsB_x_J);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface

//(* synthesize *)
module  mkDramMatrixMultiply#(HostType host)(DramMatrixMultiply#(N,TMul#(N,32)))
   provisos (Div#(J,2,halfJ),Div#(K,2,halfK));

   MemreadEngineV#(TMul#(N,32), 2, halfJ) rowReadEngine0 <- mkMemreadEngineBuff(512);
   MemreadEngineV#(TMul#(N,32), 2, halfJ) rowReadEngine1 <- mkMemreadEngineBuff(512);
   MemreadEngineV#(TMul#(N,32), 2, halfK) colReadEngine0 <- mkMemreadEngineBuff(512);
   MemreadEngineV#(TMul#(N,32), 2, halfK) colReadEngine1 <- mkMemreadEngineBuff(512);
   MemwriteEngineV#(TMul#(N,32),2, J)   writeEngine <- mkMemwriteEngine();

   Vector#(J, Server#(MemengineCmd,Bool)) rowReadServers = take(append(rowReadEngine0.readServers, rowReadEngine1.readServers));
   Vector#(K, Server#(MemengineCmd,Bool)) colReadServers = take(append(colReadEngine0.readServers, colReadEngine1.readServers));
   Vector#(J, PipeOut#(Bit#(TMul#(N,32)))) rowReadDataPipes = take(append(rowReadEngine0.dataPipes, rowReadEngine1.dataPipes));
   Vector#(K, PipeOut#(Bit#(TMul#(N,32)))) colReadDataPipes = take(append(colReadEngine0.dataPipes, colReadEngine1.dataPipes));

   Vector#(J, VectorSource#(DmaSz, Vector#(N,Float))) xvfsources <- mapM(uncurry(mkMemreadVectorSource), zip(rowReadServers, rowReadDataPipes));
   Vector#(K, VectorSource#(DmaSz, Vector#(N,Float))) yvfsources <- mapM(uncurry(mkMemreadVectorSource), zip(colReadServers, colReadDataPipes));
   Vector#(J,   VectorSink#(DmaSz, Vector#(N,Float)))      sinks <- mapM(uncurry(mkMemwriteVectorSink),   zip(writeEngine.writeServers,   writeEngine.dataPipes));

   DmaMatrixMultiplyIfc#(MMSize,DmaSz) dmaMMF <- mkDmaMatrixMultiply(xvfsources, yvfsources, sinks, host);
   interface Vector readClients = cons(rowReadEngine0.dmaClient, cons(colReadEngine0.dmaClient, cons(rowReadEngine1.dmaClient, cons(colReadEngine1.dmaClient, nil))));
   interface writeClient = writeEngine.dmaClient;
   method start = dmaMMF.start;
   method finish = dmaMMF.finish;
   interface DmaMatrixMultiplyDebug debug = dmaMMF.debug;
endmodule


interface Mm#(numeric type n);
   interface MmRequest mmRequest;
   interface MmDebugRequest mmDebug;
   interface TimerRequest timerRequest;
   interface Vector#(4, ObjectReadClient#(TMul#(32,n))) readClients;
   interface ObjectWriteClient#(TMul#(32,n)) writeClient;
endinterface

module  mkMm#(MmIndication ind, TimerIndication timerInd, MmDebugIndication mmDebugIndication, HostType host)(Mm#(N))
   provisos (Add#(1,a__,N),
	     Add#(N,0,n),
	     Mul#(N,32,DmaSz)
      );

   let n = valueOf(n);

   DramMatrixMultiply#(N, TMul#(N,32)) dmaMMF <- mkDramMatrixMultiply(host);

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
			Bit#(32) h3,
			Bit#(32) r1_x_c1, Bit#(32) c1_x_j,
			Bit#(32) r2_x_c2, Bit#(32) c2_x_k,
			Bit#(32) r1_x_r2, Bit#(32) r2_x_j);
	 dmaMMF.start(h1, unpack(truncate(r1)), unpack(truncate(c1)),
		      h2, unpack(truncate(r2)), unpack(truncate(c2)),
		      h3,
		      unpack(truncate(r1_x_c1)), unpack(truncate(c1_x_j)),
		      unpack(truncate(r2_x_c2)), unpack(truncate(c2_x_k)),
		      unpack(truncate(r1_x_r2)), unpack(truncate(r2_x_j)));

	 mmfCycles <= 0;
	 busyFifo.enq(True);
      endmethod
   endinterface
   interface MmDebugRequest mmDebug;
      method Action debug();
	 let macCount = dmaMMF.debug.macCount();
	 mmDebugIndication.debug(macCount);
      endmethod
   endinterface

   interface Vector readClients = dmaMMF.readClients;
   interface writeClient =  dmaMMF.writeClient;

endmodule

