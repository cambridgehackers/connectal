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
#include "portalmem.h" // PA_MALLOC

static int init_shared(struct PortalInternal *pint, void *aparam)
{
    PortalSharedParam *param = (PortalSharedParam *)aparam;
    if (param) {
        int fd = portalAlloc(param->size);
        pint->map_base = (volatile unsigned int *)portalMmap(fd, param->size);
        pint->map_base[SHARED_LIMIT] = param->size/sizeof(uint32_t);
        pint->map_base[SHARED_WRITE] = SHARED_START;
        pint->map_base[SHARED_READ] = SHARED_START;
        pint->map_base[SHARED_START] = 0;
        unsigned int ref = param->dma->reference(fd);
        MMURequest_setInterface(param->dma->priv.sglDevice, pint->fpga_number, ref);
    }
    return 0;
}
static volatile unsigned int *mapchannel_sharedInd(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[pint->map_base[SHARED_READ]+1];
}
static volatile unsigned int *mapchannel_sharedReq(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[pint->map_base[SHARED_WRITE]+1];
}
static inline unsigned int increment_shared(PortalInternal *pint, unsigned int newp)
{
    if (newp + pint->reqsize/sizeof(uint32_t) + 1 >= pint->map_base[SHARED_LIMIT])
        newp = SHARED_START;
    return newp;
}
static void send_shared(struct PortalInternal *pint, volatile unsigned int *buff, unsigned int hdr, int sendFd)
{
    pint->map_base[pint->map_base[SHARED_WRITE]] = hdr;
    pint->map_base[SHARED_WRITE] = increment_shared(pint, pint->map_base[SHARED_WRITE] + (hdr & 0xffff));
    pint->map_base[pint->map_base[SHARED_WRITE]] = 0;
}
static int event_shared(struct PortalInternal *pint)
{
    if (pint->map_base && pint->map_base[SHARED_READ] != pint->map_base[SHARED_WRITE]) {
        unsigned int rc = pint->map_base[pint->map_base[SHARED_READ]];
        pint->handler(pint, rc >> 16, 0);
        pint->map_base[SHARED_READ] = increment_shared(pint, pint->map_base[SHARED_READ] + (rc & 0xffff));
    }
    return -1;
}
PortalItemFunctions sharedfunc = {
    init_shared, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_sharedInd, mapchannel_sharedReq,
    send_shared, recv_portal_null, busy_portal_null, enableint_portal_null, event_shared};


