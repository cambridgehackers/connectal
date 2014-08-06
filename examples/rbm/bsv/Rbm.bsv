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

import PortalMemory::*;
import MemTypes::*;
import DmaVector::*;
import AxiMasterSlave::*;
import HostInterface::*;

import Sigmoid::*;
import FloatOps::*;
import Pipe::*;
import Timer::*;
import RbmTypes::*;

`ifdef MATRIX_TN
import MatrixTN::*;
import MmRequestTNWrapper::*;
`else
`ifdef MATRIX_NT
import MatrixNT::*;
import MmRequestNTWrapper::*;
`endif
`endif
import MmIndicationProxy::*;
import DotProdServer::*;


function Float tokenValue(MmToken v) = v.v;

function ObjectReadClient#(asz) getSourceReadClient(DmaVectorSource#(asz,a) s); return s.dmaClient; endfunction
function ObjectWriteClient#(asz) getSinkWriteClient(DmaVectorSink#(asz,a) s); return s.dmaClient; endfunction

interface DmaStatesPipe#(numeric type n, numeric type dmasz);
   interface Vector#(1, ObjectReadClient#(dmasz)) sources; 
   interface Vector#(1, ObjectWriteClient#(dmasz)) sinks; 
   method Action start(Bit#(32) readPointer, Bit#(32) readOffset,
		       Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
   method ActionValue#(Bool) finish();
endinterface

(* synthesize *)
module  mkDmaStatesPipe(DmaStatesPipe#(N, DmaSz))
   provisos (Bits#(Vector#(N, Float), DmaSz)
	     );
   DmaVectorSource#(DmaSz, Vector#(N,Float)) statesource <- mkDmaVectorSource();
   PipeOut#(Vector#(N, Float)) dmaStatesPipe <- mkComputeStatesPipe(statesource.vector.pipe);
   DmaVectorSink#(DmaSz, Vector#(N, Float)) dmaStatesSink <- mkDmaVectorSink(dmaStatesPipe);

   interface Vector sources = cons(statesource.dmaClient, nil);
   interface Vector sinks = cons(dmaStatesSink.dmaClient, nil);
   method Action start(Bit#(32) readPointer, Bit#(32) readOffset,
				  Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
      statesource.vector.start(readPointer, extend(readOffset), extend(unpack(numElts)));
      dmaStatesSink.vector.start(writePointer, extend(writeOffset), extend(unpack(numElts)));
   endmethod
   method ActionValue#(Bool) finish();
      let b <- dmaStatesSink.vector.finish();
      return b;
   endmethod
endmodule

interface DmaStatesPipe2#(numeric type n, numeric type dmasz);
   interface Vector#(2, ObjectReadClient#(dmasz))  sources; 
   interface Vector#(1, ObjectWriteClient#(dmasz)) sinks; 
   method Action start(Bit#(32) readPointer, Bit#(32) readOffset,
		       Bit#(32) readPointer2, Bit#(32) readOffset2,
		       Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
   method ActionValue#(Bool) finish();
endinterface

(* synthesize *)
module  mkDmaStatesPipe2(DmaStatesPipe2#(N, DmaSz))
   provisos (Bits#(Vector#(N, Float), DmaSz)
	     );
   Vector#(2, DmaVectorSource#(DmaSz, Vector#(N,Float))) statesources <- replicateM(mkDmaVectorSource());
   PipeOut#(Vector#(N, Float)) dmaStatesPipe <- mkComputeStatesPipe2(statesources[0].vector.pipe, statesources[1].vector.pipe);
   DmaVectorSink#(DmaSz, Vector#(N, Float)) dmaStatesSink <- mkDmaVectorSink(dmaStatesPipe);

   interface Vector sources = map(getSourceReadClient, statesources);
   interface Vector sinks = cons(dmaStatesSink.dmaClient, nil);
   method Action start(Bit#(32) readPointer, Bit#(32) readOffset,
		       Bit#(32) readPointer2, Bit#(32) readOffset2,
		       Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
      statesources[0].vector.start(readPointer, extend(readOffset), extend(unpack(numElts)));
      statesources[1].vector.start(readPointer2, extend(readOffset2), extend(unpack(numElts)));
      dmaStatesSink.vector.start(writePointer, extend(writeOffset), extend(unpack(numElts)));
   endmethod
   method ActionValue#(Bool) finish();
      let b <- dmaStatesSink.vector.finish();
      return b;
   endmethod
endmodule

interface DmaUpdateWeights#(numeric type n, numeric type dmasz);
   interface Vector#(3, ObjectReadClient#(dmasz)) readClients;
   interface Vector#(1, ObjectWriteClient#(dmasz)) writeClients;
   method Action start(Bit#(32) posAssociationsPointer, Bit#(32) negAssociationsPointer, Bit#(32) weightsPointer, Bit#(32) numElts, Float learningRateOverNumExamples);
   method ActionValue#(Bool) finish();
endinterface

(* synthesize *)
module  mkDmaUpdateWeights(DmaUpdateWeights#(N, DmaSz))
   provisos (Bits#(Vector#(N, Float), DmaSz)
	     );
   Vector#(3, DmaVectorSource#(DmaSz, Vector#(N,Float))) sources <- replicateM(mkDmaVectorSource());

   let n = valueOf(N);

   Reg#(Float) learningRateOverNumExamples <- mkReg(defaultValue);

   FIFOF#(Vector#(N,Float)) wfifo <- mkFIFOF();
   Vector#(N, FloatAlu) adders <- replicateM(mkFloatAdder(defaultValue));
   Vector#(N, FloatAlu) adders2 <- replicateM(mkFloatAdder(defaultValue));
   Vector#(N, FloatAlu) multipliers <- replicateM(mkFloatMultiplier(defaultValue));
   DmaVectorSink#(DmaSz, Vector#(N, Float)) sink <- mkDmaVectorSink(toPipeOut(wfifo));

// weights += learningRate * (pos_associations - neg_associations) / num_examples;
   rule sub;
      let pa = sources[0].vector.pipe.first();
      sources[0].vector.pipe.deq();
      let na = sources[1].vector.pipe.first();
      sources[1].vector.pipe.deq();
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
      let weights = sources[2].vector.pipe.first();
      sources[2].vector.pipe.deq();
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
      wfifo.enq(r);
   endrule

   for (Integer i = 0; i < 3; i = i + 1)
      rule finishSources;
	 let b <- sources[i].vector.finish();
      endrule

   //interface Vector sources = cons(statesource, nil);
   interface Vector readClients = map(getSourceReadClient, sources);
   interface Vector writeClients = cons(getSinkWriteClient(sink), nil);
   method Action start(Bit#(32) posAssociationsPointer, Bit#(32) negAssociationsPointer, Bit#(32) weightsPointer, Bit#(32) numElts, Float lrone);
      learningRateOverNumExamples <= lrone;
      sources[0].vector.start(posAssociationsPointer, 0, extend(numElts));
      sources[1].vector.start(negAssociationsPointer, 0, extend(numElts));
      sources[2].vector.start(weightsPointer, 0, extend(numElts));
      sink.vector.start(weightsPointer, 0, extend(numElts));
   endmethod
   method ActionValue#(Bool) finish();
      let b <- sink.vector.finish();
      return b;
   endmethod
endmodule
interface DmaSumOfErrorSquared#(numeric type n, numeric type dmasz);
   interface Vector#(2, ObjectReadClient#(dmasz)) readClients;
   interface PipeOut#(Float) pipe;
   method Action start(Bit#(32) dataPointer, Bit#(32) predPointer, Bit#(32) numElts);
endinterface

(* synthesize *)
module  mkDmaSumOfErrorSquared(DmaSumOfErrorSquared#(N, DmaSz))
   provisos (Bits#(Vector#(N, Float), DmaSz)
	     );
   Vector#(2, DmaVectorSource#(DmaSz, Vector#(N,Float))) sources <- replicateM(mkDmaVectorSource());

   let n = valueOf(N);

   let dotprod <- mkSharedInterleavedDotProdServer(0);

   FirstLastPipe#(Bit#(ObjectOffsetSize)) firstlastPipe <- mkFirstLastPipe();
   PipeOut#(Float) aPipe <- mkFunnel1(sources[0].vector.pipe);
   PipeOut#(Float) bPipe <- mkFunnel1(sources[1].vector.pipe);
   let joinPipe <- mkJoin(tuple2, aPipe, bPipe);
   let subPipe <- mkFloatSubPipe(joinPipe);
   rule fromsub;
      match {.first, .last} <- toGet(firstlastPipe.pipe).get();
      let diff <- toGet(subPipe).get();
      MmToken t = MmToken { v: diff, first: first, last: last };
      dotprod.aInput.put(t);
      dotprod.bInput.put(t);
   endrule
   

   for (Integer i = 0; i < 2; i = i + 1)
      rule finishSources;
	 let b <- sources[i].vector.finish();
      endrule

   //interface Vector sources = cons(statesource, nil);
   interface Vector readClients = map(getSourceReadClient, sources);
   interface PipeOut pipe = mapPipe(tokenValue, dotprod.pipes[0]);
   method Action start(Bit#(32) dataPointer, Bit#(32) predPointer, Bit#(32) numElts);
      sources[0].vector.start(dataPointer, 0, extend(numElts));
      sources[1].vector.start(predPointer, 0, extend(numElts));
      firstlastPipe.start(extend(numElts));
   endmethod
endmodule: mkDmaSumOfErrorSquared

interface Rbm#(numeric type n);
   interface RbmRequest rbmRequest;
`ifdef MATRIX_TN
   interface MmRequestTN mmRequest;
`else
`ifdef MATRIX_NT
   interface MmRequestNT mmRequest;
`endif
`endif
   interface MmDebugRequest mmDebugRequest;
   interface SigmoidRequest sigmoidRequest;
   interface TimerRequest timerRequest;
   interface Vector#(12, ObjectReadClient#(TMul#(32,n))) readClients;
   interface Vector#(6, ObjectWriteClient#(TMul#(32,n))) writeClients;
endinterface

module  mkRbm#(HostType host, RbmIndication rbmInd, MmIndication mmInd, MmDebugIndication mmDebugInd, SigmoidIndication sigmoidInd, TimerIndication timerInd)(Rbm#(N))
   provisos (Add#(1,a__,N),
	     Add#(N,0,n),
	     Mul#(N,32,DmaSz)
      );

   let n = valueOf(n);

`ifdef MATRIX_TN
   MmTN#(N) mm <- mkMmTN(mmInd, timerInd, mmDebugInd, host);
   MmRequestTNWrapper mmRequestWrapper <- mkMmRequestTNWrapper(MmRequestPortal,mm.mmRequest);
`else
`ifdef MATRIX_NT
   MmNT#(N) mm <- mkMmNT(mmInd, timerInd, mmDebugInd, host);
   MmRequestNTWrapper mmRequestWrapper <- mkMmRequestNTWrapper(MmRequestPortal,mm.mmRequest);
`endif
`endif

   DmaSigmoidIfc#(TMul#(32,n)) dmaSigmoid <- mkDmaSigmoid();
   Vector#(2,ObjectReadClient#(TMul#(32,n))) sigmoidsources = dmaSigmoid.readClients;

   DmaStatesPipe#(N, DmaSz) dmaStates <- mkDmaStatesPipe();
   DmaStatesPipe2#(N, DmaSz) dmaStates2 <- mkDmaStatesPipe2();

   DmaUpdateWeights#(N, DmaSz) dmaUpdateWeights <- mkDmaUpdateWeights();
   DmaSumOfErrorSquared#(N, DmaSz) dmaSumOfErrorSquared <- mkDmaSumOfErrorSquared();

   FIFOF#(Bool) busyFifo <- mkFIFOF();
   rule sigmoidDone;
      $display("sigmoidDone");
      let d <- dmaSigmoid.finish();
      busyFifo.deq();
      sigmoidInd.sigmoidDone();
   endrule
   rule sigmoidTableUpdateDone;
      $display("sigmoidDone");
      let d <- dmaSigmoid.sigmoidTableUpdated();
      busyFifo.deq();
      sigmoidInd.sigmoidTableUpdated(0);
   endrule
   rule dmaStatesDone;
      $display("dmaStatesDone");
      let b <- dmaStates.finish();
      busyFifo.deq();
      rbmInd.statesDone();
   endrule
   rule dmaStatesDone2;
      $display("dmaStatesDone2");
      let b <- dmaStates2.finish();
      busyFifo.deq();
      rbmInd.statesDone2();
   endrule

   rule dmaUpdateWeightsDone;
      $display("dmaUpdateWeightsDone");
      let b <- dmaUpdateWeights.finish();
      busyFifo.deq();
      rbmInd.updateWeightsDone();
   endrule

   rule dmaSumOfErrorSquaredDone;
      $display("dmaSumOfErrorSquaredDone");
      dmaSumOfErrorSquared.pipe.deq();
      busyFifo.deq();
      rbmInd.sumOfErrorSquared(pack(dmaSumOfErrorSquared.pipe.first()));
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

   interface MmRequest mmRequest = mm.mmRequest;
   interface MmDebugRequest mmDebugRequest = mm.mmDebug;
   
   interface SigmoidRequest sigmoidRequest;
      method Action sigmoid(Bit#(32) readPointer, Bit#(32) readOffset,
			    Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
	 dmaSigmoid.start(readPointer, writePointer, unpack(extend(numElts)));
	 busyFifo.enq(True);
      endmethod
      method Action setSigmoidLimits(Bit#(32) rscale, Bit#(32) llimit, Bit#(32) ulimit);
	 $display("rbm.setSigmoidLimits");
	 dmaSigmoid.setSigmoidLimits(unpack(rscale), unpack(llimit), unpack(ulimit));
	 busyFifo.enq(True);
      endmethod
      method Action updateSigmoidTable(Bit#(32) readPointer, Bit#(32) readOffset, Bit#(32) numElts);
	 $display("rbm.updateSigmoidTable pointer=%x addr=%h numElts=%d", readPointer, readOffset, numElts);
	 dmaSigmoid.updateSigmoidTable(readPointer, extend(readOffset), extend(numElts));
	 busyFifo.enq(True);
      endmethod
      method Action sigmoidTableSize();
	 sigmoidInd.sigmoidTableSize(dmaSigmoid.tableSize());
      endmethod
   endinterface   

   interface RbmRequest rbmRequest;
      method Action bramMmf(Bit#(32) h1, Bit#(32) r1, Bit#(32) c1,
			    Bit#(32) h2, Bit#(32) r2, Bit#(32) c2,
			    Bit#(32) h3);
	 // bramMMF.start(h1, unpack(extend(r1)), unpack(extend(c1)),
	 // 	       h2, unpack(extend(r2)), unpack(extend(c2)),
	 // 	       h3);
	 // busyFifo.enq(True);
      endmethod
      method Action toBram(Bit#(32) off, Bit#(32) pointer, Bit#(32) offset, Bit#(32) numElts);
	 // bramMMF.toBram(off, pointer, offset, numElts);
	 // busyFifo.enq(True);
      endmethod

      method Action fromBram(Bit#(32) off, Bit#(32) pointer, Bit#(32) offset, Bit#(32) numElts);
	 // bramMMF.fromBram(off, pointer, offset, numElts);
	 // busyFifo.enq(True);
      endmethod


      method Action dbg();
      endmethod

      method Action finish();
	 $finish(0);
      endmethod
      method Action computeStates(Bit#(32) readPointer, Bit#(32) readOffset,
				  Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
	 //$display("computeStates rh=%d wh=%d len=%d", readPointer, writePointer, numElts);
	 dmaStates.start(readPointer, readOffset,
			 writePointer, writeOffset, numElts);
	 busyFifo.enq(True);
      endmethod
      method Action computeStates2(Bit#(32) readPointer, Bit#(32) readOffset,
				   Bit#(32) readPointer2, Bit#(32) readOffset2,
				   Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
	 //$display("computeStates2 rh=%d wh=%d len=%d", readPointer, writePointer, numElts);
	 dmaStates2.start(readPointer, readOffset,
			  readPointer2, readOffset2,
			  writePointer,writeOffset, numElts);

	 busyFifo.enq(True);
      endmethod
      method Action updateWeights(Bit#(32) posAssociationsPointer,
	 Bit#(32) negAssociationsPointer,
				  Bit#(32) weightsPointer,
				  Bit#(32) numElts,
				  Bit#(32) learningRateOverNumExamples);
	 dmaUpdateWeights.start(posAssociationsPointer, negAssociationsPointer, weightsPointer,
				numElts, unpack(learningRateOverNumExamples));
	 busyFifo.enq(True);
      endmethod
      method Action sumOfErrorSquared(Bit#(32) dataPointer, Bit#(32) predPointer, Bit#(32) numElts);
	 dmaSumOfErrorSquared.start(dataPointer, predPointer, numElts);
	 busyFifo.enq(True);
      endmethod
   endinterface   

   interface Vector readClients = append(
					 //append(
					    mm.readClients,
					    //bramMMF.readClients
					    //),
					 append(
						append(dmaUpdateWeights.readClients,
						       dmaSumOfErrorSquared.readClients),
						append(
						   sigmoidsources,
						   append(
						      dmaStates.sources,
						      dmaStates2.sources)
						   )));

   interface Vector writeClients =
      append(dmaUpdateWeights.writeClients,
	     cons(dmaSigmoid.dmaClient, cons(dmaStates.sinks[0], cons(dmaStates2.sinks[0], mm.writeClients))));
endmodule
