
// Copyright (c) 2018, The Connectal Project

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
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

static int trace_portal=0;
static void enableint_portal(struct PortalInternal *pint, int val)
{
   pint->map_base[PORTAL_CTRL_INTERRUPT_ENABLE] = val;
}
static int event_portal(struct PortalInternal *pint)
{
    // handle all messasges from this portal instance
    volatile unsigned int *map_base = pint->map_base, len;
    while ((len = map_base[PORTAL_CTRL_IND_QUEUE_STATUS])) {
        if(trace_portal)
            PORTAL_PRINTF( "%s: (fpga%d) about to receive messages int=%08x en=%08x qs=%08x handler %p parent %p\n", __FUNCTION__, pint->fpga_number, 0, 0, 0, pint->handler, pint->parent);
        if (pint->handler)
            pint->handler(pint, 5/*portal number ATOMICC */, 0);
        else {
            PORTAL_PRINTF( "%s: (fpga%d) no handler receive int=%08x en=%08x qs=%08x handler %p parent %p\n", __FUNCTION__, pint->fpga_number, 0, 0, 0, pint->handler, pint->parent);
            exit(-1);
        }
    }
    return -1;
}

static volatile unsigned int *portalPtr;
static int init_portal(struct PortalInternal *pint, void *param)
{
    initPortalHardware();
    char oldname[128];
    int i;
    snprintf(oldname, sizeof(oldname), "/dev/portal_%d_%d", pint->fpga_tile, pint->fpga_number);
    //FIXME: race condition on Zynq between cat /dev/connectal and here
    for (i = 0; i < 5; i++) {
	// try old style name
	pint->fpga_fd = open(oldname, O_RDWR);
	if (pint->fpga_fd >= 0)
	    break;

	// retry if EACCESS
	if (errno == EACCES && i != 4) {
	    sleep(1);
	    continue;
	}

	// else fail
	PORTAL_PRINTF("Failed to open %s fd=%d errno=%d:%s\n", oldname, pint->fpga_fd, errno, strerror(errno));
	return -errno;
    }
    pint->map_base = (volatile unsigned int*)portalMmap(pint->fpga_fd, PORTAL_BASE_OFFSET);
    if (pint->map_base == MAP_FAILED) {
        PORTAL_PRINTF("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", pint->fpga_fd, errno);
        return -errno;
    }  
    portalPtr = &pint->map_base[PORTAL_FIFO(0)];
    return 0;
}
static void send_portal(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    volatile unsigned int *buffer = data-1;
    //if(trace_portal)
        fprintf(stderr, "[%s:%d] hdr %x fpga %x num %d\n", __FUNCTION__, __LINE__, hdr, pint->fpga_number, pint->client_fd_number);
    buffer[0] = hdr;
    if (!portalPtr[1]) {
        printf("[%s:%d] ERROR: queue full\n", __FUNCTION__, __LINE__);
        return;
    }
    int i = (hdr & 0xffff) - 2;
    for (; i > 0; i--) {
printf("[SEND] data[%d] = %x\n", i, data[i]);
        portalPtr[0] = data[i];
    }
printf("[SEND] Ldata[%d] = %x\n", 0, data[0]);
    portalPtr[1] = data[0];
}
static int recv_portal(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    int i;
    for (i = 0; i < len; i++) {
        buffer[i] = portalPtr[0];
printf("[RECV] data[%d] = %x\n", i, buffer[i]);
    }
    return 0;
}

PortalTransportFunctions transportPortal = {
    init_portal, NULL, NULL, NULL, NULL, NULL,
    send_portal, recv_portal, NULL, enableint_portal, event_portal, NULL};
