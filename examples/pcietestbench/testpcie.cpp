
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#include "PcieTestBenchIndicationWrapper.h"
#include "PcieTestBenchRequestProxy.h"
#include "GeneratedTypes.h"




class PcieTestBenchIndication : public PcieTestBenchIndicationWrapper
{  
public:
  uint32_t cnt;
  void incr_cnt(){
    if (++cnt == 7)
      exit(0);
  }
  PcieTestBenchIndication(unsigned int id) : PcieTestBenchIndicationWrapper(id), cnt(0){}
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


  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(2);}
}
