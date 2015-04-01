// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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
import Clocks :: *;
import FIFO::*;
import BRAMFIFO::*;
import DefaultValue::*;
import MemTypes::*;
import MemServer::*;
import MMU::*;
import ClientServer::*;
import Pipe::*;
import MemwriteEngine::*;
import Portal::*;
import HostInterface::*;
import CtrlMux::*;
import Portal::*;
import XADC::*;
import ImageonCapture::*;
import ImageonSerdesRequest::*;
import ImageonSerdesIndication::*;
import ImageonSensorRequest::*;
import ImageonSensorIndication::*;
import HdmiGeneratorRequest::*;
import HdmiGeneratorIndication::*;
import MemServerRequest::*;
import MMURequest::*;
import MemServerIndication::*;
import MMUIndication::*;
import ImageonCaptureRequest::*;
import IserdesDatadeser::*;
import IserdesDatadeserIF::*;
import Imageon::*;
import ImageonVita::*;
import HDMI::*;
import YUV::*;
import XilinxCells::*;
import ConnectalClocks::*;

typedef enum { ImageonSerdesRequestS2H, ImageonSensorRequestS2H, HdmiGeneratorRequestS2H, ImageonCaptureRequestS2H,
    ImageonSerdesIndicationH2S, ImageonSensorIndicationH2S, HdmiGeneratorIndicationH2S, MemServerIndicationH2S, MemServerRequestS2H, MMURequestS2H, MMUIndicationH2S} IfcNames deriving (Eq,Bits);

interface ImageCapture;
   interface ImageonSerdesRequest serdes_request;
   interface ImageonCaptureRequest capture_request;
   interface ImageonSensorRequest sensor_request;
   interface HdmiGeneratorRequest hdmi_request;
   interface Vector#(1, MemWriteClient#(64)) dmaClient;
   interface ImageCapturePins pins;
endinterface

//(* synthesize *)
module mkImageCapture#(ImageonSerdesIndication serdes_indication, ImageonSensorIndication sensor_ind, HdmiGeneratorIndication hdmi_ind)(ImageCapture);
`ifndef BSIM
   B2C1 iclock <- mkB2C1();
   Clock fmc_imageon_clk1 <- mkClockBUFG(clocked_by iclock.c);
`else
   Clock fmc_imageon_clk1 <- exposeCurrentClock();
`endif
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   ImageClocks clk <- mkImageClocks(fmc_imageon_clk1);
   Clock hdmi_clock = clk.hdmi;
   Clock imageon_clock = clk.imageon;
   Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
   Reset imageon_reset <- mkAsyncReset(2, defaultReset, imageon_clock);
   SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, imageon_clock);

   // serdes: serial line protocol for wires from sensor (nothing sensor specific)
   ISerdes serdes <- mkISerdes(defaultClock, defaultReset, serdes_indication,
			clocked_by imageon_clock, reset_by imageon_reset);
   ImageonCapture lImageonCapture <- mkImageonCapture(imageon_clock, imageon_reset, serdes.data, serdes_indication);

   // fromSensor: sensor specific processing of serdes input, resulting in pixels
   ImageonSensor fromSensor <- mkImageonSensor(defaultClock, defaultReset, serdes.data, vsyncPulse.pulse(),
       hdmi_clock, hdmi_reset, sensor_ind, clocked_by imageon_clock, reset_by imageon_reset);

   // hdmi: output to display
   HdmiGenerator#(Rgb888) lHdmiGenerator <- mkHdmiGenerator(defaultClock, defaultReset,
       vsyncPulse, hdmi_ind, clocked_by hdmi_clock, reset_by hdmi_reset);
   Rgb888ToYyuv converter <- mkRgb888ToYyuv(clocked_by hdmi_clock, reset_by hdmi_reset);
   mkConnection(lHdmiGenerator.rgb888, converter.rgb888);
   HDMI#(Bit#(HdmiBits)) hdmisignals <- mkHDMI(converter.yyuv, clocked_by hdmi_clock, reset_by hdmi_reset);

   Reg#(Bool) frameStart <- mkReg(False, clocked_by imageon_clock, reset_by imageon_reset);
   Reg#(Bit#(32)) frameCount <- mkReg(0, clocked_by imageon_clock, reset_by imageon_reset);
   SyncFIFOIfc#(Tuple2#(Bit#(2),Bit#(32))) frameStartSynchronizer <- mkSyncFIFO(2, imageon_clock, imageon_reset, defaultClock);

   rule frameStartRule;
       let monitor = fromSensor.monitor();
       Bool fs = unpack(monitor[0]);
       if (fs && !frameStart) begin
	  // start of frame?
	  // need to cross the clock domain
	  frameStartSynchronizer.enq(tuple2(monitor, frameCount));
	  frameCount <= frameCount + 1;
       end
      frameStart <= fs;
   endrule
   rule frameStartIndication;
      let tpl = frameStartSynchronizer.first();
      frameStartSynchronizer.deq();
      let monitor = tpl_1(tpl);
      let count = tpl_2(tpl);
      //captureIndicationProxy.ifc.frameStart(monitor, count);
   endrule

   Reg#(Bit#(10)) xsvi <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);
   rule xsviConnection;
       // copy data from sensor to hdmi output
       let xsvit <- fromSensor.get_data();
       xsvi <= xsvit;
   endrule
   rule xsviput;
       Bit#(32) pixel = {8'b0, xsvi[9:2], xsvi[9:2], xsvi[9:2]};
       lHdmiGenerator.pdata.put(pixel);
   endrule
   Reg#(Bit#(1)) bozobit <- mkReg(0, clocked_by hdmi_clock, reset_by hdmi_reset);
    rule bozobit_rule;
        bozobit <= ~bozobit;
    endrule

   interface serdes_request = serdes.request;
   interface capture_request =  lImageonCapture.request;
   interface sensor_request = fromSensor.request;
   interface hdmi_request = lHdmiGenerator.request;
   interface dmaClient = lImageonCapture.dmaClient;
   interface ImageCapturePins pins;
`ifndef BSIM
       method Action fmc_video_clk1(Bit#(1) v);
           iclock.inputclock(v);
       endmethod
`endif
       interface ImageonSensorPins pins = fromSensor.pins;
       interface ImageonSerdesPins serpins = serdes.pins;
       interface HDMI hdmi = hdmisignals;
   endinterface
endmodule

interface ImageCapturePins;
   interface ImageonSensorPins pins;
   interface ImageonSerdesPins serpins;
   (* prefix="" *)
   interface HDMI#(Bit#(HdmiBits)) hdmi;
   method Action fmc_video_clk1(Bit#(1) v);
endinterface
module mkConnectalTop(ConnectalTop#(PhysAddrWidth,64,ImageCapturePins,1));
   ImageonSerdesIndicationProxy serdesIndicationProxy <- mkImageonSerdesIndicationProxy(ImageonSerdesIndicationH2S);
   ImageonSensorIndicationProxy sensorIndicationProxy <- mkImageonSensorIndicationProxy(ImageonSensorIndicationH2S);
   HdmiGeneratorIndicationProxy hdmiIndicationProxy <- mkHdmiGeneratorIndicationProxy(HdmiGeneratorIndicationH2S);

   ImageCapture ic <- mkImageCapture(serdesIndicationProxy.ifc, sensorIndicationProxy.ifc, hdmiIndicationProxy.ifc);
   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(MMUIndicationH2S);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(MMURequestS2H, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(MemServerIndicationH2S);
   MemServer#(PhysAddrWidth,64,1) dma <- mkMemServer(nil, ic.dmaClient, cons(hostMMU,nil), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(MemServerRequestS2H, dma.request);

   ImageonSerdesRequestWrapper serdesRequestWrapper <- mkImageonSerdesRequestWrapper(ImageonSerdesRequestS2H, ic.serdes_request);
   ImageonCaptureRequestWrapper imageonCaptureWrapper <- mkImageonCaptureRequestWrapper(ImageonCaptureRequestS2H, ic.capture_request);
   ImageonSensorRequestWrapper sensorRequestWrapper <- mkImageonSensorRequestWrapper(ImageonSensorRequestS2H,ic.sensor_request);
   HdmiGeneratorRequestWrapper hdmiRequestWrapper <- mkHdmiGeneratorRequestWrapper(HdmiGeneratorRequestS2H,ic.hdmi_request);

   Vector#(11,StdPortal) portals;
   portals[0] = serdesRequestWrapper.portalIfc; 
   portals[1] = serdesIndicationProxy.portalIfc;
   portals[2] = sensorRequestWrapper.portalIfc; 
   portals[3] = sensorIndicationProxy.portalIfc; 
   portals[4] = hdmiRequestWrapper.portalIfc; 
   portals[5] = hdmiIndicationProxy.portalIfc; 
   portals[6] = hostMemServerRequestWrapper.portalIfc;
   portals[7] = hostMemServerIndicationProxy.portalIfc;
   portals[8] = imageonCaptureWrapper.portalIfc;
   portals[9] = hostMMURequestWrapper.portalIfc;
   portals[10] = hostMMUIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
   interface ImageCapturePins pins = ic.pins;
endmodule : mkConnectalTop
