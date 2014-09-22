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

class DDSTestIndication : public DDSTestIndicationWrapper
{

public:
  DDSTestIndication(unsigned int id) : DDSTestIndicationWrapper(id){}

  virtual void ddsData(unsigned phase, unsigned dataRe, unsigned dataIm){
    fprintf("data %d %X %x\n", phase, dataRe, dataIM);
    sem_post(&data_sem);
  }
  virtual void setConfigResp(){
    fprintf(stderr, "dds.setDataResp\n");
    sem_post(&config_sem);
  }
  
};

int main(int argc, const char **argv)
{

  ChannelSelectTestRequestProxy *ctdevice = 0;
  ChannelSelectTestIndication *ctindication = 0;
  DDSTestRequestProxy *ctdevice = 0;
  DDSTestIndication *ctindication = 0;
  sem_init(&data_sem, 0, 0);
  sem_init(&config_sem, 0, 0);
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  ctdevice = new ChannelSelectTestRequestProxy(IfcNames_ChannelSelectTestRequest);

  ctindication = new ChannelSelectTestIndication(IfcNames_ChannelSelectTestIndication);

  ddsdevice = new DDSTestRequestProxy(IfcNames_DDSTestRequest);

  ddsindication = new DDSTestIndication(IfcNames_DDSTestIndication);

  portalExec_start();

  fprintf(stdout, "DDSTest\n");
  ddsdevice.setPhaseAdvance(1, 0);

  for (i = 0; i < 2048; i += 1)
    ddsdevice.getData();


  fprintf(stdout, "Main::starting\n");

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
