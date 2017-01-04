// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include "portal.h"
#include "dmaManager.h"
#include "sock_utils.h"

#ifdef __KERNEL__
#include "linux/delay.h"
#include "linux/file.h"
#include "linux/dma-buf.h"
#define assert(A)
#else
#include <string.h>
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <time.h> // ctime
#endif
#include "drivers/portalmem/portalmem.h" // PA_MALLOC
#define PLATFORM_TILE 0

static int init_shared(struct PortalInternal *pint, void *aparam)
{
    PortalSharedParam *param = (PortalSharedParam *)aparam;
    if (param) {
        int fd = portalAlloc(param->size, 1);
        pint->map_base = (volatile unsigned int *)portalMmap(fd, param->size);
        pint->map_base[SHARED_LIMIT] = param->size/sizeof(uint32_t);
        pint->map_base[SHARED_WRITE] = SHARED_START;
        pint->map_base[SHARED_READ] = SHARED_START;
        pint->map_base[SHARED_START] = 0;
        if (param->dma.manager)
            pint->shared_dma = &param->dma.manager->priv;
        else if (param->dma.reqinfo) {
            PortalInternal *psgl = (PortalInternal *)malloc(sizeof(PortalInternal));
            init_portal_internal(psgl, param->dma.reqport, PLATFORM_TILE, NULL,
                NULL, NULL, NULL, NULL, param->dma.reqinfo);
            DmaManagerPrivate *p = (DmaManagerPrivate *)malloc(sizeof(DmaManagerPrivate));
            pint->shared_dma = p;
            DmaManager_init(p, psgl);
            p->poll = param->dma.poll;
            p->shared_mmu_indication = (PortalInternal *)malloc(sizeof(PortalInternal));
            init_portal_internal(p->shared_mmu_indication, param->dma.indport, PLATFORM_TILE, param->dma.handler,
                param->dma.callbackFunctions, NULL, NULL, NULL, param->dma.indinfo);
        }
        DmaManagerPrivate *p = (DmaManagerPrivate *)pint->shared_dma;
        if (p) {
            pint->sharedMem = DmaManager_reference(p, fd);
            MMURequest_setInterface(p->sglDevice, pint->fpga_number, pint->sharedMem);
        }
        if (param->hardware.setSglId) {
            PortalInternal *p = (PortalInternal *)malloc(sizeof(PortalInternal));
            pint->shared_cfg = p;
            init_portal_internal(p, param->hardware.port, pint->fpga_tile, NULL,
                NULL, NULL, NULL, NULL, param->hardware.reqinfo);
            param->hardware.setSglId(p, pint->sharedMem);
        }
    }
    return 0;
}
static volatile unsigned int *mapchannel_sharedInd(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[pint->map_base[SHARED_READ]+1];
}
static volatile unsigned int *mapchannel_sharedReq(struct PortalInternal *pint, unsigned int v, unsigned int size)
{
    return &pint->map_base[pint->map_base[SHARED_WRITE]+1];
}
static int busywait_shared(struct PortalInternal *pint, unsigned int v, const char *str)
{
    int reqwords = REQINFO_SIZE(pint->reqinfo)/sizeof(uint32_t) + 1;
    reqwords = (reqwords + 1) & 0xfffe;
    volatile unsigned int *map_base = pint->map_base;
    int limit = map_base[SHARED_LIMIT];
    while (1) {
	int write = map_base[SHARED_WRITE];
	int read = map_base[SHARED_READ];
	int avail;
	if (write >= read) {
	    avail = limit - (write - read) - 4;
	} else {
	    avail = read - write;
	}
	int enqready = (avail > 2*reqwords); // might have to wrap
	//fprintf(stderr, "busywait_shared limit=%d write=%d read=%d avail=%d enqready=%d\n", limit, write, read, avail, enqready);
	if (avail < reqwords)
	    fprintf(stderr, "****\n    not enough space available \n****\n");
	if (enqready)
	    return 0;
    }
    return 0;
}
static inline unsigned int increment_shared(PortalInternal *pint, unsigned int newp)
{
    int reqwords = REQINFO_SIZE(pint->reqinfo)/sizeof(uint32_t) + 1;
    reqwords = (reqwords + 1) & 0xfffe;
    if (newp + reqwords >= pint->map_base[SHARED_LIMIT])
        newp = SHARED_START;
    return newp;
}
static void send_shared(struct PortalInternal *pint, volatile unsigned int *buff, unsigned int hdr, int sendFd)
{
    int reqwords = hdr & 0xffff;
    int needs_padding = (reqwords & 1);

    pint->map_base[pint->map_base[SHARED_WRITE]] = hdr;
    if (needs_padding) {
	// pad req
	pint->map_base[pint->map_base[SHARED_WRITE] + reqwords] = 0xffff0001;
	reqwords = (reqwords + 1) & 0xfffe;
    }
    pint->map_base[SHARED_WRITE] = increment_shared(pint, pint->map_base[SHARED_WRITE] + reqwords);
    //fprintf(stderr, "send_shared head=%d padded=%d hdr=%08x\n", pint->map_base[SHARED_WRITE], needs_padding, hdr);
    pint->map_base[pint->map_base[SHARED_WRITE]] = 0;
}
static int event_shared(struct PortalInternal *pint)
{
    if (pint->map_base && pint->map_base[SHARED_READ] != pint->map_base[SHARED_WRITE]) {
        unsigned int hdr = pint->map_base[pint->map_base[SHARED_READ]];
	unsigned short msg_num = hdr >> 16;
	unsigned short msg_words = hdr & 0xffff;
	msg_words = (msg_words + 1) & 0xfffe;
	if (msg_num != 0xffff && pint->handler)
	    pint->handler(pint, msg_num, 0);
        pint->map_base[SHARED_READ] = increment_shared(pint, pint->map_base[SHARED_READ] + msg_words);
    }
    return -1;
}
PortalTransportFunctions transportShared = {
    init_shared, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_sharedInd, mapchannel_sharedReq,
    send_shared, recv_portal_null, busywait_shared, enableint_portal_null, event_shared, notfull_null};
static volatile unsigned int *mapchannel_traceInd(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[pint->map_base[SHARED_READ]];
}
static volatile unsigned int *mapchannel_traceReq(struct PortalInternal *pint, unsigned int v, unsigned int size)
{
    return &pint->map_base[pint->map_base[SHARED_WRITE]];
}
extern void memdump(uint8_t *p, int len, const char *title);
static void send_trace(struct PortalInternal *pint, volatile unsigned int *buff, unsigned int hdr, int sendFd)
{
    int reqwords = hdr & 0xffff;
    pint->map_base[pint->map_base[SHARED_WRITE]+reqwords-1] = hdr;
    pint->map_base[SHARED_WRITE] = increment_shared(pint, pint->map_base[SHARED_WRITE] + reqwords);
    //fprintf(stderr, "send_shared head=%d padded=%d hdr=%08x\n", pint->map_base[SHARED_WRITE], needs_padding, hdr);
    pint->map_base[pint->map_base[SHARED_WRITE]] = 0;
}
PortalTransportFunctions transportTrace = {
    init_shared, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_traceInd, mapchannel_traceReq,
    send_trace, recv_portal_null, busywait_shared, enableint_portal_null, event_shared, notfull_null};


