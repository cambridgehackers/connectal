
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
import ConnectalXilinxCells::*;
import PPS7LIB::*;
import FrequencyCounter::*;
import ConnectalClocks::*;
import XilinxCells::*;
import Clocks::*;

(* always_ready, always_enabled *)
interface SDIOPins;
   method Bit#(1) clk;
   interface Inout#(Bit#(1)) cmd;
   interface Inout#(Bit#(1)) d0;
   interface Inout#(Bit#(1)) d1;
   interface Inout#(Bit#(1)) d2;
   interface Inout#(Bit#(1)) d3;
   method Action cdn(Bit#(1) v);
   method Action wp(Bit#(1) v);
endinterface

interface SDIORequest;
   method Action cnt_cycle_req(Bit#(32) v);
   method Action set_spew_en(Bit#(1) v);
   method Action toggle_cd(Bit#(32) v);
endinterface

interface SDIOResponse;
   method Action cnt_cycle_resp(Bit#(32) v);
   method Action emio_sample(Bit#(32) v);
endinterface

interface Controller;
   interface SDIOPins pins;
   interface SDIORequest req;
endinterface

module mkController#(SDIOResponse ind, Pps7Emiosdio sdio)(Controller);
   
   B2C1 b2c <- mkB2C1();
   Clock sdio_clk <- mkClockBUFG(clocked_by b2c.c);
   rule tx_sdio_clk;
      b2c.inputclock(sdio.clk);
   endrule
   Reset def_rst <- exposeCurrentReset();
   Reset sdio_rst <- mkAsyncReset(2, def_rst, sdio_clk);
   FrequencyCounter fc <- mkFrequencyCounter(sdio_clk, sdio_rst);

   Reg#(Bit#(1)) spew_en <- mkReg(0);
   let cmdb <- mkIOBUF(sdio.cmdtn,     sdio.cmdo);
   let d0b  <- mkIOBUF(sdio.datatn[0], sdio.datao[0]);
   let d1b  <- mkIOBUF(sdio.datatn[1], sdio.datao[1]);
   let d2b  <- mkIOBUF(sdio.datatn[2], sdio.datao[2]);
   let d3b  <- mkIOBUF(sdio.datatn[3], sdio.datao[3]);
   Reg#(Bit#(32)) toggle_cd_reg <- mkReg(0);
   
   Bit#(4) db_o = {d3b.o,d2b.o,d1b.o,d0b.o};
   Bit#(1) cmdb_o = cmdb.o;
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule xxx;
      sdio.cmdi(cmdb_o);
      sdio.datai(db_o);
      sdio.clkfb(sdio.clk);
   endrule
   
   rule emio_sample_rule if (spew_en == 1);
      ind.emio_sample({0, db_o, sdio.datatn, sdio.datao, cmdb_o, sdio.cmdtn, sdio.cmdo, sdio.clk});
   endrule
   
   rule cnt_cycle_resp_rule;
      let v <- fc.elapsedCycles;
      ind.cnt_cycle_resp(v);
   endrule
   
   rule decr_toggle_cd_reg (toggle_cd_reg > 0);
	 toggle_cd_reg <= toggle_cd_reg-1;
   endrule
   
   interface SDIORequest req;
      method Action cnt_cycle_req(Bit#(32) v);
	 fc.start(v);
      endmethod
      method Action set_spew_en(Bit#(1) v);
	 spew_en <= v;
      endmethod
      method Action toggle_cd(Bit#(32) v);
	 toggle_cd_reg <= v;
      endmethod
   endinterface
   
   interface SDIOPins pins;
      method Bit#(1) clk = sdio.clk;
      interface cmd = cmdb.io;
      interface d0 = d0b.io;
      interface d1 = d1b.io;
      interface d2 = d2b.io;
      interface d3 = d3b.io;
      method Action cdn(Bit#(1) v) = sdio.cdn((toggle_cd_reg > 0) ? ~v : v);
      method Action wp(Bit#(1) v) = sdio.wp(v);
   endinterface

endmodule


