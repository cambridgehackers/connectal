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
`include "ConnectalProjectConfig.bsv"
import FIFO::*;
import FIFOF::*;
import MIMO::*;
import DefaultValue::*;
import SpecialFIFOs::*;
import Vector::*;
import BRAM::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import ConnectalMemUtils::*;
import FloatingPoint::*;
import Pipe::*;
import Arith::*;
import FloatOps::*;
import Timer::*;
import RbmTypes::*;
import Assert::*;
import Connectable::*;
import Clocks::*;
import Gearbox::*;
import XilinxCells::*;
import HostInterface::*;
import DotProdServer::*;
import DmaVector::*;

interface RowColSource#(numeric type dsz, type a);
   interface PipeOut#(a) pipe;
   method Action start(SGLId h, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l, UInt#(32) tag);
   method ActionValue#(Bool) finish();
endinterface

interface RowColSink#(numeric type dsz, type a);
   interface PipeIn#(a) pipe;
   method Action start(SGLId h, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l);
   method ActionValue#(Bool) finish();
endinterface

function PipeOut#(dtype) getRowColSourcePipe(RowColSource#(dsz,dtype) vs); return vs.pipe; endfunction
function PipeIn#(a) getRowColSinkPipe(RowColSink#(n,a) vs) = vs.pipe;

module mkRowColSink#(VectorSink#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSink#(TMul#(N,32), Vector#(N,MmToken)));
   function Float tokenValue(MmToken v) = v.v;
   method Action start(SGLId p, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l);
      vs.start(p,a,l);
   endmethod
   method finish = vs.finish;
   interface PipeIn pipe;
      method Action enq(Vector#(N,MmToken) v);
	 vs.pipe.enq(map(tokenValue,v));
      endmethod
      method Bool notFull = vs.pipe.notFull;
   endinterface
endmodule

module mkRowSource#(VectorSource#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSource#(TMul#(N,32), Vector#(N,MmToken)));
`ifdef TAGGED_TOKENS
   Reg#(UInt#(32)) col <- mkReg(0);
   FIFOF#(UInt#(32)) tagFifo <- mkSizedFIFOF(4);
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(MemOffsetSize)) countReg <- mkReg(0);
   FIFOF#(Bit#(MemOffsetSize)) cmdFifo <- mkSizedFIFOF(4);

   method Action start(SGLId h, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l, UInt#(32) tag);
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
      method Vector#(N,MmToken) first;
	 Vector#(N,MmToken) rv;
`ifdef TAGGED_TOKENS
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{row:tagFifo.first, col:col+fromInteger(i), v:vs.pipe.first[i], first:False, last:False};
`else
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{v:vs.pipe.first[i], first:False, last:False};
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

module mkColSource#(VectorSource#(TMul#(N,32),Vector#(N,Float)) vs) (RowColSource#(TMul#(N,32), Vector#(N,MmToken)));
`ifdef TAGGED_TOKENS
   Reg#(UInt#(32)) row <- mkReg(0);
   FIFOF#(UInt#(32)) tagFifo <- mkSizedFIFOF(4);
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(MemOffsetSize)) countReg <- mkReg(0);
   FIFOF#(Bit#(MemOffsetSize)) cmdFifo <- mkSizedFIFOF(4);

   method Action start(SGLId h, Bit#(MemOffsetSize) a, Bit#(MemOffsetSize) l, UInt#(32) tag);
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
      method Vector#(N,MmToken) first;
	 Vector#(N,MmToken) rv;
`ifdef TAGGED_TOKENS
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{row:row+fromInteger(i), col:tagFifo.first, v:vs.pipe.first[i], first:False, last:False};
`else
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{v:vs.pipe.first[i], first:False, last:False};
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
endmodule: mkColSource
   
// row major layout
interface DmaMatrixMultiplyIfc#(numeric type addrwidth, numeric type dsz);
   method Action start(SGLId pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       SGLId pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       SGLId pointerC,
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
			     HostInterface host
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
	     , Add#(a__, addrwidth, MemOffsetSize)
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

   let derivedClock = host.derivedClock;
   let currentReset <- exposeCurrentReset;
   let derivedReset <- mkAsyncReset(2, currentReset, derivedClock);

   Reg#(UInt#(32)) cycles <- mkReg(0);
   Reg#(Bool) doneReg <- mkReg(False);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoA <- mkSizedFIFOF(1);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoB <- mkSizedFIFOF(1);
   FIFOF#(MatrixDescriptor#(UInt#(addrwidth))) descFifoC <- mkSizedFIFOF(1);
   UnFunnelPipe#(1,J,MatrixDescriptor#(UInt#(addrwidth)),bpc_j) descriptorA <- mkPipelinedForkVector(toPipeOut(descFifoA), 0);
   UnFunnelPipe#(1,K,MatrixDescriptor#(UInt#(addrwidth)),bpc_k) descriptorB <- mkPipelinedForkVector(toPipeOut(descFifoB), 1);
   UnFunnelPipe#(1,J,MatrixDescriptor#(UInt#(addrwidth)),bpc_j) descriptorC <- mkPipelinedForkVector(toPipeOut(descFifoC), 2);
   Reg#(UInt#(addrwidth)) dotprodCount <- mkReg(0);
   
   Vector#(J, RowColSource#(TMul#(N,32), Vector#(N,MmToken))) sourceA <- mapM(mkRowSource, sA);
   Vector#(K, RowColSource#(TMul#(N,32), Vector#(N,MmToken))) sourceB <- mapM(mkColSource, sB);
   Vector#(J, RowColSink#(TMul#(N,32),   Vector#(N,MmToken))) sinks   <- mapM(mkRowColSink,ss);
   Vector#(J, PipeOut#(MmToken))       aPipes <- mapM(mkFunnelGB1(defaultClock, defaultReset, derivedClock, derivedReset), map(getRowColSourcePipe, sourceA));
   Vector#(K, PipeOut#(MmToken))       bPipes <- mapM(mkFunnelGB1(defaultClock, defaultReset, derivedClock, derivedReset), map(getRowColSourcePipe, sourceB));
   PipeOut#(MmToken)                  bFunnel <- mkFunnelPipes1(bPipes, clocked_by derivedClock, reset_by derivedReset);
   Vector#(J, PipeOut#(MmToken)) bFunnelPipes <- mkForkVector(bFunnel, clocked_by derivedClock, reset_by derivedReset);

   rule countCycles;
      cycles <= cycles+1;
   endrule

   UInt#(TAdd#(TLog#(K),1)) repetitions = fromInteger(valueOf(K));
   Vector#(J, PipeOut#(MmToken)) aRepeaters <- mapM(mkRepeat(repetitions), aPipes, clocked_by derivedClock, reset_by derivedReset);

   Vector#(T, MmTile) mmTiles <- mapM(mkMmTile(defaultClock, defaultReset), map(fromInteger,genVector), clocked_by derivedClock, reset_by derivedReset);
   Vector#(J, PipeOut#(Vector#(N,MmToken))) fxpipes;
   for (Integer t = 0; t < valueOf(T); t = t+1) begin
      for (Integer i = 0; i < valueof(RowsPerTile); i = i+1) begin
	 let j = t*valueOf(RowsPerTile) + i;
	 mkConnection(toGet(aRepeaters[j]), mmTiles[t].aInputs[i], clocked_by derivedClock, reset_by derivedReset);
	 mkConnection(toGet(bFunnelPipes[j]), mmTiles[t].bInputs[i], clocked_by derivedClock, reset_by derivedReset);
	 fxpipes[j] = mmTiles[t].fxPipes[i];
      end
   end
   
   zipWithM(mkConnection, fxpipes, map(getRowColSinkPipe, sinks));
   
   XYIteratorIfc#(UInt#(addrwidth)) indexpipeifc <- mkXYIterator();
   XYIteratorIfc#(UInt#(addrwidth)) offsetpipeA <- mkXYIterator();
   XYIteratorIfc#(UInt#(addrwidth)) offsetpipeB <- mkXYIterator();
   XYIteratorIfc#(UInt#(addrwidth)) offsetpipeC <- mkXYIterator();

   Vector#(TAdd#(J,K), PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth)))) indexpipes <- mkForkVector(indexpipeifc.pipe);
   Vector#(J, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth))))        offsetpipesA <- mkForkVector(offsetpipeA.pipe);
   Vector#(K, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth))))        offsetpipesB <- mkForkVector(offsetpipeB.pipe);
   Vector#(J, PipeOut#(Tuple2#(UInt#(addrwidth),UInt#(addrwidth))))        offsetpipesC <- mkForkVector(offsetpipeC.pipe);
   
   Vector#(J, Reg#(UInt#(32))) lastStartAs <- replicateM(mkReg(0));
   Vector#(K, Reg#(UInt#(32))) lastStartBs <- replicateM(mkReg(0));
   Vector#(K, Reg#(UInt#(32))) lastStartCs <- replicateM(mkReg(0));
      
   Reg#(Bool) running <- mkReg(False);
   FIFOF#(Bool) doneFifo <- mkFIFOF();
   FIFOF#(Bool) initNumEltsFifo <- mkFIFOF();
   
   Vector#(J, Reg#(UInt#(addrwidth))) startAOffset <- replicateM(mkReg(0));
   Vector#(K, Reg#(UInt#(addrwidth))) startBOffset <- replicateM(mkReg(0));
   Vector#(J, Reg#(UInt#(addrwidth))) startCOffset <- replicateM(mkReg(0));

   Vector#(K, FIFO#(void)) controlDependenceB <- replicateM(mkFIFO);
   for (Integer k = 0; k < kk; k = k + 1) begin
      rule startSourceB if (!initNumEltsFifo.notEmpty);
	 
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

	 sourceB[k].start(descriptorB[k].first.sglId, pack(extend(startB>>nshift)), pack(extend(descriptorB[k].first.numColumns>>nshift)), extend(col));

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
      rule startSourceAndSink if (!initNumEltsFifo.notEmpty);
	 
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
	 
	 sourceA[j].start(descriptorA[j].first.sglId, pack(extend(startA>>nshift)), pack(extend(descriptorA[j].first.numColumns>>nshift)), extend(row));
	 if (verbose || verbose1) $display($format(fshow(cycles)+fshow("    sourceA[")+fshow(jint)+fshow("].start")+fshow(startA)));
	 sinks[j].start(descriptorC[j].first.sglId, pack(extend(startC>>nshift)), fromInteger(kk/n));
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

   function PipeOut#(Bit#(32)) mmTileMacCount(MmTile mmtile); return mmtile.debug.macCount; endfunction
   Vector#(T, PipeOut#(Vector#(2,Bit#(32)))) macCountPipes <- mapM(mkUnfunnelGB(defaultClock, defaultReset, derivedClock, derivedReset),
								   map(mapPipe(replicate),
								       map(mmTileMacCount, mmTiles)));
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(uncurry(add), map(mapPipe(head),macCountPipes));
   Reg#(Bit#(32)) macCountReg <- mkReg(0);
   rule updateMacCount;
      let mc <- toGet(macCountPipe).get();
      macCountReg <= mc;
   endrule

   function Bool pipeNotEmpty(RowColSource#(asz, a) vs); return vs.pipe.notEmpty(); endfunction

   method Action start(SGLId pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       SGLId pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       SGLId pointerC,
		       UInt#(addrwidth) numRowsA_x_numColumnsA, UInt#(addrwidth) numColumnsA_x_J,
		       UInt#(addrwidth) numRowsB_x_numColumnsB, UInt#(addrwidth) numColumnsB_x_K,
		       UInt#(addrwidth) numRowsA_x_numRowsB,    UInt#(addrwidth) numRowsB_x_J
		       ) if (!running);
      XYIteratorConfig#(UInt#(addrwidth)) indexcfg  = XYIteratorConfig {xbase: 0, xlimit: numRowsA, xstep: fromInteger(jj),
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      XYIteratorConfig#(UInt#(addrwidth)) offsetcfgA = XYIteratorConfig {xbase: 0, xlimit: numRowsA_x_numColumnsA, xstep: numColumnsA_x_J,
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      XYIteratorConfig#(UInt#(addrwidth)) offsetcfgB = XYIteratorConfig {xbase: 0, xlimit: numRowsA, xstep: fromInteger(jj),
								  ybase: 0, ylimit: numRowsB_x_numColumnsB, ystep: numColumnsB_x_K };
      XYIteratorConfig#(UInt#(addrwidth)) offsetcfgC = XYIteratorConfig {xbase: 0, xlimit: numRowsA_x_numRowsB, xstep: numRowsB_x_J,
								  ybase: 0, ylimit: numRowsB, ystep: fromInteger(kk) };
      descFifoA.enq(MatrixDescriptor { sglId: pointerA, base: 0, numRows: numRowsA, numColumns: numColumnsA});
      descFifoB.enq(MatrixDescriptor { sglId: pointerB, base: 0, numRows: numRowsB, numColumns: numColumnsB});
      descFifoC.enq(MatrixDescriptor { sglId: pointerC, base: 0, numRows: numRowsA, numColumns: numRowsB});
      dotprodCount <= numRowsA_x_numRowsB;
      running <= True;

      if (verbose) $display("mm pointerA=%d pointerB=%d pointerC=%d\n", pointerA, pointerB, pointerC);
      if (verbose) $display("mm.start ra=%d ca=%d rb=%d cb=%d dotprodCount=%d", numRowsA, numColumnsA, numRowsB, numColumnsB, dotprodCount);
      if (verbose) $display($format(fshow("mm.start ")+fshow(indexcfg)));
      if (verbose) $display($format(fshow("offsetcfgA ")+fshow(offsetcfgA)));
      if (verbose) $display($format(fshow("offsetcfgB ")+fshow(offsetcfgB)));
      if (verbose) $display($format(fshow("offsetcfgC ")+fshow(offsetcfgC)));

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

interface DramMatrixMultiply#(numeric type n, numeric type dmasz, numeric type nm);
   interface Vector#(nm, MemReadClient#(dmasz)) readClients;
   interface Vector#(nm, MemWriteClient#(dmasz)) writeClients;
   method Action start(SGLId pointerA, UInt#(MMSize) numRowsA, UInt#(MMSize) numColumnsA,
		       SGLId pointerB, UInt#(MMSize) numRowsB, UInt#(MMSize) numColumnsB,
		       SGLId pointerC,
		       UInt#(MMSize) numRowsA_x_numColumnsA, UInt#(MMSize) numColumnsA_x_J,
		       UInt#(MMSize) numRowsB_x_numColumnsB, UInt#(MMSize) numColumnsB_x_K,
		       UInt#(MMSize) numRowsA_x_numRowsB,    UInt#(MMSize) numRowsB_x_J);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface

module  mkDramMatrixMultiply#(HostInterface host)(DramMatrixMultiply#(N,TMul#(N,32),2));
   MemWriteEngine#(TMul#(N,32),TMul#(N,32),2, J)   writeEngine <- mkMemWriteEngine();
   MemReadEngine#(TMul#(N,32), TMul#(N,32), 2, J) rowReadEngine <- mkMemReadEngineBuff(512);
   MemReadEngine#(TMul#(N,32), TMul#(N,32), 2, K) colReadEngine <- mkMemReadEngineBuff(512);
   
   Vector#(J, MemReadServer#(TMul#(N,32))) rowReadServers = rowReadEngine.readServers;
   Vector#(K, MemReadServer#(TMul#(N,32))) colReadServers = colReadEngine.readServers;
      
   MemWriter#(TMul#(32,N)) bogusWriter <- mkMemWriter;
   
   Vector#(J, VectorSource#(DmaSz, Vector#(N,Float))) xvfsources <- mapM(mkMemReadVectorSource, rowReadServers);
   Vector#(K, VectorSource#(DmaSz, Vector#(N,Float))) yvfsources <- mapM(mkMemReadVectorSource, colReadServers);
   Vector#(J,   VectorSink#(DmaSz, Vector#(N,Float)))      sinks <- mapM(mkMemWriteVectorSink, writeEngine);
   
   DmaMatrixMultiplyIfc#(MMSize,DmaSz) dmaMMF <- mkDmaMatrixMultiply(xvfsources, yvfsources, sinks, host);
   interface Vector readClients  = cons(rowReadEngine.dmaClient, cons(colReadEngine.dmaClient, nil));
   interface Vector writeClients = cons(writeEngine.dmaClient,   cons(bogusWriter.writeClient, nil));
   method start = dmaMMF.start;
   method finish = dmaMMF.finish;
   interface DmaMatrixMultiplyDebug debug = dmaMMF.debug;
endmodule
   
interface MmNT#(numeric type n);
   interface MmRequestNT mmRequest;
   interface TimerRequest timerRequest;
   interface Vector#(2, MemReadClient#(TMul#(32,n)))  readClients;
   interface Vector#(2, MemWriteClient#(TMul#(32,n))) writeClients;
endinterface

module  mkMmNT#(MmIndication ind, TimerIndication timerInd, HostInterface host)(MmNT#(N))
   provisos (Add#(1,a__,N),
	     Add#(N,0,n),
	     Mul#(N,32,DmaSz)
	     );

   let n = valueOf(n);

   DramMatrixMultiply#(N,TMul#(N,32),2) dmaMMF <- mkDramMatrixMultiply(host);

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

   interface MmRequestNT mmRequest;
      method Action mmf(Bit#(32) h1, Bit#(32) r1, Bit#(32) c1,
			Bit#(32) h2, Bit#(32) r2, Bit#(32) c2,
			Bit#(32) h3,
			Bit#(32) r1_x_c1, Bit#(32) c1_x_j,
			Bit#(32) r2_x_c2, Bit#(32) c2_x_k,
			Bit#(32) r1_x_r2, Bit#(32) r2_x_j);
	 check_dimension(r1);
	 check_dimension(c1);
	 check_dimension(r2);
	 check_dimension(c2);
	 dmaMMF.start(h1, unpack(truncate(r1)), unpack(truncate(c1)),
		      h2, unpack(truncate(r2)), unpack(truncate(c2)),
		      h3,
		      unpack(truncate(r1_x_c1)), unpack(truncate(c1_x_j)),
		      unpack(truncate(r2_x_c2)), unpack(truncate(c2_x_k)),
		      unpack(truncate(r1_x_r2)), unpack(truncate(r2_x_j)));

	 mmfCycles <= 0;
	 busyFifo.enq(True);
      endmethod
      method Action debug();
	 let macCount = dmaMMF.debug.macCount();
	 ind.debug(macCount);
      endmethod
   endinterface

   interface Vector readClients = dmaMMF.readClients;
   interface Vector writeClients =  dmaMMF.writeClients;

endmodule
