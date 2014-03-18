
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

#ifndef _PORTAL_MEMORY_H_
#define _PORTAL_MEMORY_H_

#include <stdint.h>
#include "portal.h"
#include "GeneratedTypes.h"

class PortalMemory : public PortalInternal 
{
 private:
  int handle;
  sem_t confSem;
  sem_t mtSem;
  sem_t dbgSem;
  uint64_t mtCnt;
  DmaDbgRec dbgRec;
#ifndef MMAP_HW
  portal p_fd;
#endif
 public:
  PortalMemory(int id);
  PortalMemory(const char *devname, unsigned int addrbits);
  void InitSemaphores();
  void InitFds();
  int pa_fd;
  void *mmap(PortalAlloc *portalAlloc);
  int dCacheFlushInval(PortalAlloc *portalAlloc, void *__p);
  int alloc(size_t size, PortalAlloc **portalAlloc);
  int reference(PortalAlloc* pa);
  uint64_t show_mem_stats(ChannelType rc);
  void confResp(uint32_t channelId);
  void mtResp(uint64_t words);
  void dbgResp(const DmaDbgRec& rec);
  virtual void sglist(uint32_t pointer, uint64_t paddr, uint32_t len) = 0;
  virtual void region(uint32_t pointer, uint64_t barr8, uint32_t off8, uint64_t barr4, uint32_t off4, uint64_t barr0, uint32_t off0) = 0;
  virtual void getMemoryTraffic (const ChannelType &rc, uint32_t client) = 0;
  virtual void getStateDbg(const ChannelType& rc) = 0;
};

// ugly hack (mdk)
typedef int SGListId;

#endif // _PORTAL_MEMORY_H_
