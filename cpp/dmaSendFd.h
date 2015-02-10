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

#define PAGE_SHIFT0 12
#define PAGE_SHIFT4 16
#define PAGE_SHIFT8 20
static int shifts[] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0, 0};

#include "dmaManager.h"
#include "drivers/portalmem/portalmem.h" // PortalAlloc

#ifdef CONNECTAL_DRIVER_CODE
#define NO_WRAPPER_FUNCTIONS
#include "MMURequest.c"
static int trace_memory = 1;
#endif

#include "GeneratedTypes.h" // generated in project directory
#define DMAsglist(P, A, B, C, D) MMURequest_sglist((P), (A), (B), (C), (D));
#define DMAregion(P, PTR, B8, I8, B4, I4, B0, I0) MMURequest_region((P), (PTR), (B8), (I8), (B4), (I4), (B0), (I0))

int send_fd_to_portal(PortalInternal *device, int fd, int id, int pa_fd)
{
    int rc = 0;
    int i, j;
    uint32_t regions[3] = {0,0,0};
    uint64_t border = 0;
    unsigned char entryCount = 0;
    uint64_t borderVal[3];
    uint32_t indexVal[3];
    unsigned char idxOffset;
#if defined(BSIM)
    int size_accum = 0;
#endif
#ifdef __KERNEL__
    struct scatterlist *sg;
    struct file *fmem;
    struct sg_table *sgtable;
#endif
#ifdef __KERNEL__
    fmem = fget(fd);
    sgtable = ((struct pa_buffer *)((struct dma_buf *)fmem->private_data)->priv)->sg_table;
#elif !defined(BSIM)
  int numEntries = 0;
  PortalAlloc *portalAlloc = NULL, pa = { 0 };
  pa.header.fd=fd;
  rc = ioctl(pa_fd, PA_DMA_ADDRESSES, &pa);
  if (rc){
    PORTAL_PRINTF("send_fd_to_portal: alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    goto retlab;
  }
  numEntries = pa.header.numEntries;
  portalAlloc = (PortalAlloc *)PORTAL_MALLOC(sizeof(PortalAlloc)+((numEntries+1)*sizeof(DmaEntry)));
  portalAlloc->header.fd = fd;
  portalAlloc->header.numEntries = numEntries;
  rc = ioctl(pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    PORTAL_PRINTF("send_fd_to_portal: alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    goto retlab;
  }
#endif
  rc = id;
#ifdef __KERNEL__
  for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
      long addr = sg_phys(sg);
      long len = sg->length;
#elif defined(BSIM)
  for(i = 0; 1; i++){
    long len, addr;
    PortalElementSize portalElementSize;

    portalElementSize.fd = fd;
    portalElementSize.index = i;
    len = ioctl(pa_fd, PA_ELEMENT_SIZE, &portalElementSize);
    if (len < 0) {
        PORTAL_PRINTF("send_fd_to_portal: bad return from PA_ELEMENT_SIZE %ld\n", len);
        rc = len;
        goto retlab;
    }
    if (!len)
        break;
#else
  for(i = 0; i < numEntries; i++) {
    long addr = portalAlloc->entries[i].dma_address;
    long len = portalAlloc->entries[i].length;
#endif
#if defined(BSIM)
    addr = size_accum;
    size_accum += len;
    addr |= ((long)id) << 32; //[39:32] = truncate(pref);
#endif

    for(j = 0; j < 3; j++)
        if (len == 1<<shifts[j]) {
          regions[j]++;
          if (addr & ((1L<<shifts[j]) - 1))
              PORTAL_PRINTF("%s: addr %lx shift %x *********\n", __FUNCTION__, addr, shifts[j]);
          addr >>= shifts[j];
          break;
        }
    if (j >= 3)
      PORTAL_PRINTF("DmaManager:unsupported sglist size %lx\n", len);
    if (trace_memory)
      PORTAL_PRINTF("DmaManager:sglist(id=%08x, i=%d dma_addr=%08lx, len=%08lx)\n", id, i, (long)addr, len);
    DMAsglist(device, id, i, addr, len);
  } // balance } }
#ifdef __KERNEL__
  fput(fmem);
#elif !defined(BSIM)
  PORTAL_FREE(portalAlloc);
#endif

  // HW interprets zeros as end of sglist
  if (trace_memory)
    PORTAL_PRINTF("DmaManager:sglist(id=%08x, i=%d end of list)\n", id, i);
  DMAsglist(device, id, i, 0, 0); // end list

  for(i = 0; i < 3; i++){
    idxOffset = entryCount - border;
    entryCount += regions[i];
    border += regions[i];
    borderVal[i] = border;
    indexVal[i] = idxOffset;
    border <<= (shifts[i] - shifts[i+1]);
  }
  if (trace_memory) {
    PORTAL_PRINTF("regions %d (%x %x %x)\n", id,regions[0], regions[1], regions[2]);
    PORTAL_PRINTF("borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borderVal[0], borderVal[1], borderVal[2]);
  }
  DMAregion(device, id, borderVal[0], indexVal[0], borderVal[1], indexVal[1], borderVal[2], indexVal[2]);
  /* ifdefs here to supress warning during kernel build */
#ifdef __KERNEL__
#elif !defined(BSIM)
retlab:
#endif
    return rc;
}
