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
import Dma::*;
import Leds::*;

interface Portal#(numeric type slaveAddrWidth, numeric type slaveDataWidth);
   method Bit#(32) ifcId();
   method Bit#(32) ifcType();
   interface MemSlave#(slaveAddrWidth,slaveDataWidth) slave;
   interface ReadOnly#(Bool) interrupt;
endinterface


function MemSlave#(_a,_d) getSlave(Portal#(_a,_d) p);
   return p.slave;
endfunction

function ReadOnly#(Bool) getInterrupt(Portal#(_a,_d) p);
   return p.interrupt;
endfunction

function Vector#(16, ReadOnly#(Bool)) getInterruptVector(Vector#(numPortals, Portal#(_a,_d)) portals);
   Vector#(16, ReadOnly#(Bool)) interrupts = replicate(interface ReadOnly; method Bool _read(); return False; endmethod endinterface);
   for (Integer i = 0; i < valueOf(numPortals); i = i + 1)
      interrupts[i] = getInterrupt(portals[i]);
   return interrupts;
endfunction

typedef Portal#(32,32) StdPortal;

interface PortalTop#(numeric type addrWidth, numeric type dataWidth, type pins);
   interface MemSlave#(32,32) slave;
   interface MemMaster#(addrWidth, dataWidth) master;
   interface Vector#(16,ReadOnly#(Bool))        interrupt;
   interface LEDS             leds;
   interface pins             pins;
endinterface

typedef PortalTop#(addrWidth,64,Empty)     StdPortalTop#(numeric type addrWidth);

typeclass SynthesizablePortalTop#(numeric type addrWidth, numeric type dataWidth, type pins);
   module mkSynthesizablePortalTop(PortalTop#(addrWidth,dataWidth,pins) ifc);
endtypeclass
