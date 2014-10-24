
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

// This is a fifo implmented with a ring buffer in main memory.
//
// SW->HW version
//  enqueue data in memory
//  update write pointer with portal request
// The hardware side activates when the write pointer is different than
// the read pointer, and copies data into an output BRAM fifo
//
// Software is responsible for knowing where the read pointer is,
// either by explicitly reading it with a portal-request -> portal indication
// or by other means
// 
// Configuration.  
import MemTypes::*;

interface RingBuffer;
   method Bool notEmpty();
   method Bool notFull();
   method Action push();
   method Action popfetch();
   method Action popack();
   interface Reg#(Bit#(MemOffsetSize)) bufferfirst;
   interface Reg#(Bit#(MemOffsetSize)) bufferlastfetch;
   interface Reg#(Bool) enable;
   interface RingBufferConfig configifc;
   interface Reg#(SGLId) mempointer;
endinterface

interface RingBufferConfig;
   method Action set(Bit#(3) regist, Bit#(64) addr);
   method Action setFirst(Bit#(64) addr);
   method Action setLast(Bit#(64) addr);
   method Bit#(64) get(Bit#(3) regist);
endinterface

module mkRingBuffer(RingBuffer);
   
   Reg#(Bit#(MemOffsetSize)) rbufferbase <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) rbufferend <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) rbufferfirst <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) rbufferlastfetch <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) rbufferlastack <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) rbuffermask <- mkReg(0);
   Reg#(SGLId) rmempointer <- mkReg(0);
   Reg#(Bool) renable <- mkReg(False);
   
   interface RingBufferConfig configifc;
   method Action set(Bit#(3) regist, Bit#(64) addr);
      if (regist == 0) rbufferbase <= truncate(addr);
      else if (regist == 1) rbufferend <= truncate(addr);
      else if (regist == 2) rbufferfirst <= truncate(addr);
      else if (regist == 3) rbufferlastfetch <= truncate(addr);
      else if (regist == 4) rbuffermask <= truncate(addr);
      else if (regist == 5) rmempointer <= truncate(addr);
      else if (regist == 6) rbufferlastack <= truncate(addr);
      else renable <= (addr[0] != 0);
   endmethod
   
   method Action setFirst(Bit#(64) addr);
      rbufferfirst <= truncate(addr);
   endmethod
   
   method Action setLast(Bit#(64) addr);
      rbufferlastfetch <= truncate(addr);
      rbufferlastack <= truncate(addr);
   endmethod
   
   method Bit#(64) get(Bit#(3) regist);
      if (regist == 0) return (zeroExtend(rbufferbase));
      else if (regist == 1) return (zeroExtend(rbufferend));
      else if (regist == 2) return (zeroExtend(rbufferfirst));
      else if (regist == 3) return (zeroExtend(rbufferlastfetch));
      else if (regist == 4) return (zeroExtend(rbuffermask));
      else if (regist == 5) return (zeroExtend(rmempointer));
      else if (regist == 6) return (zeroExtend(rbufferlastack));
      else return(zeroExtend(pack(renable)));
   endmethod
   endinterface

   /* This compares first against lastfetch.  We <start> reads when
    * first increases, and stop initiating reads when lastfetch
    * catches up
    */
   method Bool notEmpty();
   return (rbufferfirst != rbufferlastfetch);
   endmethod

   /* This compares first against lastack because items are not removed
    * from the ring until lastack increments
    */
   method Bool notFull();
   return (((rbufferfirst + 64) & rbuffermask) != rbufferlastack);
   endmethod

   method Action push();
   rbufferfirst <= (rbufferfirst + 64) & rbuffermask;
   endmethod

   method Action popfetch();
   rbufferlastfetch <= (rbufferlastfetch + 64) & rbuffermask;
   endmethod

   method Action popack();
   rbufferlastack <= (rbufferlastack + 64) & rbuffermask;
   endmethod
 
   interface Reg bufferfirst = rbufferfirst;
   interface Reg bufferlastfetch = rbufferlastfetch;
   interface Reg enable = renable;
   interface Reg mempointer = rmempointer;

endmodule
