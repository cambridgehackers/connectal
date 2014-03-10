
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
