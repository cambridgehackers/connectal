/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#ifndef __PORTAL_OFFSETS_H__
#define __PORTAL_OFFSETS_H__

/* Offset of each /dev/fpgaxxx device in the address space */
#define PORTAL_BASE_OFFSET         (1 << 16)

/* Offsets of mapped registers within an /dev/fpgaxxx device */
#define PORTAL_REQ_FIFO(A)         (((0<<14) + (A) * 256)/sizeof(uint32_t))
#define PORTAL_IND_FIFO(A)         (((2<<14) + (A) * 256)/sizeof(uint32_t))
#define PORTAL_IND_REG_OFFSET_32   ( (3<<14)             /sizeof(uint32_t))
#define     IND_REG_INTERRUPT_FLAG    (PORTAL_IND_REG_OFFSET_32 + 0)
#define     IND_REG_INTERRUPT_MASK    (PORTAL_IND_REG_OFFSET_32 + 1)
#define     IND_REG_INTERRUPT_COUNT   (PORTAL_IND_REG_OFFSET_32 + 2)
#define     IND_REG_QUEUE_STATUS      (PORTAL_IND_REG_OFFSET_32 + 6)

#ifdef __KERNEL__
#include <linux/module.h>
#include <linux/kernel.h>

typedef struct {
    volatile unsigned int *map_base;
} PortalInternal;
#define PORTAL_PRINTF printk
#else
#include "portal_internal.h"
#include <stdio.h>
#define PORTAL_PRINTF printf
#endif

#if defined(MMAP_HW) || defined(__KERNEL__)
#define READL(CITEM, A)     (*(A))
#define WRITEL(CITEM, A, B) (*(A) = (B))
#else
unsigned int read_portal_bsim(int sockfd, volatile unsigned int *addr, char *name);
void write_portal_bsim(int sockfd, volatile unsigned int *addr, unsigned int v, char *name);
#define READL(CITEM, A) read_portal_bsim((CITEM)->p_read.sockfd, (A), (CITEM)->name)
#define WRITEL(CITEM, A, B) write_portal_bsim((CITEM)->p_write.sockfd, (A), (B), (CITEM)->name)
#endif

#endif /* __PORTAL_OFFSETS_H__ */
