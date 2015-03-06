
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

import Leds::*;
import Vector::*;
import MemTypes::*;
import GetPut::*;
import Gearbox::*;
import FIFO::*;

interface MaxSonarPins;
   method Bit#(1) range_ctrl();
   method Action pulse(Bit#(1) v);
endinterface

interface MaxSonarCtrlRequest;
   method Action pulse_width();
   method Action set_en(Bit#(32) en);
   method Action range_ctrl(Bit#(1) v);
   method Action sample(Bit#(32) sgl_id, Bit#(32) alloc_sz);
endinterface

interface MaxSonarCtrlIndication;
   method Action range_ctrl(Bit#(1) v);
   method Action pulse_width(Bit#(32) v);
   method Action memwrite_status(Bit#(32) addr, Bit#(32) wrap_cnt);
endinterface

interface MaxSonarSampleStream;
   method Action sample(Bit#(32) v);
endinterface

interface MaxSonarController;
   interface MaxSonarCtrlRequest req;
   interface MaxSonarPins pins;
   interface LEDS leds;
   interface MemWriteClient#(64) dmaClient;
endinterface

module mkMaxSonarController#(MaxSonarCtrlIndication ind)(MaxSonarController);
   
   Reg#(Bit#(1)) range_ctrl_reg <- mkReg(0);
   Vector#(2,Reg#(Bit#(32))) high_cnt <- replicateM(mkReg(0));
   Reg#(Bit#(1)) last_pulse <- mkReg(0);
   Reg#(Bool) end_pulse <- mkReg(False);
   Reg#(Bit#(32))  en_memwr   <- mkReg(maxBound);
   Reg#(Bit#(32))  sampleCnt  <- mkReg(0);
   Reg#(Bit#(32))  allocSz    <- mkReg(0);
   Reg#(Bit#(32))  writePtr   <- mkReg(0);
   Reg#(Bit#(32))  wrapCnt    <- mkReg(0);
   Reg#(Bit#(32))  sglId      <- mkReg(0);
   FIFO#(Bool)     pw_fifo    <- mkSizedFIFO(1);
   Reg#(Bit#(8))   wr_reg     <- mkReg(0);
`ifdef BSIM
   Reg#(Bit#(32))  bsim_cnt   <- mkReg(0);
   Reg#(Bit#(32))  bsim_pulse <- mkReg(0);
`endif
   FIFO#(Bit#(8))  wr_queue   <- mkSizedFIFO(1);

   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   Gearbox#(1,2,Bit#(32)) gb   <- mk1toNGearbox(clk,rst,clk,rst);
   let verbose = True;
   
`ifdef BSIM
   rule bsim_pulse_rule if (!end_pulse);
      if (bsim_pulse[10] == 1) begin
	 bsim_cnt <= bsim_cnt+1;
	 high_cnt[1] <= bsim_cnt+1;
	 end_pulse <= True;
	 bsim_pulse <= 0;
      end 
      else begin
	 bsim_pulse <= bsim_pulse+1;
      end
   endrule
`endif   

   rule fill_gb if (end_pulse);
      end_pulse <= False;
      gb.enq(cons(high_cnt[1],nil));
   endrule
   
   interface MaxSonarCtrlRequest req;
      method Action set_en(Bit#(32) en);
	 en_memwr <= en;
	 if(en == 0) ind.memwrite_status(writePtr, wrapCnt);
      endmethod
      method Action sample(Bit#(32) sgl_id, Bit#(32) alloc_sz);
	 $display("sample %d %d", sgl_id, alloc_sz);
	 sampleCnt <= 0;
	 allocSz <= alloc_sz;
	 sglId <= sgl_id;
      endmethod
      method Action range_ctrl(Bit#(1) v);
	 range_ctrl_reg <= v;
	 ind.range_ctrl(v);
      endmethod
      method Action pulse_width();
	 ind.pulse_width(high_cnt[1]);
      endmethod
   endinterface
   
   // pulse width modulation
   interface MaxSonarPins pins;
      method Bit#(1) range_ctrl();
	 return range_ctrl_reg;
      endmethod
      method Action pulse(Bit#(1) v);
	 last_pulse <= v;
	 if (last_pulse == 1 && v == 0) begin // end of pulse
	    high_cnt[1] <= high_cnt[0];
	    high_cnt[0] <= 0;
	    end_pulse <= True;
	 end
	 else if (v == 1) begin
	    high_cnt[0] <= high_cnt[0]+1;
	 end
      endmethod
   endinterface
   
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = extend(range_ctrl_reg);
   endinterface
   
   interface MemWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(MemRequest) get if (allocSz > 0 && en_memwr > 0);
	    Bit#(8) bl = 8;
	    Bit#(32) new_writePtr = writePtr + extend(bl);
	    if (new_writePtr >= allocSz) begin
	       new_writePtr = 0;
	       bl =  truncate(allocSz-writePtr);
	       wrapCnt <= wrapCnt+1;
	       en_memwr <= en_memwr-1;
	    end
	    writePtr <= new_writePtr;
	    if (verbose) $display("writeReq %d", writePtr);
	    wr_queue.enq(bl);
	    return MemRequest {sglId:sglId, offset:extend(writePtr), burstLen:bl, tag:0};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(64)) get;
	    gb.deq;
	    let new_wr_reg = wr_reg-8;
	    if (wr_reg == 0) begin
	       let wrv <- toGet(wr_queue).get;
	       new_wr_reg = wrv-8;
	    end
	    wr_reg <= new_wr_reg;
	    let rv = pack(gb.first);
	    if(verbose) $display("writeData %h", rv);
	    return MemData{data:rv, tag:0, last:(new_wr_reg==0)};
	 endmethod
      endinterface
      interface Put writeDone;
	 method Action put(Bit#(MemTagSize) tag);
	    if(verbose) $display("writeDone");
	 endmethod
      endinterface
   endinterface

   
endmodule
