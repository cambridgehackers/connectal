
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
import Clocks::*;
import FIFO::*;
import FIFOF::*;
import SyncBits::*;
import ImageonVita::*;
import IserdesDatadeserIF::*;

typedef Vector#(10, Reg#(Bit#(10))) TrainRotate;

typedef enum { AIdle, AReset, AEdge, AWait, AShift,
     ARotated, AFirst, ASecond, AFound, AAlign} AState deriving (Bits,Eq);

//(* synthesize *)
module mkIserdesDatadeser#(Clock serdes_clock, Reset serdes_reset, Clock serdest, Bit#(1) align_start,
    Bit#(1) autoalign, Bit#(10) training, Bit#(10) manual_tap, TrainRotate trainrot, Bool bvi_reset_reg,
    Bool fifo_wren_sync)(IserdesDatadeser);

    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    FIFOF#(Bit#(10)) dfifo <- mkFIFOF(clocked_by serdes_clock, reset_by serdes_reset);
    SyncBitIfc#(Bit#(10)) dfifo_data <-  mkSyncBits(0, serdes_clock, serdes_reset, defaultClock, defaultReset);
    SyncBitIfc#(Bit#(1)) dfifo_empty <-  mkSyncBit(serdes_clock, serdes_reset, defaultClock);
    SyncBitIfc#(Bool) bvi_resets_reg <- mkSyncBit(serdes_clock, serdes_reset, defaultClock);
    Reg#(Bit#(3)) ctrl_sample <- mkReg(0);

    Reg#(AState)  astate <- mkReg(AIdle);
    Reg#(Bit#(1)) astate_reset <- mkSyncReg(0, defaultClock, defaultReset, serdes_clock);
    Reg#(Bit#(10)) data_init1 <- mkReg(0);
    Reg#(Bit#(10)) data_init2 <- mkReg(0);
    Reg#(Bit#(10)) edge_init <- mkReg(0);
    Reg#(Bit#(10)) edge_int <- mkSyncReg(0, serdes_clock, serdes_reset, defaultClock);
    Reg#(Bit#(11)) maxcount <- mkReg(0);
    Reg#(Bit#(10)) windowcount <- mkReg(0);
    Reg#(Bit#(16)) retrycounter <- mkReg(0);
    Reg#(Bit#(16)) gencounter <- mkReg(0);

    SyncFIFOIfc#(SerdesStart) serdes_start <- mkSyncFIFO(2, defaultClock, defaultReset, serdes_clock);
    SyncFIFOIfc#(Bit#(1)) serdes_end <- mkSyncFIFO(2, serdes_clock, serdes_reset, defaultClock);
    Reg#(Bit#(1)) serdes_running <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(10)) serdes_data <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(SerdesStart) syncparam <- mkReg(unpack(0), clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(3)) sync_counter <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(10)) ctrl_data <- mkSyncReg(0, serdes_clock, serdes_reset, defaultClock);
    ClockDividerIfc serdest_inverted <- mkClockInverter(clocked_by serdest);
    IserdesCore core <- mkIserdesCore(serdes_clock, serdes_reset, serdest,
        serdest_inverted.slowClock, astate_reset, syncparam);

    //*************************** alignment operation FSM *****************
    rule afsminit_rule if (!bvi_resets_reg.read());
        ctrl_sample <= 0;
        edge_init <= 0;
        data_init1 <= 0;
        data_init2 <= 0;
        maxcount <= -1;
        windowcount <= 0;
        retrycounter <= -1;
        gencounter <= -1;
        astate <= AIdle;
    endrule

    rule afsmidle2_rule if (bvi_resets_reg.read() && astate == AIdle && align_start == 1);
        windowcount <= 0;
        retrycounter <= 'h7ffd;
        ctrl_sample <= 0;
        astate <= AReset;
        serdes_start.enq(SerdesStart{increment: False, ce:0, bitslip:0});
    endrule
    rule afsmdelay_rule if (bvi_resets_reg.read() && astate == AReset);
        serdes_end.deq();
        let gc = 15;
        if (autoalign == 0)
            begin
            gc = {6'b0, manual_tap};
            astate <= AFound;
            end
        else
            astate <= AEdge;
        maxcount <= 31;
        gencounter <= gc;
        serdes_start.enq(SerdesStart{increment: False, ce:~autoalign, bitslip:0});
    endrule
    rule afsmcedge1_rule if (bvi_resets_reg.read() && astate == AEdge
            && retrycounter < 'h8000);
        serdes_end.deq();
        astate <= AIdle;
    endrule
    rule afsmcedge2_rule if (bvi_resets_reg.read() && astate == AEdge
            && retrycounter >= 'h8000);
        serdes_end.deq();
        let mc = maxcount;
        let inctemp = False;
        if (edge_int != 0)
            begin
            data_init1 <= rotateBitsBy(ctrl_data, 10-1);
            data_init2 <= rotateBitsBy(ctrl_data, 10-2);
            edge_init <= edge_int;
            astate <= AWait;
            end
        else if (maxcount[10] == 1)
            astate <= AReset;
        else
            begin
            maxcount <= maxcount - 1;
            inctemp = True;
            astate <= AEdge;
            end
        retrycounter <= retrycounter - 1;
        serdes_start.enq(SerdesStart{increment: inctemp, ce:pack(inctemp), bitslip:0});
    endrule
    rule afsmwait_rule if (bvi_resets_reg.read() && astate == AWait);
        serdes_end.deq();
        let gc = gencounter - 1;
        if (gencounter >= 'h8000)
            begin
            gc = 9;
            astate <= AShift;
            end
        else
            begin
            let inctemp = False;
            if (edge_init != edge_int)
                begin
                if (maxcount[10] == 1)
                    astate <= AReset;
                else
                    begin
                    gc = 14;
                    inctemp = True;
                    astate <= AEdge;
                    end
                retrycounter <= retrycounter - 1;
                maxcount <= maxcount - 1;
                end
            serdes_start.enq(SerdesStart{increment: inctemp, ce:pack(inctemp), bitslip:0});
            end
        gencounter <= gc;
    endrule
    rule afsmcompare_rule if (bvi_resets_reg.read() && astate == AShift);
        let gc = gencounter - 1;
        if (gencounter >= 'h8000)
            begin
            let inctemp = False;
            if (maxcount[10] == 1)
                astate <= AReset;
            else
                begin
                retrycounter <= retrycounter - 1;
                gc = 14;
                inctemp = True;
                astate <= AEdge;
                end
            serdes_start.enq(SerdesStart{increment: inctemp, ce:pack(inctemp), bitslip:0});
            end
        else if (ctrl_data == trainrot[gencounter])
            begin
            let csamplein = 3'b001;
            if (gencounter == 9)
                csamplein = 3'b010;
            else if (gencounter == 8)
                csamplein = 3'b100;
            ctrl_sample <= csamplein;
            astate <= ARotated;
            serdes_start.enq(SerdesStart{increment: True, ce:1, bitslip:0});
            end
        gencounter <= gc;
        maxcount <= maxcount - 1;
    endrule
    rule afsm1changed_rule if (bvi_resets_reg.read() && astate == ARotated);
        serdes_end.deq();
        let inctemp = False;
        if (ctrl_data == data_init1)
            begin
            gencounter <= 15;
            astate <= AFirst;
            end
        else if (maxcount[10] == 1)
            astate <= AReset;
        else
            begin
            inctemp = True;
            maxcount <= maxcount - 1;
            end
        serdes_start.enq(SerdesStart{increment: inctemp, ce:pack(inctemp), bitslip:0});
    endrule
    rule afsm1stable_rule if (bvi_resets_reg.read() && astate == AFirst);
        serdes_end.deq();
        let mc = maxcount;
        let inctemp = True;
        if (gencounter >= 'h8000)
            begin
            windowcount <= windowcount + 1;
            mc = mc - 1;
            astate <= ASecond;
            end
        else
            begin
            let gc = gencounter - 1;
            if (ctrl_data == data_init1)
                inctemp = False;
            else
                begin
                mc = mc - 1;
                gc = 15;
                astate <= ARotated;
                end
            gencounter <= gc;
            end
        maxcount <= mc;
        serdes_start.enq(SerdesStart{increment: inctemp, ce:pack(inctemp), bitslip:0});
    endrule
    rule afsmsecond_rule if (bvi_resets_reg.read() && astate == ASecond);
        serdes_end.deq();
        let inctemp = False;
        if (ctrl_data == data_init2)
            begin
            gencounter <= {7'b0, windowcount[9:1]} - 16'b10;
            astate <= AFound;
            end
        else if (maxcount[10] == 1)
            astate <= AReset;
        else
            begin
            windowcount <= windowcount + 1;
            inctemp = True;
            maxcount <= maxcount - 1;
            end
        serdes_start.enq(SerdesStart{increment: inctemp, ce:pack(inctemp), bitslip:0});
    endrule
    rule afsmfound_rule if (bvi_resets_reg.read() && astate == AFound);
        serdes_end.deq();
        let gc = gencounter;
        if (gencounter >= 'h8000)
            begin
            if (ctrl_data != training)
                begin
                gc = 8;
                astate <= AAlign;
                serdes_start.enq(SerdesStart{increment: False, ce:1, bitslip:0});
                end
            else
                astate <= AIdle;
            end
        else
            begin
            gc = gc - 1;
            serdes_start.enq(SerdesStart{increment: autoalign == 1, ce:1, bitslip:0});
            end
        gencounter <= gc;
    endrule
    rule afsmalign_rule if (bvi_resets_reg.read() && astate == AAlign);
        serdes_end.deq();
        if (ctrl_data == training || gencounter >= 'h8000)
            astate <= AIdle;
        else
            begin
            gencounter <= gencounter - 1;
            serdes_start.enq(SerdesStart{increment: False, ce:0, bitslip:1});
            end
    endrule

    //*************************** serdes setting FSM *****************
    rule serdes_idle_rule if (bvi_reset_reg);
        if (serdes_start.notEmpty) begin
            serdes_start.deq();
            syncparam <= serdes_start.first;
            serdes_running <= 1;
            sync_counter <= 3;
        end
        else begin
            syncparam <= unpack(0);
            sync_counter <= sync_counter - 1;
        end
    endrule

    rule serdes_running2_rule if (bvi_reset_reg && serdes_running == 1
            && sync_counter[2] == 1);
        ctrl_data <= serdes_data;
        Bit#(10) edgeo = 0;
        for (Integer i = 0; i < 9; i = i + 1)
            edgeo[i] = serdes_data[i] ^ serdes_data[i+1];
        edgeo[9] = serdes_data[0] ^ serdes_data[9];
        edge_int <= edgeo;
        serdes_end.enq(1);
        serdes_running <= 0;
    endrule

    rule reset_clock_rule;
        bvi_resets_reg.send(bvi_reset_reg);
    endrule

    rule qfsmall;
        astate_reset <= pack(astate == AReset);
    endrule
    rule serdesreset_rule if (!bvi_reset_reg);
        syncparam <= unpack(0);
        serdes_running <= 0;
        dfifo.clear();
    endrule

    rule clear_fifo if (astate_reset == 1);
        dfifo.clear();
    endrule

    rule serdesda2_rule;
        let dout = core.data();
        serdes_data <= dout;
        if (fifo_wren_sync)
            dfifo.enq(dout);
    endrule

    rule serdesrule;
        dfifo_data.send(dfifo.first);
        dfifo.deq();
    endrule
    rule fifoe_rule;
        dfifo_empty.send(pack(!dfifo.notEmpty()));
    endrule

    SyncBitIfc#(Bit#(14)) serdes_capture <-  mkSyncBits(0, serdes_clock,
        serdes_reset, defaultClock, defaultReset);
    Reg#(Bool) startCapture <- mkReg(False);
    rule startcap;
        if (bvi_resets_reg.read())
            startCapture <= True;
    endrule

    rule capstateser;
        serdes_capture.send({pack(syncparam), pack(fifo_wren_sync), serdes_data});
    endrule

    method Bit#(64) capture() if (startCapture); // early time capture
        return {edge_int, windowcount[4:0], pack(astate), ctrl_data, gencounter, ctrl_sample, align_start, autoalign,
            serdes_capture.read};
    endmethod
    method Bit#(1)                align_busy();
        return pack(astate != AIdle);
    endmethod
    method Bit#(3)                samplein();
        return ctrl_sample;
    endmethod
    method Bit#(1)                empty();
        return dfifo_empty.read();
    endmethod
    method Bit#(10)               dataout();
        return dfifo_data.read();
    endmethod
    method io_vita_data_p = core.io_vita_data_p;
    method io_vita_data_n = core.io_vita_data_n;
endmodule: mkIserdesDatadeser

module mkISerdes#(Clock axi_clock, Reset axi_reset, ImageonSerdesIndication indication)(ISerdes);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    SerdesClock coreClock <- mkSerdesClock();
    Clock serdes_clock = coreClock.serdes_clkif;
    Reset serdes_reset = coreClock.serdes_resetif;

    Reg#(Bit#(1)) decoder_enable_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_auto_align_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_align_start_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_fifo_enable_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    ReadOnly#(Bit#(1)) serdes_fifo_enable_null <- mkNullCrossingWire(serdes_clock, serdes_fifo_enable_reg);
    Reg#(Bit#(10)) serdes_manual_tap_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) serdes_training_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_reset_reg <- mkSyncReg(1, axi_clock, axi_reset, defaultClock);
    ReadOnly#(Bit#(1)) serdes_reset_null <- mkNullCrossingWire(serdes_clock, serdes_reset_reg);
    Wire#(Bit#(50)) raw_data_wire <- mkDWire(0);
    Wire#(Bit#(1)) empty_wire <- mkDWire(0);

    SyncBitIfc#(Bit#(1)) serdes_align_busy_reg <- mkSyncBit(defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(1)) new_raw_empty_reg <- mkReg(1);
    TrainRotate trainrot <- replicateM(mkSyncReg(0, axi_clock, axi_reset, defaultClock));
    Vector#(5, IserdesDatadeser) pin_v <- replicateM(mkIserdesDatadeser(serdes_clock, serdes_reset, coreClock.serdest_clkif,
	  serdes_align_start_reg, serdes_auto_align_reg, serdes_training_reg,
	  serdes_manual_tap_reg, trainrot, serdes_reset_null != 0, serdes_fifo_enable_null != 0));

    Reg#(Bit#(25)) control_data <- mkReg(0);
    Reg#(Bit#(50)) dump_data <- mkReg(0);
    rule sendup_imageon_clock;
       Bit#(5) alignbusyw = 0;
       Bit#(5) emptyw = 0;
       Bit#(15) samplein = 0;
       Bit#(50) rawdataw = 0;
       for (Bit#(8) i = 0; i < 5; i = i+1) begin
	  alignbusyw[i] = pin_v[i].align_busy();
	  emptyw[i] = pin_v[i].empty();
          samplein[(i+1)*3-1: i*3] = pin_v[i].samplein();
	  rawdataw[(i+1)*10-1: i*10] = pin_v[i].dataout();
       end
       serdes_align_busy_reg.send(pack(~alignbusyw == 0));
       //bittest_wire <= pack(samplein == 3'b110);
       empty_wire <= pack(emptyw != 0);
       raw_data_wire <= rawdataw;
       control_data <= {alignbusyw, emptyw, samplein};
       dump_data <= rawdataw;
    endrule

    rule serdes_calc2;
        new_raw_empty_reg <= empty_wire;
    endrule
    //rule clear_align if (serdes_align_busy_reg.read() == 1);
        //serdes_align_start_reg <= 0;
    //endrule

    Reg#(Bool) runCapture <- mkSyncReg(False, axi_clock, axi_reset, defaultClock);
    interface ImageonSerdesRequest request;
	method Action set_serdes_manual_tap(Bit#(10) v);
	    serdes_manual_tap_reg <= v;
	endmethod
	method Action set_serdes_training(Bit#(10) v);
	    serdes_training_reg <= v;
            for (UInt#(4) i = 0; i < 10; i = i + 1)
                trainrot[i] <= rotateBitsBy(v, i+6);
	endmethod
	method Action set_iserdes_control(Bit#(32) v);
	    serdes_reset_reg <= ~v[0];
	    serdes_auto_align_reg <= v[1];
	    serdes_align_start_reg <= v[2];
	    serdes_fifo_enable_reg <= v[3];
	endmethod
        method Action get_iserdes_control();
	    let v = 0;
	    v[9] = serdes_align_busy_reg.read();
            indication.iserdes_control_value(v);
	endmethod
	method Action set_decoder_control(Bit#(32) v);
	    decoder_enable_reg <= v[1];
	endmethod
    endinterface

    interface ImageonSerdesPins pins;
        method Action io_vita_sync_p(Bit#(1) v);
            pin_v[0].io_vita_data_p(v);
        endmethod
        method Action io_vita_sync_n(Bit#(1) v);
            pin_v[0].io_vita_data_n(v);
        endmethod
        method Action io_vita_data_p(Bit#(4) v);
            for (Integer i = 0; i < 4; i = i + 1)
                pin_v[i+1].io_vita_data_p(v[i]);
        endmethod
        method Action io_vita_data_n(Bit#(4) v);
            for (Integer i = 0; i < 4; i = i + 1)
                pin_v[i+1].io_vita_data_n(v[i]);
        endmethod
        method io_vita_clk_p = coreClock.io_vita_clk_p;
        method io_vita_clk_n = coreClock.io_vita_clk_n;
    endinterface
    interface SerdesData data;
        method Reg#(Bit#(1)) reset();
            return serdes_reset_reg;
        endmethod
        method Vector#(5, Bit#(10)) raw_data() if (new_raw_empty_reg == 0 && serdes_reset_reg != 0);
            Vector#(5, Bit#(10)) in = unpack(raw_data_wire);
            return in;
	endmethod
        method Bit#(64) capture(); // late-time capture if (runCapture);
            return pin_v[0].capture(); //{control_data, dump_data[38:0]};
	endmethod
        method Action start_capture();
            runCapture <= True;
        endmethod
    endinterface
endmodule
