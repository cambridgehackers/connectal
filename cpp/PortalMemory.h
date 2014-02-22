#ifndef _PORTAL_MEMORY_H_
#define _PORTAL_MEMORY_H_

#include <stdint.h>
#include "portal.h"
#include "GeneratedTypes.h"

class PortalMemory : public PortalInternal 
{
 private:
  int handle;
  bool callBacksRegistered;
  sem_t confSem;
  sem_t mtSem;
  uint64_t mtCnt;
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
  void configResp(uint32_t channelId);
  void reportMemoryTraffic(uint64_t words);
  void useSemaphore() { callBacksRegistered = true; }
  virtual void sglist(uint32_t pointer, uint64_t paddr, uint32_t len) = 0;
  virtual void region(uint32_t pointer, uint64_t barr8, uint32_t off8, uint64_t barr4, uint32_t off4, uint64_t barr0, uint32_t off0) = 0;
  virtual void getMemoryTraffic (const ChannelType &rc) = 0;
};

// ugly hack (mdk)
typedef int SGListId;

#endif // _PORTAL_MEMORY_H_
