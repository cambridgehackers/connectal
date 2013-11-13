
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
import Clocks :: *;
import FIFO::*;
import XilinxCells::*;
import XbsvXilinxCells::*;

typedef Vector#(10, Reg#(Bit#(10))) TrainRotate;

interface IserdesDatadeser;
    method Action           ibufdso(Bit#(1) v);
    method Bit#(1)          align_busy();
    method Bit#(1)          aligned();
    method Bit#(3)          samplein();
    method Action           delay_wren(Bit#(1) v);
    method Action           fifo_wren(Bit#(1) v);
    method Action           reset(Bit#(1) v);
    method Bit#(1)          empty();
    method Bit#(10)         dataout();
endinterface: IserdesDatadeser

interface FIFO18;
   method Action            di(Bit#(16) v);
   method Action            rden(Bit#(1) v);
   method Action            wren(Bit#(1) v);
   method Action            reset(Bit#(1) v);
   method Bit#(16)          dataout();
   method Bit#(1)           empty();
endinterface: FIFO18

import "BVI" FIFO18 = 
module mkFIFO18#(Clock clkdiv)(FIFO18);
    parameter ALMOST_FULL_OFFSET = 'h80;
    parameter ALMOST_EMPTY_OFFSET = 'h80;
    parameter DATA_WIDTH = 18;
    parameter DO_REG = 1;
    parameter EN_SYN = 0;
    parameter FIRST_WORD_FALL_THROUGH = 0;
    parameter SIM_MODE = "SAFE";

    default_clock clock(RDCLK);
    input_clock clkdiv (WRCLK) = clkdiv;
    no_reset;
    port DIP = 0;

    method          reset(RST) enable((*inhigh*) en9) clocked_by (clkdiv);
    method          di(DI) enable((*inhigh*) en0) clocked_by (clock); //clkdiv);
    method          rden(RDEN) enable((*inhigh*) en2) clocked_by (clock);
    method          wren(WREN) enable((*inhigh*) en3) clocked_by (clock);
    method DO       dataout() clocked_by(clock);
    method EMPTY    empty() clocked_by(clock);
    schedule (reset, di, rden, wren, dataout, empty) CF (reset, di, rden, wren, dataout, empty);
endmodule: mkFIFO18

typedef enum { DIdle, DValid} DState deriving (Bits,Eq);
typedef enum { QIdle, QTrain, QOn, QOff} QState deriving (Bits,Eq);
typedef enum { AIdle, ADelay, AWDelay, AEdge, ACEdge, AWait, ACompare, AValid,
     A1Changed, A1Stable, ASecond, AFound, AResetman, AStart, AAlign, ADone } AState deriving (Bits,Eq);

module mkIserdesDatadeser#(Clock serdes_clock, Reset serdes_reset, Clock serdest, Bit#(1) align_start,
    Bit#(1) autoalign, Bit#(10) training, Bit#(10) manual_tap, Bit#(1) rden, TrainRotate trainrot)(IserdesDatadeser);

    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    FIFO18 dfifo <- mkFIFO18(serdes_clock);
    IdelayE2 delaye2 <- mkIDELAYE2(IDELAYE2_Config {
        cinvctrl_sel: "FALSE", delay_src: "IDATAIN",
        high_performance_mode: "TRUE",
        idelay_type: "VARIABLE", idelay_value: 0,
        pipe_sel: "FALSE", refclk_frequency: 200, signal_pattern: "DATA"},
        defaultClock, clocked_by serdes_clock);
    ClockDividerIfc serdest_inverted <- mkClockInverter(clocked_by serdest);
    IserdesE2 master_data <- mkISERDESE2( ISERDESE2_Config{
        data_rate: "DDR", data_width: 10,
        dyn_clk_inv_en: "FALSE", dyn_clkdiv_inv_en: "FALSE",
        interface_type: "NETWORKING", num_ce: 2, ofb_used: "FALSE",
        init_q1: 0, init_q2: 0, init_q3: 0, init_q4: 0,
        srval_q1: 0, srval_q2: 0, srval_q3: 0, srval_q4: 0,
        serdes_mode: "MASTER", iobdelay: "IFD"},
        serdest, serdest_inverted.slowClock, clocked_by serdes_clock);
    IserdesE2 slave_data <- mkISERDESE2( ISERDESE2_Config{
        data_rate: "DDR", data_width: 10,
        dyn_clk_inv_en: "FALSE", dyn_clkdiv_inv_en: "FALSE",
        interface_type: "NETWORKING", num_ce: 2, ofb_used: "FALSE",
        init_q1: 0, init_q2: 0, init_q3: 0, init_q4: 0,
        srval_q1: 0, srval_q2: 0, srval_q3: 0, srval_q4: 0,
        serdes_mode: "SLAVE", iobdelay: "NONE"},
        serdest, serdest_inverted.slowClock, clocked_by serdes_clock);
    Wire#(Bit#(1)) bvi_delay_wren_wire <- mkDWire(0, clocked_by serdes_clock, reset_by serdes_reset);
    Wire#(Bit#(1)) bvi_reset_reg <- mkDWire(0, clocked_by serdes_clock, reset_by serdes_reset);
    SyncBitIfc#(Bit#(1)) bvi_resets_reg <- mkSyncBit(serdes_clock, serdes_reset, defaultClock);
    Wire#(Bit#(1)) bvi_fifo_wren_wire <- mkDWire(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(3)) dcounter <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(DState)  dstate <- mkReg(DIdle, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) fifo_reset <- mkReg(1, clocked_by serdes_clock, reset_by serdes_reset);
    SyncBitIfc#(Bit#(1)) dfifo_reset_r <- mkSyncBit(defaultClock, defaultReset, serdes_clock);
    Reg#(Bit#(1)) dfifo_wren_r <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) sync_bitslip <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(3)) sync_reset_inc_ce <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(3)) ctrl_sample <- mkReg(0);
    SyncBitIfc#(Bit#(1)) samplein_reset_null <- mkSyncBit(defaultClock, defaultReset, serdes_clock);

    SyncBitIfc#(Bit#(1)) fifo_wren_sync <- mkSyncBit(serdes_clock, serdes_reset, defaultClock);
    Vector#(10, SyncBitIfc#(Bit#(1))) iserdes_data <-  replicateM(mkSyncBit(serdes_clock, serdes_reset, defaultClock));
    SyncFIFOIfc#(Bit#(1)) serdes_end <- mkSyncFIFO(2, serdes_clock, serdes_reset, defaultClock);

    Reg#(Bit#(10)) ctrl_data <- mkSyncReg(0, serdes_clock, serdes_reset, defaultClock);
    Reg#(Bit#(10)) ctrl_data_temp <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(10)) data_init <- mkReg(0);
    Reg#(Bit#(10)) edge_init <- mkReg(0);
    Reg#(Bit#(10)) edge_int <- mkReg(0);
    Reg#(Bit#(1)) edge_intor_reg <- mkReg(0);
    SyncFIFOIfc#(Bit#(1)) serdes_setting <- mkSyncFIFO(2, defaultClock, defaultReset, serdes_clock);
    Reg#(Bit#(1)) this_aligned_reg <- mkReg(0);
    Wire#(Bit#(1)) this_align_busy_wire <- mkDWire(0);
    Reg#(Bit#(16)) serdes_counter <- mkReg(0);
    Reg#(QState)  qstate <- mkReg(QIdle);
    Reg#(AState)  astate <- mkReg(AIdle);
    Reg#(Bit#(11)) maxcount <- mkReg(0);
    Reg#(Bit#(10)) windowcount <- mkReg(0);
    Reg#(Bit#(3)) ctrl_samplein_i <- mkReg(0);
    Reg#(Bit#(16)) retrycounter <- mkReg(0);
    Reg#(Bit#(16)) gencounter <- mkReg(0);
    FIFO#(Bit#(1)) start_alignment_fsm <- mkFIFO();
    Reg#(Bit#(3)) ctrl_reset_inc_ce <- mkReg(0);
    Vector#(3, SyncBitIfc#(Bit#(1))) serdes_reset_inc_ce <- replicateM(mkSyncBit(defaultClock, defaultReset, serdes_clock));
    SyncBitIfc#(Bit#(1)) serdes_bitslip <- mkSyncBit(defaultClock, defaultReset, serdes_clock);

    //*************************** top align FSM *****************
    rule qfsmreset_rule if (bvi_resets_reg.read() == 0);
        this_aligned_reg <= 0;
        qstate <= QIdle;
        serdes_counter <= 0;
        ctrl_sample <= 0;
        start_alignment_fsm.clear();
    endrule

    rule qfsmidle_rule if (bvi_resets_reg.read() != 0 && qstate == QIdle
             && align_start == 1);
        serdes_counter <= 0;
        qstate <= QTrain;
    endrule
    rule qfsmqtrain_rule if (bvi_resets_reg.read() != 0 && qstate == QTrain);
        start_alignment_fsm.enq(1);
        qstate <= QOn;
    endrule
    rule qfsmqon_rule if (bvi_resets_reg.read() != 0 && qstate == QOn);
        qstate <= QOff;
    endrule
    rule qfsmqoff1_rule if (bvi_resets_reg.read() != 0 && qstate == QOff && serdes_counter <= 'h7fff);
        ctrl_sample <= ctrl_samplein_i;
        this_aligned_reg <= 1;
        qstate <= QIdle;
    endrule
    rule qfsmqoff2_rule if (bvi_resets_reg.read() != 0 && qstate == QOff && serdes_counter > 'h7fff);
        serdes_counter <= serdes_counter + 1;
        qstate <= QTrain;
    endrule

    rule qfsmall;
        let abusy = pack(qstate != QIdle);
        dfifo_reset_r.send(abusy);
        this_align_busy_wire <= abusy;
        samplein_reset_null.send(ctrl_sample[2]);
    endrule

    //*************************** alignment operation FSM *****************
    rule afsminit_rule if (bvi_resets_reg.read() == 0);
        ctrl_reset_inc_ce <= 3'b100;
        serdes_bitslip.send(0);
        ctrl_samplein_i <= 3'b000;
        edge_init <= 0;
        data_init <= 0;
        maxcount <= -1;
        windowcount <= 0;
        retrycounter <= -1;
        gencounter <= -1;
        astate <= AIdle;
    endrule

    rule afsmidle2_rule if (bvi_resets_reg.read() != 0 && astate == AIdle);
        start_alignment_fsm.deq();
        windowcount <= 0;
        retrycounter <= 32765;
        serdes_setting.enq(1);
        ctrl_reset_inc_ce <= 3'b100;
        maxcount <= 31;
        ctrl_samplein_i <= 3'b000;
        let as = ADelay;
        if (autoalign != 1)
            begin
            gencounter <= {6'b000000, manual_tap};
            as = AResetman;
            end
        astate <= as;
    endrule
    rule afsmdelay_rule if (bvi_resets_reg.read() != 0 && astate == ADelay);
        serdes_end.deq();
        gencounter <= 15;
        astate <= AWDelay;
    endrule
    rule afsmwdelay_rule if (bvi_resets_reg.read() != 0 && astate == AWDelay);
        serdes_setting.enq(1);
        ctrl_reset_inc_ce <= 3'b000;
        astate <= AEdge;
    endrule
    rule afsmedge_rule if (bvi_resets_reg.read() != 0 && astate == AEdge);
        serdes_end.deq();
        astate <= ACEdge;
    endrule
    rule afsmcedge_rule if (bvi_resets_reg.read() != 0 && astate == ACEdge);
        let as = AIdle;
        if (retrycounter >= 'h8000)
            begin
            let mc = maxcount;
            let cric = 3'b011;
            retrycounter <= retrycounter - 1;
            serdes_setting.enq(1);
            if (edge_intor_reg == 1)
                begin
                data_init <= ctrl_data;
                edge_init <= edge_int;
                cric = 3'b000;
                as = AWait;
                end
            else if (maxcount[10] == 1)
                begin
                cric = 3'b100;
                mc = 31;
                as = ADelay;
                end
            else
                begin
                mc = mc - 1;
                as = AEdge;
                end
            ctrl_reset_inc_ce <= cric;
            maxcount <= mc;
            end
        astate <= as;
    endrule
    rule afsmwait_rule if (bvi_resets_reg.read() != 0 && astate == AWait);
        serdes_end.deq();
        let as = astate;
        let gc = gencounter;
        if (gencounter >= 'h8000)
            begin
            gc = 9;
            as = ACompare;
            end
        else
            begin
            let cric = 3'b000;
            serdes_setting.enq(1);
            if (edge_init != edge_int)
                begin
                let mc = maxcount;
                retrycounter <= retrycounter - 1;
                if (maxcount[10] == 1)
                    begin
                    cric = 3'b100;
                    mc = 31;
                    as = ADelay;
                    end
                else
                    begin
                    cric = 3'b011;
                    mc = mc - 1;
                    gc = 14;
                    as = AEdge;
                    end
                maxcount <= mc;
                end
            else
                begin
                gc = gc - 1;
                end
            ctrl_reset_inc_ce <= cric;
            end
        astate <= as;
        gencounter <= gc;
    endrule
    rule afsmcompare_rule if (bvi_resets_reg.read() != 0 && astate == ACompare);
        let as = astate;
        let gc = gencounter;
        if (gencounter >= 'h8000)
            begin
            let mc = maxcount;
            let cric;
            serdes_setting.enq(1);
            if (maxcount[10] == 1)
                begin
                cric = 3'b100;
                mc = 31;
                as = ADelay;
                end
            else
                begin
                retrycounter <= retrycounter - 1;
                cric = 3'b011;
                mc = mc - 1;
                gc = 14;
                as = AEdge;
                end
            maxcount <= mc;
            ctrl_reset_inc_ce <= cric;
            end
        else
            begin
            if (ctrl_data == trainrot[gencounter])
                begin
                let csami = 3'b001;
                if (gencounter == 9)
                    csami = 3'b010;
                else if (gencounter == 8)
                    csami = 3'b100;
                ctrl_samplein_i <= csami;
                as = AValid;
                end
            gc = gc - 1;
            end
        astate <= as;
        gencounter <= gc;
    endrule
    rule afsmvalid_rule if (bvi_resets_reg.read() != 0 && astate == AValid);
        serdes_setting.enq(1);
        ctrl_reset_inc_ce <= 3'b011;
        maxcount <= maxcount - 1;
        astate <= A1Changed;
    endrule
    rule afsm1changed_rule if (bvi_resets_reg.read() != 0 && astate == A1Changed);
        serdes_end.deq();
        let as = astate;
        let cric = 3'b000;
        serdes_setting.enq(1);
        if (ctrl_data == rotateBitsBy(data_init, 10-1))
            begin
            gencounter <= 15;
            as = A1Stable;
            end
        else
            begin
            let mc = maxcount;
            if (maxcount[10] == 1)
                begin
                cric = 3'b100;
                mc = 31;
                as = ADelay;
                end
            else
                begin
                cric = 3'b011;
                mc = mc - 1;
                end
            maxcount <= mc;
            end
        astate <= as;
        ctrl_reset_inc_ce <= cric;
    endrule
    rule afsm1stable_rule if (bvi_resets_reg.read() != 0 && astate == A1Stable);
        serdes_end.deq();
        let as = astate;
        let mc = maxcount;
        let cric = 3'b011;
        serdes_setting.enq(1);
        if (gencounter >= 'h8000)
            begin
            windowcount <= windowcount + 1;
            mc = mc - 1;
            as = ASecond;
            end
        else
            begin
            let gc = gencounter - 1;
            if (ctrl_data == rotateBitsBy(data_init, 10-1))
                cric = 3'b000;
            else
                begin
                cric = 3'b011;
                mc = mc - 1;
                gc = 15;
                as = A1Changed;
                end
            gencounter <= gc;
            end
        astate <= as;
        maxcount <= mc;
        ctrl_reset_inc_ce <= cric;
    endrule
    rule afsmsecond_rule if (bvi_resets_reg.read() != 0 && astate == ASecond);
        serdes_end.deq();
        let as = astate;
        let cric = 3'b001;
        serdes_setting.enq(1);
        if (ctrl_data == rotateBitsBy(data_init, 10-2))
            begin
            gencounter <= {7'b0, windowcount[9:1]} - 16'b10;
            as = AFound;
            end
        else
            begin
            if (maxcount[10] == 1)
                begin
                cric = 3'b100;
                as = ADelay;
                end
            else
                begin
                windowcount <= windowcount + 1;
                cric = 3'b011;
                maxcount <= maxcount - 1;
                end
            end
        astate <= as;
        ctrl_reset_inc_ce <= cric;
    endrule
    rule afsmfound_rule if (bvi_resets_reg.read() != 0 && astate == AFound);
        serdes_end.deq();
        if (gencounter >= 'h8000)
            astate <= AStart;
        else
            begin
            serdes_setting.enq(1);
            ctrl_reset_inc_ce <= 3'b001;
            gencounter <= gencounter - 1;
            end
    endrule
    rule afsmresetman_rule if (bvi_resets_reg.read() != 0 && astate == AResetman);
        serdes_end.deq();
        if (gencounter >= 'h8000)
            astate <= AStart;
        else
            begin
            serdes_setting.enq(1);
            ctrl_reset_inc_ce <= 3'b011;
            gencounter <= gencounter - 1;
            end
    endrule
    rule afsmstart_rule if (bvi_resets_reg.read() != 0 && astate == AStart);
        let as = ADone;
        if (ctrl_data != training)
            begin
            serdes_setting.enq(1);
            ctrl_reset_inc_ce <= 3'b000;
            gencounter <= 8;
            serdes_bitslip.send(1);
            as = AAlign;
            end
        astate <= as;
    endrule
    rule afsmalign_rule if (bvi_resets_reg.read() != 0 && astate == AAlign);
        serdes_end.deq();
        let as = astate;
        if (ctrl_data == training)
            as = ADone;
        else
            begin
            if (gencounter >= 'h8000)
                as = AIdle;
            else
                begin
                serdes_setting.enq(1);
                serdes_bitslip.send(1);
                gencounter <= gencounter - 1;
                end
            end
        astate <= as;
    endrule
    rule afsmdone_rule if (bvi_resets_reg.read() != 0 && astate == ADone);
        ctrl_reset_inc_ce <= 3'b000;
        serdes_bitslip.send(0);
        astate <= AIdle;
    endrule

    //*************************** serdes setting FSM *****************
    rule clkdividle_rule if (bvi_reset_reg != 0 && dstate == DIdle);
        serdes_setting.deq();
        Bit#(3) sric = 0;
        for (Integer i = 0; i < 3; i = i + 1)
            sric[i] = serdes_reset_inc_ce[i].read();
        sync_reset_inc_ce <= sric;
        sync_bitslip <= serdes_bitslip.read();
        dstate <= DValid;
        dcounter <= 3;
    endrule

    rule clkdivvalid_rule if (bvi_reset_reg != 0 && dstate == DValid);
        dcounter <= dcounter - 1;
        if (dcounter[2] == 1)
            begin
            ctrl_data <= ctrl_data_temp;
            serdes_end.enq(1);
            dstate <= DIdle;
            end
        sync_reset_inc_ce <= {sync_reset_inc_ce[2], 2'b0};
        sync_bitslip <= 0;
    endrule

    rule controlserdes_rule;
        for (Integer i = 0; i < 3; i = i + 1)
            serdes_reset_inc_ce[i].send(ctrl_reset_inc_ce[i]);
    endrule

    rule reset_clock_rule;
        bvi_resets_reg.send(bvi_reset_reg);
    endrule

    rule wrensyncr_rule if (bvi_reset_reg == 0);
        dfifo_wren_r <= 0;
        fifo_wren_sync.send(0);
        sync_bitslip <= 0;
        sync_reset_inc_ce <= 0;
        dstate <= DIdle;
    endrule
    rule wrensync_rule if (bvi_reset_reg != 0);
        fifo_wren_sync.send(bvi_fifo_wren_wire);
        fifo_reset <= dfifo_reset_r.read();
    endrule

    rule setrule;
        dfifo.reset(sync_reset_inc_ce[2]);
        delaye2.reset(sync_reset_inc_ce[2]);
        delaye2.cinvctrl(0);
        delaye2.cntvaluein(0);
        delaye2.ld(0);
        delaye2.ldpipeen(0);
        delaye2.datain(0);
        delaye2.inc(sync_reset_inc_ce[1] == 1);
        delaye2.ce(sync_reset_inc_ce[0]);
        master_data.d(0);
        master_data.bitslip(sync_bitslip);
        master_data.ce1(1);
        master_data.ce2(1);
        master_data.ddly(delaye2.dataout());
        master_data.ofb(0);
        master_data.dynclkdivsel(0);
        master_data.dynclksel(0);
        master_data.shiftin1(0);
        master_data.shiftin2(0);
        master_data.oclk(0);
        master_data.oclkb(0);
        master_data.reset(sync_reset_inc_ce[2]);
        slave_data.d(0);
        slave_data.bitslip(sync_bitslip);
        slave_data.ce1(1);
        slave_data.ce2(1);
        slave_data.ddly(0);
        slave_data.ofb(0);
        slave_data.dynclkdivsel(0);
        slave_data.dynclksel(0);
        slave_data.shiftin1(master_data.shiftout1());
        slave_data.shiftin2(master_data.shiftout2());
        slave_data.oclk(0);
        slave_data.oclkb(0);
        slave_data.reset(sync_reset_inc_ce[2]);
    endrule

    rule serdesda2_rule;
        let dout = {slave_data.q4(), slave_data.q3(), master_data.q8(),
           master_data.q7(), master_data.q6(), master_data.q5(),
           master_data.q4(), master_data.q3(), master_data.q2(), master_data.q1()};
        ctrl_data_temp <= dout;
        for (Integer i = 0; i < 10; i = i + 1)
            iserdes_data[i].send(dout[i]);
    endrule

    rule datain_rule;
        Bit#(10) dout = 0;
        Bit#(10) edgeo = 0;
        for (Integer i = 0; i < 10; i = i + 1)
            dout[i] = iserdes_data[i].read();
        for (Integer i = 0; i < 9; i = i + 1)
            edgeo[i] = dout[i] ^ dout[i+1];
        edgeo[9] = dout[0] ^ dout[9];
        edge_int <= edgeo;
        edge_intor_reg <= pack(edgeo != 0);
        if (fifo_wren_sync.read() == 1)
            begin
            dfifo.di({6'b0,dout});
            dfifo.wren(1);
            end
        else
            begin
            dfifo.di(16'b0);
            dfifo.wren(0);
            end
    endrule

    rule serdesrule;
        dfifo.rden(rden);
    endrule

    method Action ibufdso(Bit#(1) v);
        delaye2.idatain(v);
    endmethod
    method Bit#(1)                align_busy();
        return this_align_busy_wire;
    endmethod
    method Bit#(1)                aligned();
        return this_aligned_reg;
    endmethod
    method Bit#(3)                samplein();
        return ctrl_sample;
    endmethod
    method Action                 delay_wren(Bit#(1) v);
        bvi_delay_wren_wire <= v;
    endmethod
    method Action                 fifo_wren(Bit#(1) v);
        bvi_fifo_wren_wire <= v;
    endmethod
    method Action                 reset(Bit#(1) v);
        bvi_reset_reg <= v;
    endmethod
    method Bit#(1)                empty();
        return dfifo.empty();
    endmethod
    method Bit#(10)               dataout();
        return dfifo.dataout()[9:0];
    endmethod
endmodule: mkIserdesDatadeser

(* always_enabled *)
interface ImageonSerdesPins;
    method Action io_vita_sync_p(Bit#(1) v);
    method Action io_vita_sync_n(Bit#(1) v);
    method Action io_vita_data_p(Bit#(4) v);
    method Action io_vita_data_n(Bit#(4) v);
    method Action io_vita_clk_p(Bit#(1) v);
    method Action io_vita_clk_n(Bit#(1) v);
endinterface

interface ImageonSerdesControl;
    method Action set_decoder_control(Bit#(32) v);
    method Action set_iserdes_control(Bit#(32) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Bit#(32) get_iserdes_control();
endinterface

interface SerdesData;
    method Wire#(Bit#(1)) reset();
    method Bit#(1) raw_empty();
    method Bit#(50) raw_data();
endinterface

interface ISerdes;
    interface ImageonSerdesControl control;
    interface ImageonSerdesPins pins;
    interface SerdesData data;
endinterface

module mkISerdes#(Clock axi_clock, Reset axi_reset)(ISerdes);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    Wire#(Bit#(1)) vita_clk_p <- mkDWire(0);
    Wire#(Bit#(1)) vita_clk_n <- mkDWire(0);
    Clock ibufds_clk <- mkClockIBUFDS(vita_clk_p, vita_clk_n);
    ClockGenIfc serdes_clk <- mkBUFR5(ibufds_clk);
    Clock serdes_clock = serdes_clk.gen_clk;
    Reset serdes_reset <- mkAsyncReset(2, defaultReset, serdes_clock);

    Vector#(5, Wire#(Bit#(1))) vita_data_p <- replicateM(mkDWire(0));
    Vector#(5, Wire#(Bit#(1))) vita_data_n <- replicateM(mkDWire(0));
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
    Wire#(Bit#(1)) bittest_wire <- mkDWire(0);
    Reg#(Bit#(1)) delay_wren_r_reg <-mkReg(0);
    Reg#(Bit#(1)) delay_wren_r2_reg <- mkSyncReg(0, defaultClock, defaultReset, serdes_clock);
    Reg#(Bit#(1)) delay_wren_c_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) fifo_wren_r2_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) fifo_wren_c_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);

    ClockGenIfc serdest_clk <- mkBUFIO(ibufds_clk);
    Reg#(Bit#(1)) serdes_align_busy_temp <- mkReg(0);
    Reg#(Bit#(1)) serdes_align_busy_reg <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(1)) serdes_aligned_temp <- mkReg(0);
    Reg#(Bit#(1)) serdes_aligned_reg <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Wire#(Bit#(1)) new_raw_empty_wire <- mkDWire(0);
    TrainRotate trainrot <- replicateM(mkReg(0));
    Vector#(5, IserdesDatadeser) serdes_v <- replicateM(mkIserdesDatadeser(serdes_clock, serdes_reset, serdest_clk.gen_clk,
	  serdes_align_start_reg, serdes_auto_align_reg, serdes_training_reg,
	  serdes_manual_tap_reg, decoder_enable_reg, trainrot));

    rule trainrotgen_rule;
        for (UInt#(4) i = 0; i < 10; i = i + 1)
            trainrot[i] <= rotateBitsBy(serdes_training_reg, i+6);
    endrule

    rule serdes_copybits;
        serdes_aligned_reg <= serdes_aligned_temp;
        serdes_align_busy_reg <= serdes_align_busy_temp;
    endrule

    Vector#(5, ReadOnly#(Bit#(1))) ibufds_v;
    for (Integer i = 0; i < 5; i = i + 1)
        ibufds_v[i] <- mkIBUFDS(vita_data_p[i], vita_data_n[i]);
    rule sendup_ibufdso;
       for (Bit#(8) i = 0; i < 5; i = i+1)
	   serdes_v[i].ibufdso(ibufds_v[i]);
    endrule

    rule sendup_imageon_clock;
       Bit#(1) alignedw = 1;
       Bit#(1) alignbusyw = 0;
       Bit#(1) emptyw = 0;
       Bit#(3) samplein = 0;
       Bit#(50) rawdataw = 0;
       for (Bit#(8) i = 0; i < 5; i = i+1) begin
	  alignedw = alignedw & serdes_v[i].aligned();
	  alignbusyw = alignbusyw | serdes_v[i].align_busy();
	  emptyw = emptyw | serdes_v[i].empty();
          samplein = samplein | serdes_v[i].samplein();
	  rawdataw[(i+1)*10-1: i*10] = serdes_v[i].dataout();
       end
       serdes_align_busy_temp <= alignbusyw;
       serdes_aligned_temp <= alignedw;
       bittest_wire <= pack(samplein == 3'b110);
       empty_wire <= emptyw;
       raw_data_wire <= rawdataw;
    endrule

    rule sendup_sdes_clock;
    for (Bit#(8) i = 0; i < 5; i = i+1) begin
       serdes_v[i].reset(serdes_reset_null);
       serdes_v[i].delay_wren(delay_wren_c_reg);
       serdes_v[i].fifo_wren(serdes_fifo_enable_null);
    end
    endrule
    
    rule serdes_reset_rule if (serdes_reset_reg == 0);
        new_raw_empty_wire <= 0;
        delay_wren_r_reg <= 0;
        delay_wren_r2_reg <= 0;
    endrule

    rule serdes_resetc_rule if (serdes_reset_null == 0);
        delay_wren_c_reg <= 0;
        fifo_wren_r2_reg <= 0;
        fifo_wren_c_reg <= 0;
    endrule

    rule serdes_calc2 if (serdes_reset_reg == 1);
        new_raw_empty_wire <= empty_wire;
        delay_wren_r_reg <= bittest_wire;
        delay_wren_r2_reg <= delay_wren_r_reg;
    endrule

    rule serdes_calc2c if (serdes_reset_null == 1);
        delay_wren_c_reg <= delay_wren_r2_reg;
        fifo_wren_r2_reg <= serdes_fifo_enable_null;
        fifo_wren_c_reg <= fifo_wren_r2_reg;
    endrule

    interface ImageonSerdesControl control;
	method Action set_serdes_manual_tap(Bit#(10) v);
	    serdes_manual_tap_reg <= v;
	endmethod
	method Action set_serdes_training(Bit#(10) v);
	    serdes_training_reg <= v;
	endmethod
	method Action set_iserdes_control(Bit#(32) v);
	    serdes_reset_reg <= ~v[0];
	    serdes_auto_align_reg <= v[1];
	    serdes_align_start_reg <= v[2];
	    serdes_fifo_enable_reg <= v[3];
	endmethod
	method Bit#(32) get_iserdes_control();
	    let v = 0;
	    v[8] = 1;
	    v[9] = serdes_align_busy_reg;
	    v[10] = serdes_aligned_reg;
	    return v;
	endmethod
	method Action set_decoder_control(Bit#(32) v);
	    decoder_enable_reg <= v[1];
	endmethod
    endinterface

    interface ImageonSerdesPins pins;
        method Action io_vita_sync_p(Bit#(1) v);
            vita_data_p[0] <= v;
        endmethod
        method Action io_vita_sync_n(Bit#(1) v);
            vita_data_n[0] <= v;
        endmethod
        method Action io_vita_data_p(Bit#(4) v);
            for (Integer i = 0; i < 4; i = i + 1)
                vita_data_p[i+1] <= v[i];
        endmethod
        method Action io_vita_data_n(Bit#(4) v);
            for (Integer i = 0; i < 4; i = i + 1)
                vita_data_n[i+1] <= v[i];
        endmethod
        method Action io_vita_clk_p(Bit#(1) v);
            vita_clk_p <= v;
        endmethod
        method Action io_vita_clk_n(Bit#(1) v);
            vita_clk_n <= v;
        endmethod
    endinterface
    interface SerdesData data;
        method Wire#(Bit#(1)) reset();
            return serdes_reset_reg;
        endmethod
        method Bit#(1) raw_empty();
            return new_raw_empty_wire;
        endmethod
        method Bit#(50) raw_data();
            return raw_data_wire;
	endmethod
    endinterface
endmodule
