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

#include <arpa/inet.h>
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
	int serial_fd = param->serial.serial_fd;
	pint->map_base = (volatile unsigned int *)malloc(4096);
	pint->client_fd[0] = serial_fd;
	pint->client_fd_number = 1;
	fprintf(stderr, "init_serial param=%p serial_fd=%d map_base=%p\n",
		param, param->serial.serial_fd, pint->map_base);

	if (0) {
	    struct termios terminfo;
	    int rc;
	    tcflush(serial_fd, TCIOFLUSH);
	    tcgetattr(serial_fd, &terminfo);
	    terminfo.c_ispeed = B115200;
	    terminfo.c_ospeed = B115200;
	    terminfo.c_cflag = B115200 | CS8 | CLOCAL | CREAD | PARENB;
	    terminfo.c_cflag &= ~CRTSCTS; // needed for /dev/tty.SLAB_USBtoUART
	    terminfo.c_iflag = IGNCR;
	    terminfo.c_lflag = ICANON;
	    rc = tcsetattr(serial_fd, TCSANOW, &terminfo);
	    if (rc != 0) {
		fprintf(stderr, "tcsetattr %d errno %d:%s\n", rc, errno, strerror(errno));
	    }
	}
    }
    return 0;
}
static volatile unsigned int *mapchannel_serialInd(struct PortalInternal *pint, unsigned int v)
{
    return &pint->map_base[128+1];
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
    fprintf(stderr, "send_serial head=%d hdr=%08x reqwords=%d\n", pint->map_base[0], hdr, reqwords);
    if (0)
    for (int i = 0; i < reqwords+1; i++)
	pint->map_base[i] = htonl(pint->map_base[i]);
    int nbytes = write(pint->client_fd[0], (void*)pint->map_base, 4*reqwords);
    if (nbytes != 4*reqwords) {
	fprintf(stderr, "%s:%d nbytes=%d errno=%d:%s\n", __FUNCTION__, __LINE__, nbytes, errno, strerror(errno));
    }
    pint->map_base[0] = 0;
    tcdrain(pint->client_fd[0]);
}
static int event_serial(struct PortalInternal *pint)
{
    if (0) fprintf(stderr, "%s:%d serial_fd=%d\n", __FUNCTION__, __LINE__, pint->client_fd[0]);
    int nbytes;
    int i = 0;
    char *base = (char *)&pint->map_base[128];
    int tries = 0;
    do {
      nbytes = read(pint->client_fd[0], (void*)(base + i), 1);
      if (nbytes > 0)
	i += nbytes;
      if (0) fprintf(stderr, "%s:%d i=%d nbytes=%d hdr=%#08x\n", __FUNCTION__, __LINE__, i, nbytes, pint->map_base[128]);
      if (i == 4) {
	int reqwords = pint->map_base[128] & 0xFFFF;
	int msg_num = pint->map_base[128] >> 16;
	if (reqwords > 1) {
	  nbytes = read(pint->client_fd[0], (void*)&pint->map_base[129], 4*(reqwords-1));
	  if (0) fprintf(stderr, "%s:%d i=%d nbytes=%d msgbody[0]=%#08x\n", __FUNCTION__, __LINE__, i, nbytes, pint->map_base[129]);
	}
	if (0) fprintf(stderr, "%s:%d reqwords=%d msg_num=%d handler=%p\n", __FUNCTION__, __LINE__, reqwords, msg_num, pint->handler);
	if (msg_num != 0xFFFF && pint->handler)
	    pint->handler(pint, msg_num, 0);
	i = 0;
      }
    } while (nbytes > 0 || tries-- > 0);
    return -1;
}
PortalTransportFunctions transportSerial = {
    init_serial, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_serialInd, mapchannel_serialReq,
    send_serial, recv_portal_null, busywait_serial, enableint_portal_null, event_serial, notfull_null};


