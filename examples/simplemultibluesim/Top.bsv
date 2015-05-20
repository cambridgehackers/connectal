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
import GetPut::*;
import Pipe::*;
import Connectable::*;
import CtrlMux::*;
import Portal::*;
import HostInterface::*;
import CnocPortal::*;
import BsimLink::*;
import Simple::*;
import Link::*;
import SimpleIF::*;

typedef enum {IfcNames_SimpleRequest, IfcNames_SimpleIndication, IfcNames_LinkRequest} IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalTop#(PhysAddrWidth));
   // the indications from simpleRequest will be connected to the request interface to simpleReuqest2
   SimpleProxyPortal simple1IndicationProxy <- mkSimpleProxyPortal(IfcNames_SimpleIndication);
   Simple simple1 <- mkSimple(simple1IndicationProxy.ifc);
   SimpleWrapper simple1RequestWrapper <- mkSimpleWrapper(IfcNames_SimpleRequest,simple1);

   SimpleProxy simple2IndicationProxy <- mkSimpleProxy(IfcNames_SimpleIndication);
   Simple simple2 <- mkSimple(simple2IndicationProxy.ifc);
   SimpleWrapperPortal simple2RequestWrapper <- mkSimpleWrapperPortal(IfcNames_SimpleRequest, simple2);

   // now connect them via a Cnoc link
   BsimLink#(32) link <- mkBsimLink("simplelink");
   mkConnection(simple1IndicationProxy.portalIfc, link);
   mkConnection(link, simple2RequestWrapper.portalIfc);

   Link linkRequest = (interface Link;
		       method Action start(Bool l);
			  link.start(l);
		       endmethod
		       endinterface);
   LinkWrapper linkWrapper <- mkLinkWrapper(IfcNames_LinkRequest, linkRequest);

   Vector#(3,StdPortal) portals;
   portals[0] = simple2IndicationProxy.portalIfc;
   portals[1] = simple1RequestWrapper.portalIfc;
   portals[2] = linkWrapper.portalIfc;
   let ctrl_mux <- mkSlaveMux(portals);

   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = nil;
endmodule : mkConnectalTop
