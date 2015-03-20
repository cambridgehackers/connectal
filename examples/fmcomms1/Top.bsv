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
import Portal::*;
import HostInterface::*;
import CtrlMux::*;
import MemTypes::*;
import MemServerCompat::*;
import MMU::*;
import PS7LIB::*;
import PPS7LIB::*;
import FMComms1Request::*;
import FMComms1Indication::*;
import MemServerRequest::*;
import MMURequest::*;
import MemServerIndication::*;
import MMUIndication::*;
import BlueScopeEventPIORequest::*;
import BlueScopeEventPIOIndication::*;
import XilinxCells::*;
import ConnectalXilinxCells::*;
import ConnectalClocks::*;
import BlueScopeEventPIO::*;
import FMComms1ADC::*;
import FMComms1DAC::*;
import FMComms1::*;
import extraXilinxCells::*;

/* Duplicate def here, this is also in ZynqTop */

interface I2C_Pins;
   interface Inout#(Bit#(1)) scl;
   interface Inout#(Bit#(1)) sda;
endinterface


`define BlueScopeEventPIOSampleLength 512

typedef enum { BlueScopeEventPIORequest, BlueScopeEventPIOIndication, FMComms1Request, FMComms1Indication, HostMemServerIndication, HostMemServerRequest, HostMMURequest, HostMMUIndication} IfcNames deriving (Eq,Bits);

interface FMComms1Pins;
   interface FMComms1ADCPins adcpins;
   interface FMComms1DACPins dacpins;
   interface I2C_Pins         i2c1;
   method Bit#(1) ad9548_ref_p();
   method Bit#(1) ad9548_ref_n();
   
//   (* prefix="" *)
endinterface

/* clk1 is the FCLKCLK1 controlled by software */

module mkConnectalTop#(HostType host)(ConnectalTop#(PhysAddrWidth,64,FMComms1Pins,1));

   Clock clk1 = host.ps7.fclkclk[1];
   C2B ref_clk_as_bit <- mkC2B(clk1);
   Wire#(Bit#(1)) ref_clk_wire <- mkDWire(0);
   
   rule senddown_clk;
      ref_clk_wire <= ref_clk_as_bit.o();
   endrule

   
   DiffOut ref_clk <- mkxOBUFDS(ref_clk_wire);

   FMComms1ADC adc <- mkFMComms1ADC();
   FMComms1DAC dac <- mkFMComms1DAC();
   
   BlueScopeEventPIOIndicationProxy blueScopeEventPIOIndicationProxy <- mkBlueScopeEventPIOIndicationProxy(BlueScopeEventPIOIndication);
   BlueScopeEventPIOControl#(32) bs <- mkBlueScopeEventPIO(`BlueScopeEventPIOSampleLength, blueScopeEventPIOIndicationProxy.ifc);
   BlueScopeEventPIORequestWrapper blueScopeEventPIORequestWrapper <- mkBlueScopeEventPIORequestWrapper(BlueScopeEventPIORequest,bs.requestIfc);

`ifdef USE_FMC_I2C1
   Clock mainclock = host.ps7.fclkclk[0];
   Reset mainreset = host.ps7.fclkreset[0];
   let tscl1 <- mkIOBUF(~host.ps7.i2c[1].scltn, host.ps7.i2c[1].sclo, clocked_by mainclock, reset_by mainreset);
   let tsda1 <- mkIOBUF(~host.ps7.i2c[1].sdatn, host.ps7.i2c[1].sdao, clocked_by mainclock, reset_by mainreset);
   rule sdai1;
      host.ps7.i2c[1].sdai(tsda1.o);
      host.ps7.i2c[1].scli(tscl1.o);
   endrule
   rule watchi2c;
      let a = host.ps7.i2c[1].sclo();
      let b = host.ps7.i2c[1].scltn();
      let c = host.ps7.i2c[1].sdao();
      let d = host.ps7.i2c[1].sdatn();
      bs.bse.dataIn({a, b, tscl1.o, c, d, tsda1.o, 0});
   endrule
`endif

   FMComms1IndicationProxy fmcomms1IndicationProxy <- mkFMComms1IndicationProxy(FMComms1Indication);
   FMComms1 fmcomms1 <- mkFMComms1(fmcomms1IndicationProxy.ifc, dac.dac, adc.adc);
   FMComms1RequestWrapper fmcomms1RequestWrapper <- mkFMComms1RequestWrapper(FMComms1Request, fmcomms1.request);

   Vector#(1,  MemReadClient#(64))   readClients = cons(fmcomms1.readDmaClient, nil);
   Vector#(1, MemWriteClient#(64))  writeClients = cons(fmcomms1.writeDmaClient, nil);
   MMUIndicationProxy hostMMUIndicationProxy <- mkMMUIndicationProxy(HostMMUIndication);
   MMU#(PhysAddrWidth) hostMMU <- mkMMU(0, True, hostMMUIndicationProxy.ifc);
   MMURequestWrapper hostMMURequestWrapper <- mkMMURequestWrapper(HostMMURequest, hostMMU.request);

   MemServerIndicationProxy hostMemServerIndicationProxy <- mkMemServerIndicationProxy(HostMemServerIndication);
   MemServerCompat#(PhysAddrWidth,64,1) dma <- mkMemServerCompat(readClients, writeClients, cons(hostMMU,nil), hostMemServerIndicationProxy.ifc);
   MemServerRequestWrapper hostMemServerRequestWrapper <- mkMemServerRequestWrapper(HostMemServerRequest, dma.request);

   Vector#(8,StdPortal) portals;
   portals[0] = fmcomms1RequestWrapper.portalIfc;
   portals[1] = fmcomms1IndicationProxy.portalIfc; 
   portals[2] = hostMemServerRequestWrapper.portalIfc;
   portals[3] = hostMemServerIndicationProxy.portalIfc; 
   portals[4] = hostMMURequestWrapper.portalIfc;
   portals[5] = hostMMUIndicationProxy.portalIfc;
   portals[6] = blueScopeEventPIORequestWrapper.portalIfc;
   portals[7] = blueScopeEventPIOIndicationProxy.portalIfc; 
   let ctrl_mux <- mkSlaveMux(portals);
   

   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = dma.masters;
   interface FMComms1Pins pins;
`ifdef USE_FMC_I2C1
   interface I2C_Pins i2c1;
      interface Inout scl = tscl1.io;
      interface Inout sda = tsda1.io;
   endinterface
`endif
      interface FMComms1ADCPins adcpins = adc.pins;
      interface FMComms1ADCPins dacpins = dac.pins;
      method Bit#(1) ad9548_ref_p();
	 return(ref_clk.read_p());
      endmethod
   
      method Bit#(1) ad9548_ref_n();
	 return(ref_clk.read_n());
      endmethod
   endinterface
endmodule : mkConnectalTop
