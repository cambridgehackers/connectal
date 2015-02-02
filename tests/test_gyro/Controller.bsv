
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

import GetPut::*;
import Vector::*;
import StmtFSM::*;
import FIFO::*;
import Gearbox::*;

import MemTypes::*;
import Leds::*;
import ConnectalSpi::*;

interface GyroCtrlRequest;
   method Action write_reg_req(Bit#(8) addr, Bit#(8) val);
   method Action read_reg_req(Bit#(8) addr);
   method Action sample(Bit#(32) sgl_id, Bit#(32) alloc_sz, Bit#(32) gyro_sample_period, Bit#(32) timer_period);
endinterface

interface GyroCtrlIndication;
   method Action read_reg_resp(Bit#(8) val);
   method Action write_reg_resp(Bit#(8) addr);
   method Action timer(Bit#(32) addr, Bit#(32) wrapped);
endinterface

interface Controller;
   interface GyroCtrlRequest req;
   interface SpiPins spi;
   interface LEDS leds;
   interface MemWriteClient#(64) dmaClient;
endinterface

module mkController#(GyroCtrlIndication ind)(Controller);

   Reg#(Bool)      wrapped      <- mkReg(False);
   SPI#(Bit#(16))  spiCtrl      <- mkSPI(1000, True);
   Reg#(Bit#(32))  samplePeriod <- mkReg(0);
   Reg#(Bit#(32))  timerPeriod  <- mkReg(0);
   Reg#(Bit#(32))  sampleCnt    <- mkReg(0);
   Reg#(Bit#(32))  timerCnt     <- mkReg(0);
   Reg#(Bit#(32))  sglId        <- mkReg(0);
   Reg#(Bit#(32))  allocSz      <- mkReg(0);
   Vector#(2,Reg#(Bit#(32))) writePtr <- replicateM(mkReg(0));
   FIFO#(Bool)     rc_fifo      <- mkSizedFIFO(1);
   FIFO#(Bit#(8))  wr_queue     <- mkSizedFIFO(4);
   Reg#(Bit#(8))   wr_reg       <- mkReg(0);
`ifdef BSIM
   Reg#(Bit#(8))   bsim_cnt     <- mkReg(0);
`endif
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   Gearbox#(1,8,Bit#(8)) gb     <- mk1toNGearbox(clk,rst,clk,rst);
   Bit#(8) burst_len = 128;	  
   
   
   let out_X_L = 'h28;
   let out_X_H = 'h29;
   let out_Y_L = 'h2A;
   let out_Y_H = 'h2B;
   let out_Z_L = 'h2C;
   let out_Z_H = 'h2D;
   let verbose = False;
   
   rule read_reg_resp;
      let rv <- spiCtrl.response.get;
      if (rc_fifo.first)
	 ind.read_reg_resp(truncate(rv));
      rc_fifo.deq;
   endrule

   rule sample_req(samplePeriod > 0);
      let new_sampleCnt = sampleCnt+1; 
      if (new_sampleCnt == samplePeriod-5) begin
	 spiCtrl.request.put({1'b1,1'b0,out_X_L,8'h00});
	 if(verbose) $display("sample_x_l");
      end
      else if (new_sampleCnt == samplePeriod-4) begin
	 spiCtrl.request.put({1'b1,1'b0,out_X_H,8'h00});
	 if(verbose) $display("sample_x_h");
      end
      else if (new_sampleCnt == samplePeriod-3) begin
	 spiCtrl.request.put({1'b1,1'b0,out_Y_L,8'h00});
	 if(verbose) $display("sample_y_l");
      end
      else if (new_sampleCnt == samplePeriod-2) begin
	 spiCtrl.request.put({1'b1,1'b0,out_Y_H,8'h00});
	 if(verbose) $display("sample_y_h");
      end
      else if (new_sampleCnt == samplePeriod-1) begin
	 spiCtrl.request.put({1'b1,1'b0,out_Z_L,8'h00});
	 if(verbose) $display("sample_z_l");
      end
      else if (new_sampleCnt >= samplePeriod-0) begin
	 spiCtrl.request.put({1'b1,1'b0,out_Z_H,8'h00});
	 if(verbose) $display("sample_z_h");
	 new_sampleCnt = 0;
      end
      sampleCnt <= new_sampleCnt;
   endrule
   
   rule sample_resp(samplePeriod > 0);
      if(verbose) $display("sample_resp");
      let rv <- spiCtrl.response.get;
`ifdef BSIM
      bsim_cnt <= (bsim_cnt == 5) ? 0 : bsim_cnt+1;
      let bsim_val = bsim_cnt[0]==1'b0 ? bsim_cnt+1 : 0;
      gb.enq(cons(bsim_val,nil));
`else
      gb.enq(cons(truncate(rv),nil));
`endif
   endrule
   
   rule timer_rule_a(timerPeriod > 0 && timerCnt < timerPeriod);
      timerCnt <= timerCnt+1;
   endrule

   rule timer_rule_b(timerPeriod > 0 && timerCnt >= timerPeriod);
      timerCnt <= 0;
      ind.timer(writePtr[1], extend(pack(wrapped)));
      wrapped <=  False;
   endrule
   
   interface GyroCtrlRequest req;
      method Action write_reg_req(Bit#(8) addr, Bit#(8) val);
	 spiCtrl.request.put({1'b0,1'b0,addr[5:0],val});
	 ind.write_reg_resp(addr);
	 rc_fifo.enq(False);
      endmethod
      method Action read_reg_req(Bit#(8) addr);
	 spiCtrl.request.put({1'b1,1'b0,addr[5:0],8'h00});
	 rc_fifo.enq(True);
      endmethod
      method Action sample(Bit#(32) sgl_id, Bit#(32) alloc_sz, Bit#(32) gyro_sample_period, Bit#(32) timer_period);
	 $display("sample %d %d %d %d", sgl_id, alloc_sz, gyro_sample_period, timer_period);
	 samplePeriod <= gyro_sample_period;
	 timerPeriod <= timer_period;
	 sampleCnt <= 0;
	 allocSz <= alloc_sz;
	 sglId <= sgl_id;
      endmethod
   endinterface
   
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = 0;
   endinterface

   interface SpiPins spi = spiCtrl.pins;
   interface MemWriteClient dmaClient;
      interface Get writeReq;
	 method ActionValue#(MemRequest) get if (allocSz > 0);
	    let bl = burst_len;
	    let new_writePtr = writePtr[0] + extend(bl);
	    if (new_writePtr >= allocSz) begin
	       new_writePtr = 0;
	       bl =  truncate(allocSz-writePtr[0]);
	       wrapped <= True;
	    end
	    writePtr[0] <= new_writePtr;
	    if (verbose) $display("writeReq %d", writePtr[0]);
	    wr_queue.enq(bl);
	    return MemRequest {sglId:sglId, offset:extend(writePtr[0]), burstLen:bl, tag:0};
	 endmethod
      endinterface
      interface Get writeData;
	 method ActionValue#(MemData#(64)) get;
	    let new_writePtr = writePtr[1] + extend(burst_len);
	    if (new_writePtr >= allocSz) new_writePtr = 0;
	    writePtr[1] <= new_writePtr;
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
