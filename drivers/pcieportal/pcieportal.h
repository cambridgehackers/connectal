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

typedef unsigned int tTlpData[6];

/* IOCTL code definitions */

#define BNOC_IDENTIFY        _IOR(BNOC_IOC_MAGIC,0,tBoardInfo*)
#define BNOC_IDENTIFY_PORTAL _IOR(BNOC_IOC_MAGIC,6,tPortalInfo*)
#define BNOC_GET_TLP         _IOR(BNOC_IOC_MAGIC,7,tTlpData*)
#define BNOC_TRACE           _IOWR(BNOC_IOC_MAGIC,8,tTraceInfo*)

/* maximum valid IOCTL number */
#define BNOC_IOC_MAXNR 11

#endif /* __BLUENOC_H__ */
