
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
import Vector::*;
import BuildVector::*;
import Clocks::*;
import GetPut::*;
import ClientServer::*;
import SCCB::*;
import FIFOF::*;
import BRAMFIFO::*;
import Gearbox::*;
import ConnectalMemTypes::*;
import ConnectalConfig::*;
import MemWriteEngine::*;
import Pipe::*;
import ConnectalClocks::*;
import ConnectalXilinxCells::*;
import Ov7670Interface::*;

interface Ov7670Controller;
   interface Ov7670ControllerRequest request;
   interface Ov7670Pins pins;
   interface Vector#(1,MemWriteClient#(DataBusWidth)) dmaClient;
endinterface

module mkOv7670Controller#(Ov7670ControllerIndication ind)(Ov7670Controller);

   Integer divisor = 12;
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;
   ClockDividerIfc clockDivider <- mkClockDivider(divisor);
   B2C1 b2c <- mkB2C1;
   let pclk = b2c.c;
   Reset preset <- mkAsyncReset(2, defaultReset, pclk);
   SyncFIFOIfc#(Tuple2#(Bit#(32),Bit#(1))) vsyncFifo <- mkSyncFIFO(32, pclk, preset, defaultClock);
   SyncFIFOIfc#(Tuple3#(Bool, Bool, Bit#(8))) dataFifo <- mkSyncBRAMFIFO(16384, pclk, preset, defaultClock, defaultReset);
   Gearbox#(1, 8, Bit#(8))                  dataGearbox <- mk1toNGearbox(defaultClock, defaultReset, defaultClock, defaultReset);

   MemWriteEngine#(DataBusWidth,DataBusWidth,8,1) writeEngine <- mkMemWriteEngineBuff(2048);
   FIFOF#(Bool)        sofFifo    <- mkFIFOF();
   Reg#(Bit#(32))      pointerReg <- mkReg(0);
   Reg#(Bool)     transferDoneReg <- mkReg(False);

   Reg#(Bit#(32)) cycleReg     <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(32)) lastVsyncReg <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(32)) lastDataReg  <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(1)) vsyncReg      <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(1)) hrefReg       <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bit#(8)) dataReg       <- mkReg(0, clocked_by pclk, reset_by preset);
   Reg#(Bool)    firstReg      <- mkReg(False, clocked_by pclk, reset_by preset);
   Reg#(Bool)    lastReg       <- mkReg(False, clocked_by pclk, reset_by preset);
   Reg#(Bit#(16)) dataGapCycles <- mkReg(0, clocked_by pclk, reset_by preset);
   Wire#(Bool)    dataRuleFired <- mkDWire(False, clocked_by pclk, reset_by preset);

   Vector#(3, SCCB) i2c <- replicateM(mkSCCB(1000));
   Reg#(bit) resetReg <- mkReg(0);
   Reg#(bit) pwdnReg <- mkReg(0);

   Reg#(Bit#(1))                   rSCL                <- mkReg(1);
   Reg#(Bit#(1))                   rSDA                <- mkReg(1);
   Reg#(Bool)                      rOutEn              <- mkReg(True);

   for (Integer i = 0; i < 3; i = i + 1)
      rule i2c_response_rule;
	 let response <- i2c[i].user.response.get();
	 ind.i2cResponse(fromInteger(i), response.data);
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
      if (sofFifo.notFull())
	 sofFifo.enq(True);
   endrule

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

      if (sofFifo.notEmpty() && transferDoneReg) begin
	 sofFifo.deq();
	 transferDoneReg <= False;
	 writeEngine.writeServers[0].request.put(MemengineCmd { sglId: pointerReg, base: 0, burstLen: 8*8, len: 640*480, tag: 0});
	 ind.frameStarted(pack(first));
      end

      dataGearbox.enq(unpack(pxl));
      if (gap)
	 ind.data(pack(first), pack(gap), pxl);
   endrule

   rule dataIndRule;
      let d = dataGearbox.first();
      dataGearbox.deq();
      //ind.data8(pack(d));
      if (pointerReg != 0)
	 writeEngine.writeServers[0].data.enq(pack(d));
   endrule

   rule transferDoneRule;
      let d <- writeEngine.writeServers[0].done.get();
      transferDoneReg <= True;
      ind.frameTransferred();
   endrule

   interface Ov7670ControllerRequest request;
      method Action setFramePointer(Bit#(32) frameId);
	 pointerReg <= frameId;
	 transferDoneReg <= True; // prime the pump
      endmethod
      method Action i2cRequest(Bit#(8) bus, Bool write, Bit#(7) slaveaddr, Bit#(8) address, Bit#(8) data);
	 i2c[bus].user.request.put(SCCBRequest {write: write, slaveaddr: slaveaddr, address: address, data: data});
      endmethod
      method Action setReset(Bit#(1) rval);
	 resetReg <= rval;
      endmethod
      method Action setPowerDown(Bit#(1) pwdn);
	 pwdnReg <= pwdn;
      endmethod
   endinterface
   interface Ov7670Pins pins;
      interface SCCB_Pins i2c0 = i2c[0].i2c;
      interface SCCB_Pins i2c1 = i2c[1].i2c;
      interface SCCB_Pins i2c2 = i2c[2].i2c;
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
   interface Vector dmaClient = vec(writeEngine.dmaClient);
endmodule
