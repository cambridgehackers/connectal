
// Copyright (c) 2012 Nokia, Inc.
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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

#include "portal.h"
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
#include <unistd.h>
#include <sys/ioctl.h>
#include <time.h> // ctime
#endif
#include "portalmem.h" // PA_MALLOC

#ifdef ZYNQ
#include <android/log.h>
#include <zynqportal.h>
#else
#include <pcieportal.h> // BNOC_TRACE
#endif

static void init_portal_hw(void);
int global_pa_fd = -1;
PortalInternal *utility_portal = 0x0;

#ifdef __KERNEL__
static tBoard* tboard;
#endif

#ifdef BSIM
extern int bsim_fpga_map[MAX_BSIM_PORTAL_ID];
#endif

void init_portal_internal(PortalInternal *pint, int id, PORTAL_INDFUNC handler, uint32_t reqsize)
{
    int rc = 0;
    char buff[128];
    char read_status;

    init_portal_hw();
    memset(pint, 0, sizeof(*pint));
    if(!utility_portal)
      utility_portal = pint;
    pint->fpga_number = id;
    pint->fpga_fd = -1;
    pint->handler = handler;
    pint->reqsize = reqsize;
    if (reqsize) {
#ifdef __KERNEL__
        printk("[%s:%d] software id %d reqsize %d\n", __FUNCTION__, __LINE__, id, reqsize);
#else
        sprintf(buff, "SWSOCK%d", id);
        if (we_are_initiator) {
            pint->fpga_fd = init_connecting(buff);
            pint->accept_finished = 1;
        }
        else
            pint->fpga_fd = init_listening(buff);
        pint->map_base = (volatile unsigned int*)malloc(reqsize);
#endif
        goto exitlab;
    }
    snprintf(buff, sizeof(buff), "/dev/portal%d", pint->fpga_number);
#ifdef BSIM   // BSIM version
    assert(id < MAX_BSIM_PORTAL_ID);
    pint->fpga_number = bsim_fpga_map[id];
    pint->map_base = (volatile unsigned int*)(long)(pint->fpga_number * PORTAL_BASE_OFFSET);
    portalEnableInterrupts(pint, 1);
#elif defined(__KERNEL__)
    pint->map_base = (volatile unsigned int*)(tboard->bar2io + pint->fpga_number * PORTAL_BASE_OFFSET);
#else
#ifdef ZYNQ
    PortalEnableInterrupt intsettings = {3 << 14, (3 << 14) + 4};
    int pgfile = open("/sys/devices/amba.0/f8007000.devcfg/prog_done", O_RDONLY);
    if (pgfile == -1) {
        // 3.9 kernel uses amba.2
        pgfile = open("/sys/devices/amba.2/f8007000.devcfg/prog_done", O_RDONLY);
        if (pgfile == -1) {
            // miniitx100 uses different name!
            pgfile = open("/sys/devices/amba.0/f8007000.ps7-dev-cfg/prog_done", O_RDONLY);
        }
    }
    if (pgfile == -1) {
	PORTAL_PRINTF("failed to open /sys/devices/amba.[02]/f8007000.devcfg/prog_done %d\n", errno);
	rc = -1;
	goto exitlab;
    }
    if (read(pgfile, &read_status, 1) != 1 || read_status != '1') {
	PORTAL_PRINTF("FPGA not programmed: %x\n", read_status);
	rc = -ENODEV;
	goto exitlab;
    }
    close(pgfile);
    pint->fpga_fd = open(buff, O_RDWR);
    ioctl(pint->fpga_fd, PORTAL_ENABLE_INTERRUPT, &intsettings);
#else
    // FIXME: bluenoc driver only opens readonly for some reason
    pint->fpga_fd = open(buff, O_RDONLY);
#endif
    if (pint->fpga_fd < 0) {
	PORTAL_PRINTF("Failed to open %s fd=%d errno=%d\n", buff, pint->fpga_fd, errno);
	rc = -errno;
	goto exitlab;
    }
    pint->map_base = (volatile unsigned int*)mmap(NULL, PORTAL_BASE_OFFSET, PROT_READ|PROT_WRITE, MAP_SHARED, pint->fpga_fd, 0);
    if (pint->map_base == MAP_FAILED) {
        PORTAL_PRINTF("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", pint->fpga_fd, errno);
        rc = -errno;
	goto exitlab;
    }  
#endif

exitlab:
    if (rc != 0) {
      PORTAL_PRINTF("%s: failed to open Portal fpga%d\n", __FUNCTION__, pint->fpga_number);
#ifndef __KERNEL__
      exit(1);
#endif
    }
}

int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
{
    int status = 0;
    init_portal_hw();
#ifdef ZYNQ
    PortalClockRequest request;
    request.clknum = clkNum;
    request.requested_rate = requestedFrequency;
    if (utility_portal){
      status = ioctl(utility_portal->fpga_fd, PORTAL_SET_FCLK_RATE, (long)&request);
      if (status == 0 && actualFrequency)
	*actualFrequency = request.actual_rate;
      if (status < 0)
	status = errno;
    }else{ 
      status = -1;
    }
#endif
    return status;
}

static void init_portal_hw(void)
{
  unsigned int i;
  static int once = 0;

  if (once || we_are_initiator)
      return;
  once = 1;
#ifdef __KERNEL__
  tboard = get_pcie_portal_descriptor();
#endif
#ifdef ZYNQ /* There is no way to set userclock freq from host on PCIE */
  // start by setting the clock frequency (this only has any effect on the zynq platform)
  PortalClockRequest request;
  long reqF = 100000000; // 100 Mhz
  request.clknum = 0;
  request.requested_rate = reqF;
  assert(false);
  int status = -1;//ioctl(globalDirectory.fpga_fd, PORTAL_SET_FCLK_RATE, (long)&request);
  if (status < 0)
    PORTAL_PRINTF("init_portal: error setting fclk0, errno=%d\n", errno);
  PORTAL_PRINTF("init_portal: set fclk0 (%ld,%ld)\n", reqF, request.actual_rate);
#endif
#ifdef BSIM
  connect_to_bsim();
#endif
}

void portalTrace_start()
{
  init_portal_hw();
#if !defined(ZYNQ) && !defined(__KERNEL__)
  tTraceInfo traceInfo;
  traceInfo.trace = 1;
  assert(false);
  int res = 0; //ioctl(globalDirectory.fpga_fd,BNOC_TRACE,&traceInfo);
  if (res)
    PORTAL_PRINTF("Failed to start tracing. errno=%d\n", errno);
#endif
}
void portalTrace_stop()
{
  init_portal_hw();
#if !defined(ZYNQ) && !defined(__KERNEL__)
  tTraceInfo traceInfo;
  traceInfo.trace = 0;
  assert(false);
  int res = 0; //ioctl(globalDirectory.fpga_fd,BNOC_TRACE,&traceInfo);
  if (res)
    PORTAL_PRINTF("Failed to stop tracing. errno=%d\n", errno);
#endif
}

uint64_t portalCycleCount()
{
  unsigned int high_bits, low_bits;
  if (we_are_initiator)
    return 0;
  if(!utility_portal)
    return 0;
  init_portal_hw();
  high_bits = READL(utility_portal, &(utility_portal->map_base[PORTAL_CTRL_REG_COUNTER_MSB]));
  low_bits  = READL(utility_portal, &(utility_portal->map_base[PORTAL_CTRL_REG_COUNTER_LSB]));
  return (((uint64_t)high_bits)<<32) | ((uint64_t)low_bits);
}

void portalEnableInterrupts(PortalInternal *p, int val)
{
   if (!p->reqsize)
     WRITEL(p, &(p->map_base[PORTAL_CTRL_REG_INTERRUPT_ENABLE]), val);
}

int portalDCacheFlushInval(int fd, long size, void *__p)
{
    int i;
#if defined(__arm__)
#ifdef __KERNEL__
    struct scatterlist *sg;
    struct file *fmem = fget(fd);
    struct sg_table *sgtable = ((struct pa_buffer *)((struct dma_buf *)fmem->private_data)->priv)->sg_table;
printk("[%s:%d] flush %d\n", __FUNCTION__, __LINE__, fd);
    for_each_sg(sgtable->sgl, sg, sgtable->nents, i) {
        unsigned int length = sg->length;
        dma_addr_t start_addr = sg_phys(sg), end_addr = start_addr+length;
printk("[%s:%d] start %lx end %lx len %x\n", __FUNCTION__, __LINE__, (long)start_addr, (long)end_addr, length);
        outer_clean_range(start_addr, end_addr);
        outer_inv_range(start_addr, end_addr);
    }
    fput(fmem);
#else
  int rc;
  if (utility_portal)
    rc = ioctl(utility_portal->fpga_fd, PORTAL_DCACHE_FLUSH_INVAL, fd);
  else
    rc = -1;
  if (rc){
    PORTAL_PRINTF("portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
#endif
#elif defined(__i386__) || defined(__x86_64__)
  // not sure any of this is necessary (mdk)
  for(i = 0; i < size; i++){
    char foo = *(((volatile char *)__p)+i);
    asm volatile("clflush %0" :: "m" (foo));
  }
  asm volatile("mfence");
#else
#error("dCAcheFlush not defined for unspecified architecture")
#endif
  //PORTAL_PRINTF("dcache flush\n");
  return 0;
}

void init_portal_memory(void)
{
#ifndef __KERNEL__
  if (global_pa_fd == -1)
      global_pa_fd = open("/dev/portalmem", O_RDWR);
  if (global_pa_fd < 0){
    PORTAL_PRINTF("Failed to open /dev/portalmem pa_fd=%d errno=%d\n", global_pa_fd, errno);
  }
#endif
}

int portalAlloc(size_t size)
{
  int fd;
  init_portal_memory();
#ifdef __KERNEL__
  fd = portalmem_dmabuffer_create(size);
#else
  fd = ioctl(global_pa_fd, PA_MALLOC, size);
#endif
  PORTAL_PRINTF("alloc size=%ldMB fd=%d\n", size/(1L<<20), fd);
  return fd;
}

void *portalMmap(int fd, size_t size)
{
#ifdef __KERNEL__
  struct file *fmem = fget(fd);
  void *retptr = dma_buf_vmap(fmem->private_data);
  fput(fmem);
  return retptr;
#else      ///////////////////////// userspace version
  return mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
#endif
}

void portalInitiator(void)
{
    we_are_initiator = 1;
}

