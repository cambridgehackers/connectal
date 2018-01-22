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
import Vector::*;
import FIFO::*;
import FIFOF::*;
import DefaultValue::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import FloatingPoint::*;
import BRAM::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import DmaVector::*;
import HostInterface::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import MatrixTN::*;
import Timer::*;
import Sigmoid::*;
import FloatOps::*;
import Pipe::*;
import RbmTypes::*;
import DotProdServer::*;

function Float tokenValue(MmToken v) = v.v;

interface StatesPipe#(numeric type n, numeric type dmasz);
   method Action start(Bit#(32) readPointer, Bit#(32) readOffset,
		       Bit#(32) readPointer2, Bit#(32) readOffset2,
		       Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
   method ActionValue#(Bool) finish();
endinterface
   
   
module  mkComputeStatesPipe#(PipeOut#(Vector#(n, Float)) pipe_in, 
			     PipeOut#(Vector#(n, Float)) randomPipe,
			     PipeIn#(Vector#(n,Float))   writePipe)(PipeOut#(Vector#(n, Float)))
   provisos(Add#(a__, 1, n));
   function Float greater(Float a, Float b);
      if (compareFP(a, b) == GT)
	 return 1.0;
      else
	 return 0.0;
   endfunction
   function Vector#(n, Float) vgreater(Vector#(n, Float) x, Vector#(n, Float) y);
      return map(uncurry(greater), zip(x, y));
   endfunction
   rule foo;
      let vs <- toGet(pipe_in).get;
      let rs <- toGet(randomPipe).get;
      let gs = vgreater(vs, rs); 
      //$display($format(fshow("vs=")+fshow(pack(vs)) + fshow(" rs=") + fshow(pack(rs)) + fshow(" states=") + fshow(gs)));
      writePipe.enq(gs);
   endrule
endmodule
   
   
   
module  mkStatesPipe#(Vector#(2,MemReadEngineServer#(TMul#(N,32))) readSrvrs,
		      Vector#(1,MemWriteEngineServer#(TMul#(N,32))) writeSrvrs)(StatesPipe#(N, DmaSz))
   provisos ( Bits#(Vector#(N, Float), DmaSz)
	     ,Log#(N,nshift));
   
   let verbose = True;
   let nshift = valueOf(nshift);
   
   Vector#(2, VectorSource#(DmaSz, Vector#(N,Float))) statesources <- mapM(mkMemReadVectorSource, readSrvrs);
   VectorSink#(DmaSz, Vector#(N, Float)) dmaStatesSink <- mkMemWriteVectorSink(writeSrvrs[0]);
   PipeOut#(Vector#(N, Float)) dmaStatesPipe <- mkComputeStatesPipe(statesources[0].pipe, statesources[1].pipe, dmaStatesSink.pipe);

   method Action start(Bit#(32) readPointer, Bit#(32) readOffset,
		       Bit#(32) readPointer2, Bit#(32) readOffset2,
		       Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
      statesources[0].start(readPointer, extend(readOffset), extend(unpack(numElts)>>nshift));
      statesources[1].start(readPointer2, extend(readOffset2), extend(unpack(numElts)>>nshift));
      dmaStatesSink.start(writePointer, extend(writeOffset), extend(unpack(numElts)>>nshift));
      if (verbose) $display("mkStatesPipe::start(%d %d %d %d %d %d)", readPointer, readOffset, readPointer2, readOffset2, writePointer, writeOffset, numElts);
   endmethod
   method ActionValue#(Bool) finish();
      let x0 <- statesources[0].finish;
      let x1 <- statesources[1].finish;
      let b <- dmaStatesSink.finish;
      return b;
   endmethod
endmodule

interface UpdateWeights#(numeric type n, numeric type dmasz);
   method Action start(Bit#(32) posAssociationsPointer, Bit#(32) negAssociationsPointer, 
		       Bit#(32) weightsPointer, Bit#(32) numElts, Float learningRateOverNumExamples);
   method ActionValue#(Bool) finish();
endinterface

module  mkUpdateWeights#(Vector#(3,MemReadEngineServer#(TMul#(N,32))) readSrvrs,
			    Vector#(1,MemWriteEngineServer#(TMul#(N,32))) writeSrvrs)(UpdateWeights#(N, DmaSz))
   provisos ( Bits#(Vector#(N, Float), DmaSz)
	     ,Log#(N,nshift));

   Vector#(3, VectorSource#(DmaSz, Vector#(N,Float))) sources <- mapM(mkMemReadVectorSource, readSrvrs);

   let n = valueOf(N);
   let nshift = valueOf(nshift);

   Reg#(Float) learningRateOverNumExamples <- mkReg(defaultValue);

   Vector#(N, FloatAlu) adders <- replicateM(mkFloatAdder(defaultValue));
   Vector#(N, FloatAlu) adders2 <- replicateM(mkFloatAdder(defaultValue));
   Vector#(N, FloatAlu) multipliers <- replicateM(mkFloatMultiplier(defaultValue));
   VectorSink#(DmaSz, Vector#(N, Float)) sink <- mkMemWriteVectorSink(writeSrvrs[0]);

// weights += learningRate * (pos_associations - neg_associations) / num_examples;
   rule sub;
      let pa = sources[0].pipe.first();
      sources[0].pipe.deq();
      let na = sources[1].pipe.first();
      sources[1].pipe.deq();
      for (Integer i = 0; i < n; i = i+1) begin
	 adders[i].request.put(tuple2(pa[i], -na[i]));
      end
   endrule
   rule mul;
      for (Integer i = 0; i < n; i = i+1) begin
	 let sumexc <- adders[i].response.get();
	 multipliers[i].request.put(tuple2(learningRateOverNumExamples, tpl_1(sumexc)));
      end
   endrule
   rule add;
      let weights = sources[2].pipe.first();
      sources[2].pipe.deq();
      for (Integer i = 0; i < n; i = i+1) begin
	 let resultexc <- multipliers[i].response.get();
	 adders2[i].request.put(tuple2(weights[i], tpl_1(resultexc)));
      end
   endrule
   rule result;
      Vector#(N, Float) r;
      for (Integer i = 0; i < n; i = i+1) begin
	 let resultexc <- adders2[i].response.get();
	 r[i] = tpl_1(resultexc);
      end
      sink.pipe.enq(r);
   endrule

   for (Integer i = 0; i < 3; i = i + 1)
      rule finishSources;
	 let b <- sources[i].finish();
      endrule

   method Action start(Bit#(32) posAssociationsPointer, Bit#(32) negAssociationsPointer, Bit#(32) weightsPointer, Bit#(32) numElts, Float lrone);
      learningRateOverNumExamples <= lrone;
      sources[0].start(posAssociationsPointer, 0, extend(numElts)>>nshift);
      sources[1].start(negAssociationsPointer, 0, extend(numElts)>>nshift);
      sources[2].start(weightsPointer, 0, extend(numElts)>>nshift);
      sink.start(weightsPointer, 0, extend(numElts)>>nshift);
   endmethod
   method ActionValue#(Bool) finish();
      let b <- sink.finish();
      return b;
   endmethod
endmodule
   
interface SumOfErrorSquaredDebug;
   interface PipeOut#(Bit#(32)) macCount;
endinterface

interface SumOfErrorSquared#(numeric type n, numeric type dmasz);
   interface PipeOut#(Float) pipe;
   method Action start(Bit#(32) dataPointer, Bit#(32) predPointer, Bit#(32) numElts);
   interface SumOfErrorSquaredDebug debug;
endinterface

module  mkSumOfErrorSquared#(Vector#(2,MemReadEngineServer#(TMul#(N,32))) readSrvrs)(SumOfErrorSquared#(N, DmaSz))
   provisos ( Bits#(Vector#(N, Float), DmaSz)
	     ,Log#(N,nshift));
   
   Vector#(2, VectorSource#(DmaSz, Vector#(N,Float))) sources <- mapM(mkMemReadVectorSource, readSrvrs);
   let n = valueOf(N);
   let nshift = valueOf(nshift);
   SharedDotProdServer#(1) dotprod <- mkSharedInterleavedDotProdServerConfig(0);

   FirstLastPipe#(Bit#(MemOffsetSize)) firstlastPipe <- mkFirstLastPipe();
   PipeOut#(Float) aPipe <- mkFunnel1(sources[0].pipe);
   PipeOut#(Float) bPipe <- mkFunnel1(sources[1].pipe);
   let joinPipe <- mkJoin(tuple2, aPipe, bPipe);
   let subPipe <- mkFloatSubPipe(joinPipe);
   rule fromsub;
      match {.first, .last} <- toGet(firstlastPipe.pipe).get();
      let diff <- toGet(subPipe).get();
      MmToken t = MmToken { v: diff, first: first, last: last };
      dotprod.aInput.put(t);
      dotprod.bInput.put(t);
      //$display("%d %d", first, last);
   endrule

   for (Integer i = 0; i < 2; i = i + 1)
      rule finishSources;
	 let b <- sources[i].finish();
      endrule

   interface PipeOut pipe = mapPipe(tokenValue, dotprod.pipes[0]);
   method Action start(Bit#(32) dataPointer, Bit#(32) predPointer, Bit#(32) numElts);
      sources[0].start(dataPointer, 0, extend(numElts)>>nshift);
      sources[1].start(predPointer, 0, extend(numElts)>>nshift);
      firstlastPipe.start(extend(numElts));
   endmethod
   interface SumOfErrorSquaredDebug debug;
      interface PipeOut macCount = dotprod.debug.macCount;
   endinterface
endmodule: mkSumOfErrorSquared

interface Rbm#(numeric type n);
   interface RbmRequest rbmRequest;
   interface SigmoidRequest sigmoidRequest;
   interface MmRequestTN mmRequest;
   interface TimerRequest timerRequest;
   interface Vector#(3,MemReadClient#(TMul#(32,n))) readClients;
   interface Vector#(3,MemWriteClient#(TMul#(32,n))) writeClients;
endinterface

module  mkRbm#(HostInterface host, RbmIndication rbmInd, SigmoidIndication sigmoidInd, MmIndication mmInd, TimerIndication timerInd)(Rbm#(N))
   provisos (Add#(1,a__,N),
	     Add#(N,0,n),
	     Mul#(N,32,DmaSz));
   let n = valueOf(n);
   
   // TODO: figure out the correct amount of buffering required
   MemReadEngine#(TMul#(n,32),TMul#(n,32),2, 9) readEngine  <- mkMemReadEngine;
   MemWriteEngine#(TMul#(n,32),TMul#(n,32),2, 3) writeEngine <- mkMemWriteEngine;
   
   let res = readEngine.readServers;
   let wes = writeEngine.writeServers;
   
   SigmoidIfc#(TMul#(32,n)) sigmoid <- mkSigmoid(takeAt(0,res), takeAt(0,wes)); // 2 read, 1 write
   StatesPipe#(N, DmaSz) states <- mkStatesPipe(takeAt(2,res), takeAt(1,wes));  // 2 read, 1 write
   UpdateWeights#(N, DmaSz) updateWeights <- mkUpdateWeights(takeAt(4,res), takeAt(2,wes)); // 3 read, 1 write
   SumOfErrorSquared#(N, DmaSz) sumOfErrorSquared <- mkSumOfErrorSquared(takeAt(7,res));       // 2 read, 0 write
   MmTNInternal#(N) mm <- mkMmTNInternal(host);
   
   ///////////////////////////////////////////////
   // timing cruft

   FIFOF#(Bool) busyFifo <- mkFIFOF();
   FIFOF#(Bool) timerRunning <- mkFIFOF();
   Reg#(Bit#(64)) cycleCount <- mkReg(0);
   Reg#(Bit#(64)) idleCount <- mkReg(0);
   rule countCycles if (timerRunning.notEmpty());
      cycleCount <= cycleCount + 1;
      if (!busyFifo.notEmpty())
	 idleCount <= idleCount + 1;
   endrule

   ///////////////////////////////////////////////
   
   ///////////////////////////////////////////////
   // sigmoid indication
   
   rule sigmoidDone;
      sigmoid.sigmoidDone();
      sigmoidInd.sigmoidDone();
      busyFifo.deq;
   endrule
   
   rule sigmoidTableUpdateDone;
      let b <- sigmoid.updateDone();
      sigmoidInd.tableUpdated(0);
      busyFifo.deq;
   endrule
   
   ///////////////////////////////////////////////
   
   ///////////////////////////////////////////////
   // mm indication

   rule mmfDone;
      let d <- mm.mmfDone;
      busyFifo.deq();
      mmInd.mmfDone(d);
   endrule
   
   rule mmDebugDone;
      let d <- mm.debugDone;
      mmInd.debug(d);
   endrule

   FIFO#(Bit#(32)) sumOfErrorSquaredDebugFifo <- mkFIFO();
   rule sumOfErrorSquaredDebugRule;
      let unused <- toGet(sumOfErrorSquaredDebugFifo).get();
      let macCount <- toGet(sumOfErrorSquared.debug.macCount).get();
      rbmInd.sumOfErrorSquaredDebug(macCount);
   endrule

   ///////////////////////////////////////////////
   
   ///////////////////////////////////////////////
   // rbm indication

   rule statesDone;
      $display("statesDone");
      let b <- states.finish();
      rbmInd.statesDone();
      busyFifo.deq;
   endrule

   rule updateWeightsDone;
      $display("updateWeightsDone");
      let b <- updateWeights.finish();
      rbmInd.updateWeightsDone();
      busyFifo.deq;
   endrule

   rule sumOfErrorSquaredDone;
      $display("sumOfErrorSquaredDone");
      sumOfErrorSquared.pipe.deq();
      rbmInd.sumOfErrorSquared(pack(sumOfErrorSquared.pipe.first()));
      busyFifo.deq;
   endrule
   
   ///////////////////////////////////////////////
   
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
	 mm.mmRequest.mmf(h1,r1,c1,
			  h2,r2,c2,
			  h3,
			  r1_x_c1, c1_x_j,
			  r1_x_c2, c2_x_j,
			  c1_x_c2, r2_x_c2);
	 busyFifo.enq(True);
      endmethod
      method Action debug = mm.mmRequest.debug;
   endinterface
   interface RbmRequest rbmRequest;
      method Action finish();
	 $finish(0);
      endmethod
      method Action computeStates(Bit#(32) readPointer, Bit#(32) readOffset,
				  Bit#(32) readPointer2, Bit#(32) readOffset2,
				  Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
	 states.start(readPointer, readOffset,
		      readPointer2, readOffset2,
		      writePointer,writeOffset, numElts);
	 busyFifo.enq(True);
      endmethod
      method Action updateWeights(Bit#(32) posAssociationsPointer,
	 Bit#(32) negAssociationsPointer,
				  Bit#(32) weightsPointer,
				  Bit#(32) numElts,
				  Bit#(32) learningRateOverNumExamples);
	 updateWeights.start(posAssociationsPointer, negAssociationsPointer, 
			     weightsPointer, numElts, 
			     unpack(learningRateOverNumExamples));
	 busyFifo.enq(True);
      endmethod
      method Action sumOfErrorSquared(Bit#(32) dataPointer, Bit#(32) predPointer, Bit#(32) numElts);
	 sumOfErrorSquared.start(dataPointer, predPointer, numElts);
	 busyFifo.enq(True);
      endmethod
      method Action sumOfErrorSquaredDebug();
	 sumOfErrorSquaredDebugFifo.enq(0);
      endmethod
   endinterface   
   interface SigmoidRequest sigmoidRequest;
      method Action sigmoid(Bit#(32) readPointer, Bit#(32) readOffset,
   			    Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numvalues);
	 sigmoid.sigmoidRequest.sigmoid(readPointer, readOffset, writePointer, writeOffset, numvalues);
	 busyFifo.enq(True);
      endmethod
      method Action setLimits(Bit#(32) rscale, Bit#(32) llimit, Bit#(32) ulimit);
	 sigmoid.sigmoidRequest.setLimits(rscale, llimit, ulimit);
      endmethod
      method Action updateTable(Bit#(32) readPointer, Bit#(32) readOffset, Bit#(32) numvalues);
	 sigmoid.sigmoidRequest.updateTable(readPointer, readOffset, numvalues);
	 busyFifo.enq(True);
      endmethod
      method Action tableSize();
	 sigmoidInd.tableSize(sigmoid.tableSize);
      endmethod
   endinterface
   interface Vector readClients = cons(readEngine.dmaClient,mm.readClients);
   interface Vector writeClients = cons(writeEngine.dmaClient,mm.writeClients);
endmodule
