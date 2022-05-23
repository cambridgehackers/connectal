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
#include "ConnectalProjectConfig.h"

#include "portal.h"
#include "sock_utils.h"
#ifdef __KERNEL__
#include "linux/delay.h"
#include "linux/file.h"
#include "linux/dma-buf.h"
#else
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <time.h> // ctime
#include <stdarg.h> // for portal_printf
#include <sys/wait.h>
#include <sys/stat.h>
#include <libgen.h>  // dirname
#include <pthread.h>
#endif

#ifdef __APPLE__ // hack for debugging
#include <libproc.h>
#else
#include "drivers/portalmem/portalmem.h" // PA_MALLOC
#if defined(ZYNQ) || defined(__riscv__)
#include "drivers/zynqportal/zynqportal.h"
#else
#include "drivers/pcieportal/pcieportal.h" // BNOC_TRACE
#endif
#endif // !__APPLE__

int simulator_dump_vcd = 0;
const char *simulator_vcd_name = "dump.vcd";
// set this to 1 to suppress call to fpgajtag
#ifndef DEFAULT_NOPROGRAM
#define DEFAULT_NOPROGRAM 0
#endif
int noprogram = DEFAULT_NOPROGRAM;

static int trace_portal;//= 1;

int global_pa_fd = -1;
PortalInternal *utility_portal = 0x0;
void (*connectalPrintfHandler)(struct PortalInternal *p, unsigned int header);

#ifdef __KERNEL__
static tBoard* tboard;
#endif

/*
 * Initialize control data structure for portal
 */
void init_portal_internal(PortalInternal *pint, int id, int tile,
    PORTAL_INDFUNC handler, void *cb, PortalTransportFunctions *transport, void *param, void *parent,
    uint32_t reqinfo)
{
    int rc;
    memset(pint, 0, sizeof(*pint));
    if(!utility_portal)
      utility_portal = pint;
    pint->board_number = 0;
    pint->fpga_number = id;
    pint->fpga_tile = tile;
    pint->fpga_fd = -1;
    pint->muxid = -1;
    pint->handler = handler;
    pint->cb = (PortalHandlerTemplate *)cb;
    pint->parent = parent;
    pint->reqinfo = reqinfo;
    pint->busyType = BUSY_SPIN;
    if (getenv("FPGA_NUMBER") != 0)
	pint->board_number = strtoul(getenv("FPGA_NUMBER"), 0, 0);
    if(trace_portal)
	PORTAL_PRINTF("%s: **initialize portal_b%dt%dp%d handler %p cb %p parent %p\n", __FUNCTION__, pint->board_number, pint->fpga_tile, pint->fpga_number, handler, cb, parent);
    if (!transport) {
        // Use defaults for transport handling methods
#if defined(SIMULATION) && !defined(__ATOMICC__)
        transport = &transportXsim;
#else
        transport = &transportHardware;
#endif
    }
    pint->transport = transport;
    rc = pint->transport->init(pint, param);
    if (rc != 0) {
        PORTAL_PRINTF("%s: failed to initialize Portal portal_b%dt%dp%d\n", __FUNCTION__, pint->board_number, pint->fpga_tile, pint->fpga_number);
#ifndef __KERNEL__
        exit(1);
#endif
    }
}
int portal_disconnect(struct PortalInternal *pint)
{
    if(trace_portal)
        PORTAL_PRINTF("[%s:%d] fpgafd %d num %d cli %d\n", __FUNCTION__, __LINE__, pint->fpga_fd, pint->client_fd_number, pint->client_fd[0], pint->client_fd[1]);
    close(pint->fpga_fd);
    if (pint->client_fd_number > 0)
        close(pint->client_fd[--pint->client_fd_number]);
    return 0;
}

int portal_event(struct PortalInternal *pint)
{
#if defined(SIMULATION) && !defined(__ATOMICC__)
    return event_xsim(pint);
#else
    return event_hardware(pint);
#endif
}

char *getExecutionFilename(char *buf, int buflen)
{
    int rc, fd;
#ifdef __APPLE__ // hack for debugging
    static char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    rc = proc_pidpath (getpid(), pathbuf, sizeof(pathbuf));
    return pathbuf;
#endif
    char *filename = 0;
    buf[0] = 0;
    fd = open("/proc/self/maps", O_RDONLY);
    while ((rc = read(fd, buf, buflen-1)) > 0) {
	buf[rc] = 0;
	rc = 0;
	while(buf[rc]) {
	    char *endptr;
	    unsigned long addr = strtoul(&buf[rc], &endptr, 16);
	    if (endptr && *endptr == '-') {
		char *endptr2;
		unsigned long addr2 = strtoul(endptr+1, &endptr2, 16);
		if (addr <= (unsigned long)&initPortalHardware && (unsigned long)&initPortalHardware <= addr2) {
		    filename = strstr(endptr2, "  ");
		    while (*filename == ' ')
			filename++;
		    endptr2 = strstr(filename, "\n");
		    if (endptr2)
			*endptr2 = 0;
		    fprintf(stderr, "buffer %s\n", filename);
		    goto endloop;
		}
	    }
	    while(buf[rc] && buf[rc] != '\n')
		rc++;
	    if (buf[rc])
		rc++;
	}
    }
endloop:
    if (!filename) {
	fprintf(stderr, "[%s:%d] could not find execution filename\n", __FUNCTION__, __LINE__);
	return 0;
    }
    return filename;
}
/*
 * One time initialization of portal framework
 */
static pthread_once_t once_control;
static void initPortalHardwareOnce(void)
{
#ifdef __KERNEL__
    tboard = get_pcie_portal_descriptor();
#else
    /*
     * fork/exec 'fpgajtag' to download bits to hardware
     * (the FPGA bits are stored as an extra ELF segment in the executable file)
     */
    int pid = fork();
    if (pid == -1) {
	fprintf(stderr, "[%s:%d] fork error\n", __FUNCTION__, __LINE__);
        exit(-1);
    }
    else if (pid) {
#ifndef SIMULATION
        int status;
        waitpid(pid, &status, 0);
	fprintf(stderr, "subprocess pid %d completed status=%x %d\n", pid, status, WEXITSTATUS(status));
#ifndef BOARD_de5
	if (WEXITSTATUS(status) != 0)
	    exit(-1);
#endif
	{
	  int fd = -1;
	  ssize_t len;
	  int attempt;
	  for (attempt = 0; attempt < 10; attempt++) {
            struct stat statbuf;
            int rc = stat("/dev/connectal", &statbuf); /* wait for driver to load */
            if (rc == -1)
                continue;
	    fd = open("/dev/connectal", O_RDONLY); /* scan the fpga directory */
	    if (fd < 0) {
		fprintf(stderr, "[%s:%d] waiting for '/dev/connectal'\n", __FUNCTION__, __LINE__);
		sleep(1);
		continue;
	    }
	    len = read(fd, &status, sizeof(status));
	    if (len < (ssize_t)sizeof(status))
	      fprintf(stderr, "[%s:%d] fd %d len %lu\n", __FUNCTION__, __LINE__, fd, (unsigned long)len);
	    close(fd);
	    break;
	  }
	  if (fd == -1) {
	      PORTAL_PRINTF("Error: %s: failed to open /dev/connectal, exiting\n", __FUNCTION__);
	      exit(-1);
	  }
	}
#endif // !defined(SIMULATION)
    }
    else {
#define MAX_PATH 2000
        static char buf[400000];
        char *filename = NULL;
        char *argv[] = { (char *)"fpgajtag", NULL, NULL, NULL, NULL, NULL, NULL, NULL};
	int ind = 1;
        if (noprogram || getenv("NOFPGAJTAG") || getenv("NOPROGRAM"))
            exit(0);
#ifndef SIMULATOR_USE_PATH
	filename = getExecutionFilename(buf, sizeof(buf));
#endif
#ifdef SIMULATION
        char *bindir = (filename) ? dirname(filename) : 0;
        static char exename[MAX_PATH];
        char *library_path = 0;
	if (getenv("DUMP_VCD")) {
	  simulator_dump_vcd = 1;
	  simulator_vcd_name = getenv("DUMP_VCD");
	}
#if defined(BOARD_bluesim)
	const char *exetype = "bsim";
	argv[ind++] = (char*)"-w"; // wait for license
	if (simulator_dump_vcd) {
	  argv[ind++] = (char*)"-V";
	  argv[ind++] = (char*)simulator_vcd_name;
	}
#endif
#if defined(BOARD_ncverilog)
	const char *exetype = "ncverilog";
	bindir = 0; // the simulation driver is found in $PATH
	//FIXME ARGS
#endif
#if defined(BOARD_verilator)
	const char *exetype = "vlsim";
	if (simulator_dump_vcd) {
	  argv[ind++] = (char*)"-t";
	  argv[ind++] = (char*)simulator_vcd_name;
	}
#endif
#if defined(BOARD_cvc)
	const char *exetype = "cvcsim";
	if (simulator_dump_vcd) {
	  //argv[ind++] = (char*)"-t";
	  //argv[ind++] = (char*)simulator_vcd_name;
	}
#endif
#if defined(BOARD_xsim)
	const char *exetype = "xsim";
	bindir = 0; // the simulation driver is found in $PATH
        argv[ind++] = (char *)"-R";
        argv[ind++] = (char *)"work.xsimtop";
#endif
#if defined(BOARD_vcs)
	const char *exetype = "simv";
        argv[ind++] = (char *)"+verbose=1";
        argv[ind++] = (char *)"-assert";
        argv[ind++] = (char *)"verbose+success";
	if (simulator_dump_vcd) {
	  //argv[ind++] = (char*)"-t";
	  //argv[ind++] = (char*)simulator_vcd_name;
	}
#endif
#if defined(BOARD_vsim)
	const char *exetype = "vsim";
	bindir = 0; // the simulation driver is found in $PATH
        argv[ind++] = (char *)"-c";
        argv[ind++] = (char *)"-sv_lib";
        argv[ind++] = (char *)"xsimtop";
        argv[ind++] = (char *)"work.xsimtop";
        argv[ind++] = (char *)"-do";
        argv[ind++] = (char *)"run -all; quit -f";
#endif
	if (bindir)
	    sprintf(exename, "%s/%s", bindir, exetype);
	else
	    sprintf(exename, "%s", exetype);
	argv[0] = exename;
if (trace_portal) fprintf(stderr, "[%s:%d] %s %s *******\n", __FUNCTION__, __LINE__, exetype, exename);
        argv[ind++] = NULL;
	if (bindir) {
	    const char *old_library_path = getenv("LD_LIBRARY_PATH");
	    int library_path_len = strlen(bindir);
	    if (old_library_path)
		library_path_len += strlen(old_library_path);
	    library_path = (char *)malloc(library_path_len + 2);
	    if (old_library_path)
		snprintf(library_path, library_path_len+2, "%s:%s", bindir, old_library_path);
	    else
		snprintf(library_path, library_path_len+1, "%s", bindir);
	    setenv("LD_LIBRARY_PATH", library_path, 1);
if (trace_portal) fprintf(stderr, "[%s:%d] LD_LIBRARY_PATH %s *******\n", __FUNCTION__, __LINE__, library_path);
	}
        execvp (exename, argv);
	fprintf(stderr, "[%s:%d] exec(%s) failed errno=%d:%s\n", __FUNCTION__, __LINE__, exename, errno, strerror(errno));
#else // !defined(SIMULATION)
        char *serial = getenv("SERIALNO");
        if (serial) {
            argv[ind++] = (char *)"-s";
            argv[ind++] = strdup(serial);
        }
        {
#ifdef __ANDROID__
	  // on zynq android, fpgajtag is in the initramdisk in the root directory
	  const char *fpgajtag = "/fpgajtag";
#else
	  const char *fpgajtag = "fpgajtag";
#endif // !__arm__
#ifdef __arm__
	  argv[ind++] = (char *)"-x"; // program via /dev/xdevcfg
#endif
#ifdef __aarch64__
	  argv[ind++] = (char *)"-m"; // program via fpga manager
#endif
	  argv[ind++] = filename;
          errno = 0;
          if (filename) // only run fpgajtag if filename was found
	      execvp (fpgajtag, argv);
	  fprintf(stderr, "[%s:%d] exec(%s) failed errno=%d:%s\n", __FUNCTION__, __LINE__, fpgajtag, errno, strerror(errno));
        }
#endif // !SIMULATION
        exit(-1);
    }
#endif // !__KERNEL__
}
void initPortalHardware(void)
{
    pthread_once(&once_control, initPortalHardwareOnce);
}

/*
 * Utility functions for alloc/mmap/cache for shared memory
 */
void initPortalMemory(void)
{
#ifndef __KERNEL__
    if (global_pa_fd == -1)
#ifndef SIMULATION
        global_pa_fd = open("/dev/portalmem", O_RDWR);
    if (global_pa_fd < 0){
	PORTAL_PRINTF("Failed to open /dev/portalmem pa_fd=%d errno=%d:%s\n", global_pa_fd, errno, strerror(errno));
        exit(ENODEV);
    }
#else
        global_pa_fd = -1;
#endif
#endif
}

int portalmem_sizes[1024];

int portalAlloc(size_t size, int cached)
{
    int fd;
    initPortalMemory();
#ifdef __KERNEL__
    fd = portalmem_dmabuffer_create(size);
#else
#ifndef SIMULATION
    {
	    struct PortalAlloc portalAlloc;
	    portalAlloc.len = size;
	    portalAlloc.cached = cached;
	    fd = ioctl(global_pa_fd, PA_MALLOC, &portalAlloc);
    }
#else
    {
      static int portalmem_number = 0;
      char fname[128];
      snprintf(fname, sizeof(fname), "/tmp/portalmem-%d-%d.bin", getpid(), portalmem_number++);
      fd = open(fname, O_RDWR|O_CREAT, 0600);
      if (fd < 0)
	fprintf(stderr, "ERROR %s:%d fname=%s fd=%d\n", __FUNCTION__, __LINE__, fname, fd);
      unlink(fname);
      lseek(fd, size, SEEK_SET);
      size_t bytesWritten = write(fd, (void*)fname, 512);
      if (bytesWritten != 512)
	fprintf(stderr, "ERROR %s:%d fname=%s fd=%d wrote %ld bytes\n", __FUNCTION__, __LINE__, fname, fd, (long)bytesWritten);
      portalmem_sizes[fd] = size;
    }
#endif
#endif
    if(trace_portal)
        PORTAL_PRINTF("alloc size=%ld fd=%d\n", (unsigned long)size, fd);
    if (fd == -1) {
        PORTAL_PRINTF("portalAllocCached: alloc failed size=%ld errno=%d\n", (unsigned long)size, errno);
        exit(-1);
    }
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
    void *mapped = mmap(0, size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd, 0);
    if (mapped == MAP_FAILED)
      fprintf(stderr, "ERROR: portalMmap fd=%d size=%ld mapped=%p\n", fd, (long)size, mapped);
    return mapped;
#endif
}
int portalMunmap(void *addr, size_t size)
{
#ifdef __KERNEL__
    fprintf(stderr, "UNIMPLEMENTED: portalMunmap addr=%p size=%d\n", addr, size);
#else      ///////////////////////// userspace version
    return munmap(addr, size);
#endif
}

int portalCacheFlush(int fd, void *__p, long size, int flush)
{
#if defined(__arm__) || defined (__riscv__)
#ifdef __KERNEL__
    int i;
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
    {
	int i;
	// not sure any of this is necessary (mdk)
	for(i = 0; i < size; i++){
	    char foo = *(((volatile char *)__p)+i);
	    asm volatile("clflush %0" :: "m" (foo));
	}
	asm volatile("mfence");
    }
#elif defined(__aarch64__)
    // TBD
#else
#error("portalCacheFlush not defined for unspecified architecture")
#endif
    if(trace_portal)
        PORTAL_PRINTF("dcache flush\n");
    return 0;
}

/*
 * Miscellaneous utility functions
 */
int setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
{
    int status = -1;
    initPortalHardware();
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
    } else {
      fprintf(stderr, "[%s:%d] no utility portal\n", __FUNCTION__, __LINE__);
      status = -1;
    }
#endif
    return status;
}
