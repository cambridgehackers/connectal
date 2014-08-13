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
    for (unsigned int i = 0; i < len/sizeof(uint64_t); i++) {
        uint16_t pixel[5];
        uint64_t ditem = data[i];
        uint32_t control = data[i] >> 39;
       
        for (int j = 0; j < 5; j++) {
            pixel[j] = ditem & 0x3ff; /* 10-bit pixels */
            ditem >>= 10;
        }
        for (int j = 0; j < 5; j++)
            printf(" %3x", pixel[j]);
        printf(": alignbusy %2x emptyw %2x samplein %4x", (control >> 20) & 0x1f, (control >> 15) & 0x1f, control & 0x7fff);
        printf("\n");
    }
    return 0;
}
