
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


#include "HBridgeCtrlIndication.h"
#include "GeneratedTypes.h"

uint8_t direction[2];
uint16_t power[2];

#define RIGHT 1
#define LEFT  0

#define CW   0
#define CCW  1

#define POWER_0  0x0000
#define POWER_1  0x0200
#define POWER_2  0x0400
#define POWER_3  0x0500
#define POWER_4  0x0600
#define POWER_5  0x0680
#define POWER_6  0x0700
#define POWER_7  0x0780
#define POWER_8  0x07FF

#define STOP {power[RIGHT] = POWER_0;  power[LEFT] = POWER_0; device->ctrl(power,direction);}
#define MOVE_FOREWARD(p) { direction[RIGHT] = CW;  direction[LEFT]  = CCW; power[RIGHT] = (p); power[LEFT] = (p); device->ctrl(power,direction);}
#define MOVE_BACKWARD(p) { direction[RIGHT] = CCW; direction[LEFT]  = CW;  power[RIGHT] = (p); power[LEFT] = (p); device->ctrl(power,direction);}
#define TURN_RIGHT(p)    { direction[RIGHT] = CCW; direction[LEFT]  = CCW; power[RIGHT] = (p); power[LEFT] = (p); device->ctrl(power,direction);}
#define TURN_LEFT(p)     { direction[RIGHT] = CW;  direction[LEFT]  = CW;  power[RIGHT] = (p); power[LEFT] = (p); device->ctrl(power,direction);}


class HBridgeCtrlIndication : public HBridgeCtrlIndicationWrapper
{
private:
  int hbc_event_cnt;
public:
  HBridgeCtrlIndication(int id) : HBridgeCtrlIndicationWrapper(id), hbc_event_cnt(0){}
  virtual void hbc_event( uint32_t e){
    hbc_event_cnt++;
    fprintf(stderr, "(%d) hbc_event: {", hbc_event_cnt);
    if (e & (1 << HBridgeCtrlEvent_Started))
      fprintf(stderr, "Started");
    if (e & (1 << HBridgeCtrlEvent_Stopped))
      fprintf(stderr, "Stopped");
    fprintf(stderr, "}\n");
  }
};
