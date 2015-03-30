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
import GetPut::*;
import Clocks :: *;
import BRAMFIFO::*;
import MemTypes::*;
import MemServer::*;
import ClientServer::*;
import Pipe::*;
import MemwriteEngine::*;
import HostInterface::*;
import IserdesDatadeser::*;
import IserdesDatadeserIF::*;

interface ImageonCaptureRequest;
    method Action startWrite(Bit#(32) pointer, Bit#(32) numBytes);
endinterface
interface ImageonCapture;
    interface ImageonCaptureRequest request;
    interface Vector#(1,MemWriteClient#(DataBusWidth)) dmaClient;
endinterface

module mkImageonCapture#(Clock imageon_clock, Reset imageon_reset, SerdesData serdes_data, ImageonSerdesIndication indication)(ImageonCapture);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   // mem capture
   MemwriteEngine#(64,1,1) we <- mkMemwriteEngine();
   Reg#(Bool) dmaRun <- mkSyncReg(False, defaultClock, defaultReset, imageon_clock);
   SyncFIFOIfc#(Bit#(64)) synchronizer <- mkSyncBRAMFIFO(10, imageon_clock, imageon_reset, defaultClock, defaultReset);
   rule sync_data if (dmaRun);
       synchronizer.enq(serdes_data.capture);
   endrule
   rule send_data;
       we.dataPipes[0].enq(synchronizer.first);
       synchronizer.deq;
   endrule
   rule dma_response;
       let rv <- we.writeServers[0].response.get;
       indication.iserdes_dma('hffffffff); // request is all finished
   endrule
   interface ImageonCaptureRequest request;
        method Action startWrite(Bit#(32) pointer, Bit#(32) numBytes);
            we.writeServers[0].request.put(MemengineCmd{sglId:pointer, base:0, len:truncate(numBytes), burstLen:8});
            dmaRun <= True;
       endmethod
   endinterface
   interface MemWriteClient dmaClient = cons(we.dmaClient, nil);
endmodule : mkImageonCapture
