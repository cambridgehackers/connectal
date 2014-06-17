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

interface SharedDotProdServer#(numeric type k);
   interface Reg#(UInt#(20)) numElts;
   interface Put#(Float)                 aInput;
   interface Put#(Float)                 bInput;
   interface Vector#(k, PipeOut#(Float)) pipes;
   interface SharedDotProdDebug#(k) debug;
endinterface

(* synthesize *)
module [Module] mkSharedDotProdServer#(UInt#(TLog#(TMul#(J,K))) label)(SharedDotProdServer#(K));

   let n = valueOf(N);
   UInt#(TAdd#(TLog#(K),1)) repetitions = fromInteger(valueOf(K));
   Bool verbose = False;

   Reg#(Bool)      readyReg     <- mkReg(False);
   Reg#(UInt#(20)) numEltsReg   <- mkReg(0);
   Reg#(UInt#(20)) lastCountReg <- mkReg(0);
   Reg#(UInt#(20)) countReg     <- mkReg(0);

   FloatAlu mul   <- mkFloatMultiplier(defaultValue);
   FloatAlu adder <- mkFloatAdder(defaultValue);

   // afifo receives one value per K values received on bfifo
   FIFOF#(Float)                          afifo   <- mkFIFOF();
   PipeOut#(Float)                        aFunnel <- mkRepeat(repetitions, toPipeOut(afifo));

   FIFOF#(Float)                          bfifo <- mkFIFOF();
   PipeOut#(Float)                        bFunnel = toPipeOut(bfifo);

   FIFOF#(Bool) firstFifo <- mkSizedFIFOF(valueOf(K));
   FIFOF#(Bool) lastFifo  <- mkSizedFIFOF(valueOf(K));
   PipeOut#(Bool) firstPipe <- mkRepeat(repetitions, toPipeOut(firstFifo));
   PipeOut#(Bool) lastPipe <- mkRepeat(repetitions,  toPipeOut(lastFifo));

   Vector#(K,FIFOF#(Float)) accumFifos <- replicateM(mkFIFOF1);
   Vector#(K,FIFOF#(Float)) dotfifos   <- replicateM(mkFIFOF1);

   Reg#(Bit#(TLog#(K))) chanReg <- mkReg(0);
   Vector#(2,FIFO#(Bit#(TLog#(K)))) chanFifos <- replicateM(mkSizedFIFO(valueOf(K)));

   function Bit#(TLog#(N)) i_v(Integer i) = fromInteger(i);

   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule countCycles;
      cycles <= cycles + 1;
   endrule

   Vector#(K, Reg#(Bit#(32))) lastMulin <- replicateM(mkReg(0));
   Vector#(12, Reg#(Bool))   latencyReported <- replicateM(mkReg(False));

   Reg#(Bit#(32)) macs <- mkReg(0);

   Reg#(Bool) initialized <- mkReg(False);
   rule init if (!initialized);
      for (Integer chan = 0; chan < valueOf(K); chan = chan + 1)
	 accumFifos[chan].enq(unpack(0));
      initialized <= True;
   endrule

//   (* descending_urgency = "mulin,accout" *)
   rule mulin;
      let chan = chanReg;

      lastMulin[chan] <= cycles;
      begin // measure and display latency
	 let latency = cycles-lastMulin[chan];
	 if ((lastMulin[chan] - cycles) < 6)
	    $display("%08d label=%d mulin chan=%d latency", cycles, label, chan, latency);
	 if (latency > 11) latency = 11;
	 if (!latencyReported[latency]) begin
	    $display("%08d label=%d mulin chan=%d latency", cycles, label, chan, latency);
	    latencyReported[latency] <= True;
	 end
      end

      chanFifos[0].enq(chan);
      chanReg <= (chan + 1);
      let a <- toGet(aFunnel).get();
      let b <- toGet(bFunnel).get();

      let first <- toGet(firstPipe).get();
      if (verbose) $display("%08d label=%d mulin chan=%d first=%d", cycles-lastMulin[chan], label, chan, first);
      mul.request.put(tuple2(a, b));
   endrule

   rule mulout;
      let chan <- toGet(chanFifos[0]).get();
      chanFifos[1].enq(chan);
      //if (label == 0) $display("%08d label=%d mulout chan=%d", cycles, label, chan);
      match {.resp,.*} <- mul.response.get();
      let acc <- toGet(accumFifos[chan]).get();
      //adder.request.put(tuple2(resp,acc));
      adder.request.put(tuple2(resp,acc));
   endrule

   rule accout if (initialized);
      let chan <- toGet(chanFifos[1]).get();
      let last <- toGet(lastPipe).get;
      macs <= macs + 1;
      match {.acc,.*} <- adder.response.get();
      //if (label == 0) $display("%08d label=%d accout chan=%d acc=%x last=%d", cycles, label, chan, pack(acc), last);
      if (last)
	 dotfifos[chan].enq(acc);
      accumFifos[chan].enq(last ? unpack(0) : acc);
   endrule

   Vector#(K,PipeOut#(Float)) dotpipes = map(toPipeOut, dotfifos);

   interface Put aInput;
      method Action put(Float a); // if (readyReg);

   	 afifo.enq(a);

	 let c = countReg+1;
	 Bool isFirst = (countReg == 0);
	 Bool isLast = (countReg == lastCountReg);
	 if (isLast) begin
	    c = 0;
	 end
	 countReg <= c;

	 lastFifo.enq(isLast);
	 firstFifo.enq(isFirst);

      endmethod
   endinterface
   interface Put bInput   = toPut(bfifo);
   interface Vector pipes = dotpipes;
   interface Reg numElts;
      method Action _write(UInt#(20) v); // if (!readyReg);
	 numEltsReg <= v;
	 lastCountReg <= v-1;
	 readyReg <= True;
      endmethod
      method _read = numEltsReg._read;
   endinterface
   interface SharedDotProdDebug debug;
      method PipeOut#(Bit#(32)) macCount = (interface PipeOut#(Bit#(32));
	 method Bit#(32) first(); return macs; endmethod
	 method Action deq(); endmethod
	 method Bool notEmpty(); return False; endmethod
	 endinterface);
      method    Bit#(TLog#(K)) chan(); return chanReg; endmethod
   endinterface
endmodule : mkSharedDotProdServer

interface MmTileDebug;
   interface PipeOut#(Bit#(32)) macCount;
   method Bit#(RowsPerTile) aNotEmpty;
   method Bit#(RowsPerTile) bNotEmpty;
   method Vector#(RowsPerTile, Bit#(TLog#(K))) dotProdChan();
endinterface

interface MmTile;
   interface Vector#(RowsPerTile, Put#(Float)) aInputs;
   interface Vector#(RowsPerTile, Put#(Float)) bInputs;
   interface Vector#(RowsPerTile, PipeOut#(Vector#(N, Float))) fxPipes;
   interface Reg#(UInt#(20)) numElts;
   interface MmTileDebug debug;
endinterface

(* synthesize *)
module [Module] mkMmTile#(UInt#(TLog#(T)) tile)(MmTile);

   let rowsPerTile = valueOf(RowsPerTile);
   let kk = valueOf(K);

   // aFifos receives one value per K values on bFifos
   Vector#(RowsPerTile, FIFOF#(Float))   aFifos <- replicateM(mkFIFOF);
   Vector#(RowsPerTile, PipeOut#(Float)) aPipes = map(toPipeOut, aFifos);
   Vector#(RowsPerTile,  FIFOF#(Float))   bFifos <- replicateM(mkFIFOF);
   Vector#(RowsPerTile,  PipeOut#(Float)) bPipes = map(toPipeOut, bFifos);

   function Vector#(k,PipeOut#(Float)) getDotProdServerPipes(SharedDotProdServer#(k) s); return s.pipes; endfunction
   Vector#(RowsPerTile, SharedDotProdServer#(K)) fxdotprods <- mapM(mkSharedDotProdServer, map(fromInteger,genVector));
   Vector#(RowsPerTile, Vector#(K, PipeOut#(Float))) fxpipes = map(getDotProdServerPipes, fxdotprods);
`define USE_MIMO_DFIFOS // this version is faster
`ifndef USE_MIMO_DFIFOS
   Vector#(RowsPerTile, PipeOut#(Vector#(K, Float))) fxPipesK <- mapM(mkJoinVector(id), fxpipes);
   Vector#(RowsPerTile, PipeOut#(Vector#(N, Float))) fxPipesN <- mapM(mkFunnel, fxPipesK);
`else
   MIMOConfiguration mimoCfg = defaultValue;
   Vector#(RowsPerTile, MIMO#(K,N,TAdd#(K,N),Float)) dfifos <- replicateM(mkMIMO(mimoCfg));
   Vector#(RowsPerTile, PipeOut#(Vector#(N, Float))) fxPipesN = map(toPipeOut, dfifos);
`endif
   FirstLastPipe#(UInt#(MMSize)) firstLastPipe          <- mkFirstLastPipe();
   Vector#(2, PipeOut#(Tuple2#(Bool,Bool))) firstLastPipes <- mkForkVector(firstLastPipe.pipe);

   for (Integer j = 0; j < rowsPerTile; j = j + 1) begin
      mkConnection(toGet(aPipes[j]), fxdotprods[j].aInput);
      mkConnection(toGet(bPipes[j]), fxdotprods[j].bInput);
   end

`ifdef USE_MIMO_DFIFOS
   for (Integer j = 0; j < rowsPerTile; j = j + 1) begin
      rule dotProdValue;
	 Vector#(K,Float) vs;
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
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(mkMap(my_add), map(dotProdMacCount, fxdotprods));

   interface Vector aInputs = map(toPut, aFifos);
   interface Vector bInputs = map(toPut, bFifos);
   interface Vector fxPipes = fxPipesN;
   interface Reg numElts;
      method Action _write(UInt#(20) v);
	 for (Integer i = 0; i < rowsPerTile; i = i+1)
	    fxdotprods[i].numElts <= v;
      endmethod
      method UInt#(20) _read();
	 return fxdotprods[0].numElts;
      endmethod
   endinterface
   interface MmTileDebug debug;
      interface PipeOut macCount = macCountPipe;
      method Bit#(RowsPerTile) aNotEmpty(); return pack(map(fifofNotEmpty, aFifos)); endmethod
      method Bit#(RowsPerTile) bNotEmpty(); return pack(map(fifofNotEmpty, bFifos)); endmethod
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

// row major layout
interface DmaMatrixMultiplyIfc#(numeric type addrwidth, numeric type dsz);
   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC);
   method ActionValue#(Bool) finish();
   method Tuple6#(Bit#(J),Bit#(K),Bit#(32),Bit#(J),Bit#(J),Bit#(TMul#(J,TLog#(K)))) dbg();
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
module [Module] mkDmaMatrixMultiply#(Vector#(J, VectorSource#(dsz, Vector#(N, Float))) sourceA,
				     Vector#(K, VectorSource#(dsz, Vector#(N, Float))) sourceB,
				     Vector#(J, VectorSink#(dsz, Vector#(N,Float)))    sinks
				     )(DmaMatrixMultiplyIfc#(addrwidth, dsz))
   provisos ( Add#(N,n__,K)
	     , Mul#(N,m__,K)
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
      );

   let n = valueOf(N);
   let jj = valueOf(J);
   let kk = valueOf(K);
   let tt = valueOf(T);
   let nshift = valueOf(nshift);
   Bool verbose = False;
   Bool verbose1 = False;
   Bool timing = True;

   Reg#(UInt#(32)) cycles <- mkReg(0);
   Reg#(Bool) doneReg <- mkReg(False);
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorA <- mkReg(unpack(0));
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorB <- mkReg(unpack(0));
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorC <- mkReg(unpack(0));
   Reg#(UInt#(addrwidth)) dotprodCount <- mkReg(0);

   Vector#(J, PipeOut#(Float))       aPipes <- mapM(mkFunnel1, map(vectorSourcePipe, sourceA));
   Vector#(K, PipeOut#(Float))       bPipes <- mapM(mkFunnel1, map(vectorSourcePipe, sourceB));
   PipeOut#(Float)                  bFunnel <- mkFunnelPipes1(bPipes);
   Vector#(J, PipeOut#(Float)) bFunnelPipes <- mkForkVector(bFunnel);

   rule countCycles;
      cycles <= cycles+1;
   endrule

   Vector#(T, MmTile) mmTiles <- mapM(mkMmTile,map(fromInteger,genVector));
   Vector#(J, PipeOut#(Vector#(N,Float))) fxpipes;
   for (Integer t = 0; t < valueOf(T); t = t+1) begin
      for (Integer i = 0; i < valueof(RowsPerTile); i = i+1) begin
	 let j = t*valueOf(RowsPerTile) + i;
	 mkConnection(toGet(aPipes[j]), mmTiles[t].aInputs[i]);
	 mkConnection(toGet(bFunnelPipes[j]), mmTiles[t].bInputs[i]);
	 fxpipes[j] = mmTiles[t].fxPipes[i];
      end
   end
   
   function PipeIn#(a) getPipe(VectorSink#(n,a) vs) = vs.pipe;
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
   for (Integer k = 0; k < kk; k = k + 1) begin
      rule startSourceB;
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

	 sourceB[k].start(descriptorB.pointer, pack(extend(startB>>nshift)), pack(extend(descriptorB.numColumns>>nshift)));

      endrule
      rule finishSourceB;
	 UInt#(TLog#(K)) in = fromInteger(k);
	 int kint = fromInteger(k);
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceB[")+fshow(kint)+fshow("].finish")));
	 let b <- sourceB[k].finish();
      endrule
   end
   for (Integer j = 0; j < jj; j = j + 1) begin

      int jint = fromInteger(j);

      rule startSourceAndSink;
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
	 
	 sourceA[j].start(descriptorA.pointer, pack(extend(startA>>nshift)), pack(extend(descriptorA.numColumns>>nshift)));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].start")+fshow(startA)));
	 sinks[j].start(descriptorC.pointer, pack(extend(startC>>nshift)), fromInteger(kk/n));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("      sinks[")+fshow(jint)+fshow("].start")+fshow(startC)));
	 
      endrule

      rule finishSourceA;
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].finish ")));
	 let b <- sourceA[j].finish();
      endrule

      rule finishSink;
	 $dumpoff();
	 // each time we write a burst of k values via sinks
	 //let index <- toGet(indexpipes[jj+kk+1]).get();
	 let b <- sinks[j].finish();
	 let c = dotprodCount-fromInteger(kk);
	 int jint = fromInteger(j);
	 if (verbose1) $display($format(fshow(cycles)+fshow("    finishSink c")+fshow(c)+fshow(" j=")+fshow(jint)));
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
      for (Integer t = 0; t < tt; t = t+1) begin
	 mmTiles[t].numElts <= truncate(numColumnsA);
      end
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
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(mkMap(my_add), map(mmTileMacCount, mmTiles));
   Reg#(Bit#(32)) macCount <- mkReg(0);
   rule updateMacCount;
      let mc <- toGet(macCountPipe).get();
      macCount <= mc;
   endrule

   function Vector#(RowsPerTile, Bit#(TLog#(K))) getMmTileChans(MmTile mmtile); return mmtile.debug.dotProdChan; endfunction
   function Bit#(RowsPerTile) getMmTilesANotEmpty(MmTile mmtile); return mmtile.debug.aNotEmpty; endfunction
   function Bit#(RowsPerTile) getMmTilesBNotEmpty(MmTile mmtile); return mmtile.debug.bNotEmpty; endfunction

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
   method Tuple6#(Bit#(J),Bit#(K),Bit#(32),Bit#(J),Bit#(J),Bit#(TMul#(J,TLog#(K)))) dbg();
      function Bool pipeNotEmpty(VectorSource#(asz, a) vs); return vs.pipe.notEmpty(); endfunction
      Vector#(J,Bool) aNotEmpty = map(pipeNotEmpty, sourceA);
      Vector#(K,Bool) bNotEmpty = map(pipeNotEmpty, sourceB);
      Bit#(J) mmtilesANotEmpty = pack(map(getMmTilesANotEmpty, mmTiles));
      Bit#(J) mmtilesBNotEmpty = pack(map(getMmTilesBNotEmpty, mmTiles));
      Vector#(T, Vector#(RowsPerTile, Bit#(TLog#(K)))) chans = map(getMmTileChans, mmTiles);
      return tuple6(pack(aNotEmpty), pack(bNotEmpty), macCount, mmtilesANotEmpty, mmtilesBNotEmpty, pack(chans));
   endmethod
endmodule : mkDmaMatrixMultiply

interface DramMatrixMultiply#(numeric type n, numeric type dmasz);
   interface Vector#(2, ObjectReadClient#(dmasz)) readClients;
   interface ObjectWriteClient#(dmasz) writeClient;
   method Action start(ObjectPointer pointerA, UInt#(MMSize) numRowsA, UInt#(MMSize) numColumnsA,
		       ObjectPointer pointerB, UInt#(MMSize) numRowsB, UInt#(MMSize) numColumnsB,
		       ObjectPointer pointerC);
   method ActionValue#(Bool) finish();
   method Tuple6#(Bit#(J),Bit#(K),Bit#(32),Bit#(J),Bit#(J),Bit#(TMul#(J,TLog#(K)))) dbg();
endinterface

(* synthesize *)
module [Module] mkDramMatrixMultiply(DramMatrixMultiply#(N,TMul#(N,32)));
   
   MemreadEngineV#(TMul#(N,32), 1, J) rowReadEngine <- mkMemreadEngine();
   MemreadEngineV#(TMul#(N,32), 1, K) colReadEngine <- mkMemreadEngine();
   MemwriteEngineV#(TMul#(N,32),1, J)   writeEngine <- mkMemwriteEngine();

   Vector#(J, VectorSource#(DmaSz, Vector#(N,Float))) xvfsources <- mapM(uncurry(mkMemreadVectorSource), zip(rowReadEngine.readServers, rowReadEngine.dataPipes));
   Vector#(K, VectorSource#(DmaSz, Vector#(N,Float))) yvfsources <- mapM(uncurry(mkMemreadVectorSource), zip(colReadEngine.readServers, colReadEngine.dataPipes));
   Vector#(J,   VectorSink#(DmaSz, Vector#(N,Float)))      sinks <- mapM(uncurry(mkMemwriteVectorSink),   zip(writeEngine.writeServers,   writeEngine.dataPipes));

   DmaMatrixMultiplyIfc#(MMSize,DmaSz) dmaMMF <- mkDmaMatrixMultiply(xvfsources, yvfsources, sinks);
   interface Vector readClients = cons(rowReadEngine.dmaClient, cons(colReadEngine.dmaClient, nil));
   interface writeClient = writeEngine.dmaClient;
   method start = dmaMMF.start;
   method finish = dmaMMF.finish;
   method Tuple6#(Bit#(J),Bit#(K),Bit#(32),Bit#(J),Bit#(J),Bit#(TMul#(J,TLog#(K)))) dbg();
      return dmaMMF.dbg();
   endmethod
endmodule

interface Mm#(numeric type n);
   interface MmRequest mmRequest;
   interface MmDebugRequest mmDebugRequest;
   interface TimerRequest timerRequest;
   interface Vector#(2, ObjectReadClient#(TMul#(32,N))) readClients;
   interface ObjectWriteClient#(TMul#(32,n)) writeClient;
endinterface

module [Module] mkMm#(MmIndication ind, TimerIndication timerInd, MmDebugIndication mmDebugIndication)(Mm#(N))
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
   endinterface
   interface MmDebugRequest mmDebugRequest;
      method Action debug();
	 match { .aNotEmpty, .bNotEmpty, .macCount, .mmTilesANE, .mmTilesBNE, .chans } = dmaMMF.dbg();
	 mmDebugIndication.debug(extend(aNotEmpty), extend(bNotEmpty), macCount, extend(mmTilesANE), extend(mmTilesBNE), extend(chans));
      endmethod
   endinterface

   interface Vector readClients = dmaMMF.readClients;
   interface writeClient =  dmaMMF.writeClient;

endmodule

