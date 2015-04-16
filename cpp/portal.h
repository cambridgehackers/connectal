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
#ifdef __KERNEL__
#include <linux/types.h>
#else
#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h> // for send()/recv()
#include <string.h> // memcpy
#endif

/* division of 20 bits of physical address space */
#define TILE_SEL   2
#define PORTAL_SEL 6
#define METHOD_SEL 7
#define METHOD_SZ  5

/* Offset of each /dev/fpgaxxx device in the address space */
#define PORTAL_BASE_OFFSET         (1 << (METHOD_SZ+METHOD_SEL))
#define TILE_BASE_OFFSET           (1 << (PORTAL_SEL+METHOD_SZ+METHOD_SEL))

/* Offsets of mapped registers within an /dev/fpgaxxx device */
#define PORTAL_REQ_FIFO(A)         (((A << (METHOD_SZ)) + (1 << (METHOD_SZ)))/sizeof(uint32_t))
#define PORTAL_IND_FIFO(A)         (((A << (METHOD_SZ)) + (1 << (METHOD_SZ)))/sizeof(uint32_t))

// PortalCtrl offsets
#define PORTAL_CTRL_INTERRUPT_STATUS 0
#define PORTAL_CTRL_INTERRUPT_ENABLE 1
#define PORTAL_CTRL_NUM_TILES        2
#define PORTAL_CTRL_IND_QUEUE_STATUS 3
#define PORTAL_CTRL_PORTAL_ID        4
#define PORTAL_CTRL_NUM_PORTALS      5
#define PORTAL_CTRL_COUNTER_MSB      6
#define PORTAL_CTRL_COUNTER_LSB      7


// PortalCtrl registers
#define PORTAL_CTRL_REG_OFFSET_32        0
#define PORTAL_CTRL_REG_INTERRUPT_STATUS (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_INTERRUPT_STATUS)
#define PORTAL_CTRL_REG_INTERRUPT_ENABLE (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_INTERRUPT_ENABLE)
#define PORTAL_CTRL_REG_NUM_TILES        (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_NUM_TILES       )
#define PORTAL_CTRL_REG_IND_QUEUE_STATUS (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_IND_QUEUE_STATUS)
#define PORTAL_CTRL_REG_PORTAL_ID        (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_PORTAL_ID       )
#define PORTAL_CTRL_REG_NUM_PORTALS      (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_NUM_PORTALS     )
#define PORTAL_CTRL_REG_COUNTER_MSB      (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_COUNTER_MSB     )
#define PORTAL_CTRL_REG_COUNTER_LSB      (PORTAL_CTRL_REG_OFFSET_32 + PORTAL_CTRL_COUNTER_LSB     )


typedef int Bool;   /* for GeneratedTypes.h */
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
    uint32_t               fpga_number;
    uint32_t               fpga_tile;
    volatile unsigned int *map_base;
    void                  *parent;
    PORTAL_INDFUNC         handler;
    uint32_t               reqinfo;
    int                    accept_finished;
    PortalItemFunctions    *item;
    void                   *cb;
    struct PortalInternal  *mux;
    int                    muxid;
    int                    busyType;
    uint32_t               sharedMem;
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
    void                   *websock;
    void                   *websock_context;
    void                   *websock_wsi;
    void                   *shared_dma;
    struct PortalInternal  *shared_cfg;
    int                    poller_register;
} PortalInternal;

#define SHARED_DMA(REQPORTALNAME, INDPORTALNAME) {NULL, (REQPORTALNAME), MMURequest_reqinfo, (INDPORTALNAME), MMUIndication_reqinfo, MMUIndication_handleMessage, (void *)&manualMMU_Cb, manualWaitForResp}
#define SHARED_HARDWARE(PORTALNAME) {(PORTALNAME), SharedMemoryPortalConfig_reqinfo, SharedMemoryPortalConfig_setSglId}
typedef int (*SHARED_CONFIG_SETSGLID)(struct PortalInternal *, const uint32_t sglId);
typedef int (*SHARED_MMUINDICATION_POLL)(PortalInternal *p, uint32_t *arg_id);
typedef struct {
    struct {
        struct DmaManager *manager;
        int reqport;
        int reqinfo;
        int indport;
        int indinfo;
        PORTAL_INDFUNC     handler;
        void              *callbackFunctions;
        SHARED_MMUINDICATION_POLL poll;
    } dma;
    uint32_t    size;
    struct {
        int port;
        uint32_t reqinfo;
        SHARED_CONFIG_SETSGLID setSglId;
    } hardware;
} PortalSharedParam; /* for ITEMINIT function */

typedef struct {
    PortalInternal       *pint;
    void                 *socketParam;
} PortalMuxParam;

enum {ITYPE_other, ITYPE_int16_t, ITYPE_uint16_t, ITYPE_uint32_t, ITYPE_uint64_t, ITYPE_SpecialTypeForSendingFd,
      ITYPE_ChannelType, ITYPE_DmaDbgRec};
typedef struct {
    const char *name;
    int         offset;
    int         itype;
} ConnectalParamJsonInfo;
typedef struct {
    const char *name;
    ConnectalParamJsonInfo *param;
} ConnectalMethodJsonInfo;
void connectalJsonEncode(PortalInternal *pint, void *tempdata, ConnectalMethodJsonInfo *info);
int connnectalJsonDecode(PortalInternal *pint, int channel, void *tempdata, ConnectalMethodJsonInfo *info);

#define Connectaloffsetof(TYPE, MEMBER) ((unsigned long)&((TYPE *)0)->MEMBER)

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

extern int debug_portal;
#define PORTAL_PRINTF portal_printf
#endif

#ifdef __cplusplus
extern "C" {
#endif
#ifndef __KERNEL__
int portal_printf(const char *format, ...); // outputs to stderr
#endif
void init_portal_internal(PortalInternal *pint, int id, int tile, PORTAL_INDFUNC handler, void *cb, PortalItemFunctions *item, void *param, uint32_t reqinfo);
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
int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
  int portalDCacheFlushInvalInternal(int fd, long size, void *__p, int flush);
void portalDCacheFlushInval(int fd, long size, void *__p);
void portalDCacheInval(int fd, long size, void *__p);
void init_portal_memory(void);
int portalAlloc(size_t size);
int portalAllocCached(size_t size, int cached);
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
volatile unsigned int *mapchannel_socket(struct PortalInternal *pint, unsigned int v);
unsigned int bsim_poll_interrupt(void);

extern int portalExec_timeout;
extern int global_pa_fd;
extern int global_sockfd;
extern PortalInternal *utility_portal;
extern PortalItemFunctions bsimfunc, hardwarefunc,
  socketfuncInit, socketfuncResp, sharedfunc, muxfunc, tracefunc, xsimfunc,
  websocketfuncInit, websocketfuncResp;
#ifdef __cplusplus
}
#endif

#define MAX_TIMERS 50

#define SHARED_LIMIT  0
#define SHARED_WRITE  1
#define SHARED_READ   2
#define SHARED_START  4
#define REQINFO_SIZE(A) ((A) & 0xffff)
#define REQINFO_COUNT(A) (((A) >> 16) & 0xffff)

#ifdef __cplusplus
#include <semaphore.h>
#include <unistd.h>
#include <pthread.h> // pthread_mutex_t

class Portal;
class PortalPoller {
private:
  Portal **portal_wrappers;
  pthread_mutex_t mutex;
  struct pollfd *portal_fds;
  int pipefd[2];
  int inited;
  int numWrappers;
  int numFds;
public:
  PortalPoller();
  int registerInstance(Portal *portal);
  int unregisterInstance(Portal *portal);
  void *init(void);
  void *pollFn(int timeout);
  void *event(void);
  void end(void);
  void start();
  void stop();
  void addFd(int fd);
  int timeout;
  int stopping;
  sem_t sem_startup;
  void* threadFn(void* __x);
};

extern PortalPoller *defaultPoller;
extern uint64_t poll_enter_time, poll_return_time; // for performance measurement

class PortalInternalCpp
{
 public:
  PortalInternal pint;
  PortalInternalCpp(int id, int tile, PORTAL_INDFUNC handler, void *cb, PortalItemFunctions* item, void *param, uint32_t reqinfo) { 
    init_portal_internal(&pint, id, tile, handler, cb, item, param, reqinfo); 
    //fprintf(stderr, "PortalInternalCpp %d\n", pint.fpga_number);
  };
  ~PortalInternalCpp() {
    if (pint.fpga_fd > 0) {
        ::close(pint.fpga_fd);
        pint.fpga_fd = -1;
    }    
  };
};

class Portal : public PortalInternalCpp
{
   void initPortal() {
    if (pint.handler || pint.poller_register) {
      if (pint.poller == 0)
        pint.poller = defaultPoller;
      pint.poller->registerInstance(this);
    }
  }
 public:
  Portal(int id, int tile, uint32_t reqinfo, PORTAL_INDFUNC handler, void *cb, PortalPoller *poller = 0) : PortalInternalCpp(id, tile, handler, cb, NULL, NULL, reqinfo) {
    pint.poller = poller;
    initPortal();
  };
  Portal(int id, int tile, uint32_t reqinfo, PORTAL_INDFUNC handler, void *cb, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : PortalInternalCpp(id, tile, handler, cb, item, param, reqinfo) {
    pint.poller = poller;
    initPortal();
  };
  ~Portal() { if (pint.handler) pint.poller->unregisterInstance(this); };
};
#endif // __cplusplus

#endif /* __PORTAL_OFFSETS_H__ */
