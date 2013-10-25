
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

interface IbufdsOut;
   (* prefix = "" *)
   method Action                 ibufds_out(Bit#(1) v);
endinterface: IbufdsOut

// ports in the "CLOCK" clock domain
interface IserdesControl;
   method Action                 align_start(Bit#(1) v);
   method Bit#(1)                align_busy();
   method Bit#(1)                aligned();
   method Bit#(1)                sampleinfirstbit();
   method Bit#(1)                sampleinlastbit();
   method Bit#(1)                sampleinotherbit();
   method Action                 autoalign(Bit#(1) v);
   method Action                 training(Bit#(10) v);
   method Action                 manual_tap(Bit#(10) v);
endinterface

// ports in the "CLKDIV" clock domain
interface IserdesWren;
   method Action                 delay_wren(Bit#(1) v);
   method Action                 fifo_wren(Bit#(1) v);
endinterface

interface IserdesFifo;
   method Action                 rden(Bit#(1) v);
   method Bit#(1)                empty();
   method ActionValue#(Bit#(10)) dataout();
endinterface

interface IserdesDatadeser;
   interface IbufdsOut           ibufdsOut;
   interface IserdesControl      control;
   interface IserdesWren         wren;
   interface IserdesFifo         fifo;
endinterface: IserdesDatadeser

import "BVI" iserdes_datadeser = 
module mkIserdesDatadeser#(Clock clk, Clock clkdiv)(IserdesDatadeser);

   input_clock clk (CLK) = clk;
   input_clock clkdiv (CLKDIV) = clkdiv;
   default_clock clock(CLOCK);
   default_reset reset(RESET);
   interface IbufdsOut ibufdsOut;
       method              ibufds_out(IBUFDS_OUT) enable((*inhigh*) en0); // clocked_by () reset_by ()
   endinterface: ibufdsOut
   //method sdatan(SDATAN); // unused

   interface IserdesControl control;
      method                  align_start(ALIGN_START) enable((*inhigh*) en1) clocked_by (clock);
      method ALIGN_BUSY       align_busy() clocked_by (clock);
      method ALIGNED          aligned() clocked_by (clock);
      method SAMPLEINFIRSTBIT sampleinfirstbit() clocked_by (clock);
      method SAMPLEINLASTBIT  sampleinlastbit() clocked_by (clock);
      method SAMPLEINOTHERBIT sampleinotherbit() clocked_by (clock);
      method                  autoalign(AUTOALIGN) enable((*inhigh*) en7) clocked_by (clock);
      method                  training(TRAINING) enable((*inhigh*) en8) clocked_by (clock);
      method                  manual_tap(MANUAL_TAP) enable((*inhigh*) en9) clocked_by (clock);
   endinterface

   interface IserdesWren wren;
      method                  fifo_wren(FIFO_WREN) enable((*inhigh*) en10) clocked_by (clkdiv);
      method                  delay_wren(DELAY_WREN) enable((*inhigh*) en11) clocked_by (clkdiv);
   endinterface

   interface IserdesFifo         fifo;
      method               rden(FIFO_RDEN) enable((*inhigh*) en12) clocked_by (clock);
      method FIFO_EMPTY    empty() clocked_by (clock);
      method FIFO_DATAOUT  dataout() enable((*inhigh*) en14) clocked_by(clock);
   endinterface

      schedule (wren_fifo_wren) CF (wren_delay_wren);
   schedule (ibufdsOut_ibufds_out, control_align_start, control_autoalign, control_training, control_manual_tap, fifo_rden, fifo_dataout)
      CF (ibufdsOut_ibufds_out, control_align_start, control_autoalign, control_training, control_manual_tap, fifo_rden, fifo_dataout);
endmodule: mkIserdesDatadeser
