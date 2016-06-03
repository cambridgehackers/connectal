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
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;
import BuildVector::*;
import BRAM::*;
import Gearbox::*;
import Connectable::*;
import StmtFSM::*;
import MemTypes::*;
import MPEngine::*;
import MemReadEngine::*;
import Pipe::*;

interface StrstrRequest;
   method Action setup(Bit#(32) needleSGLId, Bit#(32) mpNextSGLId, Bit#(32) needle_len);
   method Action search(Bit#(32) haystackSGLId, Bit#(32) haystack_len);
endinterface

interface StrstrIndication;
   method Action searchResult(Int#(32) v);
endinterface

interface Strstr#(numeric type haystackBusWidth, numeric type configBusWidth);
   interface StrstrRequest request;
   interface Vector#(1, MemReadClient#(haystackBusWidth)) haystack_read_client;
   interface Vector#(1, MemReadClient#(configBusWidth)) config_read_client;
endinterface

// I can't belive we still have to do this shit
function Bool my_or(Bool a, Bool b) = a || b;
   
typedef `DEGPAR DegPar;   
   
module mkStrstr#(StrstrIndication indication)(Strstr#(haystackBusWidth, configBusWidth))
   provisos( Log#(DegPar,logDegPar)


   ,Mul#(TDiv#(configBusWidth, 8), 8, configBusWidth)
   ,Mul#(TDiv#(haystackBusWidth, 8), 8, haystackBusWidth)
   ,Add#(1, a__, TDiv#(haystackBusWidth, 8))
   ,Add#(b__, TLog#(TDiv#(haystackBusWidth, 8)), 32)
   ,Mul#(TDiv#(configBusWidth, 32), 32, configBusWidth)
   ,Add#(1, c__, TDiv#(configBusWidth, 32))
   ,Add#(d__, TLog#(TDiv#(configBusWidth, 32)), 32)
   ,Add#(e__, TLog#(TDiv#(configBusWidth, 8)), 32)
   ,Add#(1, f__, TDiv#(configBusWidth, 8))
   ,Add#(g__, TLog#(TDiv#(haystackBusWidth, 32)), 32)
   ,Mul#(TDiv#(haystackBusWidth, 32), 32, haystackBusWidth)
   ,Add#(1, h__, TDiv#(haystackBusWidth, 32))
   ,Add#(i__, 32, haystackBusWidth)
   ,Add#(j__, 8, haystackBusWidth)
   ,FunnelPipesPipelined#(1, DegPar, MemData#(haystackBusWidth), MemReadFunnelBPC)
   ,FunnelPipesPipelined#(1, DegPar, MemData#(configBusWidth), MemReadFunnelBPC)
	    );
   
   let verbose = True;

   Reg#(Bit#(32)) needleLen <- mkReg(0);
   MemReadEngine#(haystackBusWidth,haystackBusWidth,1,DegPar) haystack_re <- mkMemReadEngineBuff(1024);
   MemReadEngine#(configBusWidth,configBusWidth,1,DegPar) config_re <- mkMemReadEngineBuff(1024);
   
   Reg#(Bit#(32)) needleSGLId <- mkReg(0);
   Reg#(Bit#(32)) mpNextSGLId <- mkReg(0);
   Reg#(Bit#(32)) haystackSGLId <- mkReg(0);
   Reg#(Bit#(32)) haystackLen <- mkReg(0);
   Reg#(Bit#(32)) startCnt <- mkReg(0);
   Reg#(Bit#(32)) startBase <- mkReg(0);
   Reg#(Bit#(32)) setupCnt <- mkReg(0);
   Reg#(Bit#(32)) doneCnt <- mkReg(0);

   let read_servers = zip(haystack_re.readServers,config_re.readServers);
   Vector#(DegPar, MPEngine#(haystackBusWidth,configBusWidth)) engines <- mapM(uncurry(mkMPEngine),read_servers);
   Vector#(DegPar, PipeOut#(Int#(32))) locdonePipes;

   FIFOF#(Triplet#(Bit#(32))) setsearchFIFO <- mkFIFOF;
   UnFunnelPipe#(1,DegPar,Triplet#(Bit#(32)),1) setsearchPipeUnFunnel <- mkUnFunnelPipesPipelinedRR(vec(toPipeOut(setsearchFIFO)), 1);

   for(Integer i = 0; i < valueOf(DegPar); i=i+1) begin
      locdonePipes[i] = engines[i].locdone;
      mkConnection(setsearchPipeUnFunnel[i],engines[i].setsearch);
   end

   FunnelPipe#(1,DegPar,Int#(32),1) locdonePipe <- mkFunnelPipesPipelined(locdonePipes);
   let lpv = fromInteger(valueOf(logDegPar));
   let pv = fromInteger(valueOf(DegPar));

   rule resr;
      let rv <- toGet(locdonePipe[0]).get;
      if (rv == -1) begin  
	 // notify the SW when the search is finished
	 if (doneCnt+1 == pv) begin
	    doneCnt <= 0;
	    indication.searchResult(-1);
	 end
	 else begin
	    doneCnt <= doneCnt+1;
	 end
      end
      else begin    
	 // send results back to SW
	 indication.searchResult(rv);
	 if (verbose) $display("strstr search result %d", rv);
      end
   endrule
   
   // setup the MPEngines when new configuration arrives
   Stmt setupStmt = 
   seq
      action
	 if (verbose) $display("setupStmt (begin)");
	 setupCnt <= 0;
      endaction
      while(setupCnt < pv) action
	 setupCnt <= setupCnt+1;
	 let tup = tuple3(needleSGLId, mpNextSGLId, needleLen);
	 setsearchFIFO.enq(tup);
	 if (verbose) $display(fshow("setupStmt (mid) ")+fshow(tup));
      endaction
      if (verbose) $display("setupStmt (end)");
   endseq;
   FSM setupFSM <- mkFSM(setupStmt);

   // start the search;
   Stmt startStmt = 
   seq
      action
	 if (verbose) $display("startStmt (begin)");
	 startCnt <= 0;
	 startBase <= 0;
      endaction
      while (startCnt < pv-1) action
	 let tup = tuple3(haystackSGLId, (haystackLen>>lpv)+needleLen, startBase);
	 setsearchFIFO.enq(tup);
	 startBase <= startBase + (haystackLen>>lpv);
	 startCnt <= startCnt+1;
	 if (verbose) $display(fshow("startStmt ")+fshow(tup)+fshow(" (mid)"));
      endaction
      action
	 let tup = tuple3(haystackSGLId, haystackLen>>lpv, startBase);
	 setsearchFIFO.enq(tup);
	 if (verbose) $display(fshow("startStmt ")+fshow(tup)+fshow(" (end)"));
      endaction
   endseq;
   FSM startFSM <- mkFSM(startStmt);
      
   interface StrstrRequest request;
      method Action setup(Bit#(32) needle_sglId, Bit#(32) mpNext_sglId, Bit#(32) needle_len);
	 if (verbose) $display("mkStrstr::setup %d %d %d", needle_sglId, mpNext_sglId, needle_len);
	 needleLen <= needle_len;
	 needleSGLId <= needle_sglId;
	 mpNextSGLId <= mpNext_sglId;
	 setupFSM.start();
      endmethod
   
      method Action search(Bit#(32) haystack_sglId, Bit#(32) haystack_len);
	 if (verbose) $display("mkStrstr::search %d %d", haystack_sglId, haystack_len);
	 haystackLen <= haystack_len;
	 haystackSGLId <= haystack_sglId;
	 startFSM.start();
      endmethod
   endinterface
   interface config_read_client = vec(config_re.dmaClient);
   interface haystack_read_client = vec(haystack_re.dmaClient);
endmodule
