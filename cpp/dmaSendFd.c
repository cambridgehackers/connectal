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

#include "../generated/cpp/DmaConfigProxy.c"
#include "../drivers/portalmem/portalmem.h"

int send_fd_to_portal(volatile int *map_base, int fd, int id)
{
#define PAGE_SHIFT0 12
#define PAGE_SHIFT4 16
#define PAGE_SHIFT8 20
    int i, j;
    uint64_t regions[3] = {0,0,0};
    static uint64_t shifts[] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0, 0};
    uint64_t border = 0;
    unsigned char entryCount = 0;
    uint64_t borderVal[3];
    unsigned char idxOffset;
    struct scatterlist *sg;
    PortalInternal devptr = {0};

    struct file *fmem = fget(fd);
    struct sg_table *sgtable = ((struct pa_buffer *)((struct dma_buf *)fmem->private_data)->priv)->sg_table;
    devptr.map_base = map_base;
    for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
      long addr = sg_phys(sg);
      for(j = 0; j < 3; j++)
          if (sg->length == 1<<shifts[j]) {
            regions[j]++;
            addr >>= shifts[j];
            break;
          }
      if (j >= 3)
        printk("DmaManager:unsupported sglist size %x\n", sg->length);
      printk("DmaManager:sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, addr, sg->length);
      DmaConfigProxy_sglist(&devptr, (id << 8) + i, addr, sg->length);
    }
    fput(fmem);
    // HW interprets zeros as end of sglist
    DmaConfigProxy_sglist(&devptr, (id << 8) + i, 0, 0); // end list

    for(i = 0; i < 3; i++){
      idxOffset = entryCount - border;
      entryCount += regions[i];
      border += regions[i];
      borderVal[i] = (border << 8) | idxOffset;
      border <<= (shifts[i] - shifts[i+1]);
    }
    printk("borders %d (%llx %llx %llx)\n", id,borderVal[0], borderVal[1], borderVal[2]);
    DmaConfigProxy_region(&devptr, id, borderVal[0], borderVal[1], borderVal[2]);
    return 0;
}
