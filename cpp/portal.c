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
//#define assert(A)
#else
#include <stdlib.h>
#include <string.h>
//#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <time.h> // ctime
#include <stdarg.h> // for portal_printf
#include <sys/wait.h>
#include <sys/stat.h>
#endif
#include "drivers/portalmem/portalmem.h" // PA_MALLOC

//#ifdef ANDROID
//#include <android/log.h>
//#endif
#ifdef ZYNQ
#include "drivers/zynqportal/zynqportal.h"
#else
#include "drivers/pcieportal/pcieportal.h" // BNOC_TRACE
#endif

int debug_portal = 0;

int global_pa_fd = -1;
PortalInternal *utility_portal = 0x0;

#ifdef __KERNEL__
static tBoard* tboard;
#endif

/*
 * Initialize control data structure for portal
 */
void init_portal_internal(PortalInternal *pint, int id, int tile,
    PORTAL_INDFUNC handler, void *cb, PortalItemFunctions *item, void *param,
    uint32_t reqinfo)
{
    int rc;
    initPortalFramework();
    memset(pint, 0, sizeof(*pint));
    if(!utility_portal)
      utility_portal = pint;
    pint->fpga_number = id;
    pint->fpga_tile = tile;
    pint->fpga_fd = -1;
    pint->muxid = -1;
    pint->handler = handler;
    pint->cb = cb;
    pint->reqinfo = reqinfo;
    if (!item) {
        // Use defaults for transport handling methods
#ifdef BSIM
        item = &bsimfunc;
#elif defined(XSIM)
        item = &xsimfunc;
#else
        item = &hardwarefunc;
#endif
    }
    pint->item = item;
    rc = pint->item->init(pint, param);
    if (rc != 0) {
      PORTAL_PRINTF("%s: failed to initialize Portal portal_%d_%d\n", __FUNCTION__, pint->fpga_tile, pint->fpga_number);
#ifndef __KERNEL__
      exit(1);
#endif
    }
}

/*
 * Check md5 signatures of Linux device drivers to be sure they are up to date
 */
static void check_signature(const char *filename, int ioctlnum)
{
    int status;
    static struct {
        const char *md5;
        const char *filename;
    } filesignature[] = {
#include "driver_signature_file.h"
    {} };
#ifdef ZYNQ
    PortalSignature signature;
#else
    PortalSignaturePcie signature;
#endif

    int fd = open(filename, O_RDONLY);
    if (strcmp(filename, "/dev/portalmem")) {
        ssize_t len = read(fd, &status, sizeof(status));
        if (len != sizeof(status))
            fprintf(stderr, "[%s:%d] read status from '%s' was only %d bytes long\n", __FUNCTION__, __LINE__, filename, (int)len);
    }
    signature.index = 0;
    while ((status = ioctl(fd, ioctlnum, &signature)) == 0 && strlen(signature.md5)) {
        int i = 0;
//printf("[%s:%d] found [%d] %s %s\n", __FUNCTION__, __LINE__, signature.index, signature.md5, signature.filename);
        while(filesignature[i].md5) {
            if (!strcmp(filesignature[i].filename, signature.filename)) {
//printf("[%s:%d] orig %s %s\n", __FUNCTION__, __LINE__, filesignature[i].md5, filesignature[i].filename);
                if (strcmp(filesignature[i].md5, signature.md5))
                    printf("%s: driver '%s' signature mismatch %s %s\n", __FUNCTION__,
                        signature.filename, signature.md5, filesignature[i].md5);
                break;
            }
            i++;
        }
        signature.index++;
    }
    close(fd);
}

/*
 * One time initialization of portal framework
 */
void initPortalFramework(void)
{
    static int once = 0;

    if (once)
        return;
    once = 1;
#ifdef __KERNEL__
    tboard = get_pcie_portal_descriptor();
#else
    /*
     * fork/exec 'fpgajtag' to download bits to hardware
     * (the FPGA bits are stored as an extra ELF segment in the executable file)
     */
    int pid = fork();
    if (pid == -1) {
        printf("[%s:%d] fork error\n", __FUNCTION__, __LINE__);
        exit(-1);
    }
    else if (pid) {
        int status;
        waitpid(pid, &status, 0);
#ifdef __arm__
	{
	  int fd;
	  ssize_t len;
	  fprintf(stderr, "subprocess pid %d completed status=%x %d\n", pid, status, WEXITSTATUS(status));
	  if (WEXITSTATUS(status) != 0)
	    exit(-1);
	  fd = open("/dev/connectal", O_RDONLY); /* scan the fpga directory */
	  len = read(fd, &status, sizeof(status));
	  printf("[%s:%d] fd %d len %lu\n", __FUNCTION__, __LINE__, fd, len);
	  close(fd);
	}
#elif !defined(BSIM) && !defined(BOARD_xsim)
        while (1) {
            struct stat statbuf;
            int rc = stat("/dev/connectal", &statbuf); /* wait for driver to load */
            if (rc != -1)
                break;
            printf("[%s:%d] waiting for '/dev/connectal'\n", __FUNCTION__, __LINE__);
            sleep(1);
        }
#endif
#if !defined(BSIM) && !defined(BOARD_xsim)
        check_signature("/dev/connectal",
#ifdef ZYNQ
            PORTAL_SIGNATURE
#else
            PCIE_SIGNATURE
#endif
            );
#endif
        check_signature("/dev/portalmem", PA_SIGNATURE);
    }
    else {
#define MAX_PATH 2000
        static char buf[MAX_PATH];
        buf[0] = 0;
        int rc = readlink("/proc/self/exe", buf, sizeof(buf));
	if (rc < 0)
	  fprintf(stderr, "[%s:%d] readlink error %d\n", __FUNCTION__, __LINE__, errno);
#if !defined(BOARD_bluesim) && !defined(BOARD_xsim)
        char *serial = getenv("SERIALNO");
        int ind = 1;
        char *argv[] = { (char *)"fpgajtag", NULL, NULL, NULL, NULL, NULL, NULL, NULL};
        if (serial) {
            argv[ind++] = (char *)"-s";
            argv[ind++] = strdup(serial);
        }
#ifdef __arm__
        argv[ind++] = (char *)"-x";
        argv[ind++] = buf;
        execvp ("/fpgajtag", argv);
#else
        argv[ind++] = buf;
        execvp ("fpgajtag", argv);
#endif // !__arm__
#endif
        exit(-1);
    }
#endif // !__KERNEL__
}

/*
 * Utility functions for alloc/mmap/cache for shared memory
 */
void init_portal_memory(void)
{
#ifndef __KERNEL__
  if (global_pa_fd == -1)
      global_pa_fd = open("/dev/portalmem", O_RDWR);
  if (global_pa_fd < 0){
    PORTAL_PRINTF("Failed to open /dev/portalmem pa_fd=%d errno=%d\n", global_pa_fd, errno);
    exit(ENODEV);
  }
#endif
}

int portalAllocCached(size_t size, int cached)
{
  int fd;
  struct PortalAlloc portalAlloc;
  portalAlloc.len = size;
  portalAlloc.cached = cached;
  init_portal_memory();
#ifdef __KERNEL__
  fd = portalmem_dmabuffer_create(size);
#else
  fd = ioctl(global_pa_fd, PA_MALLOC, &portalAlloc);
#endif
  PORTAL_PRINTF("alloc size=%ld fd=%d\n", (unsigned long)size, fd);
  if (fd == -1) {
       PORTAL_PRINTF("portalAllocCached: alloc failed size=%ld errno=%d\n", (unsigned long)size, errno);
       exit(-1);
  }
  return fd;
}

int portalAlloc(size_t size)
{
  return portalAllocCached(size, 0);
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

int portalDCacheFlushInvalInternal(int fd, long size, void *__p, int flush)
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
        if(flush) outer_clean_range(start_addr, end_addr);
        outer_inv_range(start_addr, end_addr);
    }
    fput(fmem);
#else
  int rc;
  if (utility_portal){
    PortalCacheRequest req;
    req.fd = fd;
    req.base = __p;
    req.len = size;
    if(flush)
      rc = ioctl(utility_portal->fpga_fd, PORTAL_DCACHE_FLUSH_INVAL, &req);
    else
      rc = ioctl(utility_portal->fpga_fd, PORTAL_DCACHE_INVAL, &req);
  }
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

void portalDCacheInval(int fd, long size, void *__p)
{
  portalDCacheFlushInvalInternal(fd,size,__p,0);
}

void portalDCacheFlushInval(int fd, long size, void *__p)
{
  portalDCacheFlushInvalInternal(fd,size,__p,1);
}

/*
 * Miscellaneous utility functions
 */
int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
{
    int status = 0;
    initPortalFramework();
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
