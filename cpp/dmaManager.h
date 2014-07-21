
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

#ifndef __KERNEL__
#include <stdint.h>
#endif

#include "portal.h"
#include "drivers/portalmem/portalmem.h"
#ifdef NO_CPP_PORTAL_CODE
#include "GeneratedTypes.h" // generated in project directory
#define DMAsglist(P, A, B, C) DmaConfigProxy_sglist((P), (A), (B), (C));
#define DMAregion(P, PTR, B8, O8, B4, O4, B0, O0) DmaConfigProxy_region((P), (PTR), (B8), (O8), (B4), (O4), (B0), (O0))
#define DMAGetMemoryTraffic(P,A) DmaConfigProxy_getMemoryTraffic((P), (A))
#else
#include "DmaConfigProxy.h" // generated in project directory
#define DMAsglist(P, A, B, C) ((DmaConfigProxy *)((P)->parent))->sglist((A), (B), (C))
#define DMAregion(P, PTR, B8, O8, B4, O4, B0, O0) ((DmaConfigProxy *)((P)->parent))->region((PTR), (B8), (O8), (B4), (O4), (B0), (O0))
#define DMAGetMemoryTraffic(P,A) ((DmaConfigProxy *)((P)->parent))->getMemoryTraffic((A))
#endif

typedef struct {
  sem_t confSem;
  sem_t mtSem;
  sem_t dbgSem;
  uint64_t mtCnt;
  PortalInternal *device;
#ifndef MMAP_HW
  int write;
#endif
  int pa_fd;
  int handle;
} DmaManagerPrivate;

#ifdef NO_CPP_PORTAL_CODE
void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *argDevice);
int DmaManager_dCacheFlushInval(DmaManagerPrivate *priv, PortalAlloc *portalAlloc, void *__p);
uint64_t DmaManager_show_mem_stats(DmaManagerPrivate *priv, ChannelType rc);
int DmaManager_reference(DmaManagerPrivate *priv, PortalAlloc* pa);
int DmaManager_alloc(DmaManagerPrivate *priv, size_t size, PortalAlloc **ppa);
#else
class DmaManager
{
 private:
  DmaManagerPrivate priv;
 public:
  DmaManager(PortalInternalCpp *argDevice);
  int dCacheFlushInval(PortalAlloc *portalAlloc, void *__p);
  int alloc(size_t size, PortalAlloc **portalAlloc);
  int reference(PortalAlloc* pa);
  uint64_t show_mem_stats(ChannelType rc);
  void confResp(uint32_t channelId);
  void mtResp(uint64_t words);
  void dbgResp(const DmaDbgRec& rec);
};
#endif
#endif // _PORTAL_MEMORY_H_
