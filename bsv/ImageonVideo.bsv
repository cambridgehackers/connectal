
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
import FIFO::*;
import GetPut::*;
import Gearbox::*;
import Clocks :: *;
import Imageon::*;
import IserdesDatadeser::*;
import XilinxCells::*;
import XbsvXilinxCells::*;
import GetPutWithClocks :: *;
import XbsvSpi :: *;
import YUV::*;

interface ImageonXsviRequest;
    method Action hactive(Bit#(16) v);
    method Action hfporch(Bit#(16) v);
    method Action vactive(Bit#(16) v);
endinterface
interface ImageonXsviIndication;
endinterface

interface ImageonVideo;
    method ActionValue#(Bit#(10)) get();
    interface ImageonXsviRequest control;
endinterface

module mkImageonVideo#(Clock imageon_clock, Reset imageon_reset, Clock axi_clock, Reset axi_reset, ImageonSensor sensor)(ImageonVideo);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    Gearbox#(4, 1, Bit#(10)) dataGearbox <- mkNto1Gearbox(imageon_clock, imageon_reset, defaultClock, defaultReset); 
    Gearbox#(4, 1, Bit#(1))  syncGearbox <- mkNto1Gearbox(imageon_clock, imageon_reset, defaultClock, defaultReset); 

    Reg#(Bit#(1))  hstate <- mkReg(0);
    Reg#(Bit#(16)) vsync_count <- mkReg(0);
    Reg#(Bit#(16)) hsync_count <- mkReg(0);
    Reg#(Bit#(1))  framestart_new <- mkReg(0);
    Reg#(Bit#(16)) syncgen_hactive_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_hfporch_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_vactive_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    
    rule start_fsm if (framestart_new == 1);
        vsync_count <= 0;
        hsync_count <= 0;
        hstate <= 1;
    endrule
 
    rule sync_fsm if (framestart_new != 1);
        let hs = hstate;
        let hc = hsync_count + 1;
  
        if (hstate == 0 && hsync_count >= syncgen_hfporch_reg)
            begin
            hc = 0;
            hs = 1;
            vsync_count <= vsync_count + 1;
            end
        if (hstate == 1 && hsync_count >= syncgen_hactive_reg)
            begin
            hc = 0;
            hs = 0;
            end
        hstate <= hs;
        hsync_count <= hc;
    endrule

    rule update_framestart;
	syncGearbox.deq;
	framestart_new <= syncGearbox.first[0];
    endrule

    rule receive_framestart;
	Vector#(4, Bit#(1)) in = replicate(0);
	// zero'th element shifted out first
	in[1] = sensor.get_framesync();
	syncGearbox.enq(in);
    endrule

    rule receive_data;
	// least signifcant 10 bits shifted out first
	Vector#(4, Bit#(10)) in = unpack(sensor.get_data());
	dataGearbox.enq(in);
    endrule

    interface ImageonXsviRequest control;
	method Action hactive(Bit#(16) v);
	    syncgen_hactive_reg <= v;
	endmethod
	method Action hfporch(Bit#(16) v);
	    syncgen_hfporch_reg <= v;
	endmethod
	method Action vactive(Bit#(16) v);
	    syncgen_vactive_reg <= v;
	endmethod
    endinterface
    method ActionValue#(Bit#(10)) get() if (hsync_count >= syncgen_hfporch_reg && vsync_count < syncgen_vactive_reg);
	dataGearbox.deq;
	return dataGearbox.first[0];
    endmethod
endmodule
