// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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
import BuildVector::*;
import Portal::*;
import PlatformTypes::*;
import CtrlMux::*;
import MemServer::*;
import MemTypes::*;
import ReadTest::*;
import ReadTestRequest::*;
import ReadTestIndication::*;

(* synthesize *)
module mkTile(Tile#(Empty,1,0));

   ReadTestIndicationProxy lReadTestIndicationProxy <- mkReadTestIndicationProxy(ReadTestIndicationH2S); //0
   ReadTest lReadTest <- mkReadTest(lReadTestIndicationProxy.ifc);
   ReadTestRequestWrapper lReadTestRequestWrapper <- mkReadTestRequestWrapper(ReadTestRequestS2H, lReadTest.request); //1
   
   Vector#(2,StdPortal) portal_vec;
   portal_vec[0] = lReadTestRequestWrapper.portalIfc;
   portal_vec[1] = lReadTestIndicationProxy.portalIfc;
   PhysMemSlave#(18,32) mem_portal <- mkSlaveMux(portal_vec);
   let interrupts <- mkInterruptMux(getInterruptVector(portal_vec));
   
   interface interrupt = interrupts;
   interface portals = mem_portal;
   interface readers = vec(lReadTest.dmaClient);
   interface writers = nil;
   interface ext = ?;

endmodule
