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

#ifdef XBSV_DRIVER_CODE
#include "portal.h"
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
    printk("DmaManager:sglist(id=%08x, i=%d end of list)\n", id, i);
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
#else // XBSV_DRIVER_CODE

static int host_sendfd(DmaManagerPrivate *priv, int id, PortalAlloc *pa)
{
  int rc = 0;
  const int PAGE_SHIFT0 = 12;
  const int PAGE_SHIFT4 = 16;
  const int PAGE_SHIFT8 = 20;
  int i, j;
  uint32_t regions[3] = {0,0,0};
  int shifts[] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0, 0};
  int size_accum = 0;
  uint64_t border = 0;
  unsigned char entryCount = 0;
  uint64_t borderVal[3];
  unsigned char idxOffset;
  PortalAlloc *portalAlloc;
#ifdef __KERNEL__
  struct sg_table *sgtable;
  struct scatterlist *sg;
  struct file *fmem = fget(pa->header.fd);

  sgtable = ((struct pa_buffer *)((struct dma_buf *)fmem->private_data)->priv)->sg_table;
  pa->header.numEntries = sgtable->nents;
#endif

  portalAlloc = (PortalAlloc *)PORTAL_MALLOC(sizeof(PortalAlloc)+((pa->header.numEntries+1)*sizeof(DmaEntry)));
  memcpy(portalAlloc, pa, sizeof(*pa));
#ifdef __KERNEL__
  for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
      portalAlloc->entries[i].dma_address = sg_phys(sg);
      portalAlloc->entries[i].length = sg->length;
  }
  fput(fmem);
#else
  rc = ioctl(priv->pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    PORTAL_PRINTF("portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    goto retlab;
  }
#endif
  if (trace_memory)
    PORTAL_PRINTF("DmaManager_reference id=%08x, numEntries:=%d len=%08lx)\n", id, pa->header.numEntries, (long)portalAlloc->header.size);
#ifdef BSIM
  bluesim_sock_fd_write(portalAlloc->header.fd);
#endif
  for(i = 0; i < portalAlloc->header.numEntries; i++){
    DmaEntry *e = &(portalAlloc->entries[i]);
    long addr;
#ifndef BSIM
    addr = e->dma_address;
#else
    addr = size_accum;
    size_accum += e->length;
    addr |= ((long)id) << 32; //[39:32] = truncate(pref);
#endif
    for(j = 0; j < 3; j++)
        if (e->length == 1<<shifts[j]) {
          regions[j]++;
          if (addr & ((1L<<shifts[j]) - 1))
              PORTAL_PRINTF("%s: addr %lx shift %x *********\n", __FUNCTION__, addr, shifts[j]);
          addr >>= shifts[j];
          break;
        }
    if (j >= 3)
      PORTAL_PRINTF("DmaManager:unsupported sglist size %x\n", e->length);
    if (trace_memory)
      PORTAL_PRINTF("DmaManager:sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, (long)addr, e->length);
    DMAsglist(priv->device, (id << 8) + i, addr, e->length);
  }
  // HW interprets zeros as end of sglist
  if (trace_memory)
    PORTAL_PRINTF("DmaManager:sglist(id=%08x, i=%d end of list)\n", id, i);
  DMAsglist(priv->device, (id << 8) + i, 0, 0); // end list

  for(i = 0; i < 3; i++){
    idxOffset = entryCount - border;
    entryCount += regions[i];
    border += regions[i];
    borderVal[i] = (border << 8) | idxOffset;
    border <<= (shifts[i] - shifts[i+1]);
  }
  if (trace_memory) {
    PORTAL_PRINTF("regions %d (%x %x %x)\n", id,regions[0], regions[1], regions[2]);
    PORTAL_PRINTF("borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borderVal[0], borderVal[1], borderVal[2]);
  }
  DMAregion(priv->device, id, borderVal[0], borderVal[1], borderVal[2]);
  //PORTAL_PRINTF("%s:%d sem_wait\n", __FUNCTION__, __LINE__);
  sem_wait(&priv->confSem);
  rc = id;
retlab:
  PORTAL_FREE(portalAlloc);
  return rc;
}
#endif // XBSV_DRIVER_CODE
