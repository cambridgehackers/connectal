#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <assert.h>
#include <semaphore.h>

#include "ChannelSelectTestRequest.h"
#include "ChannelSelectTestIndication.h"
#include "DDSTestRequest.h"
#include "DDSTestIndication.h"
#include "GeneratedTypes.h"

sem_t data_sem;
sem_t config_sem;

class ChannelSelectTestIndication : public ChannelSelectTestIndicationWrapper
{

public:
  ChannelSelectTestIndication(unsigned int id) : ChannelSelectTestIndicationWrapper(id){}

  virtual void ifreqData(unsigned dataRe, unsigned dataIm){
    fprintf(stdout, "read %x %x\n", dataRe, dataIm);
  }
  virtual void setDataResp(){
    fprintf(stdout, "setDataResp\n");
    sem_post(&data_sem);
  }
  virtual void setConfigResp(){
    fprintf(stdout, "setDataResp\n");
    sem_post(&config_sem);
  }
};

class DDSTestIndication : public DDSTestIndicationWrapper
{

public:
  DDSTestIndication(unsigned int id) : DDSTestIndicationWrapper(id){}

  virtual void ddsData(unsigned phase, unsigned dataRe, unsigned dataIm){
    fprintf(stdout, "data %d %X %x\n", phase, dataRe, dataIm);
    sem_post(&data_sem);
  }
  virtual void setConfigResp(){
    fprintf(stdout, "dds.setDataResp\n");
    sem_post(&config_sem);
  }
  
};

int main(int argc, const char **argv)
{

  ChannelSelectTestRequestProxy *ctdevice = 0;
  ChannelSelectTestIndication *ctindication = 0;
  DDSTestRequestProxy *ddsdevice = 0;
  DDSTestIndication *ddsindication = 0;
  sem_init(&data_sem, 0, 0);
  sem_init(&config_sem, 0, 0);
  fprintf(stdout, "Main::%s %s\n", __DATE__, __TIME__);

  ctdevice = new ChannelSelectTestRequestProxy(IfcNames_ChannelSelectTestRequest);

  ctindication = new ChannelSelectTestIndication(IfcNames_ChannelSelectTestIndication);

  ddsdevice = new DDSTestRequestProxy(IfcNames_DDSTestRequest);

  ddsindication = new DDSTestIndication(IfcNames_DDSTestIndication);

  portalExec_start();

  fprintf(stdout, "DDSTest\n");
  ddsdevice->setPhaseAdvance(1, 0);

  for (int i = 0; i < 2048; i += 1) {
    ddsdevice->getData();
    sem_wait(&data_sem);
  }


  fprintf(stdout, "Main::starting\n");

  ctdevice->setCoeff(0, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setCoeff(1, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setCoeff(2, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setCoeff(3, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setPhaseAdvance(0, 1 << 21);
  sem_wait(&config_sem);

  int i;
  for (i = 0; i < 128; i += 1) {
    ctdevice->rfreqDataWrite(1<<16, 0);   // should be re=1, im=0
    sem_wait(&data_sem);
  }

  fprintf(stdout, "Main::stopping\n");

  exit(0);
}
