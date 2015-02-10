
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
import GetPut::*;
import Gearbox::*;
import Clocks::*;
import IserdesDatadeser::*;
import ConnectalSpi::*;
import HDMI::*;
import ImageonVita::*;

Bit#(10) imageData = 10'h035;

(* always_enabled *)
interface ImageonSensorPins;
    interface ImageonVita io_vita;
    method Action io_vita_monitor(Bit#(2) v);
    interface SpiPins spi;
    method Bit#(1) i2c_mux_reset_n();
    interface Clock deleteme_unused_clock;
    interface Reset deleteme_unused_reset;
endinterface

interface ImageonSensorRequest;
    method Action set_host_oe(Bit#(1) v);
    method Action set_trigger_cnt_trigger(Bit#(32) v);
    method Action put_spi_request(Bit#(32) v);
    method Action set_i2c_mux_reset_n(Bit#(1) v);
endinterface

interface ImageonSensorIndication;
    method Action spi_response(Bit#(32) v);
endinterface

interface ImageonSensor;
    interface ImageonSensorRequest control;
    interface ImageonSensorPins pins;
    method ActionValue#(Bit#(10)) get_data();
    method Bit#(2) monitor();
endinterface

module mkImageonSensor#(Clock axi_clock, Reset axi_reset, SerdesData serdes, Bool send_trigger,
        Clock hdmi_clock, Reset hdmi_reset, ImageonSensorIndication indication)(ImageonSensor);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    Wire#(Bit#(2)) monitor_wires <- mkDWire(0);
    Reg#(Bit#(1)) imageon_oe <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(32)) trigger_cnt_trigger_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);

    Reg#(Bit#(1))  trigger_active <- mkReg(1);
    Reg#(Bit#(32)) tcounter <- mkReg(0);
    Reg#(Bit#(1))  remapkernel_reg <- mkReg(0);
    Gearbox#(4, 1, Bit#(10)) dataGearbox <- mkNto1Gearbox(defaultClock, defaultReset, hdmi_clock, hdmi_reset);
    SPI#(Bit#(26)) spiController <- mkSPI(1000, True, clocked_by axi_clock, reset_by axi_reset);
    Reg#(Bit#(1)) i2c_mux_reset_n_reg <- mkReg(0, clocked_by axi_clock, reset_by axi_reset);
    ImageonVita vitaItem <- mkImageonVita(imageon_oe, trigger_active, serdes.reset);

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
        if (v[0] == imageData || v[0] == 'h15)
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

    rule spiControllerResponse;
        Bit#(26) v <- spiController.response.get();
        indication.spi_response(extend(v));
    endrule

    interface ImageonSensorRequest control;
	method Action set_host_oe(Bit#(1) v);
	    imageon_oe <= ~v;
	endmethod
	method Action set_trigger_cnt_trigger(Bit#(32) v);
	    trigger_cnt_trigger_reg <= v;
            serdes.start_capture();
	endmethod
        method Action put_spi_request(Bit#(32) v);
            spiController.request.put(truncate(v));
        endmethod
        method Action set_i2c_mux_reset_n(Bit#(1) v);
            i2c_mux_reset_n_reg <= v;
        endmethod
    endinterface: control
    method ActionValue#(Bit#(10)) get_data();
        dataGearbox.deq;
        return dataGearbox.first[0];
    endmethod
    method Bit#(2) monitor();
        return monitor_wires;
    endmethod
    interface ImageonSensorPins pins;
        method Action io_vita_monitor(Bit#(2) v);
	    monitor_wires <= v;
        endmethod
        interface io_vita = vitaItem;
        method Bit#(1) i2c_mux_reset_n(); return i2c_mux_reset_n_reg; endmethod
        interface SpiPins spi = spiController.pins;
        interface deleteme_unused_clock = defaultClock;
        interface deleteme_unused_reset = defaultReset;
    endinterface
endmodule
