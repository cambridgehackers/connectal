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
#include <string.h>
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
    {10, "ei", 0},
    {5, "wc", 0},
    {4, "a", 0},
    {10, "cdata", 0x3a6},
    {16, "gen", 0},
    {3, "csam", 0},
    {1, "astart", 0},
    {1, "autoa", 0},
    {1, "sinc", 0},
    {1, "sbit", 0},
    {1, "sce", 0},
    {1, "wren", 1},
    {10, "sdata", -1},
//64
    {}};
        //return {edge_int, windowcount[4:0], pack(astate), ctrl_data, gencounter, ctrl_sample, align_start, autoalign,
        //serdes_capture.send({pack(syncparam), pack(fifo_wren_sync), serdes_data});
#define STRING_LEN 10000
static char last_string[STRING_LEN], current_string[STRING_LEN];
int main(int argc, char *argv[])
{
    int repeat_count = 0;
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
        char *p = current_string;
        do {
            uint64_t val = ditem & ((1 << dumpptr->len) - 1);
            ditem >>= dumpptr->len;
            if (val != dumpptr->default_value) {
                sprintf(p, " %s=%llx", dumpptr->name, (long long)val);
                p += strlen(p);
            }
        } while (dumpptr-- != dumpitem);
        if (!strcmp(last_string, current_string))
            repeat_count++;
        else {
            if (repeat_count)
                printf("repeat %d\n", repeat_count);
            printf("%s\n", current_string);
            repeat_count = 0;
            strcpy(last_string, current_string);
        }
    }
    return 0;
}
