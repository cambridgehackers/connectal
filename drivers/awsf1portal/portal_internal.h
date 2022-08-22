/* Copyright (c) 2020 Accelerated Tech, Inc
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
#ifndef __PORTAL_INTERNAL_H__
#define __PORTAL_INTERNAL_H__

#include <linux/ioctl.h>
#include <linux/cdev.h>
#include "pcieportal.h"

#ifdef __KERNEL__
/*
 * Per-device data
 */
typedef struct {
        struct cdev       cdev; /* per-portal cdev structure */
        unsigned int      device_number;
        unsigned int      device_tile;
        unsigned int      portal_number;
        unsigned int      device_name;
        struct tBoard    *board;
        void             *virt;
        volatile uint32_t *regs;  // Pointer to access portal from kernel
        unsigned long     offset; // Offset from base of BAR2
        struct extra_info *extra;
	struct list_head pmlist;
        wait_queue_head_t wait_queue; /* used for interrupt notifications */
        dma_addr_t        dma_handle;
} tPortal;

typedef struct {
        unsigned int      device_tile;
        struct tBoard    *board;
} tTile;

struct pmentry {
	struct file     *fmem;
	int              id;
	struct list_head pmlist;
};

typedef struct tBoard {
	struct cdev       cdev;
	struct cdev       dma_pcis_cdev;
        void __iomem     *bar0io, *bar1io, *bar2io, *bar4io; /* bars */
        struct pci_dev   *pci_dev; /* pci device pointer */
        tPortal           portal[MAX_NUM_PORTALS];
        unsigned int      irq_num;
        unsigned int      open_count;
        tTile             tile[MAX_NUM_PORTALS];
        struct extra_info *extra;
        struct extra_info *pcis; // DMA PCIS on AWSF1
        struct {
          unsigned int board_number;
          unsigned int portal_number;
          unsigned int num_portals;
	  unsigned int aws_shell;
        }                 info; /* board identification fields */
} tBoard;

extern tBoard* get_pcie_portal_descriptor(void);
#endif

struct xdma_pci_dev;
int pcieportal_board_activate(int activate, tBoard *this_board, struct xdma_pci_dev *xpdev, struct pci_dev *dev);

#endif /* __BLUENOC_H__ */
