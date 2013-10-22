
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

interface ImageonSerdes;
    method Bit#(1) reset();
    method Bit#(1) auto_align();
    method Bit#(1) align_start();
    method Bit#(1) fifo_enable();
    method Bit#(10) manual_tap();
    method Bit#(10) training();
    method Action iserdes_clk_ready(Bit#(1) ready);
    method Action iserdes_align_busy(Bit#(1) busy);
    method Action iserdes_aligned(Bit#(1) aligned);
endinterface

interface ImageonDecoder;
    method Bit#(1) reset();
    method Bit#(1) enable();
    method Bit#(10) code_ls();
    method Bit#(10) code_le();
    method Bit#(10) code_fs();
    method Action frame_start(Bit#(1) start);
endinterface

interface ImageonTrigger;
    method Bit#(3) enable();
    method Bit#(32) default_freq();
    method Bit#(32) cnt_trigger0high();
    method Bit#(32) cnt_trigger0low();
endinterface

interface ImageonSyncGen;
    //method Bit#(16) delay();
    method Bit#(16) hactive();
    method Bit#(16) hfporch();
    method Bit#(16) hsync();
    method Bit#(16) hbporch();
    method Bit#(16) vactive();
    method Bit#(16) vfporch();
    method Bit#(16) vsync();
    method Bit#(16) vbporch();
endinterface

typedef struct {
    Bit#(1) fsync;
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) active_video;
    Bit#(10) video_data;
} XsviData deriving (Bits);

(* always_enabled *)
interface ImageonSensorControl;
    method Bit#(32) get_debugind();
    method Action sframe(Bit#(1) v);
    method Action raw_data(Bit#(50) v);
    method Action raw_empty(Bit#(1) v);
    interface Reset reset;
    interface Reset hdmiReset;
endinterface

(* always_enabled *)
interface ImageonFast;
    interface ImageonSyncGen syncgen;
    method Bit#(32) get_debugreq();
    method Action set_debugind(Bit#(32) v);
    interface Reset reset;
endinterface

(* always_enabled *)
interface ImageonVita;
    method Bit#(1) host_oe();
    interface ImageonSerdes serdes;
    interface ImageonTrigger trigger;
    interface ImageonDecoder decoder;
    method Bit#(16) syncgen_delay();
endinterface

interface ImageonControl;
    method Action set_iserdes_control(Bit#(32) v);
    method Bit#(32) get_iserdes_control();
    method Action set_decoder_control(Bit#(32) v);
    method Action set_triggen_control(Bit#(32) v);

    method Action set_host_oe(Bit#(1) v);

    method Action set_serdes_reset(Bit#(1) v);
    method Action set_serdes_auto_align(Bit#(1) v);
    method Action set_serdes_align_start(Bit#(1) v);
    method Action set_serdes_fifo_enable(Bit#(1) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Action set_decoder_reset(Bit#(1) v);
    method Action set_decoder_enable(Bit#(1) v);
    method Action set_decoder_code_ls(Bit#(10) v);
    method Action set_decoder_code_le(Bit#(10) v);
    method Action set_decoder_code_fs(Bit#(10) v);
    method Action set_decoder_code_fe(Bit#(10) v);
    method Action set_decoder_code_bl(Bit#(10) v);
    method Action set_decoder_code_img(Bit#(10) v);
    method Action set_trigger_enable(Bit#(3) v);
    method Action set_trigger_default_freq(Bit#(32) v);
    method Action set_trigger_cnt_trigger0high(Bit#(32) v);
    method Action set_trigger_cnt_trigger0low(Bit#(32) v);
    method Action set_syncgen_delay(Bit#(16) v);
    method Action set_syncgen_hactive(Bit#(16) v);
    method Action set_syncgen_hfporch(Bit#(16) v);
    method Action set_syncgen_hsync(Bit#(16) v);
    method Action set_syncgen_hbporch(Bit#(16) v);
    method Action set_syncgen_vactive(Bit#(16) v);
    method Action set_syncgen_vfporch(Bit#(16) v);
    method Action set_syncgen_vsync(Bit#(16) v);
    method Action set_syncgen_vbporch(Bit#(16) v);
    method Action set_debugreq(Bit#(32) v);
    method Bit#(32) get_debugind();
endinterface

interface ImageonVitaController;
    interface ImageonFast host;
    interface ImageonVita hosts;
    interface ImageonControl control;
endinterface

module mkImageonVitaController#(Clock hdmi_clock, Reset hdmi_reset, Clock imageon_clock, Reset imageon_reset)(ImageonVitaController);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset;
    Reg#(Bit#(1)) host_oe_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Wire#(Bit#(1)) host_clock_gen_locked_wire <- mkDWire(0);

    Reg#(Bit#(1)) serdes_reset_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(1)) serdes_auto_align_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(1)) serdes_align_start_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(1)) serdes_fifo_enable_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(10)) serdes_manual_tap_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(10)) serdes_training_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Wire#(Bit#(1)) serdes_clk_ready_wire <- mkDWire(0);
    Wire#(Bit#(1)) serdes_align_busy_wire <- mkDWire(0);
    Wire#(Bit#(1)) serdes_aligned_wire <- mkDWire(0);

    Reg#(Bit#(1)) decoder_reset_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(1)) decoder_enable_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(10)) decoder_code_ls_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(10)) decoder_code_le_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(10)) decoder_code_fs_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Wire#(Bit#(1)) decoder_frame_start_wire <- mkDWire(0);

    Reg#(Bit#(3)) trigger_enable_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(32)) trigger_default_freq_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(32)) trigger_cnt_trigger0high_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(32)) trigger_cnt_trigger0low_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(16)) syncgen_delay_reg <- mkSyncReg(0, defaultClock, defaultReset, imageon_clock);
    Reg#(Bit#(16)) syncgen_hactive_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_hfporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_hsync_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_hbporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vactive_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vfporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vsync_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vbporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(32)) debugreq_value <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(32)) debugind_value <- mkReg(0);

    interface ImageonFast host;
	interface ImageonSyncGen syncgen;
	    method Bit#(16) hactive();
		return syncgen_hactive_reg;
	    endmethod
	    method Bit#(16) hfporch();
		return syncgen_hfporch_reg;
	    endmethod
	    method Bit#(16) hsync();
		return syncgen_hsync_reg;
	    endmethod
	    method Bit#(16) hbporch();
		return syncgen_hbporch_reg;
	    endmethod
	    method Bit#(16) vactive();
		return syncgen_vactive_reg;
	    endmethod
	    method Bit#(16) vfporch();
		return syncgen_vfporch_reg;
	    endmethod
	    method Bit#(16) vsync();
		return syncgen_vsync_reg;
	    endmethod
	    method Bit#(16) vbporch();
		return syncgen_vbporch_reg;
	    endmethod
	endinterface
        method Bit#(32) get_debugreq();
            return debugreq_value;
	endmethod
        method Action set_debugind(Bit#(32) v);
            debugind_value <= v;
	endmethod
        interface Reset reset = defaultReset;
    endinterface: host

    interface ImageonVita hosts;
	method Bit#(1) host_oe();
	    return host_oe_reg;
	endmethod
	interface ImageonSerdes serdes;
	    method Bit#(1) reset();
		return serdes_reset_reg;
	    endmethod
	    method Bit#(1) auto_align();
		return serdes_auto_align_reg;
	    endmethod
	    method Bit#(1) align_start();
		return serdes_align_start_reg;
	    endmethod
	    method Bit#(1) fifo_enable();
		return serdes_fifo_enable_reg;
	    endmethod
	    method Bit#(10) manual_tap();
		return serdes_manual_tap_reg;
	    endmethod
	    method Bit#(10) training();
		return serdes_training_reg;
	    endmethod
	    method Action iserdes_clk_ready(Bit#(1) ready);
	        serdes_clk_ready_wire <= ready;
	    endmethod
	    method Action iserdes_align_busy(Bit#(1) busy);
	        serdes_align_busy_wire <= busy;
	    endmethod
	    method Action iserdes_aligned(Bit#(1) aligned);
	        serdes_aligned_wire <= aligned;
	    endmethod
	endinterface
	interface ImageonTrigger trigger;
	    method Bit#(3) enable();
		return trigger_enable_reg;
	    endmethod
	    method Bit#(32) default_freq();
		return trigger_default_freq_reg;
	    endmethod
	    method Bit#(32) cnt_trigger0high();
		return trigger_cnt_trigger0high_reg;
	    endmethod
	    method Bit#(32) cnt_trigger0low();
		return trigger_cnt_trigger0low_reg;
	    endmethod
	endinterface
	interface ImageonDecoder decoder;
	    method Bit#(1) reset();
		return decoder_reset_reg;
	    endmethod
	    method Bit#(1) enable();
		return decoder_enable_reg;
	    endmethod
	    method Bit#(10) code_ls();
		return decoder_code_ls_reg;
	    endmethod
	    method Bit#(10) code_le();
		return decoder_code_le_reg;
	    endmethod
	    method Bit#(10) code_fs();
		return decoder_code_fs_reg;
	    endmethod
	    method Action frame_start(Bit#(1) start);
	        decoder_frame_start_wire <= start;
	    endmethod
	endinterface
	method Bit#(16) syncgen_delay();
	    return syncgen_delay_reg;
	endmethod
    endinterface: hosts

    interface ImageonControl control;
	method Action set_iserdes_control(Bit#(32) v);
	    serdes_reset_reg <= v[0];
	    serdes_auto_align_reg <= v[1];
	    serdes_align_start_reg <= v[2];
	    serdes_fifo_enable_reg <= v[3];
	endmethod
	method Bit#(32) get_iserdes_control();
	    let v = 0;
	    v[8] = serdes_clk_ready_wire;
	    v[9] = serdes_align_busy_wire;
	    v[10] = serdes_aligned_wire;
	    return v;
	endmethod
	method Action set_decoder_control(Bit#(32) v);
	    decoder_reset_reg <= v[0];
	    decoder_enable_reg <= v[1];
	endmethod
// TRIGGEN_CONTROL
// [ 2: 0] TRIGGEN_ENABLE
// [ 6: 4] TRIGGEN_SYNC2READOUT
// [    8] TRIGGEN_READOUTTRIGGER
// [   16] TRIGGEN_EXT_POLARITY
// [   24] TRIGGEN_CNT_UPDATE
// [30:28] TRIGGEN_GEN_POLARITY
	method Action set_triggen_control(Bit#(32) v);
	    trigger_enable_reg <= v[2:0];
	endmethod

	method Action set_host_oe(Bit#(1) v);
	    host_oe_reg <= ~v;
	endmethod

	method Action set_serdes_reset(Bit#(1) v);
	    serdes_reset_reg <= v;
	endmethod
	method Action set_serdes_auto_align(Bit#(1) v);
	    serdes_auto_align_reg <= v;
	endmethod
	method Action set_serdes_align_start(Bit#(1) v);
	    serdes_align_start_reg <= v;
	endmethod
	method Action set_serdes_fifo_enable(Bit#(1) v);
	    serdes_fifo_enable_reg <= v;
	endmethod
	method Action set_serdes_manual_tap(Bit#(10) v);
	    serdes_manual_tap_reg <= v;
	endmethod
	method Action set_serdes_training(Bit#(10) v);
	    serdes_training_reg <= v;
	endmethod
	method Action set_decoder_reset(Bit#(1) v);
	    decoder_reset_reg <= v;
	endmethod
	method Action set_decoder_enable(Bit#(1) v);
	    decoder_enable_reg <= v;
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
	method Action set_decoder_code_fe(Bit#(10) v);
	endmethod
	method Action set_decoder_code_bl(Bit#(10) v);
	endmethod
	method Action set_decoder_code_img(Bit#(10) v);
	endmethod
	method Action set_trigger_enable(Bit#(3) v);
	    trigger_enable_reg <= v;
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
	method Action set_syncgen_delay(Bit#(16) v);
	    syncgen_delay_reg <= v;
	endmethod
	method Action set_syncgen_hactive(Bit#(16) v);
	    syncgen_hactive_reg <= v;
	endmethod
	method Action set_syncgen_hfporch(Bit#(16) v);
	    syncgen_hfporch_reg <= v;
	endmethod
	method Action set_syncgen_hsync(Bit#(16) v);
	    syncgen_hsync_reg <= v;
	endmethod
	method Action set_syncgen_hbporch(Bit#(16) v);
	    syncgen_hbporch_reg <= v;
	endmethod
	method Action set_syncgen_vactive(Bit#(16) v);
	    syncgen_vactive_reg <= v;
	endmethod
	method Action set_syncgen_vfporch(Bit#(16) v);
	    syncgen_vfporch_reg <= v;
	endmethod
	method Action set_syncgen_vsync(Bit#(16) v);
	    syncgen_vsync_reg <= v;
	endmethod
	method Action set_syncgen_vbporch(Bit#(16) v);
	    syncgen_vbporch_reg <= v;
	endmethod
        method Action set_debugreq(Bit#(32) v);
            debugreq_value <= v;
	endmethod
        method Bit#(32) get_debugind();
            return debugind_value;
	endmethod
    endinterface
endmodule

interface ImageonXsviFromSensor;
    interface Get#(XsviData) out;
endinterface

interface ImageonSensor;
    interface ImageonSensorControl in;
    interface Get#(Bit#(1)) out;
    method Bit#(1)get_framesync();
    method Bit#(40)get_data();
endinterface

typedef enum { Idle, Active, FrontP, Sync, BackP} State deriving (Bits,Eq);
typedef enum { TIdle, TSend, TWait} TState deriving (Bits,Eq);

module mkImageonSensor#(Clock hdmi_clock, Reset hdmi_reset, ImageonVita host)(ImageonSensor);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    Reg#(TState)   tstate <- mkReg(TIdle);
    Reg#(Bit#(1)) sframe_wire <- mkReg(0);
    Reg#(Bit#(1)) sframe_new_wire <- mkReg(0);
    Reg#(Bit#(1))  fs2 <- mkReg(0);
    Reg#(Bit#(16)) frame_delay <- mkReg(0);
    Reg#(Bit#(1))  frame_run <- mkReg(0);
    Reg#(Bit#(32)) tcounter <- mkReg(0);
    Reg#(Bit#(32)) diff <- mkReg(0);
    Reg#(Bit#(1))  framestart_delay_reg <- mkReg(0);
    Reg#(Bit#(32)) debugind_value <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) sync_delay_reg <- mkReg(0);
    Wire#(Bit#(50)) raw_data_wire <- mkDWire(0);
    Reg#(Bit#(50)) raw_data_reg <- mkReg(0);
    Reg#(Bit#(40)) dataout_reg <- mkReg(0);
    Reg#(Bit#(50)) raw_data_delay_reg <- mkReg(0);
    Wire#(Bit#(1)) raw_empty_wire <- mkDWire(0);
    Reg#(Bit#(1)) raw_empty_reg <- mkReg(0);
    Reg#(Bit#(1)) remapkernel_reg <- mkReg(0);
    Reg#(Bit#(1)) imgdatavalid_reg <- mkReg(0);
    Reg#(Bit#(8)) dcount <- mkReg(0);
    
    rule tcalc;
        let tc = tcounter - 1;
        let ts = tstate;
        if (tstate == TIdle && tcounter == 0)
            begin
            tc = host.trigger.cnt_trigger0high();
            ts = TSend;
            end
        if (tstate == TSend && tcounter == 0)
            begin
            tc = host.trigger.cnt_trigger0low();
            ts = TWait;
            end
        if (tstate == TWait && tcounter == 0)
            begin
            ts = TIdle;
            tc = host.trigger.default_freq();
            end
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
        if (frame_run == 1 && frame_delay == host.syncgen_delay() )
            begin
            fr = 0;
            fstemp = 1;
            end
        frame_delay <= fd;
        frame_run <= fr;
        fs2 <= fstemp;
    endrule

    rule update_debug;
        //let startframe_wire     = pack(raw_data_delay_reg[9:0] == host.decoder.code_fs() && raw_data_reg[9:0] == 10'h0);
        let dval = diff;
        dval = {dcount, diff[21:0], sframe_wire, sframe_new_wire};
        if (sframe_wire != sframe_new_wire)
            begin
            dcount <= dcount + 1;
            end
        if (diff[17] == 1)
            begin
            debugind_value <= diff;
            dval = 0;
            end
        diff <= dval;
    endrule

    rule data_pipeline;
        if (raw_empty_wire == 0)
            begin
            raw_data_reg <= raw_data_wire;
            raw_data_delay_reg <= raw_data_reg;
            end
        raw_empty_reg <= raw_empty_wire;
    endrule

    rule calculate_framedata;
        let startimageline_wire = pack(raw_data_delay_reg[9:0] == host.decoder.code_ls());
        let endimageline_wire   = pack(raw_data_delay_reg[9:0] == host.decoder.code_le());
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
        sframe_new_wire <= pack(raw_data_delay_reg[9:0] == host.decoder.code_fs() && raw_data_reg[9:0] == 10'h0);
    endrule

    interface ImageonSensorControl in;
	method Action sframe(Bit#(1) v);
            sframe_wire <= v;
	endmethod
        method Action raw_data(Bit#(50) v);
            raw_data_wire <= v;
	endmethod
        method Action raw_empty(Bit#(1) v);
            raw_empty_wire <= v;
	endmethod
        method Bit#(32) get_debugind();
            return debugind_value;
	endmethod
	interface Reset reset = defaultReset;
	interface Reset hdmiReset = hdmi_reset;
    endinterface: in
    interface Get out;
	method ActionValue#(Bit#(1)) get();
	    return 1;
	endmethod
    endinterface: out

    method Bit#(1)get_framesync();
        return fs2;
    endmethod
    method Bit#(40)get_data();
        return dataout_reg;
    endmethod
endmodule

module mkImageonXsviFromSensor#(Clock imageon_clock, Reset imageon_reset, ImageonFast host, ImageonSensor sensor)(ImageonXsviFromSensor);
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
        if (hstate == FrontP && hsync_count >= host.syncgen.hfporch() - 1)
            begin
            hc = 0;
            hs = Sync;
            vc = vc + 1;
            if (vstate == Active && vsync_count >= host.syncgen.vactive() - 1)
                begin
                vc = 0;
                vs = FrontP;
                end
            if (vstate == FrontP && vsync_count >= host.syncgen.vfporch() - 1)
                begin
                vc = 0;
                vs = Sync;
                end
            if (vstate == Sync && vsync_count >= host.syncgen.vsync() - 1)
                begin
                vc = 0;
                vs = BackP;
                end
            end
        if (hstate == Sync && hsync_count >= host.syncgen.hsync() - 1)
            begin
            hc = 0;
            hs = BackP;
            end
        if (hstate == BackP && hsync_count >= host.syncgen.hbporch() - 1)
            begin
            hc = 0;
            hs = Active;
            end
        if (hstate == Active && hsync_count >= host.syncgen.hactive() - 1)
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
