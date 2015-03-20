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
import MemPortal::*;
import BlueNoC::*;
import BnocPortal::*;
import Simple::*;
import SimpleRequest::*;

typedef enum {FooRequest, FooIndication, SimpleRequestS2H, SimpleRequestH2S} IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalTop#(PhysAddrWidth));
   // the indications from simpleRequest will be connected to the request interface to simpleReuqest2
   SimpleRequestOutputPipes simple1Proxy <- mkSimpleRequestOutputPipes;
   Simple simple1 <- mkSimple(simple1Proxy.ifc);
   SimpleRequestWrapper simple1Wrapper <- mkSimpleRequestWrapper(SimpleRequestS2H,simple1.request);

   SimpleRequestProxy simple2Proxy <- mkSimpleRequestProxy(SimpleRequestH2S);
   Simple simple2 <- mkSimple(simple2Proxy.ifc);
   SimpleRequestInputPipes simple2Wrapper <- mkSimpleRequestInputPipes;
   mkConnection(simple2Wrapper, simple2.request);

   // now connect them via a BlueNoC link
   MsgSource#(4) simpleMsgSource <- mkPortalMsgSource(simple1Proxy.portalIfc);
   MsgSink#(4) simpleMsgSink <- mkPortalMsgSink(simple2Wrapper.portalIfc);
   mkConnection(simpleMsgSource, simpleMsgSink);

   Vector#(2,StdPortal) portals;
   portals[0] = simple2Proxy.portalIfc;
   portals[1] = simple1Wrapper.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);

   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = nil;
endmodule : mkConnectalTop

module mkBluenocTop(BluenocTop#(1,1));
   // instantiate user portals
   // the indications from simpleRequest will be connected to the request interface to simpleReuqest2
   SimpleRequestOutputPipes simple1Proxy <- mkSimpleRequestOutputPipes;
   Simple simple1 <- mkSimple(simple1Proxy.ifc);
   SimpleRequestInputPipes simple1Wrapper <- mkSimpleRequestInputPipes;
   mkConnection(simple1Wrapper, simple1.request);

   // now connect them via a BlueNoC link
   MsgSource#(4) simpleMsgSource <- mkPortalMsgSource(simple1Proxy.portalIfc);
   MsgSink#(4) simpleMsgSink <- mkPortalMsgSink(simple1Wrapper.portalIfc);

   Vector#(1,MsgSink#(4)) rs = cons(simpleMsgSink, nil);
   Vector#(1,MsgSource#(4)) is = cons(simpleMsgSource, nil);

   interface requests = rs;
   interface indications = is;
endmodule
