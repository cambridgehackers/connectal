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
import IserdesDatadeserIF::*;
import ConnectalSpi::*;
import HDMI::*;

interface ImageonCapturePins;
    method Bit#(1) io_vita_clk_pll();
    method Bit#(1) io_vita_reset_n();
    method Vector#(3, ReadOnly#(Bit#(1))) io_vita_trigger();
    method Action io_vita_monitor(Bit#(2) v);
    interface SpiMasterPins#(1) spi;
    method Bit#(1) i2c_mux_reset_n();
    interface Clock imageon_deleteme_unused_clock;
    interface Reset imageon_deleteme_unused_reset;
    interface ImageonSerdesPins serpins;
    (* prefix="" *)
    interface HDMI#(Bit#(HdmiBits)) hdmi;
    method Action fmc_video_clk1(Bit#(1) v);
endinterface
