
// Copyright (c) 2012 Nokia, Inc.

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

import RegFile::*;
import BRAMFIFO::*;
import FIFOF::*;
import AxiMasterSlave::*;

interface FifoToAxi#(type busWidth, type busWidthBytes);
   interface Reg#(Bit#(32)) base;
   interface Reg#(Bit#(32)) bounds;
   interface Reg#(Bit#(32)) threshold;
   interface Reg#(Bool) enabled;
   interface Reg#(Bool) oneBeatAddress;
   interface Reg#(Bool) thirtyTwoBitTransfer;
   interface Reg#(Bit#(32)) ptr;
   method Bool notEmpty();
   method Bool notFull();

   method Bit#(32) readStatus(Bit#(12) addr);

   interface AxiMasterWrite#(busWidth,busWidthBytes) axi;
   method Action enq(Bit#(busWidth) value);
   method ActionValue#(Bit#(32)) getResponse();
endinterface

interface FifoFromAxi#(type busWidth);
   interface Reg#(Bit#(32)) base;
   interface Reg#(Bit#(32)) bounds;
   interface Reg#(Bit#(32)) threshold;
   interface Reg#(Bool) enabled;
   interface Reg#(Bool) oneBeatAddress;
   interface Reg#(Bool) thirtyTwoBitTransfer;
   interface Reg#(Bit#(32)) ptr;
   method Bool notEmpty();
   method Bool notFull();

   method Bit#(32) readStatus(Bit#(12) addr);

   interface AxiMasterRead#(busWidth) axi;

   method Action deq();
   method Bit#(busWidth) first();
   method ActionValue#(Bit#(32)) getResponse();
endinterface

module mkFifoToAxi(FifoToAxi#(busWidth,busWidthBytes)) provisos(Div#(busWidth,8,busWidthBytes),Add#(1,z,busWidth));
   Reg#(Bool) enabledReg <- mkReg(False);
   Reg#(Bool) oneBeatAddressReg <- mkReg(True);
   Reg#(Bool) thirtyTwoBitTransferReg <- mkReg(False);
   Reg#(Bit#(32)) baseReg <- mkReg(0);
   Reg#(Bit#(32)) boundsReg <- mkReg(0);
   Reg#(Bit#(32)) thresholdReg <- mkReg(0);
   Reg#(Bit#(32)) ptrReg <- mkReg(0);
   Reg#(Bit#(32)) addrsBeatCount <- mkReg(0);
   Reg#(Bit#(32)) wordsWrittenCount <- mkReg(0);
   Reg#(Bit#(32)) wordsEnqCount <- mkReg(0);
   Reg#(Bit#(32)) lastDataBeatCount <- mkReg(0);
   FIFOF#(Bit#(busWidth)) dfifo <- mkSizedBRAMFIFOF(8);
   Reg#(Bit#(8)) burstCountReg <- mkReg(0);
   Reg#(Bool) operationInProgress <- mkReg(False);
   Reg#(Bool) addressPresented <- mkReg(False);
   FIFOF#(Bit#(2)) axiBrespFifo <- mkSizedBRAMFIFOF(32);

   rule updateBurstCount if (!dfifo.notFull() && !operationInProgress && enabledReg);
       burstCountReg <= 8'd8;
       operationInProgress <= True;
       addressPresented <= False;
   endrule

   method Bool notEmpty();
       return dfifo.notEmpty;
   endmethod

   method Bool notFull();
       return dfifo.notFull;
   endmethod

   interface Reg base;
       method Action _write(Bit#(32) base) if (!operationInProgress);
          if (!enabledReg) begin
              baseReg <= base;
              ptrReg <= base;
          end
       endmethod
       method Bit#(32) _read();
          return baseReg;
       endmethod
   endinterface

   interface Reg bounds;
       method Action _write(Bit#(32) bounds) if (!operationInProgress);
          if (!enabledReg) begin
              boundsReg <= bounds;
          end
       endmethod
       method Bit#(32) _read();
          return boundsReg;
       endmethod
   endinterface

   interface Reg threshold = thresholdReg;
   interface Reg enabled = enabledReg;
   interface Reg oneBeatAddress = oneBeatAddressReg;
   interface Reg thirtyTwoBitTransfer = thirtyTwoBitTransferReg;

   method Bit#(32) readStatus(Bit#(12) addr);
   Bit#(32) v = 32'h02142042;
   if (addr == 12'h000)
       v =  baseReg;
   else if (addr == 12'h004)
       v = boundsReg;
   else if (addr == 12'h008)
       v = ptrReg;
   else if (addr == 12'h00C)
       v = extend(burstCountReg);
   else if (addr == 12'h010)
       v = enabledReg ? 32'heeeeeeee : 32'hdddddddd;
   else if (addr == 12'h014)
   begin
       v = 0;
       v[3:0] = axiBrespFifo.notEmpty ? 4'h1 : 4'he;
       v[15:12] = axiBrespFifo.notFull ? 4'h0 : 4'hf;
   end
   else if (addr == 12'h018)
   begin
       v = 0;
       v[3:0] = dfifo.notEmpty ? 4'h1 : 4'he;
       v[15:12] = dfifo.notFull ? 4'h0 : 4'hf;
   end
   else if (addr == 12'h01C)
   begin
       v[31:24] = 8'hbb;
       v[23:16] = operationInProgress ? 8'haa : 8'h11;
       v[15:0] = extend(burstCountReg);
   end
   else if (addr == 12'h020)
       v = wordsEnqCount;
   else if (addr == 12'h024)
       v = addrsBeatCount;
   else if (addr == 12'h028)
       v = wordsWrittenCount;
   else if (addr == 12'h02C)
       v = lastDataBeatCount;
   return v;
   endmethod

   interface AxiMasterWrite axi;
       method ActionValue#(Bit#(32)) writeAddr() if (operationInProgress && !addressPresented);
           addrsBeatCount <= addrsBeatCount + 1;
           if (oneBeatAddressReg)
               addressPresented <= True;
           let ptrValue = ptrReg;
           return ptrReg;
       endmethod
       method Bit#(8) writeBurstLen();
           return burstCountReg-1;
       endmethod
       method Bit#(3) writeBurstWidth();
           if (valueOf(busWidth) == 32)
               return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
           else if (thirtyTwoBitTransferReg)
               return 3'b010;
           else
               return 3'b011;
       endmethod
       method Bit#(2) writeBurstType();  // drive with 2'b01 increment address
           return 2'b01; // increment address
       endmethod
       method Bit#(3) writeBurstProt(); // drive with 3'b000
           return 3'b000;
       endmethod
       method Bit#(4) writeBurstCache(); // drive with 4'b0011
           return 4'b0011;
       endmethod

       method ActionValue#(Bit#(busWidth)) writeData() if (operationInProgress && dfifo.notEmpty);
           ptrReg <= ptrReg + pack(fromInteger(valueOf(busWidth)/8));
           let bc = burstCountReg;
           if (bc == 8'd1)
           begin
               operationInProgress <= False;
               lastDataBeatCount <= lastDataBeatCount + 1;
           end
           burstCountReg <= bc - 1;
           wordsWrittenCount <= wordsWrittenCount + 1;

           let d = dfifo.first;
           dfifo.deq;
           return d;
       endmethod
       method Bit#(busWidthBytes) writeDataByteEnable();
           return maxBound;
       endmethod
       method Bit#(1) writeLastDataBeat(); // last data beat
           if (burstCountReg == 8'd1)
               return 1'b1;
           else
               return 1'b0;
       endmethod

       method Action writeResponse(Bit#(2) responseCode, Bit#(1) id) if (axiBrespFifo.notFull);
           if (responseCode != 2'b00)
               axiBrespFifo.enq(responseCode);
       endmethod
   endinterface

   method Action enq(Bit#(busWidth) value);
       wordsEnqCount <= wordsEnqCount + 1;
       dfifo.enq(value);
   endmethod
   method ActionValue#(Bit#(32)) getResponse() if (axiBrespFifo.notEmpty);
       axiBrespFifo.deq;
       return extend(axiBrespFifo.first);
   endmethod

endmodule

module mkFifoFromAxi(FifoFromAxi#(busWidth)) provisos (Add#(1,a,busWidth));
   Reg#(Bool) enabledReg <- mkReg(False);
   Reg#(Bool) oneBeatAddressReg <- mkReg(True);
   Reg#(Bool) thirtyTwoBitTransferReg <- mkReg(False);
   Reg#(Bit#(32)) baseReg <- mkReg(0);
   Reg#(Bit#(32)) boundsReg <- mkReg(0);
   Reg#(Bit#(32)) thresholdReg <- mkReg(0);
   Reg#(Bit#(32)) ptrReg <- mkReg(0);
   Reg#(Bit#(32)) addrsBeatCount <- mkReg(0);
   Reg#(Bit#(32)) wordsReceivedCount <- mkReg(0);
   Reg#(Bit#(32)) wordsDeqCount <- mkReg(0);
   Reg#(Bit#(32)) lastDataBeatCount <- mkReg(0);
   FIFOF#(Bit#(busWidth)) rfifo <- mkSizedBRAMFIFOF(32);
   Reg#(Bit#(8)) burstCountReg <- mkReg(0);
   Reg#(Bool) operationInProgress <- mkReg(False);
   Reg#(Bool) addressPresented <- mkReg(False);
   FIFOF#(Bit#(2)) axiRrespFifo <- mkSizedBRAMFIFOF(32);

   rule updateBurstCount if (!rfifo.notEmpty && !operationInProgress && enabledReg && ptrReg < boundsReg);
       burstCountReg <= 8'd8;
       operationInProgress <= True;
       addressPresented <= False;
   endrule

   method Bool notEmpty();
   // fixme
       return rfifo.notEmpty;
   endmethod

   method Bool notFull();
   // fixme
       return rfifo.notFull;
   endmethod

   interface Reg base;
       method Action _write(Bit#(32) base) if (!operationInProgress);
          if (!enabledReg) begin
              baseReg <= base;
              ptrReg <= base;
          end
       endmethod
       method Bit#(32) _read();
          return baseReg;
       endmethod
   endinterface

   interface Reg bounds;
       method Action _write(Bit#(32) bounds) if (!operationInProgress);
          if (!enabledReg) begin
              boundsReg <= bounds;
          end
       endmethod
       method Bit#(32) _read();
          return boundsReg;
       endmethod
   endinterface

   interface Reg threshold = thresholdReg;
   interface Reg enabled = enabledReg;
   interface Reg oneBeatAddress = oneBeatAddressReg;
   interface Reg thirtyTwoBitTransfer = thirtyTwoBitTransferReg;

   method Bit#(32) readStatus(Bit#(12) addr);
       Bit#(32) v = 32'h02142042;
       if (addr == 12'h000)
           v =  baseReg;
       else if (addr == 12'h004)
           v = boundsReg;
       else if (addr == 12'h008)
           v = ptrReg;
       else if (addr == 12'h00C)
           v = extend(burstCountReg);
       else if (addr == 12'h010)
           v = enabledReg ? 32'heeeeeeee : 32'hdddddddd;
       else if (addr == 12'h014)
       begin
           v = 0;
           v[3:0] = axiRrespFifo.notEmpty ? 4'h1 : 4'he;
           v[15:12] = axiRrespFifo.notFull ? 4'h0 : 4'hf;
       end
       else if (addr == 12'h018)
       begin
           v = 0;
           v[3:0] = rfifo.notEmpty ? 4'h1 : 4'he;
           v[15:12] = rfifo.notFull ? 4'h0 : 4'hf;
       end
       else if (addr == 12'h01C)
       begin
           v[31:24] = 8'hbb;
           v[23:16] = operationInProgress ? 8'haa : 8'h11;
           v[15:0] = extend(burstCountReg);
       end
       else if (addr == 12'h020)
           v = wordsDeqCount;
       else if (addr == 12'h024)
           v = addrsBeatCount;
       else if (addr == 12'h028)
           v = wordsReceivedCount;
       else if (addr == 12'h02C)
           v = lastDataBeatCount;
       return v;
   endmethod

   interface AxiMasterRead axi;
       method ActionValue#(Bit#(32)) readAddr() if (operationInProgress && !addressPresented);
           addrsBeatCount <= addrsBeatCount + 1;
           if (oneBeatAddressReg)
               addressPresented <= True;
           let ptrValue = ptrReg;
           return ptrReg;
       endmethod
       method Bit#(8) readBurstLen();
           return burstCountReg-1;
       endmethod
       method Bit#(3) readBurstWidth();
           if (valueOf(busWidth) == 32)
               return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
           else if (thirtyTwoBitTransferReg)
               return 3'b010;
           else
               return 3'b011;
       endmethod
       method Bit#(2) readBurstType();  // drive with 2'b01
           return 2'b01;
       endmethod
       method Bit#(3) readBurstProt(); // drive with 3'b000
           return 3'b000;
       endmethod
       method Bit#(4) readBurstCache(); // drive with 4'b0011
           return 4'b0011;
       endmethod
       method Action readData(Bit#(busWidth) data, Bit#(2) resp, Bit#(1) last, Bit#(1) id) if (rfifo.notFull && operationInProgress);
           let bc = burstCountReg - 1;
           if (bc == 1)
               lastDataBeatCount <= lastDataBeatCount + 1;

           if (resp == 2'b00)
           begin
               burstCountReg <= bc;
               ptrReg <= ptrReg + pack(fromInteger(valueOf(busWidth)/8));
               rfifo.enq(data);
               wordsReceivedCount <= wordsReceivedCount + 1;
           end
           else
           begin
               axiRrespFifo.enq(resp);
           end

           if (resp != 2'b00 || bc == 0)
               operationInProgress <= False;
       endmethod
   endinterface

   method Action deq();
       wordsDeqCount <= wordsDeqCount + 1;
       rfifo.deq();
   endmethod
   method Bit#(busWidth) first();
       return rfifo.first;
   endmethod

   method ActionValue#(Bit#(32)) getResponse() if (axiRrespFifo.notEmpty);
       axiRrespFifo.deq;
       return extend(axiRrespFifo.first);
   endmethod

endmodule

