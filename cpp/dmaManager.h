
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

#ifdef __KERNEL__
#include <linux/types.h>
#include <linux/semaphore.h>
#include <asm/cacheflush.h>
#define sem_wait(A) down_interruptible(A)
#define sem_post(A) up(A)
#define sem_init(A, B, C) (sema_init ((A), (C)), 0)
typedef struct semaphore sem_t;
#else
#include <semaphore.h>
#include <stdint.h>
#endif

#include "portalmem.h"
#include "portal.h"

#if 1 //def NO_CPP_PORTAL_CODE
#include "GeneratedTypes.h" // generated in project directory
#define DMAsglist(P, A, B, C) DmaConfigProxy_sglist((P), (A), (B), (C));
#define DMAregion(P, PTR, B8, B4, B0) DmaConfigProxy_region((P), (PTR), (B8), (B4), (B0))
#define DMAGetMemoryTraffic(P,A) DmaConfigProxy_getMemoryTraffic((P), (A))
#else
#include "DmaConfigProxy.h" // generated in project directory
#define DMAsglist(P, A, B, C) ((DmaConfigProxy *)((P)->parent))->sglist((A), (B), (C))
#define DMAregion(P, PTR, B8, B4, B0) ((DmaConfigProxy *)((P)->parent))->region((PTR), (B8), (B4), (B0))
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

#ifdef __cplusplus
extern "C" {
#endif
void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *argDevice);
int DmaManager_dCacheFlushInval(DmaManagerPrivate *priv, PortalAlloc *portalAlloc, void *__p);
uint64_t DmaManager_show_mem_stats(DmaManagerPrivate *priv, ChannelType rc);
int DmaManager_reference(DmaManagerPrivate *priv, PortalAlloc* pa);
int DmaManager_alloc(DmaManagerPrivate *priv, size_t size, PortalAlloc **ppa);
#ifdef __cplusplus
}
#endif
#ifndef NO_CPP_PORTAL_CODE
#ifdef __cplusplus
class DmaManager
{
 private:
  DmaManagerPrivate priv;
 public:
  DmaManager(PortalInternalCpp *argDevice) {
    DmaManager_init(&priv, &argDevice->pint);
  };
  int dCacheFlushInval(PortalAlloc *portalAlloc, void *__p) {
    return DmaManager_dCacheFlushInval(&priv, portalAlloc, __p);
  };
  int alloc(size_t size, PortalAlloc **ppa) {
   return DmaManager_alloc(&priv, size, ppa);
  };
  int reference(PortalAlloc* pa) {
    return DmaManager_reference(&priv, pa);
  };
  uint64_t show_mem_stats(ChannelType rc) {
    return DmaManager_show_mem_stats(&priv, rc);
  };
  void confResp(uint32_t channelId) {
    //fprintf(stderr, "configResp %d\n", channelId);
    sem_post(&priv.confSem);
  };
  void mtResp(uint64_t words) {
    priv.mtCnt = words;
    sem_post(&priv.mtSem);
  };
  void dbgResp(const DmaDbgRec& dbgRec) {
    fprintf(stderr, "dbgResp: %08x %08x %08x %08x\n", dbgRec.x, dbgRec.y, dbgRec.z, dbgRec.w);
    sem_post(&priv.dbgSem);
  };
};
#endif
#endif
#endif // _PORTAL_MEMORY_H_
