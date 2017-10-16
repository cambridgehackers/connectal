
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
import ConnectalConfig::*;
import HostInterface::*;
import Vector::*;
import CtrlMux::*;
import Portal::*;
import ConnectalMemTypes::*;
import SDIORequest::*;
import SDIOResponse::*;
import SDIO::*;
import Leds::*;
import PS7LIB::*;

typedef enum {IfcNames_ControllerRequest, IfcNames_ControllerResponse} IfcNames deriving (Eq,Bits);

interface TestSDIO1Pins;
   interface SDIOPins sdio;
   interface LEDS leds;
endinterface

module mkConnectalTop#(HostInterface host)(ConnectalTop);

   SDIOResponseProxy cp <- mkSDIOResponseProxy(IfcNames_ControllerResponse);
   Controller controller <- mkController(cp.ifc, host.ps7.emiosdio1);
   SDIORequestWrapper cw <- mkSDIORequestWrapper(IfcNames_ControllerRequest, controller.req);
   
   Vector#(2,StdPortal) portals;
   portals[0] = cp.portalIfc;
   portals[1] = cw.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = nil;
   interface TestSDIO1Pins pins;
      interface sdio = controller.pins;
      interface leds = ?;
   endinterface

endmodule : mkConnectalTop

export TestSDIO1Pins;
export mkConnectalTop;

