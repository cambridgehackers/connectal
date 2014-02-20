#include "PortalMemory.h"
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
  virtual void configResp(uint32_t pointer){
    //fprintf(stderr, "configResp: %lx\n", pointer);
    if (portalMemory)
      portalMemory->configResp(pointer);
  }
  virtual void addrResponse(uint64_t physAddr){
    fprintf(stderr, "DmaIndication::addrResponse(physAddr=%zx)\n", physAddr);
  }
  virtual void parefResp(uint32_t pointer){
    fprintf(stderr, "DmaIndication::parefResp(pointer=%x)\n", pointer);
  }
  virtual void badPointer (uint32_t pointer) {
    fprintf(stderr, "DmaIndication::badPointer(pointer=%x)\n", pointer);
  }
  virtual void badPageSize (uint32_t pointer, uint32_t len) {
    fprintf(stderr, "DmaIndication::badPageSize(pointer=%x, len=%x)\n", pointer, len);
  }
  virtual void badAddrTrans (uint32_t pointer, uint32_t offset) {
    fprintf(stderr, "DmaIndication::badAddrTrans(pointer=%x, offset=%x)\n", pointer, offset);
  }
  virtual void badAddr (uint32_t pointer, uint64_t offset , uint64_t physAddr) {
    fprintf(stderr, "DmaIndication::badAddr(pointer=%x offset=%zx physAddr=%zx)\n", pointer, offset, physAddr);
  }
  virtual void reportStateDbg(const DmaDbgRec& rec){
    fprintf(stderr, "reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", rec.x,rec.y,rec.z,rec.w);
  }
  virtual void reportMemoryTraffic(uint64_t words){
    fprintf(stderr, "reportMemoryTraffic: words=%zx\n", words);
    if (portalMemory)
      portalMemory->reportMemoryTraffic(words);
  }
};
