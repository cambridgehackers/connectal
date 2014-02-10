#include "DmaDbgIndicationWrapper.h"

class DmaDbgIndication : public DmaDbgIndicationWrapper
{

public:
 DmaDbgIndication(const char* devname, unsigned int addrbits) : DmaDbgIndicationWrapper(devname,addrbits) {}
 DmaDbgIndication(unsigned int id) : DmaDbgIndicationWrapper(id) {}
  virtual void reportStateDbg(const DmaDbgRec& rec){
    fprintf(stderr, "reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  
  virtual void reportMemoryTraffic(unsigned long long cycles, unsigned long long words){
    fprintf(stderr, "reportMemoryTraffic: cycles=%lld, words=%lld\n", cycles,words);
  }
};
