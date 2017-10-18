/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
import RegFile::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import Connectable::*;
import ClientServer::*;
import Memory::*;
import BRAM::*;
import DefaultValue::*;
import FloatingPoint::*;
import Real::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import DmaVector::*;
import Pipe::*;
import FloatOps::*;
import RbmTypes::*;
import BUtils::*;

interface SigmoidTable#(numeric type tsz);
   interface Vector#(2, BRAMServer#(Bit#(tsz), Vector#(3,Float))) ports;
   interface ReadOnly#(Float) rscale;
   interface ReadOnly#(Float) llimit;
   interface ReadOnly#(Float) ulimit;
   method Action setSigmoidLimits(Float rscale, Float llimit, Float ulimit);
   method Action updateSigmoidTable(Bit#(tsz) addr, Vector#(3,Float) v);
   method Bit#(32) tableSize();
endinterface

module mkSigmoidTable(SigmoidTable#(tsz));
   let tsz = valueOf(tsz);
   BRAM_Configure bramCfg = defaultValue;
   let memorySize = 2**tsz;
   bramCfg.memorySize = memorySize;
   BRAM2Port#(Bit#(tsz), Vector#(3, Float)) sigmoidTable <- mkBRAM2Server(bramCfg);

   Reg#(Float) rscaleReg <- mkReg(fromReal(0.0));
   Reg#(Float) llimitReg <- mkReg(fromReal(0.0));
   Reg#(Float) ulimitReg <- mkReg(fromReal(0.0));

   Vector#(2, BRAMServer#(Bit#(tsz), Vector#(3,Float))) bramPorts;
   bramPorts[0] = sigmoidTable.portA;
   bramPorts[1] = sigmoidTable.portB;

   interface ReadOnly rscale = regToReadOnly(rscaleReg);
   interface ReadOnly llimit = regToReadOnly(llimitReg);
   interface ReadOnly ulimit = regToReadOnly(ulimitReg);
   interface Vector ports = bramPorts;
   method Action setSigmoidLimits(Float _rscale, Float _llimit, Float _ulimit);
      $display("setSigmoidLimits memorySize=%d\n", memorySize);
      rscaleReg <= _rscale;
      llimitReg <= _llimit;
      ulimitReg <= _ulimit;
      $display($format("rscale=", fshow(_rscale), "pack(rscale)=", fshow(pack(_rscale)), " llimit=", fshow(_llimit), " ulimit=", fshow(_ulimit)));
   endmethod
   method Action updateSigmoidTable(Bit#(tsz) addr, Vector#(3,Float) v);
      sigmoidTable.portB.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: addr, datain: v});
   endmethod
   method Bit#(32) tableSize();
      return (1 << tsz);
   endmethod
endmodule

// Why was this not picked up from FloatingPoint.bsv???
function Integer bias( FloatingPoint#(e,m) din );
   return (2 ** (valueof(e)-1)) - 1;
endfunction

function Int#(32) toInt32(FloatingPoint#(e,m) din);
   Int#(32) res = 0;

   if (isNaN(din))
      res = 0;
   else if (isInfinity(din))
      res = (din.sign) ? unpack('h80000000) : unpack('h7FFFFFFF);
   else begin
      // if the quantity is less than +/-1, it is zero.
      if (din.exp >= fromInteger(bias(din))) begin
	 // be sure to re-add the hidden bit when converting.
	 Bit#(TAdd#(m,1)) y = { 1, din.sfd };
	 y = y >> (fromInteger(bias(din)) + fromInteger(valueOf(m)) - din.exp);
	 Bit#(32) r = cExtend(y);

	 if (din.sign) res = unpack(~r + 1);
	 else          res = unpack(r);
      end
   end
   return res;
endfunction

module mkSigmoidServer#(Integer id, SigmoidTable#(tsz) sigmoidTable)(Server#(Float,Float))
   provisos (Add#(tsz,2,usz),
	     Add#(a__, usz, 32)
	     );
   let tsz = valueOf(tsz);
   Int#(usz) numEntries = 1<<fromInteger(tsz);
   // linear approximation around in range [-8,8]

   Bool verbose = False;
   FIFOF#(Float) angleFifo <- mkSizedFIFOF(4);
   Vector#(2,FloatAlu) mul   <- replicateM(mkFloatMultiplier(defaultValue));
   Vector#(2,FloatAlu) adder <- replicateM(mkFloatAdder(defaultValue));
   let adder_fifo <- mkFIFO;
   
   rule lookupEntry;
      let response <- mul[1].response.get();
      Float scaled_angle = tpl_1(response);
      Exception e = tpl_2(response);
      if (verbose && pack(e) != 0) $display("lookup.exception e=%h scaled_angle=%h", e, pack(scaled_angle));
      
      Int#(usz) i = truncate(toInt32(scaled_angle));
      Bit#(tsz) index = truncate(pack(i + numEntries/2));
      if (i > (numEntries/2-1))
	 index = truncate(pack(numEntries-1));
      if (i < -numEntries/2)
	 index = 0;
      if (verbose) $display("sigmoid lookupEntry i=%d index=%d numEntries=%d", i, index, numEntries);
      sigmoidTable.ports[0].request.put(BRAMRequest{ write: False, responseOnWrite: False, address: index, datain: ?});
   endrule

   FIFOF#(Vector#(3, Float)) vFifo <- mkFIFOF();
   rule computeDelta;
      let vs <- sigmoidTable.ports[0].response.get();
      let angle <- toGet(angleFifo).get;
      if (verbose) $display("computeDelta angle=%h vs[0]=%h", pack(angle), pack(vs[0]));
      adder[1].request.put(tuple2(angle, vs[0]));
      vFifo.enq(vs);
   endrule

   rule interpolate;
      let vs <- toGet(vFifo).get;
      let result <- adder[1].response.get();
      let delta = tpl_1(result);
      Exception e = tpl_2(result);
      if (verbose && pack(e) != 0) $display("interpolate.exception e=%h delta=%h", e, pack(delta));
      if (verbose) $display("sigmoid interpolate delta=%h vs[1]=%h vs[2]", pack(delta), pack(vs[1]), pack(vs[2]));
      mul[0].request.put(tuple2(vs[2],delta));
      adder_fifo.enq(vs[1]);
   endrule
   
   rule accumulate;
      match {.p, .*} <- mul[0].response.get;
      let v <- toGet(adder_fifo).get;
      adder[0].request.put(tuple2(v,p));
   endrule
   
   interface Put request;
      method Action put(Float angle);
	 let c = compareFP(angle, sigmoidTable.llimit);
	 let d = compareFP(angle, sigmoidTable.ulimit);
	 if (c == LT)
	    angle = sigmoidTable.llimit;
	 if (d == GT)
	    angle = sigmoidTable.ulimit;
	 angleFifo.enq(angle);
	 mul[1].request.put(tuple2(angle, sigmoidTable.rscale));
	 if (verbose) $display("sigmoid request.put");
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Float) get();
	 match {.v,.e} <- adder[0].response.get();
	 if (verbose && pack(e) != 0) $display("adder[0].exception e=%h v=%h", e, pack(v));
	 if (verbose) $display("sigmoid response.get");
	return v;
     endmethod
   endinterface
endmodule

interface SigmoidIfc#(numeric type dsz);
   interface SigmoidRequest sigmoidRequest;
   method Action sigmoidDone;
   method Action updateDone;
   method Bit#(32) tableSize;
endinterface

module  mkSigmoid#(Vector#(2,MemReadEngineServer#(TMul#(N,32))) readSrvrs,
		   Vector#(1,MemWriteEngineServer#(TMul#(N,32))) writeSrvrs) (SigmoidIfc#(dsz))
   provisos (Bits#(Float, fsz)
	     , Add#(N,0,n)
	     , Mul#(fsz,N,dmasz)
	     , Bits#(Vector#(N,Float), dsz)
	     , Mul#(dbytes, 8, dsz)
	     , Div#(dsz, 8, dbytes)
	     , Log#(n,nshift)
	     );
   let nshift = valueOf(nshift);
   Bool verbose = False;
   VectorSource#(dmasz, Vector#(n,Float)) source <- mkMemReadVectorSource(readSrvrs[0]);
   VectorSource#(dmasz, Vector#(n,Float)) tabsrc <- mkMemReadVectorSource(readSrvrs[1]);

   Vector#(n, SigmoidTable#(6)) sigmoidTables <- replicateM(mkSigmoidTable);
   Vector#(n, Server#(Float,Float)) sigmoidServers <- mapM(uncurry(mkSigmoidServer), zip(genVector,sigmoidTables));

   Reg#(Bool) updatingSigmoidTable <- mkReg(False);
   Reg#(Bit#(6)) entryNumber <- mkReg(0);

   PipeOut#(Vector#(4, Float)) tabsrcs <- mkUnfunnel(tabsrc.pipe);
   Reg#(Bit#(32)) count <- mkReg(0);
   VectorSink#(TMul#(N,32),Vector#(N,Float)) sinkC <- mkMemWriteVectorSink(writeSrvrs[0]);

   rule updateSigmoidTableRule if (updatingSigmoidTable);
      let vs <- toGet(tabsrcs).get;
      if (verbose) $display("updateSigmaTableRule vs[0]=%h entryNumber=%d", vs[0], entryNumber);
      Vector#(3,Float) vs3 = take(vs);
      for (Integer i = 0; i < valueOf(n); i = i + 1) begin
	 sigmoidTables[i].updateSigmoidTable(entryNumber, vs3);
      end
      entryNumber <= entryNumber + 1;
   endrule

   Reg#(Bit#(32)) countInput <- mkReg(0);
   rule consumeInput if (!updatingSigmoidTable);
      let vs <- toGet(source.pipe).get;
      for (Integer i = 0; i < valueOf(n); i = i + 1) begin
         sigmoidServers[i].request.put(vs[i]);
      end
      if (verbose) $display("consumeInput countInput=%d vs[0]=%h", countInput+1, vs[0]);
      countInput <= countInput + 1;
   endrule

   rule enqResult;
      Vector#(n, Float) vs;
      for (Integer i = 0; i < valueOf(n); i = i + 1) begin
         let v <- sigmoidServers[i].response.get();
	 vs[i] = v;
      end
      if (verbose) $display("sigmoid count=%d value=%h", count+1, vs);
      count <= count + 1;
      sinkC.pipe.enq(vs);
   endrule

   method Action sigmoidDone;
      let b <- sinkC.finish();
   endmethod

   method Action updateDone;
      let b <- tabsrc.finish();
      updatingSigmoidTable <= False;
   endmethod

   method Bit#(32) tableSize;
      return sigmoidTables[0].tableSize;
   endmethod

   interface SigmoidRequest sigmoidRequest;
      method Action sigmoid(Bit#(32) readPointer, Bit#(32) readOffset,
   			    Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numvalues);
	 source.start(readPointer, 0, unpack(extend(numvalues))>>nshift);
	 sinkC.start(writePointer, 0, unpack(extend(numvalues))>>nshift);
	 if (verbose) $display("sigmoid.start numvalues=%d", numvalues);
      endmethod
      method Action setLimits(Bit#(32) rscale, Bit#(32) llimit, Bit#(32) ulimit);
	 for (Integer i = 0; i < valueOf(n); i = i + 1) begin
	    sigmoidTables[i].setSigmoidLimits(unpack(rscale), unpack(llimit), unpack(ulimit));
	 end
      endmethod
      method Action updateTable(Bit#(32) readPointer, Bit#(32) readOffset, Bit#(32) numvalues);
	 entryNumber <= 0;
	 updatingSigmoidTable <= True;
	 tabsrc.start(readPointer, extend(readOffset), (4*extend(numvalues))>>nshift);
	 if (verbose) $display("sigmoid.updateSigmoidTable %d %d %d", readPointer, readOffset, numvalues);
      endmethod
      method Action tableSize();
	 noAction;
      endmethod
   endinterface
endmodule
