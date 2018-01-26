
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
import MaxSonarController::*;
import GyroController::*;
import HBridgeController::*;
import ConnectalSpi::*;
import ConnectalMemTypes::*;
import Leds::*;

interface ZedboardRobotPins;
   interface MaxSonarPins maxsonar;
   interface SpiMasterPins#(1) spi;
   interface HBridge2Pins hbridge;
   interface LEDS leds;
endinterface

interface Controller;
   interface MaxSonarCtrlRequest maxsonar_req;
   interface GyroCtrlRequest gyro_req;
   interface HBridgeCtrlRequest hbridge_req;
   interface ZedboardRobotPins pins;
   interface MemWriteClient#(64) dmaClient;
endinterface

module mkController#(MaxSonarCtrlIndication maxsonar_ind, GyroCtrlIndication gyro_ind, HBridgeCtrlIndication hbridge_ind)(Controller);
   MaxSonarController msc <- mkMaxSonarController(maxsonar_ind);
   GyroController gc <- mkGyroController(gyro_ind);
   HBridgeController hbc <- mkHBridgeController(hbridge_ind);
   
   interface HBridgeCtrlRequest hbridge_req = hbc.req;
   interface MaxSonarCtrlRequest maxsonar_req = msc.req;
   interface GyroCtrlRequest gyro_req = gc.req;
   interface ZedboardRobotPins pins;
      interface maxsonar = msc.pins.maxsonar;
      interface spi = gc.pins.spi;
      interface hbridge = hbc.pins.hbridge;
      interface leds = hbc.pins.leds;
   endinterface
   interface dmaClient = gc.dmaClient;
endmodule
