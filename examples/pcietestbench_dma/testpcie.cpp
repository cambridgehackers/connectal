
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
  sem_t done_sem;
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 7)
      exit(0);
  }
  virtual void finished(uint32_t v){
    fprintf(stderr, "finished(%x)\n", v);
    sem_post(&done_sem);
  }
  virtual void started(uint32_t words){
    fprintf(stderr, "started(%x)\n", words);
  }
  void tlpout(const TLPData16 &tlp) {
    fprintf(stderr, "Received tlp: %08x%08x%08x%08x\n", tlp.data3, tlp.data2, tlp.data1, tlp.data0);
    sem_post(&sem);
  }
  PcieTestBenchIndication(unsigned int id) : PcieTestBenchIndicationWrapper(id), cnt(0)
  {
    sem_init(&sem, 0, 0);
    sem_init(&done_sem,0,0);
  }
  void wait() {
    sem_wait(&sem);
  }
};



int main(int argc, const char **argv)
{
  PcieTestBenchIndication *indication = new PcieTestBenchIndication(IfcNames_PcieTestBenchIndication);
  PcieTestBenchRequestProxy *device = new PcieTestBenchRequestProxy(IfcNames_PcieTestBenchRequest);

  PortalAlloc *srcAlloc;
  unsigned int *srcBuffer = 0;

  pthread_t tid;
  fprintf(stderr, "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  portalExec, NULL)){
    fprintf(stderr, "Main::error creating exec thread\n");
    exit(1);
  }

}
