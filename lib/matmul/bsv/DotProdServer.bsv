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

interface SharedDotProdDebug#(numeric type k);
   interface PipeOut#(Bit#(32)) macCount;
endinterface

interface SharedDotProdServer#(numeric type k);
   interface Put#(MmToken)                 aInput;
   interface Put#(MmToken)                 bInput;
   interface Vector#(k, PipeOut#(MmToken)) pipes;
   interface SharedDotProdDebug#(k) debug;
endinterface

typedef struct {
`ifdef TAGGED_TOKENS
   UInt#(32) row;
   UInt#(32) col;
`endif
   Float v;
   Bool first;
   Bool last;
} MmToken deriving (Eq,Bits);

typedef 8 UB_MulLat; // upper bound on MUL latency?
typedef 8 UB_AddLat; // upper bound on ADD latency?
	   
(* synthesize *)
module  mkSharedInterleavedDotProdServer#(UInt#(TLog#(TMul#(J,K))) label)(SharedDotProdServer#(K));
   let rv <- mkSharedInterleavedDotProdServerConfig(label);
   return rv;
endmodule


module  mkSharedInterleavedDotProdServerConfig#(UInt#(TLog#(TMul#(J,K))) label)(SharedDotProdServer#(k))
   provisos(Div#(UB_AddLat,k,gatherSz));
    
   let ub_MulLat = valueOf(UB_MulLat);
   let ub_AddLat = valueOf(UB_AddLat);
   let kk = valueOf(k);

   Bool verbose = False; //label == 0;
   
   Reg#(UInt#(20)) countReg     <- mkReg(0);

   FloatAlu mul   <- mkFloatMultiplier(defaultValue);
   FloatAlu adder <- mkFloatAdder(defaultValue);
   FIFOF#(Float) adder_buffer <- mkSizedFIFOF(valueOf(TMul#(k,gatherSz)));
   
`ifdef TAGGED_TOKENS
   FIFO#(Tuple2#(UInt#(32),UInt#(32))) tag_fifo <- mkSizedFIFO(ub_MulLat); 
   Vector#(k,Reg#(Tuple2#(UInt#(32),UInt#(32)))) tag_regs <- replicateM(mkRegU);
`endif   
   
   Reg#(Bit#(32)) cycles <- mkReg(0);
   rule countCycles;
      cycles <= cycles + 1;
   endrule

   FIFOF#(MmToken)                          afifo   <- mkFIFOF();
   PipeOut#(MmToken)                        aFunnel = toPipeOut(afifo);

   FIFOF#(MmToken)                          bfifo <- mkFIFOF();
   PipeOut#(MmToken)                        bFunnel = toPipeOut(bfifo);

   Reg#(Bit#(16)) firstCnt <- mkReg(0);
   Reg#(Bool)         gReg <- mkReg(False);
   FIFOF#(Float)     gFifo <- mkSizedFIFOF(kk);
   Reg#(Bit#(16))  lastCnt <- mkReg(0);
   Reg#(Bit#(16))gatherCnt <- mkReg(0);
   Reg#(Bool) gather_phase <- mkReg(False);
   //invariant: gather_phase = lastCnt == fromInteger(kk);
   Reg#(Bool) lastPassReg <- mkReg((0+1) == fromInteger(valueOf(gatherSz)));

   FIFOF#(Tuple2#(Bool,Bool))    flFifo <- mkSizedFIFOF(ub_MulLat);
   Vector#(k,FIFOF#(MmToken))    dotfifos <- replicateM(mkFIFOF1);
   Reg#(Bit#(TAdd#(1,TLog#(k)))) rowReg <- mkReg(0);
   Reg#(Bool)                lastRowReg <- mkReg(False);
      
   Reg#(Bit#(32)) lastMul <- mkReg(0);
   Reg#(Bit#(32)) lastAcc <- mkReg(0);
   Reg#(Bit#(32)) lastGather <- mkReg(0);
   Reg#(Bit#(32)) macs <- mkReg(0);
   
   
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
      if(label==0) $display("%d (%d,%d)(%d,%d)", label, a.row, a.col, b.row, b.col);
      tag_fifo.enq(tuple2(a.row,b.col));
`endif
   endrule
   
   function Action incrementRowReg = 
      (action
	  // I have to do this check (instead of relying on wrap-around) because
	  // rowReg has an extra bit to compenseate for bsc's silly Bit#(0) handling
	  if (rowReg+1 == fromInteger(kk)) begin
	     rowReg <= 0;
	     lastRowReg <= (0 == fromInteger(kk-1));
	  end
	  else begin
	     rowReg <= rowReg+1;
	     lastRowReg <= (rowReg == fromInteger(kk-2));
	  end
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
      if (firstCnt == fromInteger(valueOf(TMul#(k,gatherSz))))
	 acc <- toGet(adder_buffer).get;
      else begin
	 firstCnt <= firstCnt+1;
      end
      adder.request.put(tuple2(resp,acc));
      if(last) begin
	 lastCnt <= lastCnt+1;
	 gather_phase <= (lastCnt == fromInteger(kk)-1);
      end
`ifdef TAGGED_TOKENS
      let row = rowReg;
      let t <- toGet(tag_fifo).get;
      tag_regs[row] <= t;
`endif
   endrule

   rule checkInvariant;
      if (lastPassReg != ((gatherCnt+1) == fromInteger(valueOf(gatherSz)))) begin
	 $display("last_pass invariant failure: last_pass=%d %d gatherCnt=%d gatherSz=%d",
		  lastPassReg, ((gatherCnt+1) == fromInteger(valueOf(gatherSz))), gatherCnt, fromInteger(valueOf(gatherSz)));
	 $finish();
      end
      dynamicAssert(lastPassReg == (gatherCnt+1 == fromInteger(valueOf(gatherSz))), "gatherCnt invariant");
   endrule

   (* fire_when_enabled *)
   rule gather if (gather_phase);
      incrementRowReg;
      lastGather <= cycles;
      let row = rowReg;
      let last_row = lastRowReg;
      let last_pass = lastPassReg; // invariant: lastPassReg == (gatherCnt+1 == fromInteger(valueOf(gatherSz));)
      if (verbose)
	 $display("%08d gather: gather=%d row=%d last_pass=%d last_row=%d, gReg=%d", 
		  cycles-lastGather, gatherCnt, row, last_pass, last_row, gReg);
      let x <- toGet(adder_buffer).get;
      if (!last_pass) begin
	 if (last_row) begin
	    if (gReg) begin
	       gatherCnt <= gatherCnt+1;
	       lastPassReg <= ((gatherCnt+2) == fromInteger(valueOf(gatherSz)));
	    end
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
	 dotfifos[row].enq(MmToken{row:row, col:col, v:x});
`else
	 dotfifos[row].enq(MmToken{v:x, last:False, first:False});
`endif      
	 if (last_row) begin
	    gatherCnt <= 0;
	    lastPassReg <= ((0+1) == fromInteger(valueOf(gatherSz)));
	    lastCnt <= 0;
	    firstCnt <= 0;
	    gather_phase <= False;
	 end 
      end
   endrule   

   Vector#(k,PipeOut#(MmToken)) dotpipes = map(toPipeOut, dotfifos);

   interface Put aInput;
      method Action put(MmToken a);
   	 afifo.enq(a);
	 countReg <= countReg+1;
      endmethod
   endinterface
   interface Put bInput   = toPut(bfifo);
   interface Vector pipes = dotpipes;
   interface SharedDotProdDebug debug;
      interface PipeOut  macCount = toPipeOut(macs._read);
   endinterface
endmodule : mkSharedInterleavedDotProdServerConfig



interface MmTileDebug;
   interface PipeOut#(Bit#(32)) macCount;
endinterface

interface MmTile;
   interface Vector#(RowsPerTile, Put#(MmToken)) aInputs;
   interface Vector#(RowsPerTile, Put#(MmToken)) bInputs;
   interface Vector#(RowsPerTile, PipeOut#(Vector#(N, MmToken))) fxPipes;
   interface MmTileDebug debug;
endinterface

function Put#(a) toCountedPut(Reg#(Bit#(n)) r, Put#(a) p);
   return (interface Put#(a);
      method Action put(a v);
	 r <= r+1;
	 p.put(v);
      endmethod
      endinterface);
endfunction

(* synthesize *)
module  mkMmTile#(Clock slowClock, Reset slowReset, UInt#(TLog#(T)) tile)(MmTile);

   let rowsPerTile = valueOf(RowsPerTile);
   let kk = valueOf(K);

   Vector#(RowsPerTile, Reg#(Bit#(32))) aMmTokensPutRegs <- replicateM(mkReg(0));
   Vector#(RowsPerTile, Reg#(Bit#(32))) bMmTokensPutRegs <- replicateM(mkReg(0));
   Vector#(RowsPerTile, Reg#(Bit#(32))) aMmTokensReadRegs <- replicateM(mkReg(0));
   Vector#(RowsPerTile, Reg#(Bit#(32))) bMmTokensReadRegs <- replicateM(mkReg(0));

   Vector#(RowsPerTile, FIFOF#(MmToken))   aFifos <- replicateM(mkFIFOF);
   Vector#(RowsPerTile, PipeOut#(MmToken)) aPipes = zipWith(toCountedPipeOut, aMmTokensReadRegs, map(toPipeOut, aFifos));
   Vector#(RowsPerTile,  FIFOF#(MmToken))   bFifos <- replicateM(mkFIFOF);
   Vector#(RowsPerTile,  PipeOut#(MmToken)) bPipes = zipWith(toCountedPipeOut, bMmTokensReadRegs, map(toPipeOut, bFifos));

   function Vector#(k,PipeOut#(MmToken)) getDotProdServerPipes(SharedDotProdServer#(k) s); return s.pipes; endfunction
   Vector#(RowsPerTile, SharedDotProdServer#(K)) fxdotprods <- mapM(mkSharedInterleavedDotProdServer, map(fromInteger,genVector));
   Vector#(RowsPerTile, Vector#(K, PipeOut#(MmToken))) fxpipes = map(getDotProdServerPipes, fxdotprods);
//`define USE_MIMO_DFIFOS // this version is faster
   let fastClock <- exposeCurrentClock();
   let fastReset <- exposeCurrentReset();
`ifndef USE_MIMO_DFIFOS
   Vector#(RowsPerTile, PipeOut#(Vector#(K, MmToken))) fxPipesK <- mapM(mkJoinVector(id), fxpipes);
   Vector#(RowsPerTile, PipeOut#(MmToken)) fxPipes1MmToken <- mapM(mkFunnel1, fxPipesK);
   Vector#(RowsPerTile, PipeOut#(Vector#(1, MmToken))) fxPipes1 = map(mapPipe(replicate), fxPipes1MmToken);
`else
   MIMOConfiguration mimoCfg = defaultValue;
   Vector#(RowsPerTile, MIMO#(K,1,TAdd#(K,1),MmToken)) dfifos <- replicateM(mkMIMO(mimoCfg));
   Vector#(RowsPerTile, PipeOut#(Vector#(1, MmToken))) fxPipes1 = map(toPipeOut, dfifos);
`endif
   Vector#(RowsPerTile, Gearbox#(1, N, MmToken)) gearboxes <- replicateM(mk1toNGearbox(fastClock, fastReset, slowClock, slowReset));
   Vector#(RowsPerTile, PipeIn#(Vector#(1,MmToken))) toGearboxes = map(toPipeIn, gearboxes);
   Vector#(RowsPerTile, PipeOut#(Vector#(N, MmToken))) fromGearboxes = map(toPipeOut, gearboxes);
   mapM(uncurry(mkConnection), zip(fxPipes1, toGearboxes));
   // introduce a buffer to help vivado meet timing on vc707
   Vector#(RowsPerTile, FIFOF#(Vector#(N,MmToken)))    tokenfifos <- replicateM(mkFIFOF(clocked_by slowClock, reset_by slowReset));
   Vector#(RowsPerTile, PipeIn#(Vector#(N,MmToken))) toMmTokenFifos = map(toPipeIn, tokenfifos);
   mapM(uncurry(mkConnection), zip(fromGearboxes, toMmTokenFifos), clocked_by slowClock, reset_by slowReset);
   Vector#(RowsPerTile, PipeOut#(Vector#(N, MmToken))) fxPipesN = map(toPipeOut, tokenfifos);

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
	 Vector#(K,MmToken) vs;
	 for (Integer k = 0; k < kk; k = k + 1) begin
	    let v <- toGet(fxpipes[j][k]).get();
	    vs[k] = v;
	 end	    
	 dfifos[j].enq(fromInteger(kk), vs);
      endrule
   end
`endif

   function Bool fifofNotEmpty(FIFOF#(a) fifof); return fifof.notEmpty(); endfunction
   function PipeOut#(Bit#(32)) dotProdMacCount(SharedDotProdServer#(K) dotprodserver); return dotprodserver.debug.macCount; endfunction
   PipeOut#(Bit#(32)) macCountPipe <- mkReducePipes(uncurry(add), map(dotProdMacCount, fxdotprods));

   interface Vector aInputs = zipWith(toCountedPut, aMmTokensPutRegs, map(toPut, aFifos));
   interface Vector bInputs = zipWith(toCountedPut, bMmTokensPutRegs, map(toPut, bFifos));
   interface Vector fxPipes = fxPipesN;
   interface MmTileDebug debug;
      interface PipeOut macCount = macCountPipe;
   endinterface
endmodule : mkMmTile

typedef struct {
   SGLId sglId;
   addrtype base;
   addrtype numRows;
   addrtype numColumns;
} MatrixDescriptor#(type addrtype) deriving (Bits);

interface DmaMatrixMultiplyDebug;
   method Bit#(32) macCount();
endinterface
