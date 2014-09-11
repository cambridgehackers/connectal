#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#include "ChannelSelectTestRequestProxy.h"
#include "ChannelSelectTestIndicationWrapper.h"
#include "GeneratedTypes.h"

sem_t data_sem;
sem_t coeff_sem;

int readBurstLen = 16;
int writeBurstLen = 16;

  PortalPoller *poller = 0;


#ifndef BSIM
int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size
#else
int numWords = 0x124000/4;
#endif

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;

class ChannelSelectTestIndication : public ChannelSelectTestIndicationWrapper
{

public:
  ChannelSelectTestIndication(unsigned int id, PortalPoller *poller) : ChannelSelectTestIndicationWrapper(id, poller){}

  virtual void ifreqData(unsigned dataRe, unsigned dataIm){
    fprintf(stderr, "read %x %x\n", dataRe, dataIm);
  }
  virtual void setDataResp(){
    fprintf(stderr, "setDataResp\n");
    sem_post(&data_sem);
  }
  virtual void setCoeffResp(){
    fprintf(stderr, "setDataResp\n");
    sem_post(&coeff_sem);
  }
};

static void *thread_routine(void *data)
{
    fprintf(stderr, "Calling portalExec\n");
    portalExec(0);
    fprintf(stderr, "portalExec returned ???\n");
    return data;
}

int main(int argc, const char **argv)
{

  ChannelSelectTestRequestProxy *device = 0;
  ChannelSelectTestIndication *deviceIndication = 0;
  sem_init(&data_sem, 0, 0);
  sem_init(&coeff_sem, 0, 0);
  fprintf(stderr, "Main::%s %s\n", __DATE__, __TIME__);

  poller = new PortalPoller();

  device = new ChannelSelectTestRequestProxy(IfcNames_ChannelSelectTestRequest, poller);

  deviceIndication = new ChannelSelectTestIndication(IfcNames_ChannelSelectTestIndication, poller);

  pthread_t thread;
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_create(&thread, &attr, thread_routine, 0);

  int status;
    
  fprintf(stderr, "Main::flush and invalidate complete\n");


  fprintf(stderr, "Main::after getStateDbg\n");


  fprintf(stderr, "Main::starting read %08x\n", numWords);

  device->setCoeff(0, 0, 0);
  sem_wait(&coeff_sem);

  device->rfreqDataWrite(0, 0);
  sem_wait(&data_sem);



  fprintf(stderr, "Main::stopping\n");

  exit(0);
}
