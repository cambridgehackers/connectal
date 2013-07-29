
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
    //method Bit#(1) txfifo_clk();
    method Bit#(1) txfifo_wen();
    method Bit#(32) txfifo_din();
    method Action txfifo_full(Bit#(1) full);
    //method Bit#(1) rxfifo_clk();
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
    method Bit#(10) code_tr();
    method Bit#(10) code_crc();
    method Action frame_start(Bit#(1) start);
    method Action cnt_black_lines(Bit#(32) lines);
    method Action cnt_image_lines(Bit#(32) lines);
    method Action cnt_black_pixels(Bit#(32) pixels);
    method Action cnt_image_pixels(Bit#(32) pixels);
    method Action cnt_frames(Bit#(32) frames);
    method Action cnt_windows(Bit#(32) windows);
    method Action cnt_clocks(Bit#(32) clocks);
    method Action cnt_start_lines(Bit#(32) lines);
    method Action cnt_end_lines(Bit#(32) lines);
    method Action cnt_monitor0high(Bit#(32) monitor0high);
    method Action cnt_monitor0low(Bit#(32) monitor0low);
    method Action cnt_monitor1high(Bit#(32) monitor1high);
    method Action cnt_monitor1low(Bit#(32) monitor1low);
endinterface

interface ImageonCrc;
    method Bit#(1) reset();
    method Bit#(1) initvalue();
    method Action crc_status(Bit#(32) status);
endinterface

interface ImageonRemapper;
    method Bit#(3) write_cfg();
    method Bit#(3) mode();
endinterface

interface ImageonTrigger;
    method Bit#(3) enable();
    method Bit#(3) sync2readout();
    method Bit#(1) readouttrigger();
    method Bit#(32) default_freq();
    method Bit#(32) cnt_trigger0high();
    method Bit#(32) cnt_trigger0low();
    method Bit#(32) cnt_trigger1high();
    method Bit#(32) cnt_trigger1low();
    method Bit#(32) cnt_trigger2high();
    method Bit#(32) cnt_trigger2low();
    method Bit#(32) ext_debounce();
    method Bit#(1) ext_polarity();
    method Bit#(3) gen_polarity();
endinterface

interface ImageonFpnPrnu;
    method Bit#(256) prnu_values();
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

interface ImageonXsvi;
    method Action vsync(Bit#(1) v);
    method Action hsync(Bit#(1) v);
    method Action vblank(Bit#(1) v);
    method Action hblank(Bit#(1) v);
    method Action active_video(Bit#(1) v);
    method Action video_data(Bit#(10) v);
endinterface

(* always_enabled *)
interface ImageonVita;
    method Bit#(1) host_vita_reset();
    method Bit#(1) host_oe();
    method Action fsync(Bit#(1) fsync);
    interface ImageonSpi spi;
    interface ImageonSerdes serdes;
    interface ImageonDecoder decoder;
    interface ImageonCrc crc;
    interface ImageonRemapper remapper;
    interface ImageonTrigger trigger;
    interface ImageonFpnPrnu fpnPrnu;
    interface ImageonSyncGen syncgen;
    interface ImageonXsvi xsvi;
endinterface

interface ImageonControl;
    method Action set_host_vita_reset(Bit#(1) v);
    method Action set_host_oe(Bit#(1) v);
    method Action set_spi_reset(Bit#(1) v);
    method Action set_spi_timing(Bit#(16) v);

    interface Put#(Bit#(32)) txfifo;
    interface Get#(Bit#(32)) rxfifo;

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
    method Action set_decoder_code_tr(Bit#(10) v);
    method Action set_decoder_code_crc(Bit#(10) v);
    method Action set_crc_reset(Bit#(1) v);
    method Action set_crc_initvalue(Bit#(1) v);
    method Action set_remapper_write_cfg(Bit#(3) v);
    method Action set_remapper_mode(Bit#(3) v);
    method Action set_trigger_enable(Bit#(3) v);
    method Action set_trigger_sync2readout(Bit#(3) v);
    method Action set_trigger_readouttrigger(Bit#(1) v);
    method Action set_trigger_default_freq(Bit#(32) v);
    method Action set_trigger_cnt_trigger0high(Bit#(32) v);
    method Action set_trigger_cnt_trigger0low(Bit#(32) v);
    method Action set_trigger_cnt_trigger1high(Bit#(32) v);
    method Action set_trigger_cnt_trigger1low(Bit#(32) v);
    method Action set_trigger_cnt_trigger2high(Bit#(32) v);
    method Action set_trigger_cnt_trigger2low(Bit#(32) v);
    method Action set_trigger_ext_debounce(Bit#(32) v);
    method Action set_trigger_ext_polarity(Bit#(1) v);
    method Action set_trigger_gen_polarity(Bit#(3) v);
    method Action set_prnu_values(Bit#(256) v);
    method Action set_syncgen_delay(Bit#(16) v);
    method Action set_syncgen_hactive(Bit#(16) v);
    method Action set_syncgen_hfporch(Bit#(16) v);
    method Action set_syncgen_hsync(Bit#(16) v);
    method Action set_syncgen_hbporch(Bit#(16) v);
    method Action set_syncgen_vactive(Bit#(16) v);
    method Action set_syncgen_vfporch(Bit#(16) v);
    method Action set_syncgen_vsync(Bit#(16) v);
    method Action set_syncgen_vbporch(Bit#(16) v);
endinterface

interface ImageonVitaController;
    interface ImageonVita host;
    interface ImageonControl control;
endinterface

module mkImageonVitaController(ImageonVitaController);

    Reg#(Bit#(1)) host_vita_reset_reg <- mkReg(0);
    Reg#(Bit#(1)) host_oe_reg <- mkReg(0);
    Reg#(Bit#(1)) spi_reset_reg <- mkReg(0);
    Reg#(Bit#(16)) spi_timing_reg <- mkReg(0);

    Wire#(Bit#(1)) spi_txfifo_full_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_txfifo_wen_wire <- mkDWire(0);
    Wire#(Bit#(32)) spi_txfifo_din_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_rxfifo_ren_wire <- mkDWire(0);
    Wire#(Bit#(32)) spi_rxfifo_dout_wire <- mkDWire(0);
    Wire#(Bit#(1)) spi_rxfifo_empty_wire <- mkDWire(0);

    Reg#(Bit#(1)) serdes_reset_reg <- mkReg(0);
    Reg#(Bit#(1)) serdes_auto_align_reg <- mkReg(0);
    Reg#(Bit#(1)) serdes_align_start_reg <- mkReg(0);
    Reg#(Bit#(1)) serdes_fifo_enable_reg <- mkReg(0);
    Reg#(Bit#(10)) serdes_manual_tap_reg <- mkReg(0);
    Reg#(Bit#(10)) serdes_training_reg <- mkReg(0);
    Reg#(Bit#(1)) decoder_reset_reg <- mkReg(0);
    Reg#(Bit#(1)) decoder_enable_reg <- mkReg(0);
    Reg#(Bit#(32)) decoder_startoddeven_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_ls_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_le_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_fs_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_fe_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_bl_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_img_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_tr_reg <- mkReg(0);
    Reg#(Bit#(10)) decoder_code_crc_reg <- mkReg(0);
    Reg#(Bit#(1)) crc_reset_reg <- mkReg(0);
    Reg#(Bit#(1)) crc_initvalue_reg <- mkReg(0);
    Reg#(Bit#(3)) remapper_write_cfg_reg <- mkReg(0);
    Reg#(Bit#(3)) remapper_mode_reg <- mkReg(0);
    Reg#(Bit#(3)) trigger_enable_reg <- mkReg(0);
    Reg#(Bit#(3)) trigger_sync2readout_reg <- mkReg(0);
    Reg#(Bit#(1)) trigger_readouttrigger_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_default_freq_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger0high_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger0low_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger1high_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger1low_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger2high_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_cnt_trigger2low_reg <- mkReg(0);
    Reg#(Bit#(32)) trigger_ext_debounce_reg <- mkReg(0);
    Reg#(Bit#(1)) trigger_ext_polarity_reg <- mkReg(0);
    Reg#(Bit#(3)) trigger_gen_polarity_reg <- mkReg(0);
    Reg#(Bit#(256)) prnu_values_reg <- mkReg(0);
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
    Reg#(Bit#(32)) vblank_reg <- mkReg(0);
    Reg#(Bit#(32)) hblank_reg <- mkReg(0);
    Reg#(Bit#(32)) active_reg <- mkReg(0);

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
	    endmethod
	    method Action status_error(Bit#(1) error);
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
	    endmethod
	    method Action iserdes_clk_status(Bit#(16) status);
	    endmethod
	    method Action iserdes_align_busy(Bit#(1) busy);
	    endmethod
	    method Action iserdes_aligned(Bit#(1) aligned);
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
	    method Bit#(10) code_tr();
		return decoder_code_tr_reg;
	    endmethod
	    method Bit#(10) code_crc();
		return decoder_code_crc_reg;
	    endmethod
	    method Action frame_start(Bit#(1) start);
	    endmethod
	    method Action cnt_black_lines(Bit#(32) lines);
	    endmethod
	    method Action cnt_image_lines(Bit#(32) lines);
	    endmethod
	    method Action cnt_black_pixels(Bit#(32) pixels);
	    endmethod
	    method Action cnt_image_pixels(Bit#(32) pixels);
	    endmethod
	    method Action cnt_frames(Bit#(32) frames);
	    endmethod
	    method Action cnt_windows(Bit#(32) windows);
	    endmethod
	    method Action cnt_clocks(Bit#(32) clocks);
	    endmethod
	    method Action cnt_start_lines(Bit#(32) lines);
	    endmethod
	    method Action cnt_end_lines(Bit#(32) lines);
	    endmethod
	    method Action cnt_monitor0high(Bit#(32) monitor0high);
	    endmethod
	    method Action cnt_monitor0low(Bit#(32) monitor0low);
	    endmethod
	    method Action cnt_monitor1high(Bit#(32) monitor1high);
	    endmethod
	    method Action cnt_monitor1low(Bit#(32) monitor1low);
	    endmethod
	endinterface
	interface ImageonCrc crc;
	    method Bit#(1) reset();
		return crc_reset_reg;
	    endmethod
	    method Bit#(1) initvalue();
		return crc_initvalue_reg;
	    endmethod
	    method Action crc_status(Bit#(32) status);
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
	    method Bit#(3) sync2readout();
		return trigger_sync2readout_reg;
	    endmethod
	    method Bit#(1) readouttrigger();
		return trigger_readouttrigger_reg;
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
	    method Bit#(32) cnt_trigger1high();
		return trigger_cnt_trigger1high_reg;
	    endmethod
	    method Bit#(32) cnt_trigger1low();
		return trigger_cnt_trigger1low_reg;
	    endmethod
	    method Bit#(32) cnt_trigger2high();
		return trigger_cnt_trigger2high_reg;
	    endmethod
	    method Bit#(32) cnt_trigger2low();
		return trigger_cnt_trigger2low_reg;
	    endmethod
	    method Bit#(32) ext_debounce();
		return trigger_ext_debounce_reg;
	    endmethod
	    method Bit#(1) ext_polarity();
		return trigger_ext_polarity_reg;
	    endmethod
	    method Bit#(3) gen_polarity();
		return trigger_gen_polarity_reg;
	    endmethod
	endinterface
	interface ImageonFpnPrnu fpnPrnu;
	    method Bit#(256) prnu_values();
		return prnu_values_reg;
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
	        if (v == 1)
	            vsync_reg <= vsync_reg + 1;
	    endmethod
	    method Action hsync(Bit#(1) v);
	        if (v == 1)
	            hsync_reg <= hsync_reg + 1;
	    endmethod
	    method Action vblank(Bit#(1) v);
	        if (v == 1)
	            vblank_reg <= vblank_reg + 1;
	    endmethod
	    method Action hblank(Bit#(1) v);
	        if (v == 1)
	            hblank_reg <= hblank_reg + 1;
	    endmethod
	    method Action active_video(Bit#(1) v);
	        if (v == 1)
	            active_reg <= active_reg + 1;
	    endmethod
	    method Action video_data(Bit#(10) v);
	    endmethod
	endinterface
    endinterface
    interface ImageonControl control;
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
	interface Get rxfifo;
	    method ActionValue#(Bit#(32)) get() if (spi_rxfifo_empty_wire == 0);
		spi_rxfifo_ren_wire <= 1;
		return spi_rxfifo_dout_wire;
	    endmethod
	endinterface
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
	method Action set_decoder_code_tr(Bit#(10) v);
	    decoder_code_tr_reg <= v;
	endmethod
	method Action set_decoder_code_crc(Bit#(10) v);
	    decoder_code_crc_reg <= v;
	endmethod
	method Action set_crc_reset(Bit#(1) v);
	    crc_reset_reg <= v;
	endmethod
	method Action set_crc_initvalue(Bit#(1) v);
	    crc_initvalue_reg <= v;
	endmethod
	method Action set_remapper_write_cfg(Bit#(3) v);
	    remapper_write_cfg_reg <= v;
	endmethod
	method Action set_remapper_mode(Bit#(3) v);
	    remapper_mode_reg <= v;
	endmethod
	method Action set_trigger_enable(Bit#(3) v);
	    trigger_enable_reg <= v;
	endmethod
	method Action set_trigger_sync2readout(Bit#(3) v);
	    trigger_sync2readout_reg <= v;
	endmethod
	method Action set_trigger_readouttrigger(Bit#(1) v);
	    trigger_readouttrigger_reg <= v;
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
	method Action set_trigger_cnt_trigger1high(Bit#(32) v);
	    trigger_cnt_trigger1high_reg <= v;
	endmethod
	method Action set_trigger_cnt_trigger1low(Bit#(32) v);
	    trigger_cnt_trigger1low_reg <= v;
	endmethod
	method Action set_trigger_cnt_trigger2high(Bit#(32) v);
	    trigger_cnt_trigger2high_reg <= v;
	endmethod
	method Action set_trigger_cnt_trigger2low(Bit#(32) v);
	    trigger_cnt_trigger2low_reg <= v;
	endmethod
	method Action set_trigger_ext_debounce(Bit#(32) v);
	    trigger_ext_debounce_reg <= v;
	endmethod
	method Action set_trigger_ext_polarity(Bit#(1) v);
	    trigger_ext_polarity_reg <= v;
	endmethod
	method Action set_trigger_gen_polarity(Bit#(3) v);
	    trigger_gen_polarity_reg <= v;
	endmethod
	method Action set_prnu_values(Bit#(256) v);
	    prnu_values_reg <= v;
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
    endinterface
endmodule