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

#include <errno.h>

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
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <time.h> // ctime
#endif
#include "drivers/portalmem/portalmem.h" // PA_MALLOC
#define PLATFORM_TILE 0

static int init_serial(struct PortalInternal *pint, void *aparam)
{
    PortalSharedParam *param = (PortalSharedParam *)aparam;
    if (param) {
	struct termios terminfo;
	int rc;
	pint->map_base = (volatile unsigned int *)malloc(4096);
	pint->client_fd[0] = param->serial.serial_fd;
	pint->client_fd_number = 1;
	fprintf(stderr, "init_serial param=%p serial_fd=%d map_base=%p\n",
		param, param->serial.serial_fd, pint->map_base);

	pint->fpga_fd = param->serial.serial_fd;
	tcgetattr(pint->fpga_fd, &terminfo);
	terminfo.c_ispeed = B115200;
	terminfo.c_ospeed = B115200;
	terminfo.c_cflag = B115200 | CS8 | CLOCAL | CREAD | PARENB;
	terminfo.c_cflag &= ~CRTSCTS; // needed for /dev/tty.SLAB_USBtoUART
	terminfo.c_iflag = IGNCR;
	terminfo.c_lflag = ICANON;
	rc = tcsetattr(pint->fpga_fd, TCSANOW, &terminfo);
	if (rc != 0) {
	  fprintf(stderr, "tcsetattr %d errno %d:%s\n", rc, errno, strerror(errno));
	}
    }
    return 0;
}
static volatile unsigned int *mapchannel_serialInd(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[1024];
}
static volatile unsigned int *mapchannel_serialReq(struct PortalInternal *pint, unsigned int v, unsigned int size)
{
    return &pint->map_base[0+1];
}
static int busywait_serial(struct PortalInternal *pint, unsigned int v, const char *str)
{
    return 0;
}
static void send_serial(struct PortalInternal *pint, volatile unsigned int *buff, unsigned int hdr, int sendFd)
{
    int reqwords = hdr & 0xffff;

    pint->map_base[0] = hdr;
    fprintf(stderr, "send_serial head=%d hdr=%08x\n", pint->map_base[0], hdr);
    int nbytes = write(pint->client_fd[0], (void*)pint->map_base, 4*reqwords+4);
    if (nbytes != 4*reqwords+4) {
	fprintf(stderr, "%s:%d nbytes=%d errno=%d:%s\n", __FUNCTION__, __LINE__, nbytes, errno, strerror(errno));
    }
    pint->map_base[0] = 0;
}
static int event_serial(struct PortalInternal *pint)
{
    if (pint->map_base && pint->map_base[SHARED_READ] != pint->map_base[SHARED_WRITE]) {
    }
    return -1;
}
PortalTransportFunctions transportSerial = {
    init_serial, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_serialInd, mapchannel_serialReq,
    send_serial, recv_portal_null, busywait_serial, enableint_portal_null, event_serial, notfull_null};


