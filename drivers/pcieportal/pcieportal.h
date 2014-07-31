#ifndef __BLUENOC_H__
#define __BLUENOC_H__

#include <linux/ioctl.h>

/*
 * IOCTLs
 */

/* magic number for IOCTLs */
#define BNOC_IOC_MAGIC 0xB5

/* Structures used with IOCTLs */

typedef struct {
  unsigned int       board_number;
  unsigned int       portal_number;
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
  unsigned int trace;
  unsigned int oldTrace;
  unsigned int traceLength;
} tTraceInfo;

typedef struct {
  unsigned int offset;
  unsigned int value;
} tReadInfo;

typedef struct {
  unsigned int offset;
  unsigned int value;
} tWriteInfo;

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
#define PCIE_MANUAL_READ     _IOWR(BNOC_IOC_MAGIC,10,tReadInfo*)
#define PCIE_MANUAL_WRITE    _IOWR(BNOC_IOC_MAGIC,11,tWriteInfo*)
#define PCIE_SEND_FD         _IOR(BNOC_IOC_MAGIC,12,tSendFd*)

/* maximum valid IOCTL number */
#define BNOC_IOC_MAXNR 12

/* Number of boards to support */
#define NUM_BOARDS 1
#define NUM_PORTALS 16

/*
 * Per-device data
 */
typedef struct {
        unsigned int      portal_number;
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
        tPortal           portal[NUM_PORTALS];
        tBoardInfo        info; /* board identification fields */
        unsigned int      irq_num;
        unsigned int      open_count;
} tBoard;

#ifdef __KERNEL__
extern tBoard* get_pcie_portal_descriptor(void);
#endif

#endif /* __BLUENOC_H__ */
