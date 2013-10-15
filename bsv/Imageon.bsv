
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
    method Action iserdes_clk_status(Bit#(16) status);
    method Action iserdes_align_busy(Bit#(1) busy);
    method Action iserdes_aligned(Bit#(1) aligned);
endinterface

interface ImageonDecoder;
    method Bit#(1) reset();
    method Bit#(1) enable();
    method Bit#(10) code_ls();
    method Bit#(10) code_le();
    method Bit#(10) code_fs();
    method Bit#(10) code_fe();
    method Bit#(10) code_bl();
    method Bit#(10) code_img();
    method Action frame_start(Bit#(1) start);
endinterface

interface ImageonTrigger;
    method Bit#(3) enable();
    method Bit#(32) default_freq();
    method Bit#(32) cnt_trigger0high();
    method Bit#(32) cnt_trigger0low();
endinterface

interface ImageonSyncGen;
    method Bit#(16) delay();
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

interface ImageonSensorData;
    method Action fsync(Bit#(1) v);
    method Action hsync(Bit#(1) v);
    method Action vsync(Bit#(1) v);
    method Action active_video(Bit#(1) v);
    method Action video_data_old(Bit#(10) v);
    method Action framestart(Bit#(1) v);
    method Action video_data(Bit#(40) v);
    method Bit#(32) get_debugind();
    interface Reset reset;
    interface Reset slowReset;
endinterface

(* always_enabled *)
interface ImageonVita;
    method Bit#(1) host_oe();
    interface ImageonSerdes serdes;
    interface ImageonDecoder decoder;
    interface ImageonTrigger trigger;
    interface ImageonSyncGen syncgen;
    method Bit#(32) get_debugreq();
    method Action set_debugind(Bit#(32) v);
    interface Reset reset;
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
    interface ImageonVita host;
    interface ImageonControl control;
endinterface

module mkImageonVitaController#(Clock hdmi_clock, Reset hdmi_reset)(ImageonVitaController);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset;
    Reg#(Bit#(1)) host_oe_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Wire#(Bit#(1)) host_clock_gen_locked_wire <- mkDWire(0);

    Reg#(Bit#(1)) serdes_reset_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(1)) serdes_auto_align_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(1)) serdes_align_start_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(1)) serdes_fifo_enable_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) serdes_manual_tap_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) serdes_training_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Wire#(Bit#(1)) serdes_clk_ready_wire <- mkDWire(0);
    Wire#(Bit#(16)) serdes_clk_status_wire <- mkDWire(0);
    Wire#(Bit#(1)) serdes_align_busy_wire <- mkDWire(0);
    Wire#(Bit#(1)) serdes_aligned_wire <- mkDWire(0);

    Reg#(Bit#(1)) decoder_reset_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(1)) decoder_enable_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) decoder_code_ls_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) decoder_code_le_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) decoder_code_fs_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) decoder_code_fe_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) decoder_code_bl_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(10)) decoder_code_img_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Wire#(Bit#(1)) decoder_frame_start_wire <- mkDWire(0);
    Wire#(Bit#(10)) decoder_video_data_wire <- mkDWire(0);

    Reg#(Bit#(3)) trigger_enable_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(32)) trigger_default_freq_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(32)) trigger_cnt_trigger0high_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(32)) trigger_cnt_trigger0low_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_delay_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_hactive_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_hfporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_hsync_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_hbporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vactive_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vfporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vsync_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(16)) syncgen_vbporch_reg <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(32)) debugreq_value <- mkSyncReg(0, defaultClock, defaultReset, hdmi_clock);
    Reg#(Bit#(32)) debugind_value <- mkReg(0); //, defaultClock, defaultReset, hdmi_clock);

    interface ImageonVita host;
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
	    method Action iserdes_clk_status(Bit#(16) status);
	        serdes_clk_status_wire <= status;
	    endmethod
	    method Action iserdes_align_busy(Bit#(1) busy);
	        serdes_align_busy_wire <= busy;
	    endmethod
	    method Action iserdes_aligned(Bit#(1) aligned);
	        serdes_aligned_wire <= aligned;
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
	    method Bit#(10) code_fe();
		return decoder_code_fe_reg;
	    endmethod
	    method Bit#(10) code_bl();
		return decoder_code_bl_reg;
	    endmethod
	    method Bit#(10) code_img();
		return decoder_code_img_reg;
	    endmethod
	    method Action frame_start(Bit#(1) start);
	        decoder_frame_start_wire <= start;
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
	interface ImageonSyncGen syncgen;
	    method Bit#(16) delay();
		return syncgen_delay_reg;
	    endmethod
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
    interface ImageonControl control;
// ISERDES_CONTROL
//    [ 0] ISERDES_RESET
//    [ 1] ISERDES_AUTO_ALIGN
//    [ 2] ISERDES_ALIGN_START
//    [ 3] ISERDES_FIFO_ENABLE
//    [ 8] ISERDES_CLK_READY
//    [ 9] ISERDES_ALIGN_BUSY
//    [10] ISERDES_ALIGNED
// [23:16] ISERDES_TXCLK_STATUS
// [31:24] ISERDES_RXCLK_STATUS
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
	    v[31:16] = serdes_clk_status_wire;
	    return v;
	endmethod
// DECODER_CONTROL[7:0]
//    [0] DECODER_RESET
//    [1] DECODER_ENABLE
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
	    host_oe_reg <= v;
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
	    decoder_code_fe_reg <= v;
	endmethod
	method Action set_decoder_code_bl(Bit#(10) v);
	    decoder_code_bl_reg <= v;
	endmethod
	method Action set_decoder_code_img(Bit#(10) v);
	    decoder_code_img_reg <= v;
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
    interface ImageonSensorData in;
    interface Get#(XsviData) out;
endinterface

typedef enum { Idle, Active, FrontP, Sync, BackP} State deriving (Bits,Eq);

module mkImageonXsviFromSensor#(Clock slow_clock, Reset slow_reset)(ImageonXsviFromSensor);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    Gearbox#(4, 1, Bit#(10)) dataGearbox <- mkNto1Gearbox(slow_clock, slow_reset, defaultClock, defaultReset); 
    Gearbox#(4, 1, Bit#(1))  syncGearbox <- mkNto1Gearbox(slow_clock, slow_reset, defaultClock, defaultReset); 

    Reg#(Bit#(1)) vsync_reg <- mkReg(0);
    Reg#(Bit#(1)) hsync_reg <- mkReg(0);
    Reg#(Bit#(1)) active_video_reg <- mkReg(0);
    Wire#(Bit#(1))  xsvi_framestart_old_wire <- mkDWire(0);
    Wire#(Bit#(1))  xsvi_hsync_wire <- mkDWire(0);
    Wire#(Bit#(1))  xsvi_vsync_wire <- mkDWire(0);
    Wire#(Bit#(1))  xsvi_active_video_wire <- mkDWire(0);
    Wire#(Bit#(10)) xsvi_video_data_wire <- mkDWire(0);

    Reg#(Bit#(1))     framestart <- mkReg(0);
    Reg#(State)       hstate <- mkReg(Idle);
    Reg#(State)       vstate <- mkReg(Idle);
    Reg#(Bit#(16))    vsync_count <- mkReg(0);
    Reg#(Bit#(16))    hsync_count <- mkReg(0);
    Reg#(Bit#(16))    host_syncgen_hactive <- mkReg(0);
    Reg#(Bit#(16))    host_syncgen_hfporch <- mkReg(0);
    Reg#(Bit#(16))    host_syncgen_hbporch <- mkReg(0);
    Reg#(Bit#(16))    host_syncgen_hsync <- mkReg(0);
    Reg#(Bit#(16))    host_syncgen_vactive <- mkReg(0);
    Reg#(Bit#(16))    host_syncgen_vfporch <- mkReg(0);
    Reg#(Bit#(16))    host_syncgen_vsync <- mkReg(0);
    Reg#(Bit#(32))    debugind_value <- mkReg(0);
    
    rule start_fsm if (framestart == 1);
        vsync_count <= 0;
        hsync_count <= 0;
        hstate <= Active;
        vstate <= Active;
    endrule
 
    rule sync_fsm if (framestart != 1);
        let hs = hstate;
        let vs = vstate;
        let hc = hsync_count;
        let vc = vsync_count;
  
        hc = hc + 1;
        if (hstate == FrontP && hsync_count >= host_syncgen_hfporch - 1)
            begin
            hc = 0;
            hs = Sync;
            vc = vc + 1;
            if (vstate == Active && vsync_count >= host_syncgen_vactive - 1)
                begin
                vc = 0;
                vs = FrontP;
                end
            if (vstate == FrontP && vsync_count >= host_syncgen_vfporch - 1)
                begin
                vc = 0;
                vs = Sync;
                end
            if (vstate == Sync && vsync_count >= host_syncgen_vsync - 1)
                begin
                vc = 0;
                vs = BackP;
                end
            end
        if (hstate == Sync && hsync_count >= host_syncgen_hsync - 1)
            begin
            hc = 0;
            hs = BackP;
            end
        if (hstate == BackP && hsync_count >= host_syncgen_hbporch - 1)
            begin
            hc = 0;
            hs = Active;
            end
        if (hstate == Active && hsync_count >= host_syncgen_hactive - 1)
            begin
            hc = 0;
            hs = FrontP;
            end
    
        hstate <= hs;
        vstate <= vs;
        hsync_count <= hc;
        vsync_count <= vc;
    endrule

    interface ImageonSensorData in;
        method Action fsync(Bit#(1) v);
	    xsvi_framestart_old_wire <= v;
	endmethod
        method Action hsync(Bit#(1) v);
	    xsvi_hsync_wire <= v;
	endmethod
        method Action vsync(Bit#(1) v);
	    xsvi_vsync_wire <= v;
	endmethod
        method Action active_video(Bit#(1) v);
            xsvi_active_video_wire <= v;
        endmethod
	method Action video_data_old(Bit#(10) v);
            xsvi_video_data_wire <= v;
	endmethod
	method Action framestart(Bit#(1) v);
	    Vector#(4, Bit#(1)) in = replicate(0);
	    // zero'th element shifted out first
	    in[0] = v;
	    syncGearbox.enq(in);
	endmethod
	method Action video_data(Bit#(40) v);
	    // least signifcant 10 bits shifted out first
	    Vector#(4, Bit#(10)) in = unpack(v);
	    dataGearbox.enq(in);
	endmethod
        method Bit#(32) get_debugind();
            return debugind_value;
	endmethod
	interface Reset reset = defaultReset;
	interface Reset slowReset = slow_reset;
    endinterface: in
    interface Get out;
	method ActionValue#(XsviData) get();
	    dataGearbox.deq;
	    syncGearbox.deq;
            debugind_value <= { 'hab, xsvi_hsync_wire, xsvi_vsync_wire, pack(hstate), pack(vstate), hsync_count[7:0], vsync_count[7:0] } ;
	    return XsviData {
		fsync: xsvi_framestart_old_wire, //syncGearbox.first[0],
		vsync: xsvi_vsync_wire,
		hsync: xsvi_hsync_wire,
		active_video: xsvi_active_video_wire,
		video_data: xsvi_video_data_wire //dataGearbox.first[0]
	    };
	endmethod
    endinterface: out
endmodule
