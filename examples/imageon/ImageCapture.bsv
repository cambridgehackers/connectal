
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
import XilinxCells::*;
import XbsvXilinxCells::*;

interface CoreIndication;
    method Action iserdes_control_value(Bit#(32) v);
    method Action debugind(Bit#(32) v);
    method Action spi_response(Bit#(32) v);
endinterface

interface CoreRequest;
    method Action set_iserdes_control(Bit#(32) v);
    method Action get_iserdes_control();
    method Action set_decoder_control(Bit#(32) v);
    method Action set_host_oe(Bit#(1) v);
    method Action set_serdes_manual_tap(Bit#(10) v);
    method Action set_serdes_training(Bit#(10) v);
    method Action set_decoder_code_ls(Bit#(10) v);
    method Action set_decoder_code_le(Bit#(10) v);
    method Action set_decoder_code_fs(Bit#(10) v);
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
   interface HDMI hdmi;
   interface SpiPins spi;
   interface DMARequest dmaRequest;
   interface ImageonVita pins;
   interface ImageonTopPins toppins;
endinterface
 
module mkImageCaptureRequest#(Clock fmc_imageon_video_clk1, Clock processing_system7_1_fclk_clk3,
    Clock serdes_clock, Clock serdest_clock,
    ImageCaptureIndication indication)(ImageCaptureRequest) provisos (Bits#(XsviData,xsviDataWidth));

    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();

    IDELAYCTRL idel <- mkIDELAYCTRL(2, clocked_by processing_system7_1_fclk_clk3);
    Clock imageon_video_clk1_buf_wire <- mkClockIBUFG(clocked_by fmc_imageon_video_clk1);
    MMCMHACK mmcmhack <- mkMMCMHACK(clocked_by imageon_video_clk1_buf_wire);
    Clock hdmi_clock <- mkClockBUFG(clocked_by mmcmhack.mmcmadv.clkout0);
    Clock imageon_clock <- mkClockBUFG(clocked_by mmcmhack.mmcmadv.clkout1);

    Reset imageon_reset <- mkAsyncReset(2, defaultReset, imageon_clock);
    Reset serdes_reset <- mkAsyncReset(2, defaultReset, serdes_clock);
    Reset serdest_reset <- mkAsyncReset(2, defaultReset, serdes_clock);
    Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);

    ImageonSensor fromSensor <- mkImageonSensor(fmc_imageon_video_clk1,
        defaultClock, defaultReset, serdes_clock, serdes_reset, serdest_clock, serdest_reset,
        clocked_by imageon_clock, reset_by imageon_reset);
    ImageonVideo xsviFromSensor <- mkImageonVideo(imageon_clock, imageon_reset, defaultClock, defaultReset,
        fromSensor, clocked_by hdmi_clock, reset_by hdmi_reset);

    AxiDMA dma <- mkAxiDMA(indication.dmaIndication);
    WriteChan dma_debug_write_chan = dma.write.writeChannels[1];
    BlueScopeInternal bsi <- mkSyncBlueScopeInternal(32, dma_debug_write_chan, indication.bsIndication,
		hdmi_clock, hdmi_reset, defaultClock, defaultReset);
   
    SPI#(Bit#(26)) spiController <- mkSPI(1000);

    SensorToVideo converter <- mkSensorToVideo(clocked_by hdmi_clock, reset_by hdmi_reset);
    HdmiOut hdmiOut <- mkHdmiOut(clocked_by hdmi_clock, reset_by hdmi_reset);

    rule xsviConnection;
        let xsvi <- xsviFromSensor.out.get();
        //bsi.dataIn(extend(pack(xsvi)), extend(pack(xsvi)));
        converter.in.put(xsvi);
    endrule
    mkConnection(converter.out, hdmiOut.rgb);

    rule spiControllerResponse;
       Bit#(26) v <- spiController.response.get();
       indication.coreIndication.spi_response(extend(v));
    endrule

    interface CoreRequest coreRequest;
    method Action set_iserdes_control(Bit#(32) v);
        fromSensor.control.set_iserdes_control(v);
    endmethod
    method Action get_iserdes_control();
        indication.coreIndication.iserdes_control_value(fromSensor.control.get_iserdes_control());
    endmethod
    method Action set_decoder_control(Bit#(32) v);
        fromSensor.control.set_decoder_control(v);
    endmethod
    method Action set_host_oe(Bit#(1) v);
        fromSensor.control.set_host_oe(v);
    endmethod
    method Action set_serdes_manual_tap(Bit#(10) v);
        fromSensor.control.set_serdes_manual_tap(v);
    endmethod
    method Action set_serdes_training(Bit#(10) v);
        fromSensor.control.set_serdes_training(v);
    endmethod
    method Action set_decoder_code_ls(Bit#(10) v);
        fromSensor.control.set_decoder_code_ls(v);
    endmethod
    method Action set_decoder_code_le(Bit#(10) v);
        fromSensor.control.set_decoder_code_le(v);
    endmethod
    method Action set_decoder_code_fs(Bit#(10) v);
        fromSensor.control.set_decoder_code_fs(v);
    endmethod
    method Action set_trigger_default_freq(Bit#(32) v);
        fromSensor.control.set_trigger_default_freq(v);
    endmethod
    method Action set_trigger_cnt_trigger0high(Bit#(32) v);
        fromSensor.control.set_trigger_cnt_trigger0high(v);
    endmethod
    method Action set_trigger_cnt_trigger0low(Bit#(32) v);
        fromSensor.control.set_trigger_cnt_trigger0low(v);
    endmethod
    method Action set_syncgen_delay(Bit#(16) v);
        fromSensor.control.set_syncgen_delay(v);
    endmethod
    method Action set_syncgen_hactive(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_hactive(v);
    endmethod
    method Action set_syncgen_hfporch(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_hfporch(v);
    endmethod
    method Action set_syncgen_hsync(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_hsync(v);
    endmethod
    method Action set_syncgen_hbporch(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_hbporch(v);
    endmethod
    method Action set_syncgen_vactive(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_vactive(v);
    endmethod
    method Action set_syncgen_vfporch(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_vfporch(v);
    endmethod
    method Action set_syncgen_vsync(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_vsync(v);
    endmethod
    method Action set_syncgen_vbporch(Bit#(16) v);
        xsviFromSensor.control.set_syncgen_vbporch(v);
    endmethod
    method Action set_debugreq(Bit#(32) v);
    endmethod
    method Action get_debugind();
        indication.coreIndication.debugind(fromSensor.control.get_debugind());
    endmethod
    method Action put_spi_request(Bit#(32) v);
        spiController.request.put(truncate(v));
    endmethod
    endinterface
    interface ImageonTopPins toppins;
        method Clock fbbozo();
            return mmcmhack.mmcmadv.clkfbout;
        endmethod
        method Action fbbozoin(Bit#(1) v);
            mmcmhack.mmcmadv.clkfbin(v);
        endmethod
    endinterface
   interface BlueScopeRequest bsRequest = bsi.requestIfc;
   interface HDMI hdmi = hdmiOut.hdmi;
   interface SpiPins spi = spiController.pins;
   interface ImageonVita pins = fromSensor.pins;
endmodule
