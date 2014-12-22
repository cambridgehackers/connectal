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

#include <stdio.h>
#include <fcntl.h>
#include <sys/select.h>
#include <sys/mman.h>
#include <errno.h>

#include "sock_utils.h"
#include "portal.h"

static void memdump(unsigned char *p, int len, char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                printf("\n");
            printf("%s: ",title);
        }
        printf("%02x ", *p++);
        i++;
        len--;
    }
    printf("\n");
}

int main(int argc, char *argv[])
{
struct memrequest req;
PortalInternal pint;
int rc;

    int fd = open("/dev/connectaltest", O_RDWR);
    if (fd == -1) {
        printf("bsimhost: /dev/connectaltest not found\n");
        return -1;
    }
printf("[%s:%d] trying to connect to bsim\n", __FUNCTION__, __LINE__);
    connect_to_bsim();
printf("[%s:%d] opened bsim\n", __FUNCTION__, __LINE__);
    while ((rc = read(fd, &req, sizeof(req)))) {
        struct memresponse rv;
        if (rc == -1) {
            struct timeval timeout;
            timeout.tv_sec = 0;
            timeout.tv_usec = 10000;
            select(0, NULL, NULL, NULL, &timeout);
            continue;
        }
        if (rc != sizeof(req)) {
            printf("[%s:%d] rc = %d.\n", __FUNCTION__, __LINE__, rc);
            memdump((unsigned char *)&req, sizeof(req), "RX");
        }
        rv.portal = req.portal;
pint.fpga_number = req.portal;
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
        if (req.portal == MAGIC_PORTAL_FOR_SENDING_FD) {
            //bluesim_sock_fd_write((long)req.addr);
            bsimfunc.writefd(&pint, &req.addr, req.data_or_tag);
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
            rv.data = 0xdead;
            write(fd, &rv, sizeof(rv));
        }
        else if (req.write_flag)
            bsimfunc.write(&pint, &req.addr, req.data_or_tag);
        else {
            rv.data = bsimfunc.read(&pint, &req.addr);
            write(fd, &rv, sizeof(rv));
        }
    }
    return 0;
}
