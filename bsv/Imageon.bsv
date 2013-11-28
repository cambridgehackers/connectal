
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
import Clocks::*;
import IserdesDatadeser::*;
import XilinxCells::*;
import XbsvXilinxCells::*;
import GetPutWithClocks::*;
import XbsvSpi::*;
import YUV::*;

(* always_enabled *)
interface ImageonSensorPins;
    method Bit#(1) io_vita_clk_pll();
    method Bit#(1) io_vita_reset_n();
    method Vector#(3, ReadOnly#(Bit#(1))) io_vita_trigger();
    interface Clock clock_if;
    interface Reset reset_if;
endinterface

interface ImageonSensorRequest;
    method Bit#(32) get_debugind();
    method Action set_host_oe(Bit#(1) v);
    method Action set_decoder_code_ls(Bit#(10) v);
    method Action set_decoder_code_le(Bit#(10) v);
    method Action set_syncgen_delay(Bit#(16) v);
    method Action set_trigger_cnt_trigger(Bit#(32) v);
endinterface
interface ImageonSensorIndication;
endinterface

interface ImageonSensor;
    interface ImageonSensorRequest control;
    interface ImageonSensorPins pins;
    method Bit#(50) get_data();
endinterface

(* always_enabled *)
interface ImageonTopPins;
    method Clock fbbozo();
    method Action fbbozoin(Bit#(1) v);
endinterface

interface ImageonVita;
   interface SpiPins spi;
   interface ImageonSensorPins pins;
   interface ImageonTopPins toppins;
   interface ImageonSerdesPins serpins;
endinterface

module mkImageonSensor#(Clock axi_clock, Reset axi_reset, SerdesData serdes, Bool send_trigger)(ImageonSensor);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    XbsvODDR#(Bit#(1)) pll_out <- mkXbsvODDR(ODDRParams{ddr_clk_edge:"SAME_EDGE", init:1, srtype:"ASYNC"});
    XbsvODDR#(Bit#(1)) pll_t <- mkXbsvODDR(ODDRParams{ddr_clk_edge:"SAME_EDGE", init:1, srtype:"ASYNC"});
    Wire#(Bit#(1)) poutq <- mkDWire(0);
    Wire#(Bit#(1)) ptq <- mkDWire(0);
    ReadOnly#(Bit#(1)) vita_clk_pll <- mkOBUFT(poutq, ptq);
    Reg#(Bit#(1)) imageon_oe <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) decoder_code_ls_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) decoder_code_le_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(32)) trigger_cnt_trigger_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);

    Reg#(Bit#(50)) dataout_reg <- mkReg(0);
    Reg#(Bit#(10)) sync_channel_reg <- mkReg(0);
    Reg#(Bit#(1))  raw_empty_reg <- mkReg(0);
    Reg#(Bool)     tstate <- mkReg(False);
    Reg#(Bit#(32)) tcounter <- mkReg(0);
    Reg#(Bit#(32)) debugind_value <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(10)) sync_delay_reg <- mkReg(0);
    Reg#(Bit#(1))  remapkernel_reg <- mkReg(0);
    Reg#(Bit#(1))  imgdatavalid_reg <- mkReg(0);
    Reg#(Bit#(8))  dcount <- mkReg('hab);

    Wire#(Bit#(1)) zero_wire <- mkDWire(0);
    Wire#(Bit#(1)) one_wire <- mkDWire(1);
    Wire#(Bit#(1)) trigger_wire <- mkDWire(pack(!tstate));
    Vector#(3, ReadOnly#(Bit#(1))) vita_trigger_wire;
    vita_trigger_wire[2] <- mkOBUFT(zero_wire, imageon_oe);
    vita_trigger_wire[1] <- mkOBUFT(one_wire, imageon_oe);
    vita_trigger_wire[0] <- mkOBUFT(trigger_wire, imageon_oe);
    ReadOnly#(Bit#(1)) vita_reset_n_wire <- mkOBUFT(serdes.reset(), imageon_oe);

    rule pll_rule;
        poutq <= pll_out.q();
        ptq <= pll_t.q();
        pll_t.s(False);
        pll_out.s(False);
        pll_out.d1(0);
        pll_out.d2(1);
        pll_out.ce(True);
        pll_t.d1(imageon_oe);
        pll_t.d2(imageon_oe);
        pll_t.ce(True);
    endrule

    rule tcalc;
        if (!tstate && send_trigger)
            begin
            tcounter <= trigger_cnt_trigger_reg;
            tstate <= True;
            end
        else
            tcounter <= tcounter - 1;
        if (tstate && tcounter == 0)
            tstate <= False;
    endrule

    rule data_pipeline;
        raw_empty_reg <= serdes.raw_empty();
    endrule

    rule calculate_framedata;
        if (raw_empty_reg == 0)
            begin
            let idv = imgdatavalid_reg;
            sync_channel_reg <= serdes.raw_data()[9:0];
            if (imgdatavalid_reg == 1)
                begin
                let dor = serdes.raw_data()[49:10];
                if (remapkernel_reg == 0)
                    begin
                    dor[39: 30] = serdes.raw_data()[19: 10];
                    dor[29: 20] = serdes.raw_data()[29: 20];
                    dor[19: 10] = serdes.raw_data()[39: 30];
                    dor[ 9:  0] = serdes.raw_data()[49: 40];
                    end
                remapkernel_reg <= ~ remapkernel_reg;
                if (sync_channel_reg == decoder_code_le_reg)
                    idv = 0;
                dataout_reg <= {sync_channel_reg, dor};
                end
            else if (sync_channel_reg == decoder_code_ls_reg)
                idv = 1;
            imgdatavalid_reg <= idv;
            end
    endrule

    interface ImageonSensorRequest control;
        method Bit#(32) get_debugind();
            return debugind_value;
	endmethod
	method Action set_host_oe(Bit#(1) v);
	    imageon_oe <= ~v;
	endmethod
	method Action set_decoder_code_ls(Bit#(10) v);
	    decoder_code_ls_reg <= v;
	endmethod
	method Action set_decoder_code_le(Bit#(10) v);
	    decoder_code_le_reg <= v;
	endmethod
	method Action set_trigger_cnt_trigger(Bit#(32) v);
	    trigger_cnt_trigger_reg <= v;
	endmethod
    endinterface: control
    method Bit#(50) get_data();
        return dataout_reg;
    endmethod
    interface ImageonSensorPins pins;
        method Bit#(1) io_vita_clk_pll();
            return vita_clk_pll;
        endmethod
        method Bit#(1) io_vita_reset_n();
            return vita_reset_n_wire;
        endmethod
        method Vector#(3, ReadOnly#(Bit#(1))) io_vita_trigger();
            return vita_trigger_wire;
        endmethod
        interface clock_if = defaultClock;
        interface reset_if = defaultReset;
    endinterface
endmodule
