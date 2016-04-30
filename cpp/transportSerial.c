// Copyright (c) 2016 Connectal Project

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
	fprintf(stderr, "init_serial param=%p pint=%p serial_fd=%d map_base=%p\n",
		param, pint, param->serial.serial_fd, pint->map_base);

	if (0) {
	    struct termios terminfo;
	    int rc;
	    tcflush(serial_fd, TCIOFLUSH);
	    tcgetattr(serial_fd, &terminfo);
	    terminfo.c_cflag = CS8 | CLOCAL | CREAD | PARENB;
	    terminfo.c_cflag &= ~CRTSCTS; // needed for /dev/tty.SLAB_USBtoUART
	    terminfo.c_iflag = IGNCR;
	    terminfo.c_lflag = ICANON;
	    cfsetspeed(&terminfo, B115200);
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
static void send_serial(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd)
{
    int reqwords = hdr & 0xffff;
    int i;

    fprintf(stderr, "send_serial head=%d hdr=%08x reqwords=%d buffer=%p buffer[1]=%08x buffer[2]=%08x\n",
	    buffer[0], hdr, reqwords, buffer, buffer[1], buffer[2]);
    buffer[0] = hdr;
    if (0)
    for (i = 0; i < reqwords+1; i++)
	buffer[i] = htonl(buffer[i]);
    int nbytes = write(pint->client_fd[0], (void*)buffer, 4*reqwords);
    if (nbytes != 4*reqwords) {
	fprintf(stderr, "%s:%x pint=%p fd=%d nbytes=%d errno=%d:%s\n", __FUNCTION__, __LINE__, pint, pint->client_fd[0], nbytes, errno, strerror(errno));
    }
    buffer[0] = 0;
    //tcdrain(pint->client_fd[0]);
}
static int event_serial(struct PortalInternal *pint)
{
    if (0) fprintf(stderr, "%s:%d serial_fd=%d\n", __FUNCTION__, __LINE__, pint->client_fd[0]);
    int nbytes;
    int i = 0;
    char *base = (char *)&pint->map_base[128];
    int tries = 0;
    do {
      nbytes = read(pint->client_fd[0], (void*)(base + i), 4);
      if (nbytes > 0)
	i += nbytes;
      if (0) fprintf(stderr, "%s:%d i=%d nbytes=%d hdr=%#08x\n", __FUNCTION__, __LINE__, i, nbytes, pint->map_base[128]);
      if (i >= 4) {
	int reqwords = pint->map_base[128] & 0xFFFF;
	int msg_num = pint->map_base[128] >> 16;
	if (reqwords > 1) {
	  nbytes = read(pint->client_fd[0], (void*)&pint->map_base[129], 4*(reqwords-1));
	  if (nbytes < 4*(reqwords-1))
	    fprintf(stderr, "SHORT READ %s:%d i=%d nbytes=%d buffer=%p msgbody[0]=%08x\n", __FUNCTION__, __LINE__, i, nbytes, &pint->map_base[128], pint->map_base[128+1]);
	}
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

static int init_serialmux(struct PortalInternal *pint, void *aparam)
{
    PortalMuxParam *param = (PortalMuxParam *)aparam;
    fprintf(stderr, "%s:%d pint=%p client_fd=%d\n", __FUNCTION__, __LINE__, pint, pint->client_fd[0]);
    pint->mux = param->pint;
    pint->map_base = ((volatile unsigned int*)malloc(REQINFO_SIZE(pint->reqinfo) + sizeof(uint32_t))) + 1;
    memset((void *)(pint->map_base-1), 0, REQINFO_SIZE(pint->reqinfo) + sizeof(uint32_t));  // for valgrind
    pint->mux->map_base[0] = -1;
    pint->mux->mux_ports_number++;
    pint->mux->mux_ports = (PortalMuxHandler *)realloc(pint->mux->mux_ports, pint->mux->mux_ports_number * sizeof(PortalMuxHandler));
    pint->mux->mux_ports[pint->mux->mux_ports_number-1].pint = pint;
    return 0;
}
static void send_serialmux(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
    volatile unsigned int *buffer = data-1;
    buffer[0] = hdr;
    fprintf(stderr, "%s:%d pint=%p mux=%p map_base=%p mux->map_base=%p buffer=%p\n", __FUNCTION__, __LINE__, pint, pint->mux, pint->map_base, pint->mux->map_base, buffer);
    pint->mux->request_index = pint->request_index;
    pint->mux->transport->send(pint->mux, buffer, (pint->fpga_number << 24) | hdr, sendFd);
}
static int recv_serialmux(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    return pint->mux->transport->recv(pint->mux, buffer, len, recvfd);
}
int portal_serialmux_handler(struct PortalInternal *pint, unsigned int channel, int messageFd)
{
    int i;
    unsigned int fpga_number = (channel >> 8) & 0xFF;
    unsigned int msg_number  = (channel >> 0) & 0xFF;
    fprintf(stderr, "%s:%d channel=%x\n", __FUNCTION__, __LINE__, channel);
    for (i = 0; i < pint->mux_ports_number; i++) {
        PortalInternal *p = pint->mux_ports[i].pint;
	int hdr = pint->map_base[128];
	int reqwords = hdr & 0xffff;
	memcpy((void *)&p->map_base[128], (void *)&pint->map_base[128], 4*reqwords);
        if (fpga_number == p->fpga_number && p->handler) {
            p->handler(p, msg_number, messageFd);
        }
    }
    return -1;
}
PortalTransportFunctions transportSerialMux = {
    init_serialmux, read_portal_memory, write_portal_memory, write_fd_portal_memory, mapchannel_serialInd, mapchannel_req_generic,
    send_serialmux, recv_serialmux, busy_portal_null, enableint_portal_null, event_null, notfull_null};

