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

#include <socket_channel.h>

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

typedef struct PortalInternal {
  struct PortalPoller *poller;
  int fpga_fd;
  struct channel p_read;
  struct channel p_write;
  int fpga_number;
  volatile unsigned int *map_base;
  void *parent;
} PortalInternal;

#ifdef __KERNEL__
#include <linux/module.h>
#include <linux/kernel.h>
#define PORTAL_PRINTF printk
#else
#include <stdio.h>   // printf()
#include <stdlib.h>  // exit()
#ifdef __cplusplus
#include "portal_internal.h"
#endif
void init_portal_internal(PortalInternal *pint, int fpga_number, int addrbits);
#define PORTAL_PRINTF printf
#endif

#if defined(MMAP_HW) || defined(__KERNEL__)
#define READL(CITEM, A)     (*(A))
#define WRITEL(CITEM, A, B) (*(A) = (B))
#else
unsigned int read_portal_bsim(int sockfd, volatile unsigned int *addr, int id);
void write_portal_bsim(int sockfd, volatile unsigned int *addr, unsigned int v, int id);
#define READL(CITEM, A) read_portal_bsim((CITEM)->p_read.sockfd, (A), (CITEM)->fpga_number)
#define WRITEL(CITEM, A, B) write_portal_bsim((CITEM)->p_write.sockfd, (A), (B), (CITEM)->fpga_number)
#endif

#endif /* __PORTAL_OFFSETS_H__ */
