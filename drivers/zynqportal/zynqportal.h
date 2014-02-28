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
    long interrupt_offset;
    long mask_offset;
} PortalEnableInterrupt;

#define PORTAL_SET_FCLK_RATE    _IOWR('B', 40, PortalClockRequest)
#define PORTAL_ENABLE_INTERRUPT _IOWR('B', 41, PortalEnableInterrupt)

#endif /* __PORTAL_H__ */
