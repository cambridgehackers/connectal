
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
import IserdesDatadeser::*;
import XilinxCells::*;
import XbsvXilinxCells::*;
import GetPutWithClocks :: *;

(* always_enabled *)
interface ImageonVita;
    method Bit#(1) io_vita_clk_pll();
    method Bit#(1) io_vita_reset_n();
    method Vector#(3, ReadOnly#(Bit#(1))) io_vita_trigger();
    //method Bit#(2) io_vita_monitor();
    method Action io_vita_clk_p(Bit#(1) v);
    method Action io_vita_clk_n(Bit#(1) v);
    method Action io_vita_sync_p(Bit#(1) v);
    method Action io_vita_sync_n(Bit#(1) v);
    method Action io_vita_data_p(Bit#(4) v);
    method Action io_vita_data_n(Bit#(4) v);
    interface Clock imageon_clock_if;
    interface Reset imageon_reset_if;
endinterface

typedef struct {
    Bit#(1) fsync;
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) active_video;
    Bit#(10) video_data;
} XsviData deriving (Bits);

interface ImageonSensorControl;
    method Bit#(32) get_debugind();
    method Action raw_data(Bit#(50) v);
    method Action set_host_oe(Bit#(1) v);
    method Action set_decoder_control(Bit#(32) v);
    method Action set_decoder_code_ls(Bit#(10) v);
    method Action set_decoder_code_le(Bit#(10) v);
    method Action set_decoder_code_fs(Bit#(10) v);
    method Action set_iserdes_control(Bit#(32) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Action set_syncgen_delay(Bit#(16) v);
    method Action set_trigger_default_freq(Bit#(32) v);
    method Action set_trigger_cnt_trigger0high(Bit#(32) v);
    method Action set_trigger_cnt_trigger0low(Bit#(32) v);
    method Bit#(32) get_iserdes_control();
endinterface

interface ImageonXsviControl;
    method Action hactive(Bit#(16) v);
    method Action hfporch(Bit#(16) v);
    method Action hsync(Bit#(16) v);
    method Action hbporch(Bit#(16) v);
    method Action vactive(Bit#(16) v);
    method Action vfporch(Bit#(16) v);
    method Action vsync(Bit#(16) v);
    method Action vbporch(Bit#(16) v);
endinterface

interface ImageonVideo;
    interface Get#(XsviData) out;
    interface ImageonXsviControl control;
endinterface

interface ImageonSensor;
    interface ImageonSensorControl control;
    interface ImageonVita pins;
    method Bit#(1) get_framesync();
    method Bit#(40) get_data();
endinterface

interface ImageonTopPins;
    method Clock fbbozo();
    method Action fbbozoin(Bit#(1) v);
endinterface

typedef enum { TIdle, TSend, TWait} TState deriving (Bits,Eq);

module mkImageonSensor#(Clock axi_clock, Reset axi_reset)(ImageonSensor);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    Vector#(5, Wire#(Bit#(1))) vita_data_p <- replicateM(mkDWire(0));
    Vector#(5, Wire#(Bit#(1))) vita_data_n <- replicateM(mkDWire(0));
    Wire#(Bit#(1)) vita_clk_p <- mkDWire(0);
    Wire#(Bit#(1)) vita_clk_n <- mkDWire(0);
    Clock ibufds_clk <- mkClockIBUFDS(vita_clk_p, vita_clk_n);
    ClockGenIfc serdes_clk <- mkBUFR5(ibufds_clk);
    Clock serdes_clock = serdes_clk.gen_clk;
    ODDR#(Bit#(1)) pll_out <- mkXbsvODDR(ODDRParams{ddr_clk_edge:"SAME_EDGE", init:1, srtype:"ASYNC"});
    ODDR#(Bit#(1)) pll_t <- mkXbsvODDR(ODDRParams{ddr_clk_edge:"SAME_EDGE", init:1, srtype:"ASYNC"});
    Wire#(Bit#(1)) poutq <- mkDWire(0);
    Wire#(Bit#(1)) ptq <- mkDWire(0);
    ReadOnly#(Bit#(1)) vita_clk_pll <- mkOBUFT(poutq, ptq);
    Reset serdes_reset <- mkAsyncReset(2, defaultReset, serdes_clock);
    Reset serdest_reset <- mkAsyncReset(2, defaultReset, serdes_clock);
    Reg#(Bit#(1)) imageon_oe <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) decoder_code_ls_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) decoder_code_le_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) decoder_code_fs_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) decoder_enable_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_auto_align_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_align_start_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_fifo_enable_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    ReadOnly#(Bit#(1)) serdes_fifo_enable_null <- mkNullCrossingWire(serdes_clock, serdes_fifo_enable_reg);
    Reg#(Bit#(10)) serdes_manual_tap_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(10)) serdes_training_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(1)) serdes_reset_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    ReadOnly#(Bit#(1)) serdes_reset_null <- mkNullCrossingWire(serdes_clock, serdes_reset_reg);
    Reg#(Bit#(16)) syncgen_delay_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(32)) trigger_default_freq_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(32)) trigger_cnt_trigger0high_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(32)) trigger_cnt_trigger0low_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);

    Reg#(TState)   tstate <- mkReg(TIdle);
    Reg#(Bit#(1)) sframe_wire <- mkReg(0);
    Reg#(Bit#(1)) sframe_new_wire <- mkReg(0);
    Reg#(Bit#(1))  fs2 <- mkReg(0);
    Reg#(Bit#(16)) frame_delay <- mkReg(0);
    Reg#(Bit#(1))  frame_run <- mkReg(0);
    Reg#(Bit#(32)) tperiod <- mkReg(0);
    Reg#(Bit#(32)) tcounter <- mkReg(0);
    Reg#(Bit#(32)) diff <- mkReg(0);
    Reg#(Bit#(1))  framestart_delay_reg <- mkReg(0);
    Reg#(Bit#(32)) debugind_value <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(10)) sync_delay_reg <- mkReg(0);
    Wire#(Bit#(50)) raw_data_wire <- mkDWire(0);
    Reg#(Bit#(50)) raw_data_reg <- mkReg(0);
    Reg#(Bit#(40)) dataout_reg <- mkReg(0);
    Reg#(Bit#(50)) raw_data_delay_reg <- mkReg(0);
    Wire#(Bit#(1)) new_raw_empty_wire <- mkDWire(0);
    Reg#(Bit#(1)) raw_empty_reg <- mkReg(0);
    Reg#(Bit#(1)) remapkernel_reg <- mkReg(0);
    Reg#(Bit#(1)) imgdatavalid_reg <- mkReg(0);
    Reg#(Bit#(8)) dcount <- mkReg('hab);
    Wire#(Bit#(1)) empty_wire <- mkDWire(0);
    Wire#(Bit#(1)) bittest_wire <- mkDWire(0);
    Reg#(Bit#(1)) delay_wren_r_reg <-mkReg(0);
    Reg#(Bit#(1)) delay_wren_r2_reg <- mkSyncReg(0, defaultClock, defaultReset, serdes_clock);
    Reg#(Bit#(1)) delay_wren_c_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) fifo_wren_r2_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);
    Reg#(Bit#(1)) fifo_wren_c_reg <- mkReg(0, clocked_by serdes_clock, reset_by serdes_reset);

    ClockGenIfc serdest_clk <- mkBUFIO(ibufds_clk);
    Vector#(5, ReadOnly#(Bit#(1))) ibufds_v;
    for (Integer i = 0; i < 5; i = i + 1)
        ibufds_v[i] <- mkIBUFDS(vita_data_p[i], vita_data_n[i]);
    Vector#(5, IserdesDatadeser) serdes_v <- replicateM(mkIserdesDatadeser(serdes_clock, serdest_clk.gen_clk));

    Reg#(Bit#(1)) vita_reset_n_o <- mkReg(0);
    Wire#(Bit#(1)) zero_wire <- mkDWire(0);
    Wire#(Bit#(1)) one_wire <- mkDWire(1);
    Wire#(Bit#(1)) trigger_wire <- mkDWire(0);
    Vector#(3, ReadOnly#(Bit#(1))) vita_trigger_wire;
    vita_trigger_wire[2] <- mkOBUFT(zero_wire, imageon_oe);
    vita_trigger_wire[1] <- mkOBUFT(one_wire, imageon_oe);
    vita_trigger_wire[0] <- mkOBUFT(trigger_wire, imageon_oe);
    ReadOnly#(Bit#(1)) vita_reset_n_wire <- mkOBUFT(vita_reset_n_o, imageon_oe);

    Reg#(Bit#(1)) serdes_align_busy_temp <- mkReg(0);
    Reg#(Bit#(1)) serdes_align_busy_reg <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);
    Reg#(Bit#(1)) serdes_aligned_temp <- mkReg(0);
    Reg#(Bit#(1)) serdes_aligned_reg <- mkSyncReg(0, defaultClock, defaultReset, axi_clock);

    rule serdes_copybits;
        serdes_aligned_reg <= serdes_aligned_temp;
        serdes_align_busy_reg <= serdes_align_busy_temp;
    endrule

    rule pll_rule;
        poutq <= pll_out.q();
        ptq <= pll_t.q();
        pll_out.d1(0);
        pll_out.d2(1);
        pll_out.ce(True);
        pll_t.d1(imageon_oe);
        pll_t.d2(imageon_oe);
        pll_t.ce(True);
    endrule

    rule trigger_rule;
        trigger_wire <= pack(tstate != TSend);
    endrule

    rule vr_rule;
        vita_reset_n_o <= ~serdes_reset_reg;
    endrule

    rule sendup_imageon_clock;
       Bit#(5) alignbusyw = 0;
       Bit#(5) alignedw = 0;
       Bit#(5) firstw = 0;
       Bit#(5) lastw = 0;
       Bit#(5) otherw = 0;
       Bit#(5) emptyw = 0;
       Bit#(50) rawdataw = 0;
       for (Bit#(8) i = 0; i < 5; i = i+1) begin
	  serdes_v[i].control.align_start(serdes_align_start_reg);
	  serdes_v[i].control.autoalign(serdes_auto_align_reg);
	  serdes_v[i].control.training(serdes_training_reg);
	  serdes_v[i].control.manual_tap(serdes_manual_tap_reg);
	  serdes_v[i].control.rden(decoder_enable_reg);

	  serdes_v[i].ibufdsOut.ibufds_out(ibufds_v[i]);

	  alignbusyw[i] = serdes_v[i].control.align_busy();
	  alignedw[i] = serdes_v[i].control.aligned();
	  firstw[i] = serdes_v[i].control.sampleinfirstbit();
	  lastw[i] = serdes_v[i].control.sampleinlastbit();
	  otherw[i] = serdes_v[i].control.sampleinotherbit();
	  emptyw[i] = serdes_v[i].fifo.empty();
	  rawdataw[(i+1)*10-1: i*10] = serdes_v[i].fifo.dataout();
       end
       serdes_align_busy_temp <= pack(alignbusyw != 0);
       serdes_aligned_temp <= pack(alignedw == 5'b11111);
       bittest_wire <= pack(otherw == 0 && firstw != 0 && lastw != 0);
       empty_wire <= pack(emptyw != 0);
       raw_data_wire <= rawdataw;
    endrule

    rule sendup_sdes_clock;
    for (Bit#(8) i = 0; i < 5; i = i+1) begin
       serdes_v[i].wren.reset(serdes_reset_null);
       serdes_v[i].wren.delay_wren(delay_wren_c_reg);
       serdes_v[i].wren.fifo_wren(serdes_fifo_enable_null);
    end
    endrule
    
    rule serdes_reset_rule if (serdes_reset_reg == 1);
        new_raw_empty_wire <= 0;
        delay_wren_r_reg <= 0;
        delay_wren_r2_reg <= 0;
    endrule

    rule serdes_resetc_rule if (serdes_reset_null == 1);
        delay_wren_c_reg <= 0;
        fifo_wren_r2_reg <= 0;
        fifo_wren_c_reg <= 0;
    endrule

    rule serdes_calc2 if (serdes_reset_reg == 0);
        new_raw_empty_wire <= empty_wire;
        delay_wren_r_reg <= bittest_wire;
        delay_wren_r2_reg <= delay_wren_r_reg;
    endrule

    rule serdes_calc2c if (serdes_reset_null == 0);
        delay_wren_c_reg <= delay_wren_r2_reg;
        fifo_wren_r2_reg <= serdes_fifo_enable_null;
        fifo_wren_c_reg <= fifo_wren_r2_reg;
    endrule

    rule tcalc;
        let tp = tperiod - 1;
        let tc = tcounter - 1;
        let ts = tstate;
        if (tperiod == 0)
            begin
            tp = trigger_default_freq_reg;
            end
        if (tstate == TIdle && tperiod == 0)
            begin
            tc = trigger_cnt_trigger0high_reg;
            ts = TSend;
            end
        if (tstate == TSend && tcounter == 0)
            begin
            tc = trigger_cnt_trigger0low_reg;
            ts = TWait;
            end
        if (tstate == TWait && tcounter == 0)
            begin
            ts = TIdle;
            end
        tperiod  <= tp;
        tcounter  <= tc;
        tstate  <= ts;
    endrule

    rule sframe_calc;
        let fd = frame_delay+1;
        let fr = frame_run;
        let fstemp = 0;
        if (sframe_new_wire == 1)
            begin
            fr = 1;
            fd = 0;
            end
        if (frame_run == 1 && frame_delay == syncgen_delay_reg )
            begin
            fr = 0;
            fstemp = 1;
            end
        frame_delay <= fd;
        frame_run <= fr;
        fs2 <= fstemp;
    endrule

    rule update_debug;
        let dval = diff;
        dval = {dcount, diff[21:0], 1'b0, delay_wren_r_reg};
        if (1'b0 != delay_wren_r_reg)
            begin
            dcount <= dcount + 1;
            end
        if (diff[17] == 1 || (diff[31:24] != 'hab && diff[31:24] != 0))
            begin
            debugind_value <= diff;
            dval = 0;
            end
        diff <= dval;
    endrule

    rule data_pipeline;
        if (new_raw_empty_wire == 0)
            begin
            raw_data_reg <= raw_data_wire;
            raw_data_delay_reg <= raw_data_reg;
            end
        raw_empty_reg <= new_raw_empty_wire;
    endrule

    rule calculate_framedata;
        let startimageline_wire = pack(raw_data_delay_reg[9:0] == decoder_code_ls_reg);
        let endimageline_wire   = pack(raw_data_delay_reg[9:0] == decoder_code_le_reg);
        let datain_temp = raw_data_reg[49:10];
        let idv = imgdatavalid_reg;
        let dor = dataout_reg;
            //WRITE_DATA <= 0;
            if (raw_empty_reg == 0)
                begin
                if (imgdatavalid_reg == 1)
                    begin
                    if (remapkernel_reg == 0)
                        begin
                        dor[39: 30] = datain_temp[9: 0];
                        dor[29: 20] = datain_temp[19: 10];
                        dor[19: 10] = datain_temp[29: 20];
                        dor[ 9:  0] = datain_temp[39: 30];
                        end
                    else
                        begin
                        dor[39: 30] = datain_temp[39: 30];
                        dor[29: 20] = datain_temp[29: 20];
                        dor[19: 10] = datain_temp[19: 10];
                        dor[ 9:  0] = datain_temp[9: 0];
                        end
                    //WRITE_DATA <= 1;
                    remapkernel_reg <= ~ remapkernel_reg;
                    if (endimageline_wire == 1 && startimageline_wire == 0)
                        begin
                        idv = 0;
                        end
                    end
                else if (startimageline_wire == 1)
                    begin
                    idv = 1;
                    end
                end
        imgdatavalid_reg <= idv;
        dataout_reg <= dor;
        sframe_new_wire <= pack(raw_data_delay_reg[9:0] == decoder_code_fs_reg && raw_data_reg[9:0] == 10'h0);
    endrule

    interface ImageonSensorControl control;
	method Bit#(32) get_iserdes_control();
	    let v = 0;
	    v[8] = 1;
	    v[9] = serdes_align_busy_reg;
	    v[10] = serdes_aligned_reg;
	    return v;
	endmethod
        method Action raw_data(Bit#(50) v);
            raw_data_wire <= v;
	endmethod
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
	method Action set_decoder_code_fs(Bit#(10) v);
	    decoder_code_fs_reg <= v;
	endmethod
	method Action set_serdes_manual_tap(Bit#(10) v);
	    serdes_manual_tap_reg <= v;
	endmethod
	method Action set_serdes_training(Bit#(10) v);
	    serdes_training_reg <= v;
	endmethod
	method Action set_iserdes_control(Bit#(32) v);
	    serdes_reset_reg <= v[0];
	    serdes_auto_align_reg <= v[1];
	    serdes_align_start_reg <= v[2];
	    serdes_fifo_enable_reg <= v[3];
	endmethod
	method Action set_decoder_control(Bit#(32) v);
	    decoder_enable_reg <= v[1];
	endmethod
	method Action set_syncgen_delay(Bit#(16) v);
	    syncgen_delay_reg <= v;
	endmethod
	method Action set_trigger_default_freq(Bit#(32) v);
	    trigger_default_freq_reg <= v;
	endmethod
	method Action set_trigger_cnt_trigger0high(Bit#(32) v);
	    trigger_cnt_trigger0high_reg <= v;
	endmethod
	method Action set_trigger_cnt_trigger0low(Bit#(32) v);
	    trigger_cnt_trigger0low_reg <= v;
	endmethod
    endinterface: control
    method Bit#(1) get_framesync();
        return fs2;
    endmethod
    method Bit#(40) get_data();
        return dataout_reg;
    endmethod
    interface ImageonVita pins;
        method Bit#(1) io_vita_clk_pll();
            return vita_clk_pll;
        endmethod
        method Bit#(1) io_vita_reset_n();
            return vita_reset_n_wire;
        endmethod
        method Vector#(3, ReadOnly#(Bit#(1))) io_vita_trigger();
            return vita_trigger_wire;
        endmethod
        //method Bit#(2) io_vita_monitor();
        method Action io_vita_clk_p(Bit#(1) v);
            vita_clk_p <= v;
        endmethod
        method Action io_vita_clk_n(Bit#(1) v);
            vita_clk_n <= v;
        endmethod
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
        interface imageon_clock_if = defaultClock;
        interface imageon_reset_if = defaultReset;
    endinterface
endmodule

typedef enum { Idle, Active, FrontP, Sync, BackP} State deriving (Bits,Eq);

module mkImageonVideo#(Clock imageon_clock, Reset imageon_reset, Clock axi_clock, Reset axi_reset, ImageonSensor sensor)(ImageonVideo);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    Gearbox#(4, 1, Bit#(10)) dataGearbox <- mkNto1Gearbox(imageon_clock, imageon_reset, defaultClock, defaultReset); 
    Gearbox#(4, 1, Bit#(1))  syncGearbox <- mkNto1Gearbox(imageon_clock, imageon_reset, defaultClock, defaultReset); 

    Reg#(State)    hstate <- mkReg(Idle);
    Reg#(State)    vstate <- mkReg(Idle);
    Reg#(Bit#(1))  active_video_reg <- mkReg(0);
    Reg#(Bit#(16)) vsync_count <- mkReg(0);
    Reg#(Bit#(16)) hsync_count <- mkReg(0);
    Reg#(Bit#(10)) videodata <- mkReg(0);
    Reg#(Bit#(1))  framestart_new <- mkReg(0);
    Reg#(Bit#(16)) syncgen_hactive_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_hfporch_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_hsync_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_hbporch_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_vactive_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_vfporch_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_vsync_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    Reg#(Bit#(16)) syncgen_vbporch_reg <- mkSyncReg(0, axi_clock, axi_reset, defaultClock);
    
    rule start_fsm if (framestart_new == 1);
        vsync_count <= 0;
        hsync_count <= 0;
        hstate <= Active;
        vstate <= Active;
    endrule
 
    rule sync_fsm if (framestart_new != 1);
        let hs = hstate;
        let vs = vstate;
        let hc = hsync_count;
        let vc = vsync_count;
  
        hc = hc + 1;
        if (hstate == FrontP && hsync_count >= syncgen_hfporch_reg)
            begin
            hc = 0;
            hs = Sync;
            vc = vc + 1;
            if (vstate == Active && vsync_count >= syncgen_vactive_reg)
                begin
                vc = 0;
                vs = FrontP;
                end
            if (vstate == FrontP && vsync_count >= syncgen_vfporch_reg)
                begin
                vc = 0;
                vs = Sync;
                end
            if (vstate == Sync && vsync_count >= syncgen_vsync_reg)
                begin
                vc = 0;
                vs = BackP;
                end
            end
        if (hstate == Sync && hsync_count >= syncgen_hsync_reg)
            begin
            hc = 0;
            hs = BackP;
            end
        if (hstate == BackP && hsync_count >= syncgen_hbporch_reg)
            begin
            hc = 0;
            hs = Active;
            end
        if (hstate == Active && hsync_count >= syncgen_hactive_reg)
            begin
            hc = 0;
            hs = FrontP;
            end
    
        hstate <= hs;
        vstate <= vs;
        hsync_count <= hc;
        vsync_count <= vc;
        active_video_reg <= pack(hstate == Active && vstate == Active);
    endrule

    rule update_framestart;
	syncGearbox.deq;
	framestart_new <= syncGearbox.first[0];
    endrule

    rule update_videodata if (active_video_reg == 1);
	dataGearbox.deq;
	videodata <= dataGearbox.first[0];
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

    interface ImageonXsviControl control;
	method Action hactive(Bit#(16) v);
	    syncgen_hactive_reg <= v;
	endmethod
	method Action hfporch(Bit#(16) v);
	    syncgen_hfporch_reg <= v;
	endmethod
	method Action hsync(Bit#(16) v);
	    syncgen_hsync_reg <= v;
	endmethod
	method Action hbporch(Bit#(16) v);
	    syncgen_hbporch_reg <= v;
	endmethod
	method Action vactive(Bit#(16) v);
	    syncgen_vactive_reg <= v;
	endmethod
	method Action vfporch(Bit#(16) v);
	    syncgen_vfporch_reg <= v;
	endmethod
	method Action vsync(Bit#(16) v);
	    syncgen_vsync_reg <= v;
	endmethod
	method Action vbporch(Bit#(16) v);
	    syncgen_vbporch_reg <= v;
	endmethod
    endinterface
    interface Get out;
	method ActionValue#(XsviData) get();
	    return XsviData {
		fsync: framestart_new,
		vsync: pack(vstate == Sync),
		hsync: pack(hstate == Sync),
		active_video: active_video_reg,
		video_data: videodata
	    };
	endmethod
    endinterface: out
endmodule

interface MMCMHACK;
    interface XbsvMMCME2 mmcmadv;
endinterface

module mkMMCMHACK(MMCMHACK);
    XbsvMMCME2 mm <- mkXbsvMMCM(MMCMParams {
        bandwidth:"OPTIMIZED", compensation:"ZHOLD",
        clkfbout_mult_f:8.000, clkfbout_phase:0.0,
        clkin1_period:6.734007, clkin2_period:6.734007,
        clkout0_divide_f:8.000, clkout0_duty_cycle:0.5, clkout0_phase:0.0000,
        clkout1_divide:32, clkout1_duty_cycle:0.5, clkout1_phase:0.0000,
        divclk_divide:1, ref_jitter1:0.010, ref_jitter2:0.010
        });
    interface XbsvMMCME2 mmcmadv = mm;
endmodule
