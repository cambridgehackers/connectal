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
   interface Vector#(11,StdPortal) portalif;
   interface ImageonSensorPins sensorpins;
   interface ImageonSerdesPins serpins;
   interface HDMI#(Bit#(HdmiBits)) hdmi;
   interface XADC             xadc;
   interface MemServer#(PhysAddrWidth,64,1)   dmaif;
endinterface

(* synthesize *)
module mkImageCapture#(Clock fmc_imageon_clk1)(ImageCapture);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
   ImageClocks clk <- mkImageClocks(fmc_imageon_clk1);
   Clock hdmi_clock = clk.hdmi;
   Clock imageon_clock = clk.imageon;
   Reset hdmi_reset <- mkAsyncReset(2, defaultReset, hdmi_clock);
   Reset imageon_reset <- mkAsyncReset(2, defaultReset, imageon_clock);
   SyncPulseIfc vsyncPulse <- mkSyncHandshake(hdmi_clock, hdmi_reset, imageon_clock);

   // serdes: serial line protocol for wires from sensor (nothing sensor specific)
   ImageonSerdesIndicationProxy serdesIndicationProxy <- mkImageonSerdesIndicationProxy(ImageonSerdesIndicationH2S);
   ISerdes serdes <- mkISerdes(defaultClock, defaultReset, serdesIndicationProxy.ifc,
			clocked_by imageon_clock, reset_by imageon_reset);
   ImageonSerdesRequestWrapper serdesRequestWrapper <- mkImageonSerdesRequestWrapper(ImageonSerdesRequestS2H,serdes.request);
   ImageonCapture lImageonCapture <- mkImageonCapture(imageon_clock, imageon_reset, serdes.data, serdesIndicationProxy.ifc);
   ImageonCaptureRequestWrapper imageonCaptureWrapper <- mkImageonCaptureRequestWrapper(ImageonCaptureRequestS2H, lImageonCapture.request);
   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(MMUIndicationH2S);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(MMURequestS2H, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(MemServerIndicationH2S);
   MemServer#(PhysAddrWidth,64,1) dma <- mkMemServer(nil, lImageonCapture.dmaClient, cons(hostMMU,nil), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(MemServerRequestS2H, dma.request);

   // fromSensor: sensor specific processing of serdes input, resulting in pixels
   ImageonSensorIndicationProxy sensorIndicationProxy <- mkImageonSensorIndicationProxy(ImageonSensorIndicationH2S);
   ImageonSensor fromSensor <- mkImageonSensor(defaultClock, defaultReset, serdes.data, vsyncPulse.pulse(),
       hdmi_clock, hdmi_reset, sensorIndicationProxy.ifc, clocked_by imageon_clock, reset_by imageon_reset);
   ImageonSensorRequestWrapper sensorRequestWrapper <- mkImageonSensorRequestWrapper(ImageonSensorRequestS2H,fromSensor.request);

   // hdmi: output to display
   HdmiGeneratorIndicationProxy hdmiIndicationProxy <- mkHdmiGeneratorIndicationProxy(HdmiGeneratorIndicationH2S);
   HdmiGenerator#(Rgb888) lHdmiGenerator <- mkHdmiGenerator(defaultClock, defaultReset,
       vsyncPulse, hdmiIndicationProxy.ifc, clocked_by hdmi_clock, reset_by hdmi_reset);
   Rgb888ToYyuv converter <- mkRgb888ToYyuv(clocked_by hdmi_clock, reset_by hdmi_reset);
   mkConnection(lHdmiGenerator.rgb888, converter.rgb888);
   HDMI#(Bit#(HdmiBits)) hdmisignals <- mkHDMI(converter.yyuv, clocked_by hdmi_clock, reset_by hdmi_reset);
   HdmiGeneratorRequestWrapper hdmiRequestWrapper <- mkHdmiGeneratorRequestWrapper(HdmiGeneratorRequestS2H,lHdmiGenerator.request);

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
   interface Vector portalif = portals;

   interface ImageonSensorPins sensorpins = fromSensor.pins;
   interface ImageonSerdesPins serpins = serdes.pins;
   interface HDMI hdmi = hdmisignals;
   interface XADC             xadc;
        method Bit#(4) gpio;
            return { bozobit, hdmisignals.hdmi_vsync,
                hdmisignals.hdmi_hsync, hdmisignals.hdmi_de};
        endmethod
   endinterface
   interface dmaif = dma;
endmodule

interface ImageCapturePins;
   interface ImageonSensorPins pins;
   interface ImageonSerdesPins serpins;
   (* prefix="" *)
   interface HDMI#(Bit#(HdmiBits)) hdmi;
   method Action fmc_video_clk1(Bit#(1) v);
endinterface
module mkConnectalTop(ConnectalTop#(PhysAddrWidth,64,ImageCapturePins,1));
`ifndef BSIM
   B2C1 iclock <- mkB2C1();
   Clock iclock_buf <- mkClockBUFG(clocked_by iclock.c);
`else
   Clock iclock_buf <- exposeCurrentClock();
`endif
   ImageCapture ic <- mkImageCapture(iclock_buf);
   let ctrl_mux <- mkSlaveMux(ic.portalif);
   
   interface interrupt = getInterruptVector(ic.portalif);
   interface slave = ctrl_mux;
   interface masters = ic.dmaif.masters;
   interface ImageCapturePins pins;
`ifndef BSIM
       method Action fmc_video_clk1(Bit#(1) v);
           iclock.inputclock(v);
       endmethod
`endif
       interface ImageonSensorPins pins = ic.sensorpins;
       interface ImageonSerdesPins serpins = ic.serpins;
       interface HDMI hdmi = ic.hdmi;
   endinterface
endmodule : mkConnectalTop
