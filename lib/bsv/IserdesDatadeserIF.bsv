
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
import Vector::*;

interface IserdesDatadeser;
    method Bit#(1)          align_busy();
    method Bit#(3)          samplein();
    method Bit#(1)          empty();
    method Bit#(10)         dataout();
    method Action io_vita_data_p(Bit#(1) v);
    method Action io_vita_data_n(Bit#(1) v);
    method Bit#(64) capture();
endinterface: IserdesDatadeser

(* always_enabled *)
interface ImageonSerdesPins;
    method Action io_vita_sync_p(Bit#(1) v);
    method Action io_vita_sync_n(Bit#(1) v);
    method Action io_vita_data_p(Bit#(4) v);
    method Action io_vita_data_n(Bit#(4) v);
    method Action io_vita_clk_p(Bit#(1) v);
    method Action io_vita_clk_n(Bit#(1) v);
endinterface

interface ImageonSerdesRequest;
    method Action set_decoder_control(Bit#(32) v);
    method Action set_iserdes_control(Bit#(32) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Action get_iserdes_control();
endinterface
interface ImageonSerdesIndication;
    method Action iserdes_control_value(Bit#(32) v);
    method Action iserdes_dma(Bit#(32) v);
endinterface

interface SerdesData;
    method Reg#(Bit#(1)) reset();
    method Vector#(5, Bit#(10)) raw_data();
    method Bit#(64) capture();
    method Action start_capture();
endinterface

interface ISerdes;
    interface ImageonSerdesRequest request;
    interface ImageonSerdesPins pins;
    interface SerdesData data;
endinterface
