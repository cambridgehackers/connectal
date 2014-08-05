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

import BRAMFIFO::*;
import FIFO::*;
import FIFOF::*;
import MIMO::*;
import DefaultValue::*;
import SpecialFIFOs::*;
import Vector::*;
import DmaVector::*;
import PortalMemory::*;
import MemTypes::*;
import MemUtils::*;
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
import ClientServer::*;
import GetPut::*;

interface RowColSource#(numeric type dsz, type a);
   interface PipeOut#(a) pipe;
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l, UInt#(32) tag);
endinterface

interface RowColSink#(numeric type dsz, type a);
   interface PipeIn#(a) pipe;
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
   method ActionValue#(Bool) finish();
endinterface

typedef struct {
   a xbase;
   a xlimit;
   a xstep;
   a ybase;
   a ylimit;
   a ystep;
   a zbase;
   a zlimit;
   a zstep;
} XYZRangeConfig#(type a) deriving (Bits, FShow);

interface XYZRangePipeIfc#(type a);
   interface PipeOut#(Tuple2#(a,a)) pipe;
   method Action start(XYZRangeConfig#(a) cfg);
   method Action display();
endinterface

typedef enum {RangeA,RangeB,RangeC} RangeBehavior deriving (Eq); 

module mkXYZRangePipeOut#(RangeBehavior alt) (XYZRangePipeIfc#(a)) provisos (Arith#(a), Bits#(a,awidth), Eq#(a), Ord#(a));
   Reg#(a) x <- mkReg(0);
   Reg#(a) y <- mkReg(0);
   Reg#(a) z <- mkReg(0);
   Reg#(a) xbase <- mkReg(0);
   Reg#(a) ybase <- mkReg(0);
   Reg#(a) zbase <- mkReg(0);
   Reg#(a) xstep <- mkReg(0);
   Reg#(a) ystep <- mkReg(0);
   Reg#(a) zstep <- mkReg(0);
   Reg#(a) xlimit <- mkReg(0);
   Reg#(a) ylimit <- mkReg(0);
   Reg#(a) zlimit <- mkReg(0);
   
   let guard = (x < xlimit && y < ylimit && z < zlimit);
   
   interface PipeOut pipe;
      method Tuple2#(a,a) first() if (guard);
	 if (alt==RangeA)
	    return tuple2(x,z);
	 else if (alt == RangeB)
	    return tuple2(x,y);
	 else //if (alt == RangeC)
	    return tuple2(x+y,z);
      endmethod
      method Action deq if (guard);
	 let newx = x+xstep;
	 let newy = y;
	 let newz = z;
	 if (newx >= xlimit) begin
	    newx = xbase;
	    newy = y + ystep;
	    if (newy >= ylimit) begin
	       newy = ybase;
	       newz = z + zstep;
	    end
	 end
	 x <= newx;
	 y <= newy;
	 z <= newz;
      endmethod
      method Bool notEmpty();
	 return guard;
      endmethod
   endinterface
   method Action start(XYZRangeConfig#(a) cfg) if (x >= xlimit);
      x <= cfg.xbase;
      y <= cfg.ybase;
      z <= cfg.zbase;
      xbase <= cfg.xbase;
      ybase <= cfg.ybase;
      zbase <= cfg.zbase;
      xstep <= cfg.xstep;
      ystep <= cfg.ystep;
      zstep <= cfg.zstep;
      xlimit <= cfg.xlimit;
      ylimit <= cfg.ylimit;
      zlimit <= cfg.zlimit;
   endmethod
   method Action display();
      $display("XYZRangePipe x=%d xlimit=%d y=%d ylimit=%d z=%d zlimit=%d xstep=%d ystep=%d zstep=%d", x, xlimit, y, ylimit, z, zlimit,  xstep, ystep, zstep);
   endmethod
endmodule: mkXYZRangePipeOut

module mkRowSource#(ObjectReadServer#(TMul#(N,32)) vs, Reg#(UInt#(addrwidth)) numRows, Bit#(ObjectTagSize) id) (RowColSource#(TMul#(N,32), Vector#(N,MmToken)))
   provisos (Bits#(Vector#(N,Float),asz),
      Div#(asz,8,abytes),
      Log#(abytes,ashift),
      Mul#(abytes, 8, asz)
      );
   
   let cmd_buffer_depth = 32;
   
   let verbose = False;   
   let ashift = valueOf(ashift);
`ifdef TAGGED_TOKENS
   Reg#(UInt#(32)) row <- mkReg(0);
   FIFOF#(UInt#(32)) tagFifo <- mkSizedBRAMFIFOF(cmd_buffer_depth);
`endif
   // perhaps memreadengine could do the labeling
   Reg#(Bit#(ObjectOffsetSize)) countReg <- mkReg(0);
   Reg#(UInt#(addrwidth)) cmdCountReg <- mkReg(0);
   FIFOF#(Bit#(ObjectOffsetSize)) cmdFifo <- mkSizedBRAMFIFOF(cmd_buffer_depth);
   FIFOF#(Vector#(N,Float)) read_data_buffer <- mkFIFOF;
   
   rule read_data;
      let foo <- vs.readData.get;
      read_data_buffer.enq(unpack(foo.data));
   endrule
   
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l, UInt#(32) tag);
`ifdef TAGGED_TOKENS
      tagFifo.enq(tag);
`endif
      let cmd = ObjectRequest{pointer:h, offset:a<<ashift, burstLen:truncate(l<<ashift), tag:id};
      vs.readReq.put(cmd); //start(h,a,l);
      if(verbose) $display("mkRowSource.start %d %d", cmd.offset, cmd.burstLen);
      cmdFifo.enq(l);
   endmethod
   interface PipeOut pipe;
      method Vector#(N,MmToken) first;
	 Vector#(N,MmToken) rv;
	 Vector#(N,Float) foo = read_data_buffer.first;
`ifdef TAGGED_TOKENS
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{row:row+fromInteger(i), col:tagFifo.first, v:foo[i], first:False, last:False};
`else
	 for(Integer i = 0; i < valueOf(N); i=i+1)
	    rv[i] = MmToken{v:foo[i], first:False, last:False};
`endif
	 if (cmdCountReg == 0)  
	    for(Integer i = 0; i < valueOf(N); i=i+1)
	       rv[i].first = True;

	 if (cmdCountReg+1 == numRows)
	    for(Integer i = 0; i < valueOf(N); i=i+1)
	       rv[i].last = True;
	 return rv;
      endmethod
      method Action deq;
	 if(verbose) $display("mkRowSource.deq %d %d", countReg+1==cmdFifo.first, cmdCountReg+1==numRows);
	 read_data_buffer.deq;
	 if(countReg+1==cmdFifo.first) begin
	    countReg <= 0;
	    cmdFifo.deq;
	    if (cmdCountReg+1 == numRows)
	       cmdCountReg <= 0;
	    else
	       cmdCountReg <= cmdCountReg+1;
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
	 return (tagFifo.notEmpty && vs.dataPipes[0].notEmpty);
`else
	 return (read_data_buffer.notEmpty);
`endif
      endmethod
   endinterface
endmodule: mkRowSource

module mkRowColSink#(ObjectWriteServer#(TMul#(N,32)) vs, Bit#(ObjectTagSize) id) (RowColSink#(TMul#(N,32), Vector#(N,MmToken)))
   provisos (Bits#(Vector#(N,Float),asz),
      Div#(asz,8,abytes),
      Log#(abytes,ashift),
      Mul#(abytes, 8, asz)
      );
   let ashift = valueOf(ashift);
   let write_data_buffer <- mkFIFOF;
   rule write_data;
      let foo <- toGet(write_data_buffer).get;
      vs.writeData.put(foo);
   endrule
   function Float tokenValue(MmToken v) = v.v;
   method Action start(ObjectPointer h, Bit#(ObjectOffsetSize) a, Bit#(ObjectOffsetSize) l);
      let cmd = ObjectRequest{pointer:h, offset:a<<ashift, burstLen:truncate(l<<ashift), tag:id};
      vs.writeReq.put(cmd);
   endmethod
   interface PipeIn pipe;
      method Action enq(Vector#(N,MmToken) v);
	 write_data_buffer.enq(ObjectData{data:pack(map(tokenValue,v)),tag:id,last:True});
      endmethod
      method Bool notFull = write_data_buffer.notFull;
   endinterface
   method ActionValue#(Bool) finish();
      let rv <- vs.writeDone.get;
      return True;
   endmethod
endmodule
   
// row major layout
interface DmaMatrixMultiplyIfc#(numeric type addrwidth, numeric type dsz);
   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(addrwidth) numRowsA_x_numColumnsA, UInt#(addrwidth) numColumnsA_x_J,
		       UInt#(addrwidth) numRowsA_x_numColumnsB, UInt#(addrwidth) numColumnsB_x_K,
		       UInt#(addrwidth) numColumnsA_x_numColumnsB,    UInt#(addrwidth) numRowsB_x_J);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface

typedef enum {
   Idle, Ready, Running, Done
   } MMState deriving (Bits, Eq);

/*!
 * Multiplies two matrices A and B and writes the result to memory.
 * Simultaneously fetches J rows from A and K rows from B. Each cycle, 
 * it can fetch N elements from either matrix.
 *
 * Just considering memory bandwidth, every J+K cycles it is ready to 
 * perform J*K*N multiply accumulates.
 *
 */
module  mkDmaMatrixMultiply#(ObjectReadServer#(TMul#(N,32)) sA,
			     ObjectReadServer#(TMul#(N,32)) sB,
			     ObjectWriteServer#(TMul#(N,32))ss,
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
      );

   let n = valueOf(N);
   let jj = valueOf(J);
   let kk = valueOf(K);
   let tt = valueOf(T);
   let nshift = valueOf(nshift);
   Bool verbose = False;

   let defaultClock <- exposeCurrentClock();
   let defaultReset <- exposeCurrentReset();

   let doubleClock = host.doubleClock;
   let doubleReset = host.doubleReset;

   Reg#(UInt#(32)) cycles <- mkReg(0);
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorC <- mkReg(unpack(0));
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorA <- mkReg(unpack(0));
   Reg#(MatrixDescriptor#(UInt#(addrwidth))) descriptorB <- mkReg(unpack(0));
   Reg#(UInt#(addrwidth)) sinkCnt <- mkReg(0);
   
   Reg#(UInt#(addrwidth)) numRowsAReg <- mkReg(0);
   Reg#(UInt#(addrwidth)) numRowsBReg <- mkReg(0);
   RowColSource#(TMul#(N,32), Vector#(N,MmToken)) sourceA <- mkRowSource(sA, numRowsAReg, 0);
   RowColSource#(TMul#(N,32), Vector#(N,MmToken)) sourceB <- mkRowSource(sB, numRowsBReg, 1);
   RowColSink#(TMul#(N,32),   Vector#(N,MmToken))    sink <- mkRowColSink(ss, 0);

   PipeOut#(MmToken) aPipe <- mkFunnelGB1(defaultClock, defaultReset, doubleClock, doubleReset, sourceA.pipe);
   UnFunnelPipe#(1,J,MmToken,1) aPipes <- mkUnFunnelPipesPipelinedRR(clocked_by doubleClock, reset_by doubleReset, cons(aPipe,nil), 1);
   PipeOut#(MmToken) bFunnel <- mkFunnelGB1(defaultClock, defaultReset, doubleClock, doubleReset, sourceB.pipe);
   Vector#(J, PipeOut#(MmToken)) bPipes <- mkForkVector(bFunnel, clocked_by doubleClock, reset_by doubleReset);
   
   rule countCycles;
      cycles <= cycles+1;
   endrule

   UInt#(TAdd#(TLog#(K),1)) repetitions = fromInteger(valueOf(K));
   Vector#(J, PipeOut#(MmToken)) aRepeaters <- mapM(mkRepeat(repetitions), aPipes, clocked_by doubleClock, reset_by doubleReset);

   Vector#(T, MmTile) mmTiles <- mapM(mkMmTile(defaultClock, defaultReset), map(fromInteger,genVector), clocked_by doubleClock, reset_by doubleReset);
   Vector#(J, PipeOut#(Vector#(N,MmToken))) fxpipes;
   for (Integer t = 0; t < valueOf(T); t = t+1) begin
      for (Integer i = 0; i < valueof(RowsPerTile); i = i+1) begin
   	 let j = t*valueOf(RowsPerTile) + i;
   	 mkConnection(toGet(aRepeaters[j]), mmTiles[t].aInputs[i], clocked_by doubleClock, reset_by doubleReset);
   	 mkConnection(toGet(bPipes[j]), mmTiles[t].bInputs[i], clocked_by doubleClock, reset_by doubleReset);
   	 fxpipes[j] = mmTiles[t].fxPipes[i];
      end
   end
   FunnelPipe#(1,J,Vector#(N,MmToken),2) sinks <- mkFunnelPipesPipelinedRR(fxpipes,kk/valueOf(N));
   mkConnection(sinks[0],sink.pipe);

   XYZRangePipeIfc#(UInt#(addrwidth)) offsetpipeC <- mkXYZRangePipeOut(RangeC);
   XYZRangePipeIfc#(UInt#(addrwidth)) offsetpipeA <- mkXYZRangePipeOut(RangeA);
   XYZRangePipeIfc#(UInt#(addrwidth)) offsetpipeB <- mkXYZRangePipeOut(RangeB);
   
   Reg#(UInt#(32)) lastStartA <- mkReg(0);
   Reg#(UInt#(32)) lastStartB <- mkReg(0);
   Reg#(UInt#(32)) lastStartC <- mkReg(0);
      
   Reg#(Bool) running <- mkReg(False);
   FIFOF#(Bool) doneFifo <- mkFIFOF();
   
   rule startSourceB;
      match { .startBBase, .startBOffset } <- toGet(offsetpipeB.pipe).get();
      let startB = startBBase + startBOffset;
      lastStartB <= cycles;
      let interval = cycles-lastStartB;
      if ( verbose) $display($format(fshow(interval)+fshow(" startB=")+fshow(startB)));
      sourceB.start(descriptorB.pointer, pack(extend(startB>>nshift)), fromInteger(kk)>>nshift, 0);
   endrule
   
   rule startSourceA;
      match { .startABase, .startAOffset } <- toGet(offsetpipeA.pipe).get();
      let startA = startABase + startAOffset;
      lastStartA <= cycles;
      let interval = cycles-lastStartA;
      if ( verbose) $display($format(fshow(interval)+fshow(" startA=")+fshow(startA)));
      sourceA.start(descriptorA.pointer, pack(extend(startA>>nshift)), fromInteger(jj)>>nshift, 1);      
   endrule
   
   rule startSink;
      match { .startCBase, .offsetC } <- toGet(offsetpipeC.pipe).get();
      let startC = startCBase + offsetC;
      lastStartC <= cycles;
      let interval = cycles-lastStartC;
      if ( verbose) $display($format(fshow(interval)+fshow(" startC=")+fshow(startC)));
      sink.start(descriptorC.pointer, pack(extend(startC>>nshift)), fromInteger(kk)>>nshift);
   endrule

   rule finishSink;
      let b <- sink.finish();
      let c = sinkCnt-1;
      sinkCnt <= c;
      //$display("finishSink %d", c);
      if (c == 0) begin
	 running <= False;
	 doneFifo.enq(?);
      end
   endrule

   function PipeOut#(Bit#(32)) mmTileMacCount(MmTile mmtile); return mmtile.debug.macCount; endfunction
   Vector#(T, PipeOut#(Vector#(2,Bit#(32)))) macCountPipes <- mapM(mkUnfunnelGB(defaultClock, defaultReset, doubleClock, doubleReset),
								   map(mapPipe(replicate),
								       map(mmTileMacCount, mmTiles)));
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(uncurry(add), map(mapPipe(head),macCountPipes));
   Reg#(Bit#(32)) macCountReg <- mkReg(0);
   rule updateMacCount;
      let mc <- toGet(macCountPipe).get();
      macCountReg <= mc;
   endrule

   function Bool pipeNotEmpty(RowColSource#(asz, a) vs); return vs.pipe.notEmpty(); endfunction

   method Action start(ObjectPointer pointerA, UInt#(addrwidth) numRowsA, UInt#(addrwidth) numColumnsA,
		       ObjectPointer pointerB, UInt#(addrwidth) numRowsB, UInt#(addrwidth) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(addrwidth) numRowsA_x_numColumnsA,UInt#(addrwidth) numColumnsA_x_J,
		       UInt#(addrwidth) numRowsA_x_numColumnsB,UInt#(addrwidth) numColumnsB_x_J,
		       UInt#(addrwidth) numColumnsA_x_numColumnsB,UInt#(addrwidth) numRowsB_x_numColumnsB
		       ) if (!running);

      XYZRangeConfig#(UInt#(addrwidth)) offsetcfgA = XYZRangeConfig {xbase: 0, xlimit: numRowsA_x_numColumnsA, xstep: numColumnsA,
								     ybase: 0, ylimit: numColumnsB,            ystep: fromInteger(kk),
								     zbase: 0, zlimit: numColumnsA,            zstep: fromInteger(jj)};

      XYZRangeConfig#(UInt#(addrwidth)) offsetcfgB = XYZRangeConfig {xbase: 0, xlimit: numRowsB_x_numColumnsB, xstep: numColumnsB,
								     ybase: 0, ylimit: numColumnsB,            ystep: fromInteger(kk),
								     zbase: 0, zlimit: numColumnsA,            zstep: fromInteger(jj)};

      XYZRangeConfig#(UInt#(addrwidth)) offsetcfgC = XYZRangeConfig {xbase: 0, xlimit: numColumnsB_x_J,           xstep: numColumnsB,
								     ybase: 0, ylimit: numColumnsB,               ystep: fromInteger(kk),
								     zbase: 0, zlimit: numColumnsA_x_numColumnsB, zstep: numColumnsB_x_J };

      descriptorA <= MatrixDescriptor { pointer: pointerA, base: 0, numRows: numRowsA,    numColumns: numColumnsA};
      descriptorB <= MatrixDescriptor { pointer: pointerB, base: 0, numRows: numRowsB,    numColumns: numColumnsB};
      descriptorC <= MatrixDescriptor { pointer: pointerC, base: 0, numRows: numColumnsA, numColumns: numColumnsB};
      sinkCnt <= numColumnsA_x_numColumnsB/fromInteger(kk);
      numRowsBReg <= numRowsB;
      numRowsAReg <= numRowsA;
      running <= True;

      if (verbose) $display("mm pointerA=%d pointerB=%d pointerC=%d\n", pointerA, pointerB, pointerC);
      if (verbose) $display("mm.start ra=%d ca=%d rb=%d cb=%d", numRowsA, numColumnsA, numRowsB, numColumnsB);
      if (verbose) $display($format(fshow("offsetcfgA ")+fshow(offsetcfgA)));
      if (verbose) $display($format(fshow("offsetcfgB ")+fshow(offsetcfgB)));
      if (verbose) $display($format(fshow("offsetcfgC ")+fshow(offsetcfgC)));
      offsetpipeA.start(offsetcfgA);
      offsetpipeC.start(offsetcfgC);
      offsetpipeB.start(offsetcfgB);
      
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
   interface Vector#(2, ObjectReadClient#(dmasz)) readClients;
   interface Vector#(2, ObjectWriteClient#(dmasz)) writeClients;
   method Action start(ObjectPointer pointerA, UInt#(MMSize) numRowsA, UInt#(MMSize) numColumnsA,
		       ObjectPointer pointerB, UInt#(MMSize) numRowsB, UInt#(MMSize) numColumnsB,
		       ObjectPointer pointerC,
		       UInt#(MMSize) numRowsA_x_numColumnsA, UInt#(MMSize) numColumnsA_x_J,
		       UInt#(MMSize) numRowsA_x_numColumnsB, UInt#(MMSize) numColumnsB_x_J,
		       UInt#(MMSize) numColumnsA_x_numColumnsB, UInt#(MMSize) numRowsB_x_J);
   method ActionValue#(Bool) finish();
   interface DmaMatrixMultiplyDebug debug;
endinterface
      
module  mkDramMatrixMultiply#(HostType host)(DramMatrixMultiply#(N,TMul#(N,32)));

   MemWriterBuff#(TMul#(N,32),128)    writer <- mkMemWriterBuff;
   MemReaderBuff#(TMul#(N,32),256) rowReader <- mkMemReaderBuff;
   MemReaderBuff#(TMul#(N,32),256) colReader <- mkMemReaderBuff;
   MemWriter#(TMul#(32,N))       bogusWriter <- mkMemWriter;
   
   DmaMatrixMultiplyIfc#(MMSize,DmaSz) dmaMMF <- mkDmaMatrixMultiply(rowReader.readServer, colReader.readServer, writer.writeServer, host);

   interface Vector readClients  = cons(rowReader.readClient, cons(colReader.readClient,    nil));
   interface Vector writeClients = cons(writer.writeClient,   cons(bogusWriter.writeClient, nil));
   method start = dmaMMF.start;
   method finish = dmaMMF.finish;
   interface DmaMatrixMultiplyDebug debug = dmaMMF.debug;
endmodule
   
interface MmTN#(numeric type n);
   interface MmRequestTN mmRequest;
   interface MmDebugRequest mmDebug;
   interface TimerRequest timerRequest;
   interface Vector#(2, ObjectReadClient#(TMul#(32,n)))  readClients;
   interface Vector#(2, ObjectWriteClient#(TMul#(32,n))) writeClients;
endinterface

module  mkMmTN#(MmIndication ind, TimerIndication timerInd, MmDebugIndication mmDebugIndication, HostType host)(MmTN#(N))
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

   interface MmRequestTN mmRequest;
      method Action mmf(Bit#(32) h1, Bit#(32) r1, Bit#(32) c1,
			Bit#(32) h2, Bit#(32) r2, Bit#(32) c2,
			Bit#(32) h3,
			Bit#(32) r1_x_c1, Bit#(32) c1_x_j,
			Bit#(32) r1_x_c2, Bit#(32) c2_x_j,
			Bit#(32) c1_x_c2, Bit#(32) r2_x_c2);
	 dmaMMF.start(h1, unpack(truncate(r1)), unpack(truncate(c1)),
		      h2, unpack(truncate(r2)), unpack(truncate(c2)),
		      h3,
		      unpack(truncate(r1_x_c1)), unpack(truncate(c1_x_j)),
		      unpack(truncate(r1_x_c2)), unpack(truncate(c2_x_j)),
		      unpack(truncate(c1_x_c2)), unpack(truncate(r2_x_c2)));

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
   interface Vector writeClients =  dmaMMF.writeClients;

endmodule

