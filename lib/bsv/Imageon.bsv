
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
import Gearbox::*;
import Clocks::*;
import IserdesDatadeser::*;
import XilinxCells::*;
import XbsvXilinxCells::*;
import XbsvSpi::*;
import HDMI::*;

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
    method Action set_trigger_cnt_trigger(Bit#(32) v);
endinterface

interface ImageonSensor;
    interface ImageonSensorRequest control;
    interface ImageonSensorPins pins;
    method ActionValue#(Bit#(10)) get_data();
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

module mkImageonSensor#(Clock axi_clock, Reset axi_reset, SerdesData serdes, Bool send_trigger,
        HdmiInternalRequest hdmicontrol, Clock hdmi_clock, Reset hdmi_reset)(ImageonSensor);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    XbsvODDR#(Bit#(1)) pll_out <- mkXbsvODDR(ODDRParams{ddr_clk_edge:"SAME_EDGE", init:1, srtype:"ASYNC"});
    XbsvODDR#(Bit#(1)) pll_t <- mkXbsvODDR(ODDRParams{ddr_clk_edge:"SAME_EDGE", init:1, srtype:"ASYNC"});
    Wire#(Bit#(1)) poutq <- mkDWire(0);
    Wire#(Bit#(1)) ptq <- mkDWire(0);
    ReadOnly#(Bit#(1)) vita_clk_pll <- mkOBUFT(poutq, ptq);
    Reg#(Bit#(1)) imageon_oe <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(32)) trigger_cnt_trigger_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);

    Reg#(Bit#(1))  trigger_active <- mkReg(1);
    Reg#(Bit#(32)) tcounter <- mkReg(0);
    Reg#(Bit#(1))  remapkernel_reg <- mkReg(0);

    Wire#(Bit#(1)) zero_wire <- mkDWire(0);
    Wire#(Bit#(1)) one_wire <- mkDWire(1);
    Vector#(3, ReadOnly#(Bit#(1))) vita_trigger_wire;
    vita_trigger_wire[2] <- mkOBUFT(zero_wire, imageon_oe);
    vita_trigger_wire[1] <- mkOBUFT(one_wire, imageon_oe);
    vita_trigger_wire[0] <- mkOBUFT(trigger_active, imageon_oe);
    ReadOnly#(Bit#(1)) vita_reset_n_wire <- mkOBUFT(serdes.reset(), imageon_oe);
    Gearbox#(4, 1, Bit#(10)) dataGearbox <- mkNto1Gearbox(defaultClock, defaultReset, hdmi_clock, hdmi_reset);

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
        if (trigger_active == 1 && send_trigger)
            begin
            tcounter <= trigger_cnt_trigger_reg;
            trigger_active <= 0;
            end
        else
            tcounter <= tcounter - 1;
        if (trigger_active == 0 && tcounter == 0)
            trigger_active <= 1;
    endrule

    rule calculate_framedata;
        Vector#(5, Bit#(10)) v = serdes.raw_data();
        if (v[0] == 10'h035)
            begin
            Vector#(4, Bit#(10)) dor;
            for (Integer i = 0; i < 4; i = i + 1)
                if (remapkernel_reg == 0)
                    dor[i] = v[i+1];
                else
                    dor[i] = v[4-i];
            remapkernel_reg <= ~remapkernel_reg;
            dataGearbox.enq(dor);
            end
        else
            remapkernel_reg <= 0;
    endrule

    interface ImageonSensorRequest control;
        method Bit#(32) get_debugind();
            return 0;
	endmethod
	method Action set_host_oe(Bit#(1) v);
	    imageon_oe <= ~v;
            hdmicontrol.setTestPattern(0);
	endmethod
	method Action set_trigger_cnt_trigger(Bit#(32) v);
	    trigger_cnt_trigger_reg <= v;
	endmethod
    endinterface: control
    method ActionValue#(Bit#(10)) get_data();
        dataGearbox.deq;
        return dataGearbox.first[0];
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
