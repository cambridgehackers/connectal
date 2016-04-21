// Copyright (c) 2016 Connectal Project

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

import BuildVector::*;
import Clocks::*;
import ClientServer::*;
import Connectable::*;
import Gearbox::*;
import GetPut::*;
import RS232::*;
import Vector::*;

import Pipe::*;
import Portal::*;
import SharedMemoryPortal::*;

import SerialPortalIfc::*;
import Echo::*;
import EchoRequest::*;
import EchoIndication::*;
import Simple::*;
import SimpleRequest::*;

interface SerialPortalTest;
   interface SerialPortalRequest request;
   interface EchoIndication echoIndication;
   interface SimpleRequest  simpleRequest;
   interface SerialPortalPins    pins;
endinterface

module mkSerialPortalTest#(SerialPortalIndication indication, EchoRequest echoRequest, SimpleRequest simpleRequest)(SerialPortalTest);

   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();

   // 250MHz clock
   //   9600 baud: divisor=26042
   // 115200 baud: divisor=134
   Reg#(Bit#(16)) divisor <- mkReg(134);
   UART#(16) uart <- mkUART(8, EVEN, STOP_1, divisor);

   SerialPortalDemux#(3) serialEchoRequestDemux <- mkSerialPortalDemux(Method); // why the asymmetry?
   let echoRequestInput <- mkEchoRequestInput();
   mkConnection(echoRequestInput.pipes, echoRequest);
   mkConnection(serialEchoRequestDemux.data, echoRequestInput.portalIfc.requests);

   SerialPortalDemux#(12) serialSimpleRequestDemux <- mkSerialPortalDemux(Method); // why the asymmetry?
   let simpleRequestInput <- mkSimpleRequestInput();
   mkConnection(simpleRequestInput.pipes, simpleRequest);
   mkConnection(serialSimpleRequestDemux.data, simpleRequestInput.portalIfc.requests);

   SerialPortalDemux#(2) portalDemux <- mkSerialPortalDemux(Portal);
   mkConnection(portalDemux.data[0], serialEchoRequestDemux.inputPipe);
   mkConnection(portalDemux.data[1], serialSimpleRequestDemux.inputPipe);

   Gearbox#(1,4,Bit#(8)) tx_gb <- mk1toNGearbox(clock,reset,clock,reset);
   mkConnection(uart.tx, toPut(toPipeIn(tx_gb)));
   mkConnection(mapPipe(pack,toPipeOut(tx_gb)), portalDemux.inputPipe);

   let echoIndicationOutput <- mkEchoIndicationOutput;
   Vector#(2,PipeOut#(Bit#(32))) echoMethodPipes <- genWithM(mkFramedMessagePipe(0, echoIndicationOutput.portalIfc, getEchoIndicationMessageSize));
   PipeOut#(Bit#(32)) serialEchoPortalPipe <- mkSerialPortalMux(echoMethodPipes);

   let simpleRequestOutput <- mkSimpleRequestOutput;
   Vector#(12,PipeOut#(Bit#(32))) simpleMethodPipes <- genWithM(mkFramedMessagePipe(1, simpleRequestOutput.portalIfc, getSimpleRequestMessageSize));
   PipeOut#(Bit#(32)) serialSimplePortalPipe <- mkSerialPortalMux(simpleMethodPipes);

   PipeOut#(Bit#(32)) portalMux <- mkSerialPortalMux(vec(serialEchoPortalPipe, serialSimplePortalPipe));

   Gearbox#(4,1,Bit#(8)) rx_gb <- mkNto1Gearbox(clock,reset,clock,reset);
   rule rl_rx_gb;
      let v <- toGet(portalMux).get();
      rx_gb.enq(unpack(v));
   endrule
   rule rl_rx;
      let char = rx_gb.first()[0]; rx_gb.deq();
      uart.rx.put(char);
      indication.rx(char);
   endrule

   interface SerialPortalRequest request;
      method Action setDivisor(Bit#(16) d);
	 divisor <= d;
      endmethod
   endinterface
   interface EchoIndication echoIndication = echoIndicationOutput.ifc;
   interface SimpleRequest  simpleRequest  = simpleRequestOutput.ifc;
   interface SerialPortalPins pins;
      interface uart = uart.rs232;
      interface deleteme_unused_clock = clock;
   endinterface
endmodule
