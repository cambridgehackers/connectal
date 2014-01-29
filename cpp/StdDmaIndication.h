#include "DmaIndicationWrapper.h"

class DmaIndication : public DmaIndicationWrapper
{
  PortalMemory *portalMemory;

public:
  DmaIndication(unsigned int id) : DmaIndicationWrapper(id), portalMemory(0) {}
  DmaIndication(PortalMemory *pm, unsigned int id)
    : DmaIndicationWrapper(id), portalMemory(pm)
  {
    pm->useSemaphore();
  }
  DmaIndication(const char* devname, unsigned int addrbits) : DmaIndicationWrapper(devname,addrbits), portalMemory(0) {}
  DmaIndication(PortalMemory *pm, const char* devname, unsigned int addrbits)
    : DmaIndicationWrapper(devname,addrbits)
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
  virtual void sglistResp(unsigned long channelId, unsigned long idx, unsigned long pa){
    fprintf(stderr, "sglistResp: %lx idx=%lx physAddr=%lx\n", channelId, idx, pa);
    if (portalMemory)
      portalMemory->sglistResp(channelId);
  }
  virtual void sglistEntry(unsigned long idx, unsigned long long physAddr){
    fprintf(stderr, "sglistEntry: idx=%lx physAddr=%llx\n", idx, physAddr);
  }
  virtual void parefResp(unsigned long channelId){
    fprintf(stderr, "parefResp: %lx\n", channelId);
  }
  virtual void badHandle ( const unsigned long handle, const unsigned long address ) {
    fprintf(stderr, "DmaIndication bad handle pref=%lx addr=%lx\n", handle, address);
  }
  virtual void badAddr ( const unsigned long handle, const unsigned long address , const unsigned long long pa) {
    fprintf(stderr, "DmaIndication bad address pref=%lx addr=%lx physaddr=%llx\n", handle, address, pa);
  }
};
