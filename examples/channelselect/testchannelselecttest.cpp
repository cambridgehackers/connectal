#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <assert.h>
#include <semaphore.h>

#include "ChannelSelectTestRequestProxy.h"
#include "ChannelSelectTestIndicationWrapper.h"
#include "GeneratedTypes.h"

sem_t data_sem;
sem_t config_sem;

class ChannelSelectTestIndication : public ChannelSelectTestIndicationWrapper
{

public:
  ChannelSelectTestIndication(unsigned int id) : ChannelSelectTestIndicationWrapper(id){}

  virtual void ifreqData(unsigned dataRe, unsigned dataIm){
    fprintf(stderr, "read %x %x\n", dataRe, dataIm);
  }
  virtual void setDataResp(){
    fprintf(stderr, "setDataResp\n");
    sem_post(&data_sem);
  }
  virtual void setConfigResp(){
    fprintf(stderr, "setDataResp\n");
    sem_post(&config_sem);
  }
};

int main(int argc, const char **argv)
{

  ChannelSelectTestRequestProxy *device = 0;
  ChannelSelectTestIndication *indication = 0;
  sem_init(&data_sem, 0, 0);
  sem_init(&config_sem, 0, 0);
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  device = new ChannelSelectTestRequestProxy(IfcNames_ChannelSelectTestRequest);

  indication = new ChannelSelectTestIndication(IfcNames_ChannelSelectTestIndication);

  portalExec_start();

  fprintf(stderr, "Main::starting\n");

  device->setCoeff(0, 1<<21, 0);
  sem_wait(&config_sem);
  device->setCoeff(1, 1<<21, 0);
  sem_wait(&config_sem);
  device->setCoeff(2, 1<<21, 0);
  sem_wait(&config_sem);
  device->setCoeff(3, 1<<21, 0);
  sem_wait(&config_sem);
  device->setPhaseAdvance(0, 1 << 21);
  sem_wait(&config_sem);

  int i;
  for (i = 0; i < 128; i += 1) {
    device->rfreqDataWrite(1<<16, 0);   // should be re=1, im=0
    sem_wait(&data_sem);
  }

  fprintf(stderr, "Main::stopping\n");

  exit(0);
}
