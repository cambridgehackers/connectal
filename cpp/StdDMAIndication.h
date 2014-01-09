#include "DMAIndicationWrapper.h"

class DMAIndication : public DMAIndicationWrapper
{
  PortalMemory *portalMemory;

public:
  DMAIndication(unsigned int id) : DMAIndicationWrapper(id), portalMemory(0) {}
  DMAIndication(const char* devname, unsigned int addrbits) : DMAIndicationWrapper(devname,addrbits), portalMemory(0) {}
  DMAIndication(PortalMemory *pm, const char* devname, unsigned int addrbits)
    : DMAIndicationWrapper(devname,addrbits)
    , portalMemory(pm)
  {
    pm->useSemaphore();
  }

  virtual void reportStateDbg(const DmaDbgRec& rec){
    fprintf(stderr, "reportStateDbg: {x:%08lx y:%08lx z:%08lx w:%08lx}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void configResp(unsigned long channelId){
    fprintf(stderr, "configResp: %lx\n", channelId);
  }
  virtual void sglistResp(unsigned long channelId, unsigned long idx){
    fprintf(stderr, "sglistResp: %lx idx=%lx\n", channelId, idx);
    if (portalMemory)
      portalMemory->sglistResp(channelId);
  }
  virtual void sglistEntry(unsigned long long physAddr){
    fprintf(stderr, "sglistEntry: physAddr=%llx\n", physAddr);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "parefResp: %lx\n", channelId);
  }
  virtual void badHandle ( const unsigned long handle, const unsigned long address ) {
    fprintf(stderr, "DMAIndication bad handle pref=%lx addr=%lx\n", handle, address);
  }
  virtual void badAddr ( const unsigned long handle, const unsigned long address ) {
    fprintf(stderr, "DMAIndication bad address pref=%lx addr=%lx\n", handle, address);
  }
};
