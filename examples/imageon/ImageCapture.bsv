
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
import GetPut::*;
import Connectable :: *;
import PCIE :: *; // ConnectableWithClocks
import Clocks :: *;
import XbsvSpi :: *;

import GetPutWithClocks :: *;
import Leds::*;
import Imageon::*;
import IserdesDatadeser::*;
import HDMI::*;
import AxiDma::*;
import Dma::*;
import PortalMemory::*;
import BlueScope::*;
import SensorToVideo::*;
import XilinxCells::*;
import XbsvXilinxCells::*;
import YUV::*;

interface CoreIndication;
    method Action debugind(Bit#(32) v);
    method Action spi_response(Bit#(32) v);
endinterface

interface CoreRequest;
    method Action set_debugreq(Bit#(32) v);
    method Action get_debugind();
    method Action put_spi_request(Bit#(32) v);
endinterface

interface ImageCaptureIndication;
    interface CoreIndication coreIndication;
    interface ImageonSensorIndication isIndication;
    interface ImageonSerdesIndication idIndication;
    interface HdmiInternalIndication coIndication;
    interface BlueScopeIndication bsIndication;
    interface DmaIndication dmaIndication;
endinterface

interface ImageCaptureRequest;
    interface CoreRequest coreRequest;
    interface ImageonSensorRequest isRequest;
    interface ImageonSerdesRequest idRequest;
    interface HdmiInternalRequest coRequest;
    interface BlueScopeRequest bsRequest;
    interface HDMI hdmi;
    interface DmaConfig dmaRequest;
    interface ImageonVita vita;
endinterface
 
module mkImageCaptureRequest#(Clock fmc_imageon_video_clk1, Clock processing_system7_1_fclk_clk3,
    ImageCaptureIndication indication)(ImageCaptureRequest);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    IDELAYCTRL idel <- mkIDELAYCTRL(2, clocked_by processing_system7_1_fclk_clk3);
    Clock imageon_video_clk1_buf_wire <- mkClockIBUFG(clocked_by fmc_imageon_video_clk1);
    MMCMHACK mmcmhack <- mkMMCMHACK(clocked_by imageon_video_clk1_buf_wire);
    Clock hdmi_clock <- mkClockBUFG(clocked_by mmcmhack.mmcmadv.clkout0);
    Clock imageon_clock <- mkClockBUFG(clocked_by mmcmhack.mmcmadv.clkout1);
    Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
    Reset imageon_reset <- mkAsyncReset(2, defaultReset, imageon_clock);
    ISerdes serdes <- mkISerdes(defaultClock, defaultReset, indication.idIndication,
        clocked_by imageon_clock, reset_by imageon_reset);
    AxiDma#(Bit#(64)) dma <- mkAxiDma(indication.dmaIndication);
    WriteChan#(Bit#(64)) dma_debug_write_chan = dma.write.writeChannels[1];
    BlueScope bsi <- mkSyncBlueScope(32, dma_debug_write_chan, indication.bsIndication,
		hdmi_clock, hdmi_reset, defaultClock, defaultReset);
    SPI#(Bit#(26)) spiController <- mkSPI(1000);
    SensorToVideo converter <- mkSensorToVideo(clocked_by hdmi_clock, reset_by hdmi_reset);
    SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, imageon_clock);
    HdmiGenerator hdmiGen <- mkHdmiGenerator(defaultClock, defaultReset,
        vsyncPulse, indication.coIndication, clocked_by hdmi_clock, reset_by hdmi_reset);
    ImageonSensor fromSensor <- mkImageonSensor(defaultClock, defaultReset, serdes.data, vsyncPulse.pulse(),
        hdmiGen.control, hdmi_clock, hdmi_reset, clocked_by imageon_clock, reset_by imageon_reset);

    rule xsviConnection;
        let xsvi <- fromSensor.get_data();
        //bsi.dataIn(extend(pack(xsvi)), extend(pack(xsvi)));
        //converter.in.put(xsvi);
        //let xvideo <- converter.out.get();
        //hdmiGen.rgb(xvideo);
        Bit#(64) pixel = {40'b0, xsvi[9:2], xsvi[9:2], xsvi[9:2]};
        hdmiGen.request.put(pixel);
    endrule

    rule spiControllerResponse;
        Bit#(26) v <- spiController.response.get();
        indication.coreIndication.spi_response(extend(v));
    endrule

    interface CoreRequest coreRequest;
        method Action set_debugreq(Bit#(32) v);
        endmethod
        method Action get_debugind();
            indication.coreIndication.debugind(fromSensor.control.get_debugind());
        endmethod
        method Action put_spi_request(Bit#(32) v);
            spiController.request.put(truncate(v));
        endmethod
    endinterface
    interface ImageonSensorRequest isRequest = fromSensor.control;
    interface ImageonSerdesRequest idRequest = serdes.control;
    interface BlueScopeRequest bsRequest = bsi.requestIfc;
    interface HDMI hdmi = hdmiGen.hdmi;
    interface HdmiInternalRequest coRequest = hdmiGen.control;
    interface ImageonVita vita;
        interface ImageonTopPins toppins;
            method Clock fbbozo();
                return mmcmhack.mmcmadv.clkfbout;
            endmethod
            method Action fbbozoin(Bit#(1) v);
                mmcmhack.mmcmadv.clkfbin(v);
            endmethod
        endinterface
        interface SpiPins spi = spiController.pins;
        interface ImageonSensorPins pins = fromSensor.pins;
        interface ImageonSerdesPins serpins = serdes.pins;
    endinterface
endmodule
