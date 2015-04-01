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

typedef struct {
    int clknum;
    long requested_rate;
    long actual_rate;
} PortalClockRequest;

typedef struct {
    int fd;
    int id;
} PortalSendFd;

typedef struct {
    uint32_t msb;
    uint32_t lsb;
} PortalInterruptTime;

typedef struct {
  int fd;
  void *base;
  size_t len;
} PortalCacheRequest;

typedef struct {
    int  index;        /* in param */
    char md5[33];      /* out param -- asciz */
    char filename[33]; /* out param -- asciz */
} PortalSignature;

#define PORTAL_SET_FCLK_RATE      _IOWR('B', 40, PortalClockRequest)
#define PORTAL_SEND_FD            _IOR('B',  42, PortalSendFd)
#define PORTAL_DCACHE_FLUSH_INVAL _IOR('B',  43, PortalCacheRequest)
#define PORTAL_DIRECTORY_READ     _IOR('B',  44, unsigned long)
#define PORTAL_INTERRUPT_TIME     _IOR('B',  45, PortalInterruptTime)
#define PORTAL_DCACHE_INVAL       _IOR('B',  46, PortalCacheRequest)
#define PORTAL_DEREFERENCE        _IOR('B',  47, int)
#define PORTAL_SIGNATURE          _IOR('B',  47, PortalSignature)

#endif /* __PORTAL_H__ */
