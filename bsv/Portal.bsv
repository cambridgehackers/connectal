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
import MemTypes::*;
import Leds::*;
import XADC::*;
import Pipe::*;

interface Portal#(numeric type numRequests, numeric type numIndications, numeric type slaveDataWidth);
   method Bit#(32) ifcId();
   method Bit#(32) ifcType();
   interface Vector#(numRequests, PipeIn#(Bit#(slaveDataWidth))) requests;
   interface Vector#(numRequests, Bit#(32))                      requestSizeBits;
   interface Vector#(numIndications, PipeOut#(Bit#(slaveDataWidth))) indications;
   interface Vector#(numIndications, Bit#(32))                       indicationSizeBits;
endinterface

interface MemPortal#(numeric type slaveAddrWidth, numeric type slaveDataWidth);
   method Bit#(32) ifcId();
   method Bit#(32) ifcType();
   interface MemSlave#(slaveAddrWidth,slaveDataWidth) slave;
   interface ReadOnly#(Bool) interrupt;
endinterface

function MemSlave#(_a,_d) getSlave(MemPortal#(_a,_d) p);
   return p.slave;
endfunction

function ReadOnly#(Bool) getInterrupt(MemPortal#(_a,_d) p);
   return p.interrupt;
endfunction

function Vector#(16, ReadOnly#(Bool)) getInterruptVector(Vector#(numPortals, MemPortal#(_a,_d)) portals);
   Vector#(16, ReadOnly#(Bool)) interrupts = replicate(interface ReadOnly; method Bool _read(); return False; endmethod endinterface);
   for (Integer i = 0; i < valueOf(numPortals); i = i + 1)
      interrupts[i] = getInterrupt(portals[i]);
   return interrupts;
endfunction

typedef MemPortal#(16,32) StdPortal;

interface PortalTop#(numeric type addrWidth, numeric type dataWidth, type pins, numeric type numMasters);
   interface MemSlave#(32,32) slave;
   interface Vector#(numMasters,MemMaster#(addrWidth, dataWidth)) masters;
   interface Vector#(16,ReadOnly#(Bool)) interrupt;
   interface LEDS             leds;
   interface pins             pins;
endinterface

typedef PortalTop#(addrWidth,64,Empty,0) StdPortalTop#(numeric type addrWidth);
typedef PortalTop#(addrWidth,64,Empty,1) StdPortalDmaTop#(numeric type addrWidth);

typeclass SynthesizablePortalTop#(numeric type addrWidth, numeric type dataWidth, type pins, numeric type numMasters);
   module mkSynthesizablePortalTop(PortalTop#(addrWidth,dataWidth,pins,numMasters) ifc);
endtypeclass
