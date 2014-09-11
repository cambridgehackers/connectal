
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

#include "dmaManager.h"
#include "DmaDebugIndicationWrapper.h"
#include "SGListConfigIndicationWrapper.h"

static int error_limit = 20;
class SGListConfigIndication : public SGListConfigIndicationWrapper
{
  DmaManager *portalMemory;
 public:
  SGListConfigIndication(DmaManager *pm, unsigned int  id) : SGListConfigIndicationWrapper(id), portalMemory(pm) {}
  virtual void configResp(uint32_t pointer){
    fprintf(stderr, "configResp: %x\n", pointer);
    portalMemory->confResp(pointer);
  }
  virtual void error (uint32_t code, uint32_t pointer, uint64_t offset, uint64_t extra) {
    fprintf(stderr, "SGListConfigIndication::error(code=%x, pointer=%x, offset=%"PRIx64" extra=%"PRIx64"\n", code, pointer, offset, extra);
    if (--error_limit < 0)
        exit(-1);
  }
  virtual void idResponse(uint32_t sglId){
    portalMemory->sglIdResp(sglId);
  }
};

class DmaDebugIndication : public DmaDebugIndicationWrapper
{
  DmaManager *portalMemory;
 public:
  DmaDebugIndication(DmaManager *pm, unsigned int  id) : DmaDebugIndicationWrapper(id), portalMemory(pm) {}
  virtual void addrResponse(uint64_t physAddr){
    fprintf(stderr, "DmaIndication::addrResponse(physAddr=%"PRIx64")\n", physAddr);
  }
  virtual void reportStateDbg(const DmaDbgRec rec){
    //fprintf(stderr, "reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", rec.x,rec.y,rec.z,rec.w);
    portalMemory->dbgResp(rec);
  }
  virtual void reportMemoryTraffic(uint64_t words){
    //fprintf(stderr, "reportMemoryTraffic: words=%"PRIx64"\n", words);
    portalMemory->mtResp(words);
  }
  virtual void error (uint32_t code, uint32_t pointer, uint64_t offset, uint64_t extra) {
    fprintf(stderr, "DmaDebugIndication::error(code=%x, pointer=%x, offset=%"PRIx64" extra=%"PRIx64"\n", code, pointer, offset, extra);
    if (--error_limit < 0)
        exit(-1);
  }
};
