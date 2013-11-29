
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
import FIFOF::*;
import SyncBits::*;
import XilinxCells::*;
import XbsvXilinxCells::*;

typedef Vector#(10, Reg#(Bit#(10))) TrainRotate;

interface IserdesDatadeser;
    method Action           ibufdso(Bit#(1) v);
    method Bit#(1)          align_busy();
    method Bit#(3)          samplein();
    method Action           fifo_wren(Bit#(1) v);
    method Action           reset(Bit#(1) v);
    method Bit#(1)          empty();
    method Bit#(10)         dataout();
endinterface: IserdesDatadeser

typedef enum { QIdle, QTrain, QOff} QState deriving (Bits,Eq);
typedef enum { AIdle, AReset, AEdge, AWait, AShift,
     ARotated, AFirst, ASecond, AFound, AAlign} AState deriving (Bits,Eq);

module mkIserdesDatadeser#(Clock serdes_clock, Reset serdes_reset, Clock serdest, Bit#(1) align_start,
    Bit#(1) autoalign, Bit#(10) training, Bit#(10) manual_tap, TrainRotate trainrot)(IserdesDatadeser);

    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    FIFOF#(Bit#(10)) dfifo <- mkFIFOF(clocked_by serdes_clock, reset_by serdes_reset);
    SyncBitIfc#(Bit#(10)) dfifo_data <-  mkSyncBits(0, serdes_clock, serdes_reset, defaultClock, defaultReset);
    SyncBitIfc#(Bit#(1)) dfifo_empty <-  mkSyncBit(serdes_clock, serdes_reset, defaultClock);
    IdelayE2 delaye2 <- mkIDELAYE2(IDELAYE2_Config {
        cinvctrl_sel: "FALSE", delay_src: "IDATAIN",
        high_performance_mode: "TRUE",
        idelay_type: "VARIABLE", idelay_value: 0,
        pipe_sel: "FALSE", refclk_frequency: 200, signal_pattern: "DATA"},
        defaultClock, clocked_by serdes_clock);
    ClockDividerIfc serdest_inverted <- mkClockInverter(clocked_by serdest);
    Vector#(2, IserdesE2) iserdes_v;
    iserdes_v[0] <- mkISERDESE2( ISERDESE2_Config{
        data_rate: "DDR", data_width: 10,
        dyn_clk_inv_en: "FALSE", dyn_clkdiv_inv_en: "FALSE",
        interface_type: "NETWORKING", num_ce: 2, ofb_used: "FALSE",
        init_q1: 0, init_q2: 0, init_q3: 0, init_q4: 0,
        srval_q1: 0, srval_q2: 0, srval_q3: 0, srval_q4: 0,
        serdes_mode: "MASTER", iobdelay: "IFD"},
        serdest, serdest_inverted.slowClock, clocked_by serdes_clock);
    iserdes_v[1] <- mkISERDESE2( ISERDESE2_Config{
        data_rate: "DDR", data_width: 10,
        dyn_clk_inv_en: "FALSE", dyn_clkdiv_inv_en: "FALSE",
        interface_type: "NETWORKING", num_ce: 2, ofb_used: "FALSE",
        init_q1: 0, init_q2: 0, init_q3: 0, init_q4: 0,
        srval_q1: 0, srval_q2: 0, srval_q3: 0, srval_q4: 0,
        serdes_mode: "SLAVE", iobdelay: "NONE"},
        serdest, serdest_inverted.slowClock, clocked_by serdes_clock);
    Wire#(Bit#(1)) bvi_reset_reg <- mkDWire(0, clocked_by serdes_clock, reset_by serdes_reset);
    SyncBitIfc#(Bit#(1)) bvi_resets_reg <- mkSyncBit(serdes_clock, serdes_reset, defaultClock);
    Reg#(Bit#(3)) ctrl_sample <- mkReg(0);
    Reg#(Bit#(1)) fifo_reset <- mkReg(1, clocked_by serdes_clock, reset_by serdes_reset);
    SyncBitIfc#(Bit#(1)) fifo_reset_sync <- mkSyncBit(defaultClock, defaultReset, serdes_clock);
    SyncBitIfc#(Bit#(1)) fifo_wren_sync <- mkSyncBit(serdes_clock, serdes_reset, serdes_clock);

    Reg#(QState)  qstate <- mkReg(QIdle);

    Reg#(AState)  astate <- mkReg(AIdle);
    SyncBitIfc#(Bit#(1)) astate_reset <- mkSyncBit(defaultClock, defaultReset, serdes_clock);
    SyncBitIfc#(Bit#(1)) astate_bitslip <- mkSyncBit(defaultClock, defaultReset, serdes_clock);
    SyncBitIfc#(Bit#(1)) astate_found <- mkSyncBit(defaultClock, defaultReset, serdes_clock);
    Reg#(Bit#(10)) data_init1 <- mkReg(0);
    Reg#(Bit#(10)) data_init2 <- mkReg(0);
    Reg#(Bit#(10)) edge_init <- mkReg(0);
    Reg#(Bit#(10)) edge_int <- mkSyncReg(0, serdes_clock, serdes_reset, defaultClock);
    Reg#(Bit#(11)) maxcount <- mkReg(0);
    Reg#(Bit#(10)) windowcount <- mkReg(0);
    Reg#(Bit#(16)) retrycounter <- mkReg(0);
    Reg#(Bit#(16)) gencounter <- mkReg(0);

    SyncFIFOIfc#(Bit#(1)) serdes_start <- mkSyncFIFO(2, defaultClock, defaultReset, serdes_clock);
    SyncFIFOIfc#(Bit#(1)) serdes_end <- mkSyncFIFO(2, serdes_clock, serdes_reset, defaultClock);
    Reg#(Bit#(1)) serdes_running <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(10)) serdes_data <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) sync_bitslip <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) sync_increment <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) sync_ce <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(3)) sync_counter <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(10)) ctrl_data <- mkSyncReg(0, serdes_clock, serdes_reset, defaultClock);

    //*************************** alignment operation FSM *****************
    rule afsminit_rule if (bvi_resets_reg.read() == 0);
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

    rule afsmidle2_rule if (bvi_resets_reg.read() != 0 && astate == AIdle && align_start == 1);
        windowcount <= 0;
        retrycounter <= 'h7ffd;
        ctrl_sample <= 0;
        astate <= AReset;
        serdes_start.enq(0);
    endrule
    rule afsmdelay_rule if (bvi_resets_reg.read() != 0 && astate == AReset);
        serdes_end.deq();
        let as = AEdge;
        let gc = 15;
        if (autoalign == 0)
            begin
            gc = {6'b0, manual_tap};
            as = AFound;
            end
        maxcount <= 31;
        gencounter <= gc;
        astate <= as;
        serdes_start.enq(0);
    endrule
    rule afsmcedge1_rule if (bvi_resets_reg.read() != 0 && astate == AEdge
            && retrycounter < 'h8000);
        serdes_end.deq();
        astate <= AIdle;
    endrule
    rule afsmcedge2_rule if (bvi_resets_reg.read() != 0 && astate == AEdge
            && retrycounter >= 'h8000);
        serdes_end.deq();
        let mc = maxcount;
        let inctemp = 0;
        let as = AEdge;
        if (edge_int != 0)
            begin
            data_init1 <= rotateBitsBy(ctrl_data, 10-1);
            data_init2 <= rotateBitsBy(ctrl_data, 10-2);
            edge_init <= edge_int;
            as = AWait;
            end
        else if (maxcount[10] == 1)
            as = AReset;
        else
            begin
            maxcount <= maxcount - 1;
            inctemp = 1;
            end
        retrycounter <= retrycounter - 1;
        astate <= as;
        serdes_start.enq(inctemp);
    endrule
    rule afsmwait_rule if (bvi_resets_reg.read() != 0 && astate == AWait);
        serdes_end.deq();
        let as = astate;
        let gc = gencounter - 1;
        if (gencounter >= 'h8000)
            begin
            gc = 9;
            as = AShift;
            end
        else
            begin
            let inctemp = 0;
            if (edge_init != edge_int)
                begin
                if (maxcount[10] == 1)
                    as = AReset;
                else
                    begin
                    gc = 14;
                    inctemp = 1;
                    as = AEdge;
                    end
                retrycounter <= retrycounter - 1;
                maxcount <= maxcount - 1;
                end
            serdes_start.enq(inctemp);
            end
        astate <= as;
        gencounter <= gc;
    endrule
    rule afsmcompare_rule if (bvi_resets_reg.read() != 0 && astate == AShift);
        let as = astate;
        let gc = gencounter - 1;
        if (gencounter >= 'h8000)
            begin
            let inctemp = 0;
            if (maxcount[10] == 1)
                as = AReset;
            else
                begin
                retrycounter <= retrycounter - 1;
                gc = 14;
                inctemp = 1;
                as = AEdge;
                end
            serdes_start.enq(inctemp);
            end
        else if (ctrl_data == trainrot[gencounter])
            begin
            let csamplein = 3'b001;
            if (gencounter == 9)
                csamplein = 3'b010;
            else if (gencounter == 8)
                csamplein = 3'b100;
            ctrl_sample <= csamplein;
            as = ARotated;
            serdes_start.enq(1);
            end
        astate <= as;
        gencounter <= gc;
        maxcount <= maxcount - 1;
    endrule
    rule afsm1changed_rule if (bvi_resets_reg.read() != 0 && astate == ARotated);
        serdes_end.deq();
        let as = astate;
        let inctemp = 0;
        if (ctrl_data == data_init1)
            begin
            gencounter <= 15;
            as = AFirst;
            end
        else if (maxcount[10] == 1)
            as = AReset;
        else
            begin
            inctemp = 1;
            maxcount <= maxcount - 1;
            end
        astate <= as;
        serdes_start.enq(inctemp);
    endrule
    rule afsm1stable_rule if (bvi_resets_reg.read() != 0 && astate == AFirst);
        serdes_end.deq();
        let as = astate;
        let mc = maxcount;
        let inctemp = 1;
        if (gencounter >= 'h8000)
            begin
            windowcount <= windowcount + 1;
            mc = mc - 1;
            as = ASecond;
            end
        else
            begin
            let gc = gencounter - 1;
            if (ctrl_data == data_init1)
                inctemp = 0;
            else
                begin
                mc = mc - 1;
                gc = 15;
                as = ARotated;
                end
            gencounter <= gc;
            end
        maxcount <= mc;
        astate <= as;
        serdes_start.enq(inctemp);
    endrule
    rule afsmsecond_rule if (bvi_resets_reg.read() != 0 && astate == ASecond);
        serdes_end.deq();
        let as = astate;
        let inctemp = 0;
        if (ctrl_data == data_init2)
            begin
            gencounter <= {7'b0, windowcount[9:1]} - 16'b10;
            as = AFound;
            end
        else if (maxcount[10] == 1)
            as = AReset;
        else
            begin
            windowcount <= windowcount + 1;
            inctemp = 1;
            maxcount <= maxcount - 1;
            end
        astate <= as;
        serdes_start.enq(inctemp);
    endrule
    rule afsmfound_rule if (bvi_resets_reg.read() != 0 && astate == AFound);
        serdes_end.deq();
        let gc = gencounter;
        if (gencounter >= 'h8000)
            begin
            let as = AIdle;
            if (ctrl_data != training)
                begin
                gc = 8;
                as = AAlign;
                serdes_start.enq(0);
                end
            astate <= as;
            end
        else
            begin
            gc = gc - 1;
            serdes_start.enq(autoalign);
            end
        gencounter <= gc;
    endrule
    rule afsmalign_rule if (bvi_resets_reg.read() != 0 && astate == AAlign);
        serdes_end.deq();
        if (ctrl_data == training || gencounter >= 'h8000)
            astate <= AIdle;
        else
            begin
            gencounter <= gencounter - 1;
            serdes_start.enq(0);
            end
    endrule

    rule qfsmall;
        fifo_reset_sync.send(pack(qstate != QIdle));
        astate_reset.send(pack(astate == AReset));
        astate_bitslip.send(pack(astate == AAlign));
        astate_found.send(pack(astate == AFound));
    endrule

    //*************************** serdes setting FSM *****************
    rule serdes_idle_rule if (bvi_reset_reg != 0 && serdes_running == 0);
        serdes_start.deq();
        sync_increment <= serdes_start.first;
        sync_ce <= serdes_start.first | astate_found.read();
        sync_bitslip <= astate_bitslip.read();
        serdes_running <= 1;
        sync_counter <= 3;
    endrule

    rule serdes_running1_rule if (bvi_reset_reg != 0 && serdes_running == 1
            && sync_counter[2] != 1);
        sync_counter <= sync_counter - 1;
        sync_increment <= 0;
        sync_ce <= 0;
        sync_bitslip <= 0;
    endrule
    rule serdes_running2_rule if (bvi_reset_reg != 0 && serdes_running == 1
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

    rule serdesreset_rule if (bvi_reset_reg == 0);
        sync_bitslip <= 0;
        sync_increment <= 0;
        sync_ce <= 0;
        serdes_running <= 0;
        dfifo.clear();
    endrule
    rule wrensync_rule if (bvi_reset_reg != 0);
        fifo_reset <= fifo_reset_sync.read();
    endrule

    rule clear_fifo if (astate_reset.read() == 1);
        dfifo.clear();
    endrule
    rule setrule;
        delaye2.reset(astate_reset.read());
        delaye2.cinvctrl(0);
        delaye2.cntvaluein(0);
        delaye2.ld(0);
        delaye2.ldpipeen(0);
        delaye2.datain(0);
        delaye2.inc(sync_increment == 1);
        delaye2.ce(sync_ce);
        for (Integer i = 0; i < 2; i = i + 1)
            begin
            iserdes_v[i].d(0);
            iserdes_v[i].bitslip(sync_bitslip);
            iserdes_v[i].ce1(1);
            iserdes_v[i].ce2(1);
            iserdes_v[i].ofb(0);
            iserdes_v[i].dynclkdivsel(0);
            iserdes_v[i].dynclksel(0);
            iserdes_v[i].oclk(0);
            iserdes_v[i].oclkb(0);
            iserdes_v[i].reset(astate_reset.read());
            end
        iserdes_v[0].ddly(delaye2.dataout());
        iserdes_v[0].shiftin1(0);
        iserdes_v[0].shiftin2(0);
        iserdes_v[1].ddly(0);
        iserdes_v[1].shiftin1(iserdes_v[0].shiftout1());
        iserdes_v[1].shiftin2(iserdes_v[0].shiftout2());
    endrule

    rule serdesda2_rule;
        let dout = {iserdes_v[1].q4(), iserdes_v[1].q3(), iserdes_v[0].q8(),
           iserdes_v[0].q7(), iserdes_v[0].q6(), iserdes_v[0].q5(),
           iserdes_v[0].q4(), iserdes_v[0].q3(), iserdes_v[0].q2(), iserdes_v[0].q1()};
        serdes_data <= dout;
        if (fifo_wren_sync.read() == 1)
            dfifo.enq(dout);
    endrule

    rule serdesrule;
        dfifo_data.send(dfifo.first);
        dfifo.deq();
    endrule
    rule fifoe_rule;
        dfifo_empty.send(pack(!dfifo.notEmpty()));
    endrule

    method Action ibufdso(Bit#(1) v);
        delaye2.idatain(v);
    endmethod
    method Bit#(1)                align_busy();
        return pack(astate != AIdle);
    endmethod
    method Bit#(3)                samplein();
        return ctrl_sample;
    endmethod
    method Action                 fifo_wren(Bit#(1) v);
        fifo_wren_sync.send(v);
    endmethod
    method Action                 reset(Bit#(1) v);
        bvi_reset_reg <= v;
    endmethod
    method Bit#(1)                empty();
        return dfifo_empty.read();
    endmethod
    method Bit#(10)               dataout();
        return dfifo_data.read();
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

interface ImageonSerdesRequest;
    method Action set_decoder_control(Bit#(32) v);
    method Action set_iserdes_control(Bit#(32) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Action get_iserdes_control();
endinterface
interface ImageonSerdesIndication;
    method Action iserdes_control_value(Bit#(32) v);
endinterface

interface SerdesData;
    method Wire#(Bit#(1)) reset();
    method Vector#(5, Bit#(10)) raw_data();
endinterface

interface ISerdes;
    interface ImageonSerdesRequest control;
    interface ImageonSerdesPins pins;
    interface SerdesData data;
endinterface

module mkISerdes#(Clock axi_clock, Reset axi_reset, ImageonSerdesIndication indication)(ISerdes);
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

    ClockGenIfc serdest_clk <- mkBUFIO(ibufds_clk);
    Reg#(Bit#(1)) serdes_align_busy_temp <- mkReg(0);
    Reg#(Bit#(1)) serdes_align_busy_reg <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(1)) new_raw_empty_reg <- mkReg(0);
    TrainRotate trainrot <- replicateM(mkReg(0));
    Vector#(5, IserdesDatadeser) pin_v <- replicateM(mkIserdesDatadeser(serdes_clock, serdes_reset, serdest_clk.gen_clk,
	  serdes_align_start_reg, serdes_auto_align_reg, serdes_training_reg,
	  serdes_manual_tap_reg, trainrot));

    rule trainrotgen_rule;
        for (UInt#(4) i = 0; i < 10; i = i + 1)
            trainrot[i] <= rotateBitsBy(serdes_training_reg, i+6);
    endrule

    rule serdes_copybits;
        serdes_align_busy_reg <= serdes_align_busy_temp;
    endrule

    Vector#(5, ReadOnly#(Bit#(1))) ibufds_v;
    for (Integer i = 0; i < 5; i = i + 1)
        ibufds_v[i] <- mkIBUFDS(vita_data_p[i], vita_data_n[i]);
    rule sendup_ibufdso;
       for (Bit#(8) i = 0; i < 5; i = i+1)
	   pin_v[i].ibufdso(ibufds_v[i]);
    endrule

    rule sendup_imageon_clock;
       Bit#(1) alignbusyw = 0;
       Bit#(1) emptyw = 0;
       Bit#(3) samplein = 0;
       Bit#(50) rawdataw = 0;
       for (Bit#(8) i = 0; i < 5; i = i+1) begin
	  alignbusyw = alignbusyw | pin_v[i].align_busy();
	  emptyw = emptyw | pin_v[i].empty();
          samplein = samplein | pin_v[i].samplein();
	  rawdataw[(i+1)*10-1: i*10] = pin_v[i].dataout();
       end
       serdes_align_busy_temp <= alignbusyw;
       //bittest_wire <= pack(samplein == 3'b110);
       empty_wire <= emptyw;
       raw_data_wire <= rawdataw;
    endrule

    rule sendup_sdes_clock;
    for (Bit#(8) i = 0; i < 5; i = i+1) begin
       pin_v[i].reset(serdes_reset_null);
       //pin_v[i].delay_wren(delay_wren_c_reg);
       pin_v[i].fifo_wren(serdes_fifo_enable_null);
    end
    endrule
    
    rule serdes_reset_rule if (serdes_reset_reg == 0);
        new_raw_empty_reg <= 0;
    endrule

    rule serdes_calc2 if (serdes_reset_reg == 1);
        new_raw_empty_reg <= empty_wire;
    endrule

    interface ImageonSerdesRequest control;
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
        method Action get_iserdes_control();
	    let v = 0;
	    v[9] = serdes_align_busy_reg;
            indication.iserdes_control_value(v);
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
        method Vector#(5, Bit#(10)) raw_data() if (new_raw_empty_reg == 0 && serdes_reset_reg != 0);
            Vector#(5, Bit#(10)) in = unpack(raw_data_wire);
            return in;
	endmethod
    endinterface
endmodule
