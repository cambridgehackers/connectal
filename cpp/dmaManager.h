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
#include <linux/slab.h>
#include <linux/dma-buf.h>
#define PORTAL_MALLOC(A) vmalloc(A)
#define PORTAL_FREE(A) vfree(A)
#else
#include <semaphore.h>
#include <stdint.h>
#define PORTAL_MALLOC(A) malloc(A)
#define PORTAL_FREE(A) free(A)
#endif

#include "portal.h"

typedef struct {
  sem_t confSem;
  sem_t sglIdSem;
  uint32_t sglId;
  PortalInternal *sglDevice;
  int pa_fd;
  SHARED_MMUINDICATION_POLL poll;
  PortalInternal  *shared_mmu_indication;
} DmaManagerPrivate;

#ifdef __cplusplus
extern "C" {
#endif
void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *sglDevice);
int DmaManager_reference(DmaManagerPrivate *priv, int fd);
void DmaManager_dereference(DmaManagerPrivate *priv, int ref);
void DmaManager_idresp(DmaManagerPrivate *priv, uint32_t sglId);
void DmaManager_confresp(DmaManagerPrivate *priv, uint32_t channelId);
#ifdef __cplusplus
}
#endif

#ifndef NO_CPP_PORTAL_CODE
#ifdef __cplusplus
#include "GeneratedTypes.h" //ChannelType!!
class DmaManager
{
 public:
  DmaManagerPrivate priv;
  DmaManager(Portal *sglDevice) {
    DmaManager_init(&priv, &sglDevice->pint);
  };
  int reference(int fd) {
    return DmaManager_reference(&priv, fd);
  };
  void dereference(int ref){
    DmaManager_dereference(&priv, ref);
  }
  void sglIdResp(uint32_t sglId) {
    DmaManager_idresp(&priv, sglId);
  }
  void confResp(uint32_t channelId) {
    DmaManager_confresp(&priv, channelId);
  };
};
extern "C" DmaManager *platformInit(void);
extern "C" void platformStatistics(void);
#else
struct DmaManager
{
  DmaManagerPrivate priv;
};
typedef struct DmaManager DmaManager;
DmaManager *platformInit(void);
void platformStatistics(void);
#endif
#endif
#endif // _PORTAL_MEMORY_H_
