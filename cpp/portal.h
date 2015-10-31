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
#include <linux/types.h>  // has same typedefs as stdint.h
#include <linux/module.h>
#include <linux/kernel.h>
typedef struct task_struct *pthread_t;
int pthread_create(pthread_t *thread, void *attr, void *(*start_routine) (void *), void *arg);
#define PRIu64 "llx"
#define PRIx64 "llx"
#define PORTAL_PRINTF printk
#else
#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h> // for send()/recv()
#include <string.h> // memcpy
#include <stdio.h>   // printf()
#include <stdlib.h>  // exit()
#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#ifdef __cplusplus
#include <semaphore.h>
#include <unistd.h>
#include <pthread.h> // pthread_mutex_t
#endif

extern int simulator_dump_vcd;
extern const char *simulator_vcd_name;

#define PORTAL_PRINTF portal_printf
#endif

// Other constants
#define MAX_TIMERS    50
#define MAX_CLIENT_FD 10
#define DEFAULT_TILE  1

/*
 * Function vector for portal transport primitives used in generated C code
 */
struct PortalInternal;
typedef int  (*ITEMINIT)(struct PortalInternal *pint, void *param);
typedef unsigned int (*READWORD)(struct PortalInternal *pint, volatile unsigned int **addr);
typedef void (*WRITEWORD)(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
typedef void (*WRITEFDWORD)(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
typedef volatile unsigned int *(*MAPCHANNELIND)(struct PortalInternal *pint, unsigned int v);
typedef volatile unsigned int *(*MAPCHANNELREQ)(struct PortalInternal *pint, unsigned int v, unsigned int size);
typedef void (*SENDMSG)(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd);
typedef int  (*RECVMSG)(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd);
typedef int  (*BUSYWAIT)(struct PortalInternal *pint, unsigned int v, const char *str);
typedef void (*ENABLEINT)(struct PortalInternal *pint, int val);
typedef int  (*EVENT)(struct PortalInternal *pint);
typedef int  (*NOTFULL)(struct PortalInternal *pint, unsigned int v);
typedef struct {
    ITEMINIT    init;
    READWORD    read;
    WRITEWORD   write;
    WRITEFDWORD writefd;
    MAPCHANNELIND  mapchannelInd;
    MAPCHANNELREQ  mapchannelReq;
    SENDMSG     send;
    RECVMSG     recv;
    BUSYWAIT    busywait;
    ENABLEINT   enableint;
    EVENT       event;
    NOTFULL     notFull;
} PortalTransportFunctions;

/*
 * Indication function vector for method invocations from HW->SW
 */
typedef int (*PORTAL_INDFUNC)(struct PortalInternal *p, unsigned int channel, int messageFd);

/*
 * Disconnect indications from sockets
 */
typedef int (*PORTAL_DISCONNECT)(struct PortalInternal *pint);
typedef struct {
    PORTAL_DISCONNECT disconnect;
} PortalHandlerTemplate;

/*
 * Main data structure used for managing Portal info at runtime
 */
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
    PortalTransportFunctions    *item;
    PortalHandlerTemplate  *cb;
    struct PortalInternal  *mux;
    int                    muxid;
    int                    busyType;
#define BUSY_TIMEWAIT 0
#define BUSY_SPIN     1
#define BUSY_EXIT     2
#define BUSY_ERROR    3
    uint32_t               sharedMem;
    int                    indication_index;
    int                    request_index;
    int                    client_fd_number;
    int                    client_fd[MAX_CLIENT_FD];
    int                    mux_ports_number;
    struct PortalMuxHandler *mux_ports;
    void                   *websock;
    void                   *websock_context;
    void                   *websock_wsi;
    void                   *shared_dma;
    struct PortalInternal  *shared_cfg;
    int                    poller_register;
} PortalInternal;

typedef struct PortalMuxHandler {
    PortalInternal *pint;
} PortalMuxHandler;

/*
 * Struct definitions for optional parameter when initializing transport for portal
 */
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

typedef struct {
    const char *name;
    int         offset;
    int         itype;
} ConnectalParamJsonInfo;
typedef struct {
    const char *name;
    ConnectalParamJsonInfo *param;
} ConnectalMethodJsonInfo;
enum {ITYPE_other, ITYPE_int16_t, ITYPE_uint16_t, ITYPE_uint32_t, ITYPE_uint64_t, ITYPE_SpecialTypeForSendingFd,
      ITYPE_ChannelType, ITYPE_DmaDbgRec};

typedef int Bool;   /* for GeneratedTypes.h */
typedef uint32_t fixed32; /* for GeneratedTypes.h from protobuf */

#define SHARED_DMA(REQPORTALNAME, INDPORTALNAME) {NULL, (REQPORTALNAME), MMURequest_reqinfo, (INDPORTALNAME), MMUIndication_reqinfo, MMUIndication_handleMessage, (void *)&manualMMU_Cb, manualWaitForResp}
#define SHARED_HARDWARE(PORTALNAME) {(PORTALNAME), SharedMemoryPortalConfig_reqinfo, SharedMemoryPortalConfig_setSglId}
#define Connectaloffsetof(TYPE, MEMBER) ((unsigned long)&((TYPE *)0)->MEMBER)

/*
 * Address constants for portal memory mapped registers
 */
/* Divide up 20 bits of physical address space into Tile:Portal:Method selectors */
#define ADDRESS_TILE_SELECTOR   2
#define ADDRESS_PORTAL_SELECTOR 6
#define ADDRESS_METHOD_SELECTOR 7
#define ADDRESS_METHOD_SIZE     5

/* Offset of each /dev/fpgaxxx device in the address space */
#define PORTAL_BASE_OFFSET   (1 << (ADDRESS_METHOD_SIZE+ADDRESS_METHOD_SELECTOR))
#define TILE_BASE_OFFSET     (PORTAL_BASE_OFFSET << ADDRESS_PORTAL_SELECTOR)

/* Offsets of mapped registers within an /dev/fpgaxxx device */
#define PORTAL_FIFO(A)   ( (((A)+1) << ADDRESS_METHOD_SIZE) / sizeof(uint32_t) )

// PortalCtrl offsets
#define PORTAL_CTRL_INTERRUPT_STATUS 0
#define PORTAL_CTRL_INTERRUPT_ENABLE 1
#define PORTAL_CTRL_NUM_TILES        2
#define PORTAL_CTRL_IND_QUEUE_STATUS 3
#define PORTAL_CTRL_PORTAL_ID        4
#define PORTAL_CTRL_NUM_PORTALS      5
#define PORTAL_CTRL_COUNTER_MSB      6
#define PORTAL_CTRL_COUNTER_LSB      7

/*
 * Constants used in shared memory transport for portals
 */
#define SHARED_LIMIT  0
#define SHARED_WRITE  1
#define SHARED_READ   2
#define SHARED_START  4
#define REQINFO_SIZE(A)   ((A) & 0xffff)
#define REQINFO_COUNT(A) (((A) >> 16) & 0xffff)

#ifdef __cplusplus
extern "C" {
#endif
// Initialize portal control structure. (called by constructor when creating a portal at runtime)
void init_portal_internal(PortalInternal *pint, int id, int tile,
    PORTAL_INDFUNC handler, void *cb, PortalTransportFunctions *item,
    void *param, void *parent, uint32_t reqinfo);
int portal_disconnect(struct PortalInternal *p);
// Shared memory functions
void initPortalMemory(void);
int portalAlloc(size_t size, int cached);
void *portalMmap(int fd, size_t size);
int portalMunmap(void *addr, size_t size);
int portalCacheFlush(int fd, void *__p, long size, int flush);

// Timer functions
uint64_t portalCycleCount(void);
void portalTimerStart(unsigned int i);
uint64_t portalTimerLap(unsigned int i);
void portalTimerInit(void);
uint64_t portalTimerCatch(unsigned int i);
void portalTimerPrint(int loops);

// Functions shared across several portal transports
void enableint_portal_null(struct PortalInternal *pint, int val);
int busy_portal_null(struct PortalInternal *pint, unsigned int v, const char *str);
int notfull_null(PortalInternal *pint, unsigned int v);
void send_portal_null(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd);
int recv_portal_null(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd);
int event_null(struct PortalInternal *pint);
volatile unsigned int *mapchannel_req_generic(struct PortalInternal *pint, unsigned int v, unsigned int size);
unsigned int read_portal_memory(PortalInternal *pint, volatile unsigned int **addr);
void write_portal_memory(PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
void write_fd_portal_memory(PortalInternal *pint, volatile unsigned int **addr, unsigned int v);
void enableint_hardware(struct PortalInternal *pint, int val);
int busy_hardware(struct PortalInternal *pint, unsigned int v, const char *str);
int notfull_hardware(PortalInternal *pint, unsigned int v);
int event_hardware(struct PortalInternal *pint);
volatile unsigned int *mapchannel_hardware(struct PortalInternal *pint, unsigned int v);
volatile unsigned int *mapchannel_socket(struct PortalInternal *pint, unsigned int v);
int portal_mux_handler(struct PortalInternal *p, unsigned int channel, int messageFd);

// Json encode/decode functions called from generated code
void connectalJsonEncode(PortalInternal *pint, void *tempdata, ConnectalMethodJsonInfo *info);
int connnectalJsonDecode(PortalInternal *pint, int channel, void *tempdata, ConnectalMethodJsonInfo *info);

// Primitive used to send/recv data across a socket.
void portalSendFd(int fd, void *data, int len, int sendFd);
int portalRecvFd(int fd, void *data, int len, int *recvFd);
unsigned int bsim_poll_interrupt(void);
unsigned int read_pareff32(uint32_t pref, uint32_t offset);
unsigned int read_pareff64(uint64_t pref, uint64_t offset);

int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency);
void initPortalHardware(void);
void addFdToPoller(struct PortalPoller *poller, int fd);
#ifndef __KERNEL__
int portal_printf(const char *format, ...); // outputs to stderr
#endif

extern int global_sockfd, global_pa_fd;
extern PortalInternal *utility_portal;

// Portal transport variants
extern PortalTransportFunctions transportBsim, // Transport for bsim
  transportHardware,    // Memory-mapped register transport for hardware
  transportSocketInit,  // Linux socket transport (Unix sockets and TCP); Initiator side
                   // (the 'connect()' call is on Initiator side; Responder does 'listen()'
  transportSocketResp,  // Linux socket transport (Unix sockets and TCP); Responder side
  transportShared,      // Shared memory transport
  transportMux,         // Multiplex transport (to use 1 transport for all methods or multiple portals)
  transportTrace,       // Trace transport tee
  transportXsim,        // Xilinx xsim transport
  transportWebSocketInit, // Websocket transport; Initiator side
  transportWebSocketResp; // Websocket transport; Responder side
#ifdef __cplusplus
}
#endif

/*
 * C++ class definitions used in application software
 */
#ifdef __cplusplus
class Portal;
class PortalPoller {
private:
    Portal **portal_wrappers;
    pthread_mutex_t mutex;
    struct pollfd *portal_fds;
    int pipefd[2];
    int startThread;
    int numWrappers;
    int numFds;
public:
    PortalPoller(int autostart=1);
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
class Portal {
    void initPortal() {
        if (pint.handler || pint.poller_register) {
            if (pint.poller == 0)
                pint.poller = defaultPoller;
            pint.poller->registerInstance(this);
        }
    }
public:
    Portal(int id, int tile, uint32_t reqinfo, PORTAL_INDFUNC handler, void *cb, void *parent, PortalPoller *poller = 0) {
        init_portal_internal(&pint, id, tile, handler, cb, NULL, NULL, parent, reqinfo); 
        pint.poller = poller;
        initPortal();
    };
    Portal(int id, int tile, uint32_t reqinfo, PORTAL_INDFUNC handler, void *cb,
          PortalTransportFunctions *item, void *param, void *parent, PortalPoller *poller = 0) {
        init_portal_internal(&pint, id, tile, handler, cb, item, param, parent, reqinfo); 
        pint.poller = poller;
        initPortal();
    };
    ~Portal() {
        if (pint.handler)
            pint.poller->unregisterInstance(this);
        if (pint.fpga_fd > 0) {
            ::close(pint.fpga_fd);
            pint.fpga_fd = -1;
        }    
    };
    PortalInternal pint;
};

extern uint64_t poll_enter_time, poll_return_time; // for performance measurement
extern int mmu_error_limit, mem_error_limit;       // portalMemory
extern const char *dmaErrors[];                    // portalMemory
#endif // __cplusplus

#endif /* __PORTAL_OFFSETS_H__ */
