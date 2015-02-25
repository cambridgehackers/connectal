
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

import Leds::*;
import Vector::*;
import MaxSonarController::*;
import GyroController::*;
import ConnectalSpi::*;
import MemTypes::*;

interface ZedboardRobotPins;
   interface MaxSonarPins maxsonar_pins;
   interface SpiPins spi_pins;
endinterface

interface Controller;
   interface MaxSonarCtrlRequest maxsonar_req;
   interface GyroCtrlRequest gyro_req;
   interface ZedboardRobotPins pins;
   interface LEDS leds;
   interface Vector#(2,MemWriteClient#(64)) dmaClients;
endinterface

module mkController#(MaxSonarCtrlIndication maxsonar_ind, GyroCtrlIndication gyro_ind)(Controller);

   MaxSonarController msc <- mkMaxSonarController(maxsonar_ind);
   GyroController gc <- mkGyroController(gyro_ind);
   
   interface MaxSonarCtrlRequest maxsonar_req = msc.req;
   interface GyroCtrlRequest gyro_req = gc.req;
   interface ZedboardRobotPins pins;
      interface MaxSonarPins maxsonar_pins = msc.pins;
      interface SpiPins spi_pins = gc.spi;
   endinterface
   interface LEDS leds = msc.leds;
   interface dmaClients = cons(gc.dmaClient, cons(msc.dmaClient,nil));

endmodule
