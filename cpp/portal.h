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

// PortalCtrl offsets
#define PORTAL_CTRL_INTERRUPT_STATUS 0
#define PORTAL_CTRL_INTERRUPT_ENABLE 1
#define PORTAL_CTRL_SEVEN            2
#define PORTAL_CTRL_IND_QUEUE_STATUS 3
#define PORTAL_CTRL_PORTAL_ID        4
#define PORTAL_CTRL_TOP              5
#define PORTAL_CTRL_COUNTER_MSB      6
#define PORTAL_CTRL_COUNTER_LSB      7


// PortalCtrl registers
#define PORTAL_CTRL_REG_OFFSET_32   ( (0<<14)             /sizeof(uint32_t))
#define PORTAL_CTRL_REG_INTERRUPT_STATUS (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_INTERRUPT_STATUS)
#define PORTAL_CTRL_REG_INTERRUPT_ENABLE (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_INTERRUPT_ENABLE)
#define PORTAL_CTRL_REG_SEVEN            (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_SEVEN           )
#define PORTAL_CTRL_REG_IND_QUEUE_STATUS (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_IND_QUEUE_STATUS)
#define PORTAL_CTRL_REG_PORTAL_ID        (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_PORTAL_ID       )
#define PORTAL_CTRL_REG_TOP              (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_TOP             )
#define PORTAL_CTRL_REG_COUNTER_MSB      (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_COUNTER_MSB     )
#define PORTAL_CTRL_REG_COUNTER_LSB      (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_COUNTER_LSB     )


typedef int Bool;   /* for GeneratedTypes.h */
typedef int SpecialTypeForSendingFd;
struct PortalInternal;
typedef int (*ITEMINIT)(struct PortalInternal *pint, void *param);
typedef int (*PORTAL_INDFUNC)(struct PortalInternal *p, unsigned int channel, int messageFd);
typedef void (*SENDMSG)(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd);
typedef int (*RECVMSG)(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd);
typedef unsigned int (*READWORD)(struct PortalInternal *pint, volatile unsigned int **addr);
typedef void (*WRITEWORD)(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
typedef void (*WRITEFDWORD)(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
typedef int (*BUSYWAIT)(struct PortalInternal *pint, unsigned int v, const char *str);
typedef void (*ENABLEINT)(struct PortalInternal *pint, int val);
typedef volatile unsigned int *(*MAPCHANNEL)(struct PortalInternal *pint, unsigned int v);
typedef int (*EVENT)(struct PortalInternal *pint);
typedef int (*NOTFULL)(struct PortalInternal *pint, unsigned int v);
typedef struct {
    ITEMINIT    init;
    READWORD    read;
    WRITEWORD   write;
    WRITEFDWORD writefd;
    MAPCHANNEL  mapchannelInd;
    MAPCHANNEL  mapchannelReq;
    SENDMSG     send;
    RECVMSG     recv;
    BUSYWAIT    busywait;
    ENABLEINT   enableint;
    EVENT       event;
    NOTFULL     notFull;
} PortalItemFunctions;

typedef struct {
  struct PortalInternal *pint;
} PortalMuxHandler;

#define MAX_CLIENT_FD 10
typedef struct PortalInternal {
  struct PortalPoller   *poller;
  int                    fpga_fd;
  int                    fpga_number;
  volatile unsigned int *map_base;
  void                  *parent;
  PORTAL_INDFUNC         handler;
  uint32_t               reqsize;
  int                    accept_finished;
  PortalItemFunctions    *item;
  void                   *cb;
  struct PortalInternal  *mux;
  int                    muxid;
  int                    busyType;
#define BUSY_TIMEWAIT 0
#define BUSY_SPIN     1
#define BUSY_EXIT     2
#define BUSY_ERROR    3
  int                    indication_index;
  int                    request_index;
  int                    client_fd_number;
  int                    client_fd[MAX_CLIENT_FD];
  int                    mux_ports_number;
  PortalMuxHandler       *mux_ports;
} PortalInternal;

typedef struct {
    struct DmaManager *dma;
    uint32_t    size;
} PortalSharedParam; /* for ITEMINIT function */

typedef struct PortalSocketParam {
    struct addrinfo *addr;
} PortalSocketParam; /* for ITEMINIT function */

typedef struct {
    PortalInternal       *pint;
    void                 *socketParam;
} PortalMuxParam;

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
void init_portal_internal(PortalInternal *pint, int id, PORTAL_INDFUNC handler, void *cb, PortalItemFunctions *item, void *param, uint32_t reqsize);
void portalCheckIndication(PortalInternal *pint);
uint64_t portalCycleCount(void);
void write_portal_fd_bsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v);

// uses the default poller
void* portalExec(void* __x);
/* fine grained functions for building custom portalExec */
void* portalExec_init(void);
void* portalExec_poll(int timeout);
void* portalExec_event(void);
void portalExec_start(void);
void portalExec_stop(void);
void portalExec_end(void);
void portalTrace_start(void);
void portalTrace_stop(void);
int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
int portalDCacheFlushInval(int fd, long size, void *__p);
void init_portal_memory(void);
int portalAlloc(size_t size);
void *portalMmap(int fd, size_t size);
void portalSendFd(int fd, void *data, int len, int sendFd);
int portalRecvFd(int fd, void *data, int len, int *recvFd);

void portalTimerStart(unsigned int i);
uint64_t portalTimerLap(unsigned int i);
void portalTimerInit(void);
uint64_t portalTimerCatch(unsigned int i);
void portalTimerPrint(int loops);

void send_portal_null(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd);
int recv_portal_null(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd);
int busy_portal_null(struct PortalInternal *pint, unsigned int v, const char *str);
void enableint_portal_null(struct PortalInternal *pint, int val);
unsigned int read_portal_memory(PortalInternal *pint, volatile unsigned int **addr);
void write_portal_memory(PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
void write_fd_portal_memory(PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
volatile unsigned int *mapchannel_hardware(struct PortalInternal *pint, unsigned int v);
int busy_hardware(struct PortalInternal *pint, unsigned int v, const char *str);
void enableint_hardware(struct PortalInternal *pint, int val);
int event_hardware(struct PortalInternal *pint);
void addFdToPoller(struct PortalPoller *poller, int fd);
int portal_mux_handler(struct PortalInternal *p, unsigned int channel, int messageFd);
int notfull_null(PortalInternal *pint, unsigned int v);
int notfull_hardware(PortalInternal *pint, unsigned int v);

extern int portalExec_timeout;
extern int global_pa_fd;
extern int global_sockfd;
extern PortalInternal *utility_portal;
extern PortalItemFunctions bsimfunc, hardwarefunc,
    socketfuncInit, socketfuncResp, sharedfunc, muxfunc;
#ifdef __cplusplus
}
#endif
#ifdef __cplusplus
#include "poller.h"
#endif

#define MAX_TIMERS 50

#define SHARED_LIMIT  0
#define SHARED_WRITE  1
#define SHARED_READ   2
#define SHARED_START  4

#endif /* __PORTAL_OFFSETS_H__ */
