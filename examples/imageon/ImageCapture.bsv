
// Copyright (c) 2013 Nokia, Inc.
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

import FIFO::*;
import SPI::*;
import GetPut::*;

import Zynq::*;
import Imageon::*;
import HDMI::*;
import BlueScope::*;

interface ImageCaptureIndications;
    method Action spi_control_value(Bit#(32) v);
    method Action iserdes_control_value(Bit#(32) v);
    method Action decoder_control_value(Bit#(32) v);
    method Action crc_control_value(Bit#(32) v);
    method Action crc_status_value(Bit#(32) v);
    method Action remapper_control_value(Bit#(32) v);
    method Action triggen_control_value(Bit#(32) v);

    method Action rxfifo_value(Bit#(32) v);
endinterface

interface ImageCapture;
    method Action set_spi_control(Bit#(32) v);
    method Action get_spi_control();
    method Action set_iserdes_control(Bit#(32) v);
    method Action get_iserdes_control();
    method Action set_decoder_control(Bit#(32) v);
    method Action get_decoder_control();
    method Action set_crc_control(Bit#(32) v);
    method Action get_crc_control();
    method Action get_crc_status();
    method Action set_remapper_control(Bit#(32) v);
    method Action get_remapper_control();
    method Action set_triggen_control(Bit#(32) v);
    method Action get_triggen_control();

    method Action set_host_vita_reset(Bit#(1) v);
    method Action set_host_oe(Bit#(1) v);

    method Action set_spi_reset(Bit#(1) v);
    method Action set_spi_timing(Bit#(16) v);
    method Action spi_txfifo_put(Bit#(32) v);
    method Action spi_rxfifo_get();

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
    method Action set_prnu_values(Bit#(64) v0, Bit#(64) v1, Bit#(64) v2, Bit#(64) v3);
    method Action set_syncgen_delay(Bit#(16) v);
    method Action set_syncgen_hactive(Bit#(16) v);
    method Action set_syncgen_hfporch(Bit#(16) v);
    method Action set_syncgen_hsync(Bit#(16) v);
    method Action set_syncgen_hbporch(Bit#(16) v);
    method Action set_syncgen_vactive(Bit#(16) v);
    method Action set_syncgen_vfporch(Bit#(16) v);
    method Action set_syncgen_vsync(Bit#(16) v);
    method Action set_syncgen_vbporch(Bit#(16) v);

    interface ImageonVita imageon;
//    interface HDMI hdmi;
endinterface

module mkImageCapture#(//Clock hdmi_clock, 
       ImageCaptureIndications indications)(ImageCapture);
    ImageonVitaController imageonVita <- mkImageonVitaController();
    ImageonControl control = imageonVita.control;
    //BlueScope#(96,96) spiBlueScope <- mkBlueScope(1024);

    method Action set_spi_control(Bit#(32) v);
        control.set_spi_control(v);
    endmethod
    method Action get_spi_control();
        indications.spi_control_value(control.get_spi_control());
    endmethod

    method Action set_iserdes_control(Bit#(32) v);
        control.set_iserdes_control(v);
    endmethod
    method Action get_iserdes_control();
        indications.iserdes_control_value(control.get_iserdes_control());
    endmethod

    method Action set_decoder_control(Bit#(32) v);
        control.set_decoder_control(v);
    endmethod
    method Action get_decoder_control();
        indications.decoder_control_value(control.get_decoder_control());
    endmethod

    method Action set_crc_control(Bit#(32) v);
        control.set_crc_control(v);
    endmethod
    method Action get_crc_control();
        indications.crc_control_value(control.get_crc_control());
    endmethod

    method Action get_crc_status();
        indications.crc_status_value(control.get_crc_status());
    endmethod

    method Action set_remapper_control(Bit#(32) v);
        control.set_remapper_control(v);
    endmethod
    method Action get_remapper_control();
        indications.remapper_control_value(control.get_remapper_control());
    endmethod

    method Action set_triggen_control(Bit#(32) v);
        control.set_triggen_control(v);
    endmethod
    method Action get_triggen_control();
        indications.triggen_control_value(control.get_triggen_control());
    endmethod


    method Action set_host_vita_reset(Bit#(1) v);
        control.set_host_vita_reset(v);
    endmethod
    method Action set_host_oe(Bit#(1) v);
        control.set_host_oe(v);
    endmethod
    method Action set_spi_reset(Bit#(1) v);
        control.set_spi_reset(v);
    endmethod
    method Action set_spi_timing(Bit#(16) v);
        control.set_spi_timing(v);
    endmethod
    method Action spi_txfifo_put(Bit#(32) v);
        control.txfifo.put(v);
    endmethod
    method Action spi_rxfifo_get();
        Bit#(32) v <- control.rxfifo.get();
        indications.rxfifo_value(v);
    endmethod
    method Action set_serdes_reset(Bit#(1) v);
        control.set_serdes_reset(v);
    endmethod
    method Action set_serdes_auto_align(Bit#(1) v);
        control.set_serdes_auto_align(v);
    endmethod
    method Action set_serdes_align_start(Bit#(1) v);
        control.set_serdes_align_start(v);
    endmethod
    method Action set_serdes_fifo_enable(Bit#(1) v);
        control.set_serdes_fifo_enable(v);
    endmethod
    method Action set_serdes_manual_tap(Bit#(10) v);
        control.set_serdes_manual_tap(v);
    endmethod
    method Action set_serdes_training(Bit#(10) v);
        control.set_serdes_training(v);
    endmethod
    method Action set_decoder_reset(Bit#(1) v);
        control.set_decoder_reset(v);
    endmethod
    method Action set_decoder_enable(Bit#(1) v);
        control.set_decoder_enable(v);
    endmethod
    method Action set_decoder_startoddeven(Bit#(32) v);
        control.set_decoder_startoddeven(v);
    endmethod
    method Action set_decoder_code_ls(Bit#(10) v);
        control.set_decoder_code_ls(v);
    endmethod
    method Action set_decoder_code_le(Bit#(10) v);
        control.set_decoder_code_le(v);
    endmethod
    method Action set_decoder_code_fs(Bit#(10) v);
        control.set_decoder_code_fs(v);
    endmethod
    method Action set_decoder_code_fe(Bit#(10) v);
        control.set_decoder_code_fe(v);
    endmethod
    method Action set_decoder_code_bl(Bit#(10) v);
        control.set_decoder_code_bl(v);
    endmethod
    method Action set_decoder_code_img(Bit#(10) v);
        control.set_decoder_code_img(v);
    endmethod
    method Action set_decoder_code_tr(Bit#(10) v);
        control.set_decoder_code_tr(v);
    endmethod
    method Action set_decoder_code_crc(Bit#(10) v);
        control.set_decoder_code_crc(v);
    endmethod
    method Action set_crc_reset(Bit#(1) v);
        control.set_crc_reset(v);
    endmethod
    method Action set_crc_initvalue(Bit#(1) v);
        control.set_crc_initvalue(v);
    endmethod
    method Action set_remapper_write_cfg(Bit#(3) v);
        control.set_remapper_write_cfg(v);
    endmethod
    method Action set_remapper_mode(Bit#(3) v);
        control.set_remapper_mode(v);
    endmethod
    method Action set_trigger_enable(Bit#(3) v);
        control.set_trigger_enable(v);
    endmethod
    method Action set_trigger_sync2readout(Bit#(3) v);
        control.set_trigger_sync2readout(v);
    endmethod
    method Action set_trigger_readouttrigger(Bit#(1) v);
        control.set_trigger_readouttrigger(v);
    endmethod
    method Action set_trigger_default_freq(Bit#(32) v);
        control.set_trigger_default_freq(v);
    endmethod
    method Action set_trigger_cnt_trigger0high(Bit#(32) v);
        control.set_trigger_cnt_trigger0high(v);
    endmethod
    method Action set_trigger_cnt_trigger0low(Bit#(32) v);
        control.set_trigger_cnt_trigger0low(v);
    endmethod
    method Action set_trigger_cnt_trigger1high(Bit#(32) v);
        control.set_trigger_cnt_trigger1high(v);
    endmethod
    method Action set_trigger_cnt_trigger1low(Bit#(32) v);
        control.set_trigger_cnt_trigger1low(v);
    endmethod
    method Action set_trigger_cnt_trigger2high(Bit#(32) v);
        control.set_trigger_cnt_trigger2high(v);
    endmethod
    method Action set_trigger_cnt_trigger2low(Bit#(32) v);
        control.set_trigger_cnt_trigger2low(v);
    endmethod
    method Action set_trigger_ext_debounce(Bit#(32) v);
        control.set_trigger_ext_debounce(v);
    endmethod
    method Action set_trigger_ext_polarity(Bit#(1) v);
        control.set_trigger_ext_polarity(v);
    endmethod
    method Action set_trigger_gen_polarity(Bit#(3) v);
        control.set_trigger_gen_polarity(v);
    endmethod
    method Action set_prnu_values(Bit#(64) v0, Bit#(64) v1, Bit#(64) v2, Bit#(64) v3);
        Bit#(256) bitvec;
	bitvec[63:0] = v0;
	bitvec[127:64] = v1;
	bitvec[191:128] = v2;
	bitvec[255:192] = v3;
        control.set_prnu_values(bitvec);
    endmethod
    method Action set_syncgen_delay(Bit#(16) v);
        control.set_syncgen_delay(v);
    endmethod
    method Action set_syncgen_hactive(Bit#(16) v);
        control.set_syncgen_hactive(v);
    endmethod
    method Action set_syncgen_hfporch(Bit#(16) v);
        control.set_syncgen_hfporch(v);
    endmethod
    method Action set_syncgen_hsync(Bit#(16) v);
        control.set_syncgen_hsync(v);
    endmethod
    method Action set_syncgen_hbporch(Bit#(16) v);
        control.set_syncgen_hbporch(v);
    endmethod
    method Action set_syncgen_vactive(Bit#(16) v);
        control.set_syncgen_vactive(v);
    endmethod
    method Action set_syncgen_vfporch(Bit#(16) v);
        control.set_syncgen_vfporch(v);
    endmethod
    method Action set_syncgen_vsync(Bit#(16) v);
        control.set_syncgen_vsync(v);
    endmethod
    method Action set_syncgen_vbporch(Bit#(16) v);
        control.set_syncgen_vbporch(v);
    endmethod

    interface ImageonVita imageon = imageonVita.host;
endmodule
