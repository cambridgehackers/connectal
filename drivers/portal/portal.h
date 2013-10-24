/*
 * Generic userspace hardware bridge
 *
 * Author: Jamey Hicks <jamey.hicks@gmail.com>
 *
 * 2012 (c) Jamey Hicks
 *
 * This file is licensed under the terms of the GNU General Public License
 * version 2.  This program is licensed "as is" without any warranty of any
 * kind, whether express or implied.
 */

#ifndef __PORTAL_H__
#define __PORTAL_H__

typedef struct PortalAlloc {
  size_t size;
  int fd;
  struct {
    unsigned long dma_address;
    unsigned long length;
  } entries[64];
  int numEntries;
} PortalAlloc;

typedef struct PortalClockRequest {
    int clknum;
    long requested_rate;
    long actual_rate;
} PortalClockRequest;

#define PORTAL_ALLOC _IOWR('B', 10, PortalAlloc)
#define PORTAL_DCACHE_FLUSH_INVAL _IOWR('B', 11, PortalAlloc)
#define PORTAL_SET_FCLK_RATE _IOWR('B', 40, PortalClockRequest)

#endif /* __PORTAL_H__ */
