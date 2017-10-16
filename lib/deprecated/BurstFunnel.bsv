// Copyright (c) 2015 The Connectal Project

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
import FIFOF::*;
import FIFO::*;
import GetPut::*;
import ClientServer::*;
import BRAM::*;
import BRAMFIFO::*;
import Connectable::*;
import ConfigCounter::*;
import ConnectalMemory::*;
import ConnectalMemTypes::*;
import Pipe::*;
import ConnectalMemUtils::*;

typedef struct {
   Bit#(busWidth)  data;
   Bool            last;
} BFunnelData#(numeric type busWidth) deriving (Bits, Eq);
typedef struct {
   Bit#(nameWidth)        name;
   BFunnelData#(busWidth) data;
} BFunnelNameData#(numeric type nameWidth, numeric type busWidth) deriving (Bits, Eq);
typedef struct {
   Bit#(nameWidth)        name;
   Bit#(busWidth)         data;
} BFunnelFunnel#(numeric type nameWidth, numeric type busWidth) deriving (Bits, Eq);
typedef struct {
   Bit#(oldWidth) oldName;
   Bit#(newWidth) newName;
} BFunnelRename#(numeric type oldWidth, numeric type newWidth) deriving (Bits, Eq);

interface BurstFunnel#(numeric type k, numeric type w);
   method Action loadIdx(Bit#(TLog#(k)) i);
   interface Vector#(k, PipeIn#(Bit#(w))) dataIn;
   interface Vector#(k, Reg#(Bit#(BurstLenSize))) burstLen;
   interface PipeOut#(BFunnelFunnel#(TLog#(k),w)) dataOut;
endinterface

module mkBurstFunnel#(Integer maxBurstLen)(BurstFunnel#(k,w))
   provisos( Log#(k,logk)
	    ,Min#(2,logk,bpc)
	    ,FunnelPipesPipelined#(1, k, BFunnelNameData#(2,w), bpc)
	    );

   Reg#(Bit#(2)) nameGen <- mkReg(0);
   UGBramFifos#(4,16,BFunnelData#(w)) complBuff <- mkUGBramFifos;
   Vector#(4, ConfigCounter#(16)) compCnts <- replicateM(mkConfigCounter(0));
   Vector#(k,FIFOF#(BFunnelNameData#(2, w))) data_in <- replicateM(mkFIFOF);
   Vector#(k,Reg#(Bit#(BurstLenSize))) burst_len <- replicateM(mkReg(0));
   Vector#(k,Reg#(Bit#(BurstLenSize))) drain_cnt <- replicateM(mkReg(0));
   Reg#(Bit#(BurstLenSize)) inj_ctrl <- mkReg(0);
   FIFO#(BFunnelRename#(TAdd#(1,logk),2)) loadIdxs <- mkSizedBRAMFIFO(32);
   FIFO#(BFunnelRename#(TAdd#(1,logk),2)) inFlight <- mkSizedBRAMFIFO(4);
   FunnelPipe#(1, k, BFunnelNameData#(2,w),bpc) data_in_funnel <- mkFunnelPipesPipelined(map(toPipeOut,data_in));
   Reg#(Bit#(BurstLenSize)) drainCnt <- mkReg(0);
   FIFOF#(BFunnelFunnel#(TLog#(k),w)) exit_data <- mkFIFOF;
   FIFO#(Bit#(logk)) drainRename <- mkFIFO;
   
   Reg#(Bit#(32)) cycle <- mkReg(0);
   Reg#(Bit#(32)) last_entry <- mkReg(0);
   
   rule cyc;
      cycle <= cycle+1;
   endrule
   
   function PipeIn#(Bit#(w)) enter_data(FIFOF#(BFunnelNameData#(2, w)) f, Integer i) = 
      (interface PipeIn;
   	  method Bool notFull = f.notFull;
          method Action enq(Bit#(w) data) if (loadIdxs.first.oldName == fromInteger(i));
	     last_entry <= cycle;
	     let first = inj_ctrl == 0;
	     let cnt = first ? burst_len[i] : inj_ctrl;
	     let new_cnt = cnt-1;
	     let last = new_cnt == 0;
	     inj_ctrl <= new_cnt;
	     if (first)
		inFlight.enq(loadIdxs.first);
	     if (last) 
		loadIdxs.deq;
	     f.enq(BFunnelNameData{name:loadIdxs.first.newName, data:BFunnelData{data:data, last:last}});
	     //$display("%d enq %d", cycle-last_entry, i);
	  endmethod
       endinterface);
   Vector#(k, PipeIn#(Bit#(w))) data_in_pipes = zipWith(enter_data, data_in, genVector);

   function Reg#(Bit#(BurstLenSize)) check(Reg#(Bit#(BurstLenSize)) r) =
      (interface Reg;
	  method Action _write(Bit#(BurstLenSize) v);
	     if(v > 16) begin
		$display("ERROR mkBurstFunnel: burstLen too large");
		$finish;
	     end
	     r <= v;
	  endmethod
	  method Bit#(BurstLenSize) _read = r._read;
       endinterface);

   rule drain_funnel;
      let v <- toGet(data_in_funnel[0]).get;
      complBuff.enq(v.name,v.data);
      compCnts[v.name].increment(1);
   endrule
      
   
   rule drain_req (compCnts[inFlight.first.newName].read > 0);
      let new_drainCnt = drainCnt-1;
      if (drainCnt == 0) begin
	 new_drainCnt = burst_len[inFlight.first.oldName]-1;
	 drainRename.enq(truncate(inFlight.first.oldName));
      end
      if (new_drainCnt == 0) begin
	 inFlight.deq;
      end
      complBuff.first_req(inFlight.first.newName);
      drainCnt <= new_drainCnt;
      compCnts[inFlight.first.newName].decrement(1);
      complBuff.deq(inFlight.first.newName);
   endrule
      
   rule drain_resp;
      let v <- complBuff.first_resp;
      if (v.last)
	 drainRename.deq;
      exit_data.enq(BFunnelFunnel{name:drainRename.first,data:v.data});
   endrule
      
   method Action loadIdx(Bit#(logk) idx);
      loadIdxs.enq(BFunnelRename{oldName:extend(idx), newName: nameGen});
      nameGen <= nameGen+1;
   endmethod
   interface burstLen = map(check,burst_len);
   interface dataIn = data_in_pipes;
   interface PipeOut dataOut = toPipeOut(exit_data);
endmodule
