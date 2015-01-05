
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

#include "HBridgeCtrlRequest.h"
#include "HBridgeCtrlIndication.h"
#include "GeneratedTypes.h"
 

bool finished = false;

 
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
    finished = (hbc_event_cnt >= 8);
  }
};



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


int main(int argc, const char **argv)
{
  HBridgeCtrlIndication *ind = new HBridgeCtrlIndication(IfcNames_ControllerIndication);
  HBridgeCtrlRequestProxy *device = new HBridgeCtrlRequestProxy(IfcNames_ControllerRequest);
  portalExec_start();

  uint32_t direction[2];
  uint32_t power[2];
  sleep(2);

  while(!finished){
    MOVE_FOREWARD(POWER_5);
    usleep(1000000);
    STOP;
    
    MOVE_BACKWARD(POWER_5);
    usleep(1000000);
    STOP;
    
    TURN_RIGHT(POWER_5);
    usleep(1000000);
    STOP;
    
    TURN_LEFT(POWER_5);
    usleep(1000000);
    STOP;
    sleep(1);
  }

}
