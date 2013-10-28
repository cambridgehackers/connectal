
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
import GetPut::*;
import Connectable :: *;
import PCIE :: *; // ConnectableWithClocks
import Clocks :: *;
import XbsvSpi :: *;

import GetPutWithClocks :: *;
import Zynq::*;
import Imageon::*;
import HDMI::*;
import AxiDMA::*;
import BlueScope::*;
import SensorToVideo::*;

interface CoreIndication;
    method Action iserdes_control_value(Bit#(32) v);
    method Action debugind(Bit#(32) v);
    method Action spi_response(Bit#(32) v);
endinterface


interface CoreRequest;
    method Action set_iserdes_control(Bit#(32) v);
    method Action get_iserdes_control();
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
    method Action get_debugind();
    method Action put_spi_request(Bit#(32) v);
endinterface

interface ImageCaptureIndication;
    interface CoreIndication coreIndication;
    interface BlueScopeIndication bsIndication;
    interface DMAIndication dmaIndication;
endinterface

interface ImageCaptureRequest;
   interface CoreRequest coreRequest;
   interface BlueScopeRequest bsRequest;
   interface ImageonVita imageon;
   interface ImageonSerdes serdes;
   interface ImageonSensorControl sensor;
   interface HDMI hdmi;
   interface SpiPins spi;
   interface DMARequest dmaRequest;
endinterface
 
module mkImageCaptureRequest#(Clock imageon_clock, Clock serdes_clock, Clock serdest_clock, Clock hdmi_clock, 
    ImageCaptureIndication indication)(ImageCaptureRequest) provisos (Bits#(XsviData,xsviDataWidth));

    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    Reset imageon_reset <- mkAsyncReset(2, defaultReset, imageon_clock);
    Reset serdes_reset <- mkAsyncReset(2, defaultReset, serdes_clock);
    Reset serdest_reset <- mkAsyncReset(2, defaultReset, serdes_clock);
    Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);

    ImageonVitaController imageonVita <- mkImageonVitaController(hdmi_clock, hdmi_reset, imageon_clock, imageon_reset, serdes_clock, serdes_reset);
    ImageonControl control = imageonVita.control;
    let imageon_vita_clock_binder <- mkClockBinder(imageonVita.host, clocked_by hdmi_clock);
    let imageon_vitas_clock_binder <- mkClockBinder(imageonVita.hosts, clocked_by imageon_clock);
    let imageon_serdes_clock_binder <- mkClockBinder(imageonVita.serdes, clocked_by serdes_clock);

    ImageonSensor fromSensor <- mkImageonSensor(hdmi_clock, hdmi_reset, serdes_clock, serdes_reset, serdest_clock, serdest_reset, imageon_vitas_clock_binder,
        imageon_serdes_clock_binder, clocked_by imageon_clock, reset_by imageon_reset);
    ImageonXsviFromSensor xsviFromSensor <- mkImageonXsviFromSensor(imageon_clock, imageon_reset, imageon_vita_clock_binder,
        fromSensor,
        clocked_by hdmi_clock, reset_by hdmi_reset);
SensorDiffData foo <- mkGetSensorDiffData(serdes_clock, fromSensor.in, imageon_vitas_clock_binder,
        imageon_serdes_clock_binder, clocked_by imageon_clock, reset_by imageon_reset);

    Reg#(Bit#(32)) debugind_value <- mkSyncReg(0, imageon_clock, imageon_reset, defaultClock);
    rule copydebugval;
        debugind_value <= fromSensor.in.get_debugind();
    endrule

    AxiDMA dma <- mkAxiDMA(indication.dmaIndication);
    WriteChan dma_debug_write_chan = dma.write.writeChannels[1];
    BlueScopeInternal bsi <- mkSyncBlueScopeInternal(32, dma_debug_write_chan, indication.bsIndication,
					             hdmi_clock, hdmi_reset, defaultClock, defaultReset);
   
    SPI#(Bit#(26)) spiController <- mkSPI(1000);

    SensorToVideo converter <- mkSensorToVideo(clocked_by hdmi_clock, reset_by hdmi_reset);
    HdmiOut hdmiOut <- mkHdmiOut(clocked_by hdmi_clock, reset_by hdmi_reset);

    // hdmi clock domain
    //mkConnection(xsviFromSensor.out, converter.in);
    rule xsviConnection;
        let xsvi <- xsviFromSensor.out.get();
        //bsi.dataIn(extend(pack(xsvi)), extend(pack(xsvi)));
        converter.in.put(xsvi);
    endrule
    // hdmi clock domain
    mkConnection(converter.out, hdmiOut.rgb);

    rule spiControllerResponse;
       Bit#(26) v <- spiController.response.get();
       indication.coreIndication.spi_response(extend(v));
    endrule

    interface CoreRequest coreRequest;

    method Action set_iserdes_control(Bit#(32) v);
        control.set_iserdes_control(v);
    endmethod
    method Action get_iserdes_control();
        indication.coreIndication.iserdes_control_value(control.get_iserdes_control());
    endmethod

    method Action set_decoder_control(Bit#(32) v);
        control.set_decoder_control(v);
    endmethod

    method Action set_triggen_control(Bit#(32) v);
        control.set_triggen_control(v);
    endmethod

    method Action set_host_oe(Bit#(1) v);
        control.set_host_oe(v);
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
    method Action set_trigger_enable(Bit#(3) v);
        control.set_trigger_enable(v);
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
    method Action set_debugreq(Bit#(32) v);
        control.set_debugreq(v);
    endmethod
    method Action get_debugind();
        indication.coreIndication.debugind(debugind_value);
    endmethod
    method Action put_spi_request(Bit#(32) v);
        spiController.request.put(truncate(v));
    endmethod

    endinterface
   interface BlueScopeRequest bsRequest = bsi.requestIfc;
   interface ImageonVita imageon = imageon_vitas_clock_binder;
   interface ImageonSerdes serdes = imageonVita.serdes;
   interface ImageonSensorControl sensor = fromSensor.in;
   interface HDMI hdmi = hdmiOut.hdmi;
   interface SpiPins spi = spiController.pins;
endmodule
