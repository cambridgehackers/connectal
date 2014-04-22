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

interface ImageCaptureIndication;
    method Action debugind(Bit#(32) v);
    method Action axi_clock_period(Bit#(32) hdmi_cycles);
    method Action hdmi_clock_period(Bit#(32) hdmi_cycles);
    method Action imageon_clock_period(Bit#(32) imageon_cycles);
    method Action fmc_clock_period(Bit#(32) imageon_cycles);
    method Action frameStart(Bit#(2) monitor, Bit#(32) count);
endinterface

interface ImageCaptureRequest;
    method Action set_debugreq(Bit#(32) v);
    method Action get_debugind();
    method Action measure_axi_clock_period(Bit#(32) cycles_100mhz);
    method Action measure_hdmi_clock_period(Bit#(32) cycles_100mhz);
    method Action measure_imageon_clock_period(Bit#(32) cycles_100mhz);
    method Action measure_fmc_clock_period(Bit#(32) cycles_100mhz);
endinterface
