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
  unsigned int       is_active;
  unsigned int       major_rev;
  unsigned int       minor_rev;
  unsigned int       build;
  unsigned int       timestamp;
  unsigned int       bytes_per_beat;
  unsigned long long content_id;
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
  dma_addr_t dma_handle;
} tPciAlloc;

typedef unsigned int tDebugLevel;

typedef unsigned int tTlpData[6];

const tDebugLevel DEBUG_OFF     =        0;
const tDebugLevel DEBUG_CALLS   = (1 <<  0);
const tDebugLevel DEBUG_DATA    = (1 <<  1);
const tDebugLevel DEBUG_DMA     = (1 <<  2);
const tDebugLevel DEBUG_INTR    = (1 <<  3);
const tDebugLevel DEBUG_PROFILE = (1 << 31);

/* IOCTL code definitions */

#define BNOC_IDENTIFY        _IOR(BNOC_IOC_MAGIC,0,tBoardInfo*)
#define BNOC_SOFT_RESET      _IO(BNOC_IOC_MAGIC,1)
#define BNOC_DEACTIVATE      _IO(BNOC_IOC_MAGIC,2)
#define BNOC_REACTIVATE      _IO(BNOC_IOC_MAGIC,3)
#define BNOC_GET_DEBUG_LEVEL _IOR(BNOC_IOC_MAGIC,4,tDebugLevel*)
#define BNOC_SET_DEBUG_LEVEL _IOW(BNOC_IOC_MAGIC,5,tDebugLevel*)
#define BNOC_IDENTIFY_PORTAL _IOR(BNOC_IOC_MAGIC,6,tPortalInfo*)
#define BNOC_GET_TLP         _IOR(BNOC_IOC_MAGIC,7,tTlpData*)
#define BNOC_TRACE           _IOWR(BNOC_IOC_MAGIC,8,int*)
#define BNOC_SEQNO           _IOWR(BNOC_IOC_MAGIC,9,int*)
#define BNOC_DMA_MAP         _IOWR(BNOC_IOC_MAGIC,10,long)
#define BNOC_PCI_ALLOC       _IOWR(BNOC_IOC_MAGIC,11,tPciAlloc*)

/* maximum valid IOCTL number */
#define BNOC_IOC_MAXNR 11

#endif /* __BLUENOC_H__ */
