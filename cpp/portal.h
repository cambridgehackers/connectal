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
#ifndef __KERNEL__
#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h> // for send()/recv()
#endif

/* Offset of each /dev/fpgaxxx device in the address space */
#define PORTAL_BASE_OFFSET         (1 << 16)

/* Offsets of mapped registers within an /dev/fpgaxxx device */
#define PORTAL_REQ_FIFO(A)         (((0<<14) + (A) * 256 + 256)/sizeof(uint32_t))
#define PORTAL_IND_FIFO(A)         (((0<<14) + (A) * 256 + 256)/sizeof(uint32_t))
#define PORTAL_IND_REG_OFFSET_32   ( (0<<14)             /sizeof(uint32_t))
#define     IND_REG_INTERRUPT_FLAG    (PORTAL_IND_REG_OFFSET_32 + 0)
#define     IND_REG_INTERRUPT_MASK    (PORTAL_IND_REG_OFFSET_32 + 1)
#define     IND_REG_INTERRUPT_COUNT   (PORTAL_IND_REG_OFFSET_32 + 2)
#define     IND_REG_QUEUE_STATUS      (PORTAL_IND_REG_OFFSET_32 + 6)

// Directory offsets

#define PORTAL_DIRECTORY_OFFSET(A)      &globalDirectory.map_base[128+(A)]
#define PORTAL_DIRECTORY_VERSION        PORTAL_DIRECTORY_OFFSET(0)
#define PORTAL_DIRECTORY_TIMESTAMP      PORTAL_DIRECTORY_OFFSET(1)
#define PORTAL_DIRECTORY_NUMPORTALS     PORTAL_DIRECTORY_OFFSET(2)
#define PORTAL_DIRECTORY_ADDRBITS       PORTAL_DIRECTORY_OFFSET(3)
#define PORTAL_DIRECTORY_COUNTER_MSB    PORTAL_DIRECTORY_OFFSET(4)
#define PORTAL_DIRECTORY_COUNTER_LSB    PORTAL_DIRECTORY_OFFSET(5)
#define PORTAL_DIRECTORY_PORTAL_ID(A)   PORTAL_DIRECTORY_OFFSET(6 + 2 * (A))
#define PORTAL_DIRECTORY_PORTAL_TYPE(A) PORTAL_DIRECTORY_OFFSET(6 + 2 * (A) + 1)

typedef int Bool;   /* for GeneratedTypes.h */
typedef int SpecialTypeForSendingFd;   /* for GeneratedTypes.h */
struct PortalInternal;
typedef int (*PORTAL_INDFUNC)(struct PortalInternal *p, unsigned int channel);
typedef struct PortalInternal {
  struct PortalPoller   *poller;
  int                    fpga_fd;
  int                    fpga_number;
  volatile unsigned int *map_base;
  void                  *parent;
  PORTAL_INDFUNC         handler;
  uint32_t               reqsize;
  int                    accept_finished;
} PortalInternal;

#ifdef __KERNEL__
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/types.h>  // has same typedefs as stdint.h

typedef struct task_struct *pthread_t;
int pthread_create(pthread_t *thread, void *attr, void *(*start_routine) (void *), void *arg);
#define PRIu64 "llx"
#define PRIx64 "llx"

#define PORTAL_PRINTF printk
#else
#include <stdio.h>   // printf()
#include <stdlib.h>  // exit()
#include <stdint.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#define PORTAL_PRINTF printf
#endif

#ifdef __cplusplus
extern "C" {
#endif
void init_portal_internal(PortalInternal *pint, int id, PORTAL_INDFUNC handler, uint32_t reqsize);
uint64_t portalCycleCount(void);
unsigned int portalGetFpga(unsigned int id);
unsigned int portalGetAddrbits(unsigned int id);
unsigned int read_portal_bsim(volatile unsigned int *addr, int id);
void write_portal_bsim(volatile unsigned int *addr, unsigned int v, int id);
void write_portal_fd_bsim(volatile unsigned int *addr, unsigned int v, int id);

void portalTimerInit(void);
void portalTimerStart(unsigned int i);
uint64_t portalTimerLap(unsigned int i);
uint64_t portalTimerCatch(unsigned int i);
void portalTimerPrint(int loops);

// uses the default poller
void* portalExec(void* __x);
/* fine grained functions for building custom portalExec */
void* portalExec_init(void);
void* portalExec_poll(int timeout);
void* portalExec_event(void);
void portalExec_start(void);
void portalExec_end(void);
void portalTrace_start(void);
void portalTrace_stop(void);
int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
void portalEnableInterrupts(PortalInternal *p, int val);
int portalDCacheFlushInval(int fd, long size, void *__p);
void init_portal_memory(void);
int portalAlloc(size_t size);
void *portalMmap(int fd, size_t size);
void portalInitiator(void);
void portalSend(int fd, void *data, int len);
int portalRecv(int fd, void *data, int len);

extern int portalExec_timeout;
extern int global_pa_fd;
extern int global_sockfd;
extern int we_are_initiator;
extern PortalInternal globalDirectory;
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include "poller.h"
#endif

#define MAX_TIMERS 50

#if !defined(BSIM)
#define READL(CITEM, A)     (*(A))
#define WRITEL(CITEM, A, B) (*(A) = (B))
#define WRITEFD(CITEM, A, B) {}
#else
#define READL(CITEM, A)     read_portal_bsim((A), (CITEM)->fpga_number)
#define WRITEL(CITEM, A, B) write_portal_bsim((A), (B), (CITEM)->fpga_number)
#define WRITEFD(CITEM, A, B) write_portal_fd_bsim((A), (B), (CITEM)->fpga_number)
#endif

#endif /* __PORTAL_OFFSETS_H__ */
