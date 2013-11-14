
#ifndef __PORTALALLOC_H__
#define __PORTALALLOC_H__

typedef struct PortalAllocHeader {
    size_t size;
    int fd;
    int numEntries;
} PortalAllocHeader;

typedef struct PortalAlloc {
  PortalAllocHeader header;
  struct {
    unsigned long dma_address;
    unsigned long length;
  } entries[64];
} PortalAlloc;

#define PA_ALLOC _IOWR('B', 10, PortalAlloc)
#define PA_DCACHE_FLUSH_INVAL _IOWR('B', 11, PortalAlloc)
#define PA_DEBUG_PK _IOWR('B', 12, PortalAlloc)

#endif /* __PORTALALLOC_H__ */
