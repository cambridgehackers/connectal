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
import FIFO::*;
import Connectable::*;
import CtrlMux::*;
import Portal::*;
import HostInterface::*;
import BlueNoC::*;
import BnocPortal::*;
import Simple::*;
import SimpleRequest::*;

typedef enum {IfcNames_FooRequest, IfcNames_FooIndication, IfcNames_SimpleRequestS2H, IfcNames_SimpleRequestH2S} IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalTop#(PhysAddrWidth));
   // the indications from simpleRequest will be connected to the request interface to simpleReuqest2
   SimpleRequestOutput lSimpleRequestOutput <- mkSimpleRequestOutput;
   Simple simple1 <- mkSimple(lSimpleRequestOutput.ifc);
   SimpleRequestWrapper lSimpleRequestInput <- mkSimpleRequestWrapper(IfcNames_SimpleRequestS2H,simple1.request);

   SimpleRequestProxy simple2Proxy <- mkSimpleRequestProxy(IfcNames_SimpleRequestH2S);
   Simple simple2 <- mkSimple(simple2Proxy.ifc);
   SimpleRequestInput simple2Wrapper <- mkSimpleRequestInput;
   mkConnection(simple2Wrapper.pipes, simple2.request);

   // now connect them via a BlueNoC link
   MsgSource#(4) simpleMsgSource <- mkPortalMsgIndication(lSimpleRequestOutput.portalIfc);
   MsgSink#(4) simpleMsgSink <- mkPortalMsgRequest(simple2Wrapper.portalIfc);
   mkConnection(simpleMsgSource, simpleMsgSink);

   Vector#(2,StdPortal) portals;
   portals[0] = simple2Proxy.portalIfc;
   portals[1] = lSimpleRequestInput.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);

   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = nil;
endmodule : mkConnectalTop
