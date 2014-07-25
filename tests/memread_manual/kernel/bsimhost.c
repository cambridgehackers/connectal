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
int rc;

printf("[%s:%d] start\n", __FUNCTION__, __LINE__);
    int fd = open("/dev/xbsvtest", O_RDWR);
    if (fd == -1) {
        printf("bsimhost: /dev/xbsvtest not found\n");
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
        if (1||rc != sizeof(req)) {
            printf("[%s:%d] rc = %d.\n", __FUNCTION__, __LINE__, rc);
            memdump((unsigned char *)&req, sizeof(req), "RX");
        }
        rv.portal = req.portal;
        if (req.portal == 666) {
printf("[%s:%d] fd write %d\n", __FUNCTION__, __LINE__, req.data);
#define numWords 0x124000/4
static long alloc_sz = numWords*sizeof(unsigned int);
  unsigned int *srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, req.data, 0);
printf("[%s:%d] buf %p errno %d BADF %d\n", __FUNCTION__, __LINE__, srcBuffer, errno, BADF);
            sock_fd_write(req.data);
            rv.data = 0xdead;
            write(fd, &rv, sizeof(rv));
        }
        else if (req.write_flag) {
printf("[%s:%d] write\n", __FUNCTION__, __LINE__);
            write_portal_bsim(req.addr, req.data, req.portal);
        }
        else {
printf("[%s:%d] read\n", __FUNCTION__, __LINE__);
            rv.data = read_portal_bsim(req.addr, req.portal);
            write(fd, &rv, sizeof(rv));
        }
    }
printf("[%s:%d] over\n", __FUNCTION__, __LINE__);
    return 0;
}
