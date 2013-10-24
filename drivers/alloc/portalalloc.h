
#ifndef __PORTALALLOC_H__
#define __PORTALALLOC_H__

typedef struct PortalAlloc {
  size_t size;
  int fd;
  struct {
    unsigned long dma_address;
    unsigned long length;
  } entries[64];
  int numEntries;
} PortalAlloc;

#define PORTAL_ALLOC _IOWR('B', 10, PortalAlloc)
#define PORTAL_DCACHE_FLUSH_INVAL _IOWR('B', 11, PortalAlloc)

#endif /* __PORTALALLOC_H__ */
