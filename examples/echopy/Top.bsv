/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
import Vector::*;
import Portal::*;
import CtrlMux::*;
import ConnectalConfig::*;
import EchoIndication::*;
import EchoRequest::*;
import Echo::*;

typedef enum {IfcNames_EchoIndication, IfcNames_EchoRequest} IfcNames deriving (Eq,Bits);

module mkConnectalTop(ConnectalTop);

   // instantiate user portals
   EchoIndicationProxy echoIndicationProxy <- mkEchoIndicationProxy(IfcNames_EchoIndication);
   EchoRequestInternal echoRequestInternal <- mkEchoRequestInternal(echoIndicationProxy.ifc);
   EchoRequestWrapper echoRequestWrapper <- mkEchoRequestWrapper(IfcNames_EchoRequest,echoRequestInternal.ifc);
   
   Vector#(2,StdPortal) portals;
   portals[0] = echoRequestWrapper.portalIfc; 
   portals[1] = echoIndicationProxy.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
endmodule : mkConnectalTop
