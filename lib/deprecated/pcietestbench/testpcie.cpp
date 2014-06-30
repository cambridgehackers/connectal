
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <semaphore.h>

#include "PcieTestBenchIndicationWrapper.h"
#include "PcieTestBenchRequestProxy.h"
#include "GeneratedTypes.h"




class PcieTestBenchIndication : public PcieTestBenchIndicationWrapper
{  
  sem_t sem;
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 7)
      exit(0);
  }
  void tlpout(const TLPData16 &tlp) {
    fprintf(stderr, "Received tlp: %08x%08x%08x%08x\n", tlp.data3, tlp.data2, tlp.data1, tlp.data0);
    sem_post(&sem);
  }
  PcieTestBenchIndication(unsigned int id) : PcieTestBenchIndicationWrapper(id), cnt(0)
  {
    sem_init(&sem, 0, 0);
  }
  void wait() {
    sem_wait(&sem);
  }
};



int main(int argc, const char **argv)
{
  PcieTestBenchIndication *indication = new PcieTestBenchIndication(IfcNames_PcieTestBenchIndication);
  PcieTestBenchRequestProxy *device = new PcieTestBenchRequestProxy(IfcNames_PcieTestBenchRequest);

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }

  device->sendReadRequest(1, 4, 1, 5);
  indication->wait();
  device->sendReadRequest(1, 0, 2, 7);
  indication->wait();
  device->sendReadRequest(1, 0, 3, 9);
  indication->wait();
  device->sendReadRequest(1, 0, 4, 10);
  indication->wait();
  device->sendReadRequest(1, 0, 5, 11);
  indication->wait();
  device->sendReadRequest(1, 0, 6, 12);
  indication->wait();
  device->sendReadRequest(1, 0, 7, 12);
  indication->wait();
  device->sendReadRequest(1, 0, 8, 12);
  indication->wait();

}
