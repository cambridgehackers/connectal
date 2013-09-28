
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

import SPI::*;
import I2C::*;
import FIFO::*;
import GetPut::*;

interface ImageonSpi;
    method Bit#(1) reset();
    method Bit#(16) timing();
    method Action status_busy(Bit#(1) busy);
    method Action status_error(Bit#(1) error);
    method Bit#(1) txfifo_wen();
    method Bit#(32) txfifo_din();
    method Action txfifo_full(Bit#(1) full);
    method Bit#(1) rxfifo_ren();
    method Action rxfifo_dout(Bit#(32) dout);
    method Action rxfifo_empty(Bit#(1) empty);
endinterface

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
    method Bit#(32) startoddeven();
    method Bit#(10) code_ls();
    method Bit#(10) code_le();
    method Bit#(10) code_fs();
    method Bit#(10) code_fe();
    method Bit#(10) code_bl();
    method Bit#(10) code_img();
    method Action frame_start(Bit#(1) start);
endinterface

interface ImageonRemapper;
    method Bit#(3) write_cfg();
    method Bit#(3) mode();
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
    Bit#(1) vsync;
    Bit#(1) hsync;
    Bit#(1) active_video;
    Bit#(10) video_data;
} XsviData deriving (Bits);

interface ImageonXsvi;
    method Action vsync(Bit#(1) v);
    method Action hsync(Bit#(1) v);
    method Action active_video(Bit#(1) v);
    method Action video_data(Bit#(10) v);
endinterface

interface ImageonDebugSpi;
    method Action debug_spi(Bit#(96) o);
endinterface

(* always_enabled *)
interface ImageonVita;
    method Bit#(1) host_vita_reset();
    method Bit#(1) host_oe();
    method Action fsync(Bit#(1) fsync);
    interface ImageonSpi spi;
    interface ImageonSerdes serdes;
    interface ImageonDecoder decoder;
    interface ImageonRemapper remapper;
    interface ImageonTrigger trigger;
    interface ImageonSyncGen syncgen;
    interface ImageonXsvi xsvi;
    interface ImageonDebugSpi debugSpi;
    method Bit#(32) get_debugreq();
    method Action set_debugind(Bit#(32) v);
endinterface

interface ImageonControl;
    method Action set_spi_control(Bit#(32) v);
    method Bit#(32) get_spi_control();
    method Action set_iserdes_control(Bit#(32) v);
    method Bit#(32) get_iserdes_control();
    method Action set_decoder_control(Bit#(32) v);
    method Bit#(32) get_decoder_control();
    method Action set_triggen_control(Bit#(32) v);
    method Bit#(32) get_triggen_control();

    method Action set_host_vita_reset(Bit#(1) v);
    method Action set_host_oe(Bit#(1) v);

    method Action set_spi_reset(Bit#(1) v);
    method Action set_spi_timing(Bit#(16) v);
    method Bit#(96) get_spi_debug();

    interface Put#(Bit#(32)) txfifo;
    interface Put#(Bit#(32)) rxfifo_request;
    interface Get#(Bit#(32)) rxfifo_response;

    method Action set_serdes_reset(Bit#(1) v);
    method Action set_serdes_auto_align(Bit#(1) v);
    method Action set_serdes_align_start(Bit#(1) v);
    method Action set_serdes_fifo_enable(Bit#(1) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Action set_decoder_reset(Bit#(1) v);
    method Action set_decoder_enable(Bit#(1) v);
    method Action set_decoder_startoddeven(Bit#(32) v);
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
    method XsviData xsviData();
endinterface

interface ImageonVitaController;
    interface ImageonVita host;
    interface ImageonControl control;
endinterface

module mkImageonVitaController(ImageonVitaController);

    Reg#(Bit#(1)) host_vita_reset_reg <- mkReg(0);
    Reg#(Bit#(1)) host_oe_reg <- mkReg(0);
    Wire#(Bit#(1)) host_clock_gen_locked_wire <- mkDWire(0);
    Reg#(Bit#(1)) spi_reset_reg <- mkReg(0);
    Reg#(Bit#(16)) spi_timing_reg <- mkReg(0);

    Wire#(Bit#(1)) spi_status_busy_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_status_error_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_txfifo_full_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_txfifo_wen_wire <- mkDWire(0);
    Wire#(Bit#(32)) spi_txfifo_din_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_rxfifo_ren_wire <- mkDWire(0);
    Wire#(Bit#(32)) spi_rxfifo_dout_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_rxfifo_empty_wire <- mkDWire(0);
    Reg#(Bool) spi_rxfifo_requested_reg <- mkReg(False);

    Reg#(Bit#(1)) serdes_reset_reg <- mkReg(0);
    Reg#(Bit#(1)) serdes_auto_align_reg <- mkReg(0);
    Reg#(Bit#(1)) serdes_align_start_reg <- mkReg(0);
    Reg#(Bit#(1)) serdes_fifo_enable_reg <- mkReg(0);
    Reg#(Bit#(10)) serdes_manual_tap_reg <- mkReg(0);
    Reg#(Bit#(10)) serdes_training_reg <- mkReg(0);
    Wire#(Bit#(1)) serdes_clk_ready_wire <- mkDWire(0);
    Wire#(Bit#(16)) serdes_clk_status_wire <- mkDWire(0);
    Wire#(Bit#(1)) serdes_align_busy_wire <- mkDWire(0);
    Wire#(Bit#(1)) serdes_aligned_wire <- mkDWire(0);

    Reg#(Bit#(1)) decoder_reset_reg <- mkReg(0);
    Reg#(Bit#(1)) decoder_enable_reg <- mkReg(0);
    Reg#(Bit#(32)) decoder_startoddeven_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_ls_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_le_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_fs_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_fe_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_bl_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_img_reg <- mkReg(0);
    Wire#(Bit#(1)) decoder_frame_start_wire <- mkDWire(0);
    Wire#(Bit#(10)) decoder_video_data_wire <- mkDWire(0);

    Reg#(Bit#(3)) remapper_write_cfg_reg <- mkReg(0);
    Reg#(Bit#(3)) remapper_mode_reg <- mkReg(0);
    Reg#(Bit#(3)) trigger_enable_reg <- mkReg(0);
    Reg#(Bit#(3)) trigger_sync2readout_reg <- mkReg(0);
    Reg#(Bit#(1)) trigger_readouttrigger_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_default_freq_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger0high_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger0low_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_delay_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_hactive_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_hfporch_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_hsync_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_hbporch_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_vactive_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_vfporch_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_vsync_reg <- mkReg(0);
    Reg#(Bit#(16)) syncgen_vbporch_reg <- mkReg(0);
    Reg#(Bit#(32)) vsync_reg <- mkReg(0);
    Reg#(Bit#(32)) hsync_reg <- mkReg(0);
    Reg#(Bit#(32)) active_reg <- mkReg(0);
    Wire#(Bit#(10)) xsvi_video_data_wire <- mkDWire(0);
    Wire#(Bit#(1))  xsvi_vsync_wire <- mkDWire(0);
    Wire#(Bit#(1))  xsvi_hsync_wire <- mkDWire(0);
    Wire#(Bit#(1))  xsvi_active_video_wire <- mkDWire(0);
    Wire#(Bit#(96)) debug_spi_wire <- mkDWire(0);
    Reg#(Bit#(32)) debugreq_value <- mkReg(0);
    Reg#(Bit#(32)) debugind_value <- mkReg(0);

    interface ImageonVita host;
	method Bit#(1) host_vita_reset();
	    return host_vita_reset_reg;
	endmethod
	method Bit#(1) host_oe();
	    return host_oe_reg;
	endmethod
	method Action fsync(Bit#(1) sync);
	endmethod
	interface ImageonSpi spi;
	    method Bit#(1) reset();
		return spi_reset_reg;
	    endmethod
	    method Bit#(16) timing();
		return spi_timing_reg;
	    endmethod
	    method Action status_busy(Bit#(1) busy);
	        spi_status_busy_wire <= busy;
	    endmethod
	    method Action status_error(Bit#(1) error);
	        spi_status_error_wire <= error;
	    endmethod
	    method Bit#(1) txfifo_wen();
		return spi_txfifo_wen_wire;
	    endmethod
	    method Bit#(32) txfifo_din();
		return spi_txfifo_din_wire;
	    endmethod
	    method Action txfifo_full(Bit#(1) full);
	        spi_txfifo_full_wire <= full;
	    endmethod
	    method Bit#(1) rxfifo_ren();
		return spi_rxfifo_ren_wire;
	    endmethod
	    method Action rxfifo_dout(Bit#(32) dout);
	        spi_rxfifo_dout_wire <= dout;
	    endmethod
	    method Action rxfifo_empty(Bit#(1) empty);
	        spi_rxfifo_empty_wire <= empty;
	    endmethod
	endinterface
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
	    method Bit#(32) startoddeven();
		return decoder_startoddeven_reg;
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
	interface ImageonRemapper remapper;
	    method Bit#(3) write_cfg();
		return remapper_write_cfg_reg;
	    endmethod
	    method Bit#(3) mode();
		return remapper_mode_reg;
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
	interface ImageonXsvi xsvi;
	    method Action vsync(Bit#(1) v);
	        xsvi_vsync_wire <= v;
	        if (v == 1)
	            vsync_reg <= vsync_reg + 1;
	    endmethod
	    method Action hsync(Bit#(1) v);
	        xsvi_hsync_wire <= v;
	        if (v == 1)
	            hsync_reg <= hsync_reg + 1;
	    endmethod
	    method Action active_video(Bit#(1) v);
	        xsvi_active_video_wire <= v;
	        if (v == 1)
	            active_reg <= active_reg + 1;
	    endmethod
	    method Action video_data(Bit#(10) v);
	        xsvi_video_data_wire <= v;
	    endmethod
	endinterface
	interface ImageonDebugSpi debugSpi;
	    method Action debug_spi(Bit#(96) o);
	        debug_spi_wire <= o;
	    endmethod
	endinterface
        method Bit#(32) get_debugreq();
            return debugreq_value;
	endmethod
        method Action set_debugind(Bit#(32) v);
            debugind_value <= v;
	endmethod
    endinterface
    interface ImageonControl control;
// SPI_CONTROL
//    [ 0] VITA_RESET
//    [ 1] SPI_RESET
//    [ 8] SPI_STATUS_BUSY
//    [ 9] SPI_STATUS_ERROR
//    [16] SPI_TXFIFO_FULL
//    [24] SPI_RXFIFO_EMPTY
	method Action set_spi_control(Bit#(32) v);
            host_vita_reset_reg <= v[0];
            spi_reset_reg <= v[1];
	endmethod
	method Bit#(32) get_spi_control();
	    let v = 0;
            v[0] = host_vita_reset_reg;
	    v[1] = spi_reset_reg;
	    v[8] = spi_status_busy_wire;
	    v[9] = spi_status_error_wire;
	    v[16] = spi_txfifo_full_wire;
	    v[24] = spi_rxfifo_empty_wire;
	    return v;
	endmethod

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
	    v[0] = serdes_reset_reg;
	    v[1] = serdes_auto_align_reg;
	    v[2] = serdes_align_start_reg;
	    v[3] = serdes_fifo_enable_reg;
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
	method Bit#(32) get_decoder_control();
	    let v = 0;
	    v[0] = decoder_reset_reg;
	    v[1] = decoder_enable_reg;
	    return v;
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
	method Bit#(32) get_triggen_control();
	    let v = 0;
	    v[2:0] = trigger_enable_reg;
	    return v;
	endmethod

	method Action set_host_vita_reset(Bit#(1) v);
	    host_vita_reset_reg <= v;
	endmethod
	method Action set_host_oe(Bit#(1) v);
	    host_oe_reg <= v;
	endmethod

	method Action set_spi_reset(Bit#(1) v);
	    spi_reset_reg <= v;
	endmethod
	method Action set_spi_timing(Bit#(16) v);
	    spi_timing_reg <= v;
	endmethod
	interface Put txfifo;
	    method Action put(Bit#(32) v) if (spi_txfifo_full_wire == 0);
	        spi_txfifo_wen_wire <= 1;
		spi_txfifo_din_wire <= v;
	    endmethod
	endinterface
        interface Put rxfifo_request;
	    method Action put(Bit#(32) v) if (!spi_rxfifo_requested_reg && (spi_rxfifo_empty_wire == 0));
	        spi_rxfifo_requested_reg <= True;
		spi_rxfifo_ren_wire <= 1;
	    endmethod
	endinterface
	interface Get rxfifo_response;
	    method ActionValue#(Bit#(32)) get() if (spi_rxfifo_requested_reg);
	        spi_rxfifo_requested_reg <= False;
		return spi_rxfifo_dout_wire;
	    endmethod
	endinterface
	method Bit#(96) get_spi_debug();
	    return debug_spi_wire;
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
	method Action set_decoder_startoddeven(Bit#(32) v);
	    decoder_startoddeven_reg <= v;
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
	method XsviData xsviData();
	    return XsviData {
	        vsync: xsvi_vsync_wire,
		hsync: xsvi_hsync_wire,
		active_video: xsvi_active_video_wire,
		video_data: xsvi_video_data_wire
	    };
	endmethod
    endinterface
endmodule
