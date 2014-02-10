#ifndef _PORTAL_MEMORY_H_
#define _PORTAL_MEMORY_H_

#include "portal.h"
#include "GeneratedTypes.h"

class PortalMemory : public PortalProxy 
{
 private:
  int handle;
  bool callBacksRegistered;
  sem_t sglistSem;
  sem_t mtSem;
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
  void show_mem_stats(ChannelType rc);
  void configResp(unsigned long channelId);
  void reportMemoryTraffic(unsigned long long cycles, unsigned long long words);
  void useSemaphore() { callBacksRegistered = true; }
  virtual void sglist(unsigned long pref, unsigned long long addr, unsigned long len) = 0;
  virtual void getMemoryTraffic (const ChannelType &rc) = 0;
};

// ugly hack (mdk)
typedef int SGListId;

#endif // _PORTAL_MEMORY_H_
