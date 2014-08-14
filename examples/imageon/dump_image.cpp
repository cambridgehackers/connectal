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
#include <sys/types.h>
#include <unistd.h>
#include <stdint.h>
#include <stdlib.h>

static struct {
    int         len;       /* number of bits of field */
    const char *name;      /* name of field */
    uint64_t    default_value; /* value to skip when dumping */
} *dumpptr, *dumpend, dumpitem[] = {
    {4, "astate", 0},
    {2, "qstate", 0},
    {10, "ctrl_data", 0x3a6},
    {8, "data_init1[7:0]", 0},
//24
    {16, "gencounter", 0},
//40
    {3, "ctrl_sample", 0},
    {1, "align_start", 0},
    {1, "autoalign", 0},
    {1, "sync_increment", 0},
    {1, "sync_bitslip", 0},
    {1, "sync_ce", 0},
//48
    {1, "bvi_reset_reg", 1},
    {1, "bvi_reset_reg", 1},
    {1, "fifo_wren_sync", 1},
    {3, "sync_counter", 7},
    {10, "serdes_data", -1},
//64
    {}};
int main(int argc, char *argv[])
{
    if (argc != 2) {
        printf("dump_pixel <filename>\n");
        return -1;
    }
    int fd = open(argv[1], O_RDONLY);
    int len = lseek(fd, 0, SEEK_END);
    printf("dump_pixel: filename '%s' len %d\n", argv[1], len);
    lseek(fd, 0, SEEK_SET);
    uint64_t *data = (uint64_t *)malloc(len);
    read(fd, data, len);
    close(fd);
    dumpend = dumpitem;
    while((dumpend+1)->len) /* get last value in list to be dumped (LSB bits) */
        dumpend++;
    for (unsigned int i = 0; i < len/sizeof(uint64_t); i++) {
        uint64_t ditem = data[i];
        dumpptr = dumpend;
        do {
            uint64_t val = ditem & ((1 << dumpptr->len) - 1);
            ditem >>= dumpptr->len;
            if (val != dumpptr->default_value)
                printf(" %s=%llx", dumpptr->name, (long long)val);
        } while (dumpptr-- != dumpitem);
        printf("\n");
    }
    return 0;
}
