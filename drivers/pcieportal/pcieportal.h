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
#define NUM_BOARDS 1
#define MAX_NUM_PORTALS 16

/* Structures used with IOCTLs */

typedef struct {
  unsigned int       board_number;
  unsigned int       portal_number;
  unsigned int       num_portals;
} tBoardInfo;

typedef struct {
  unsigned int interrupt_status;
  unsigned int interrupt_enable;
  unsigned int indication_channel_count;
  unsigned int base_fifo_offset;
  unsigned int request_fired_count;
  unsigned int response_fired_count;
  unsigned int magic;
  unsigned int put_word_count;
  unsigned int get_word_count;
  unsigned int scratchpad;
  unsigned int fifo_status;
} tPortalInfo;

typedef struct {
  unsigned int size;
  void *virt;
  unsigned long dma_handle;
} tDmaMap;

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

typedef unsigned int tTlpData[6];

/* IOCTL code definitions */

#define BNOC_IDENTIFY        _IOR(BNOC_IOC_MAGIC,0,tBoardInfo*)
#define BNOC_IDENTIFY_PORTAL _IOR(BNOC_IOC_MAGIC,6,tPortalInfo*)
#define BNOC_GET_TLP         _IOR(BNOC_IOC_MAGIC,7,tTlpData*)
#define BNOC_TRACE           _IOWR(BNOC_IOC_MAGIC,8,tTraceInfo*)
#define BNOC_ENABLE_TRACE    _IOR(BNOC_IOC_MAGIC,8,int*)
#define PCIE_SEND_FD         _IOR(BNOC_IOC_MAGIC,12,tSendFd*)

/*
 * Per-device data
 */
typedef struct {
        unsigned int      portal_number;
        unsigned int      device_name;
        struct tBoard    *board;
        void             *virt;
        volatile uint32_t *regs;
        struct extra_info *extra;
} tPortal;

#ifndef __KERNEL__
#define __iomem
#endif
typedef struct tBoard {
        void __iomem     *bar0io, *bar1io, *bar2io; /* bars */
        struct pci_dev   *pci_dev; /* pci device pointer */
        tPortal           portal[MAX_NUM_PORTALS];
        tBoardInfo        info; /* board identification fields */
        unsigned int      irq_num;
        unsigned int      open_count;
} tBoard;

#ifdef __KERNEL__
extern tBoard* get_pcie_portal_descriptor(void);
#endif

#endif /* __BLUENOC_H__ */
