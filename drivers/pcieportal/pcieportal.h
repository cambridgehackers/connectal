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
#ifndef __BLUENOC_H__
#define __BLUENOC_H__

#include <linux/ioctl.h>

/*
 * IOCTLs
 */

/* magic number for IOCTLs */
#define BNOC_IOC_MAGIC 0xB5

/* Number of boards to support */
#define NUM_BOARDS 4
#define MAX_NUM_PORTALS 32

/* Structures used with IOCTLs */

typedef struct {
  unsigned long base;
  unsigned int trace;
  unsigned int traceLength;
  unsigned int intval[MAX_NUM_PORTALS];
  unsigned int name[MAX_NUM_PORTALS];
} tTraceInfo;

typedef struct {
  int fd;
  int id;
} tSendFd;

typedef struct {
    int  index;        /* in param */
    char md5[33];      /* out param -- asciz */
    char filename[33]; /* out param -- asciz */
} PortalSignaturePcie;

typedef unsigned int tTlpData[6];

typedef struct ChangeEntry {
  unsigned int timestamp;
  unsigned char src;
  unsigned int value : 24;
} tChangeEntry;
/* IOCTL code definitions */

#define BNOC_GET_TLP         _IOR(BNOC_IOC_MAGIC,7,tTlpData*)
#define BNOC_TRACE           _IOWR(BNOC_IOC_MAGIC,8,tTraceInfo*)
#define BNOC_ENABLE_TRACE    _IOR(BNOC_IOC_MAGIC,8,int*)
#define PCIE_SEND_FD         _IOR(BNOC_IOC_MAGIC,12,tSendFd*)
#define PCIE_DEREFERENCE     _IOR(BNOC_IOC_MAGIC,13,int)
#define PCIE_SIGNATURE       _IOR(BNOC_IOC_MAGIC,14,PortalSignaturePcie)
#define PCIE_CHANGE_ENTRY    _IOR(BNOC_IOC_MAGIC,15,tChangeEntry*)

#ifdef __KERNEL__
/*
 * Per-device data
 */
typedef struct {
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

#endif /* __BLUENOC_H__ */
