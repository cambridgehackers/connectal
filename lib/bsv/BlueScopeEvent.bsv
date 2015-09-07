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

// Idea:
// BlueScopeEvent allows one to record values only when they change,
// along with timestamps of the time of change.
// The input is some collection of bits, in some clock domain
// A trigger signal is generated when the input, anded with a trigger
// mask, changes from clock to clock
// Whenever the trigger happens, the new value and a timestamp are saved
// into a SyncBRAMFiFo.  The output of the FiFo is in the system clock
// domain, as is a counter value that says how many events have happened.
// One can request a DMA write from the FiFo to system memory, at a given
// address, for a given count.
// One can reset the fifo and counter.
import Clocks::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import GetPut::*;
import Connectable::*;
import MemTypes::*;
import MemWriteEngine::*;
import ClientServer::*;

// This version records timestamped events
interface BlueScopeEventRequest;
   // emtpy fifo and reset event counter
   method Action doReset();
   // changes in bits selected by the mask will trigger events
   method Action setTriggerMask(Bit#(32) mask);
   // generate a report pointer indication
   method Action getCounterValue();
   // copy from fifo to memory
   method Action startDma(Bit#(32) pointer, Bit#(32) len);
endinterface

interface BlueScopeEventIndication;
   // report number of events since last reset,
   method Action counterValue(Bit#(32) v);
   // dma operation complete
   method Action dmaDone();
endinterface

interface BlueScopeEvent#(numeric type dataWidth);
   method Action dataIn(Bit#(dataWidth) d);
endinterface
   
interface BlueScopeEventControl#(numeric type dataWidth);
   interface BlueScopeEvent#(dataWidth) bse;
   interface BlueScopeEventRequest requestIfc;
   interface MemWriteClient#(64) writeClient;
endinterface

module mkBlueScopeEvent#(Integer samples, BlueScopeEventIndication indication)(BlueScopeEventControl#(dataWidth))
   provisos(Add#(0,dataWidth,32));
   
   let clk <- exposeCurrentClock;
   let rst <- exposeCurrentReset;
   let rv  <- mkSyncBlueScopeEvent(samples, indication, clk, rst, clk,rst);
   return rv;
endmodule

// sClk is the source? sample? side, input samples come here
// dClk is the destination? dma? side, this will generally be the system clock

module mkSyncBlueScopeEvent#(Integer samples, BlueScopeEventIndication indication, Clock sClk, Reset sRst, Clock dClk, Reset dRst)(BlueScopeEventControl#(dataWidth))
   provisos(Add#(0, dataWidth, 32));

   // the idea here is that we let events pour into the Bram continually,
   // then reset them before starting an acquisition interval
   // we reset both halves of the fifo, not clear that is needed
   MakeResetIfc sFifoReset <- mkReset(2, True, sClk);
   MakeResetIfc dFifoReset <- mkReset(2, True, dClk);
   SyncFIFOIfc#(Bit#(64)) dfifo <- mkSyncBRAMFIFO(samples, sClk, sFifoReset.new_rst, dClk, dFifoReset.new_rst);
   // mask reg is set from a request in the dClk domain but used in the
   // sClk domain to determine triggering
   Reg#(Bit#(dataWidth))       maskReg <- mkSyncReg(0, dClk, dRst, sClk);
   // freeClockReg counts cycles to timestamp events
   Reg#(Bit#(32)) freeClockReg <- mkReg(0, clocked_by sClk, reset_by sRst);
   // countReg counts accumulated samples
   Reg#(Bit#(32)) countReg <- mkReg(0, clocked_by sClk, reset_by sRst);
   // countSyncReg repeats that value into the dClk domain
   Reg#(Bit#(32)) countSyncReg <- mkSyncReg(0, sClk, sFifoReset.new_rst, dClk);
   // oldData is used in the sample domain, to save the previous value
   Reg#(Bit#(dataWidth)) olddata <- mkReg(0, clocked_by sClk, reset_by sRst);


   MemWriteEngine#(64,64,2,1) mwriter <- mkMemWriteEngine;
   
//   (* descending_urgency = "resetState, startState" *)

   mkConnection(toGet(dfifo), toPut(mwriter.writeServers[0].data));

   rule writeDone;
      let tag <- mwriter.writeServers[0].done.get();
      indication.dmaDone;
   endrule

   rule freeClock;
      freeClockReg <= freeClockReg + 1;
   endrule
   
   interface BlueScopeEvent bse;
   
      method Action dataIn(Bit#(dataWidth) data);// if (stateReg != Idle);
	 let c = countReg;
	 if ((maskReg & (data ^ olddata)) != 0)
            begin
	       if (dfifo.notFull())
		  begin
		     dfifo.enq({data, freeClockReg});
		     countReg <= c + 1;
		     countSyncReg <= c + 1;
		  end
	       else
		  $display("bluescope.stall c=%d", c);
	    end
	 olddata <= data;
      endmethod

     endinterface
      
   interface BlueScopeEventRequest requestIfc;

      method Action doReset();
	 sFifoReset.assertReset();
	 dFifoReset.assertReset();
      endmethod
      
      method Action setTriggerMask(Bit#(32) mask);
	 maskReg <= truncate(mask);
      endmethod

      method Action getCounterValue();
         indication.counterValue(countSyncReg);
      endmethod

      method Action startDma(Bit#(32) pointer, Bit#(32) len);
	 mwriter.writeServers[0].request.put(MemengineCmd {sglId: pointer, base: 0, burstLen: 8*fromInteger(valueOf(TDiv#(dataWidth,8))), len: len, tag: ?});
      endmethod

   endinterface
   interface writeClient = mwriter.dmaClient;
endmodule

