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
import ConnectalConfig::*;
import Vector::*;
import MemTypes::*;
import Pipe::*;
import ConnectalMemory::*;
import HostInterface::*;
`include "ConnectalProjectConfig.bsv"
import `PinTypeInclude::*;

interface PortalInterrupt#(numeric type dataWidth);
   method Bool status();
   method Bit#(dataWidth) channel();
endinterface

interface PortalSize;
   method Bit#(16) size(Bit#(16) methodNumber);
endinterface

typeclass PortalMessageSize#(type t);
   function Bit#(16) portalMessageSize(t p, Bit#(16) methodNumber);
endtypeclass

// implementation of a Portal as a group of Pipes
interface PipePortal#(numeric type numRequests, numeric type numIndications, numeric type slaveDataWidth);
   interface PortalSize messageSize;
   interface Vector#(numRequests, PipeIn#(Bit#(slaveDataWidth))) requests;
   //method PipeIn#(Bit#(slaveDataWidth)) requestsPipe(Integer a);
   interface Vector#(numIndications, PipeOut#(Bit#(slaveDataWidth))) indications;
   //method PipeOut#(Bit#(slaveDataWidth)) indicationsPipe(Integer a);
   interface PortalInterrupt#(slaveDataWidth) intr;
endinterface

// implementation of a Portal as a physical memory slave
interface MemPortal#(numeric type slaveAddrWidth, numeric type slaveDataWidth);
   interface PhysMemSlave#(slaveAddrWidth,slaveDataWidth) slave;
   interface ReadOnly#(Bool) interrupt;
   interface WriteOnly#(Bit#(slaveDataWidth)) num_portals;
endinterface

function ReadOnly#(Bool) getInterrupt(MemPortal#(_a,_d) p);
   return p.interrupt;
endfunction

function Vector#(MaxNumberOfPortals, ReadOnly#(Bool)) getInterruptVector(Vector#(numPortals, MemPortal#(_a,_d)) portals);
   Vector#(MaxNumberOfPortals, ReadOnly#(Bool)) interrupts = replicate(interface ReadOnly; method Bool _read(); return False; endmethod endinterface);
   for (Integer i = 0; i < valueOf(numPortals); i = i + 1)
      interrupts[i] = getInterrupt(portals[i]);
   return interrupts;
endfunction

interface SharedMemoryPortalConfig;
   method Action setSglId(Bit#(32) sglId);
endinterface

interface SharedMemoryPortal#(numeric type dataBusWidth);
   interface SharedMemoryPortalConfig cfg;
   interface ReadOnly#(Bool) interrupt;
endinterface

typedef MemPortal#(12,32) StdPortal;

interface ConnectalTop;
   interface PhysMemSlave#(18,32) slave;
   interface Vector#(MaxNumberOfPortals,ReadOnly#(Bool)) interrupt;
   interface Vector#(NumReadClients,MemReadClient#(DataBusWidth)) readers;
   interface Vector#(NumWriteClients,MemWriteClient#(DataBusWidth)) writers;
   interface `PinType pins;
endinterface
