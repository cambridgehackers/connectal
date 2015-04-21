
// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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

import Clocks::*;
import GetPut::*;
import ClientServer::*;
import I2C::*;

import ConnectalClocks::*;
import Ov7670Interface::*;

interface Ov7670Controller;
   interface Ov7670ControllerRequest request;
   interface Ov7670Pins pins;
endinterface

module mkOv7670Controller#(Ov7670ControllerIndication ind)(Ov7670Controller);

   Integer divisor = 4;
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;
   ClockDividerIfc clockDivider <- mkClockDivider(divisor);
   B2C1 b2c <- mkB2C1;
   let pclk = b2c.c;
   Reset preset <- mkAsyncReset(2, defaultReset, pclk);
   SyncFIFOIfc#(Tuple2#(Bit#(32),Bit#(1))) vsyncFifo <- mkSyncFIFO(32, pclk, preset, defaultClock);
   SyncFIFOIfc#(Tuple3#(Bool, Bool, Bit#(8))) dataFifo <- mkSyncFIFO(32, pclk, preset, defaultClock);

   Reg#(Bit#(32)) cycleReg     <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(32)) lastVsyncReg <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(32)) lastDataReg  <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(1)) vsyncReg      <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(1)) hrefReg       <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(8)) dataReg       <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bool)    firstReg      <- mkReg(False, clocked_by pclk, reset_by preset);
   Reg#(Bool)    lastReg       <- mkReg(False, clocked_by pclk, reset_by preset);

   I2C i2c <- mkI2C(10000);
   Reg#(bit) resetReg <- mkReg(0);
   Reg#(bit) pwdnReg <- mkReg(0);
   rule i2c_response_rule;
      let response <- i2c.user.response.get();
      ind.probeResponse(response.data);
   endrule

   rule cycleRule;
      cycleReg <= cycleReg + 1;
   endrule
   rule vsyncRule;
      if (vsyncReg == 1) begin
	 vsyncFifo.enq(tuple2(cycleReg - lastVsyncReg, hrefReg));
	 lastVsyncReg <= cycleReg;
      end
   endrule
   rule vsyncSyncRule;
      match { .cycles, .href } <- toGet(vsyncFifo).get();
      ind.vsync(cycles, href);
   endrule
   Reg#(Bit#(16)) dataGapCycles <- mkReg(0, clocked_by pclk, reset_by preset);
   Wire#(Bool)    dataRuleFired <- mkDWire(False, clocked_by pclk, reset_by preset);
   rule dataRule;
      if (hrefReg == 1) begin
	 dataRuleFired <= True;
	 let gap = dataGapCycles != 0;
	 dataFifo.enq(tuple3(firstReg, (firstReg ? False : gap), dataReg));
	 lastDataReg <= cycleReg;
	 firstReg <= False;
      end
      else begin
	 firstReg <= True;
      end
   endrule
   rule dataRuleGap if (hrefReg == 1);
      if (!dataRuleFired)
	 dataGapCycles <= dataGapCycles + 1;
      else
	 dataGapCycles <= 0;
   endrule

   rule dataSyncRule;
      match { .first, .gap, .pxl } <- toGet(dataFifo).get();
      ind.data(pack(first), pack(gap), pxl);
   endrule

   interface Ov7670ControllerRequest request;
      method Action probe(Bool write, Bit#(7) slaveaddr, Bit#(8) address, Bit#(8) data);
	 i2c.user.request.put(I2CRequest {write: write, slaveaddr: slaveaddr, address: address, data: data});
      endmethod
      method Action setReset(Bit#(1) rval);
	 resetReg <= rval;
      endmethod
      method Action setPowerDown(Bit#(1) pwdn);
	 pwdnReg <= pwdn;
      endmethod
   endinterface
   interface Ov7670Pins pins;
      interface I2C_Pins i2c = i2c.i2c;
      interface Clock xclk = clockDivider.slowClock;
      interface Clock pclk_deleteme_unused_clock = pclk;
      method bit reset() = resetReg;
      method bit pwdn() = pwdnReg;
      method Action pclk(Bit#(1) v);
	 b2c.inputclock(v);
      endmethod
      method Action pxl(Bit#(1) vsync, Bit#(1) href, Bit#(8) data);
	 vsyncReg <= vsync;
	 hrefReg  <= href;
	 dataReg <= data;
      endmethod
   endinterface
endmodule
