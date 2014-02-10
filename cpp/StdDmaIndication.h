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
  virtual void configResp(unsigned long pointer){
    fprintf(stderr, "configResp: %lx\n", pointer);
    if (portalMemory)
      portalMemory->configResp(pointer);
  }
  virtual void addrResponse(unsigned long long physAddr){
    fprintf(stderr, "DmaIndication::addrResponse(physAddr=%llx)\n", physAddr);
  }
  virtual void parefResp(unsigned long pointer){
    fprintf(stderr, "DmaIndication::parefResp(pointer=%lx)\n", pointer);
  }
  virtual void badPointer (unsigned long pointer) {
    fprintf(stderr, "DmaIndication::badPointer(pointer=%lx)\n", pointer);
  }
  virtual void badAddr (unsigned long pointer, unsigned long long offset , unsigned long long physAddr) {
    fprintf(stderr, "DmaIndication::badAddr(pointer=%lx offset=%llx physAddr=%llx)\n", pointer, offset, physAddr);
  }
};
