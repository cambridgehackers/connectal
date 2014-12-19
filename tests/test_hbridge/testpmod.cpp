
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

#include "HBridgeCtrlRequest.h"
#include "HBridgeCtrlIndication.h"
#include "GeneratedTypes.h"


class HBridgeCtrlIndication : public HBridgeCtrlIndicationWrapper
{
public:
  HBridgeCtrlIndication(int id) : HBridgeCtrlIndicationWrapper(id) {}
  virtual void ctrl ( const uint32_t i, const uint32_t p, const uint32_t d ) {
    fprintf(stderr, "HBridgeCtrlIndication::ctrl(i=%04x, p=%04x, d=%d)\n", i,p,d);
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

void slow_start(int idx, int direction, HBridgeCtrlRequestProxy *device){
  device->ctrl(idx,POWER_1,direction);
  sleep(1);
  device->ctrl(idx,POWER_2,direction);
  sleep(1);
  device->ctrl(idx,POWER_3,direction);
  sleep(1);
  device->ctrl(idx,POWER_4,direction);
  sleep(1);
  device->ctrl(idx,POWER_5,direction);
  sleep(1);
  device->ctrl(idx,POWER_6,direction);
  sleep(1);
  device->ctrl(idx,POWER_7,direction);
  sleep(1);
  device->ctrl(idx,POWER_8,direction);
}

void quick_start(int idx, int direction, HBridgeCtrlRequestProxy *device){
  device->ctrl(idx,POWER_8,direction);
}
void quick_stop(int idx, int direction, HBridgeCtrlRequestProxy *device){
  device->ctrl(idx,POWER_0,direction);
}

int main(int argc, const char **argv)
{
  HBridgeCtrlIndication *ind = new HBridgeCtrlIndication(IfcNames_ControllerIndication);
  HBridgeCtrlRequestProxy *device = new HBridgeCtrlRequestProxy(IfcNames_ControllerRequest);

  portalExec_start();

  slow_start(LEFT,CCW,device);
  sleep(1);
  quick_stop(LEFT,CCW,device);

  slow_start(RIGHT,CCW,device);
  sleep(1);
  quick_stop(RIGHT,CCW,device);

  slow_start(LEFT,CW,device);
  sleep(1);
  quick_stop(LEFT,CW,device);

  slow_start(RIGHT,CW,device);
  sleep(1);
  quick_stop(RIGHT,CW,device);

  sleep(1);
}
