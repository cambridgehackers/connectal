
// Copyright (c) 2012 Nokia, Inc.

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

#include <errno.h>
#include <fcntl.h>
#include <linux/ioctl.h>
#include <linux/types.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <assert.h>
#include <time.h>

#ifdef ZYNQ
#include <android/log.h>
#endif

#include "portal.h"
#include "sock_utils.h"
#include "sock_fd.h"

PortalWrapper **portal_wrappers = 0;
struct pollfd *portal_fds = 0;
int numFds = 0;
Directory dir;

#ifdef ZYNQ
#define ALOGD(fmt, ...) __android_log_print(ANDROID_LOG_DEBUG, "PORTAL", fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, "PORTAL", fmt, __VA_ARGS__)
#else
#define ALOGD(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#define ALOGE(fmt, ...) fprintf(stderr, "PORTAL: " fmt, __VA_ARGS__)
#endif

unsigned int read_portal(portal *p, unsigned int addr, char *name)
{
  unsigned int rv;
  struct memrequest foo = {false,addr,0};

  if (send(p->read.s2, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (%s) send error\n",__FUNCTION__, name);
    //exit(1);
  }

  if(recv(p->read.s2, &rv, sizeof(rv), 0) == -1){
    fprintf(stderr, "%s (%s) recv error\n",__FUNCTION__, name);
    //exit(1);	  
  }

  return rv;
}

void write_portal(portal *p, unsigned int addr, unsigned int v, char *name)
{
  struct memrequest foo = {true,addr,v};

  if (send(p->write.s2, &foo, sizeof(foo), 0) == -1) {
    fprintf(stderr, "%s (%s) send error\n",__FUNCTION__, name);
    //exit(1);
  }

}

void Portal::close()
{
    if (fd > 0) {
        ::close(fd);
        fd = -1;
    }    
}

Portal::Portal(const char *devname, unsigned int addrbits)
  : fd(-1),
    ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0),
    name(strdup(devname))
{
  int rc = open(addrbits);
  if (rc != 0) {
    printf("[%s:%d] failed to open Portal %s\n", __FUNCTION__, __LINE__, name);
    ALOGD("Portal::Portal failure rc=%d\n", rc);
    exit(1);
  }
}
Portal::Portal(int id)
  : fd(-1),
    ind_reg_base(0x0), 
    ind_fifo_base(0x0),
    req_reg_base(0x0),
    req_fifo_base(0x0)
{
  char buff[128];
  sprintf(buff, "fpga%d", dir.fpga(id));
  name = strdup(buff);
  int rc = open(dir.addrbits(id));
  if (rc != 0) {
    printf("[%s:%d] failed to open Portal %s\n", __FUNCTION__, __LINE__, name);
    ALOGD("Portal::Portal failure rc=%d\n", rc);
    exit(1);
  }
}

Portal::~Portal()
{
  close();
  free(name);
}


int Portal::open(int addrbits)
{
#ifdef ZYNQ
    FILE *pgfile = fopen("/sys/devices/amba.0/f8007000.devcfg/prog_done", "r");
    if (!pgfile) {
        // 3.9 kernel uses amba.2
        pgfile = fopen("/sys/devices/amba.2/f8007000.devcfg/prog_done", "r");
    }
    if (pgfile == 0) {
	ALOGE("failed to open /sys/devices/amba.[02]/f8007000.devcfg/prog_done %d\n", errno);
	printf("failed to open /sys/devices/amba.[02]/f8007000.devcfg/prog_done %d\n", errno);
	return -1;
    }
    char line[128];
    fgets(line, sizeof(line), pgfile);
    if (line[0] != '1') {
	ALOGE("FPGA not programmed: %s\n", line);
	printf("FPGA not programmed: %s\n", line);
	return -ENODEV;
    }
    fclose(pgfile);
#endif
#ifdef MMAP_HW

    char path[128];
    snprintf(path, sizeof(path), "/dev/%s", name);
#ifdef ZYNQ
    this->fd = ::open(path, O_RDWR);
#else
    // FIXME: bluenoc driver only opens readonly for some reason
    this->fd = ::open(path, O_RDONLY);
#endif
    if (this->fd < 0) {
	ALOGE("Failed to open %s fd=%d errno=%d\n", path, this->fd, errno);
	return -errno;
    }
    volatile unsigned int *dev_base = (volatile unsigned int*)mmap(NULL, 1<<addrbits, PROT_READ|PROT_WRITE, MAP_SHARED, this->fd, 0);
    if (dev_base == MAP_FAILED) {
      ALOGE("Failed to mmap PortalHWRegs from fd=%d errno=%d\n", this->fd, errno);
      return -errno;
    }  
    ind_reg_base   = (volatile unsigned int*)(((unsigned long)dev_base)+(3<<14));
    ind_fifo_base  = (volatile unsigned int*)(((unsigned long)dev_base)+(2<<14));
    req_reg_base   = (volatile unsigned int*)(((unsigned long)dev_base)+(1<<14));
    req_fifo_base  = (volatile unsigned int*)(((unsigned long)dev_base)+(0<<14));

    fprintf(stderr, "Portal::disabling interrupts %s\n", name);
    *(ind_reg_base+0x1) = 0;

#else
    snprintf(p.read.path, sizeof(p.read.path), "%s_rc", name);
    connect_socket(&(p.read));
    snprintf(p.write.path, sizeof(p.read.path), "%s_wc", name);
    connect_socket(&(p.write));

    unsigned long dev_base = 0;
    ind_reg_base   = dev_base+(3<<14);
    ind_fifo_base  = dev_base+(2<<14);
    req_reg_base   = dev_base+(1<<14);
    req_fifo_base  = dev_base+(0<<14);

    fprintf(stderr, "Portal::disabling interrupts %s\n", name);
    unsigned int addr = ind_reg_base+0x4;
    write_portal(&p, addr, 0, name);
#endif
    return 0;
}

int Portal::sendMessage(PortalMessage *msg)
{

  // TODO: this intermediate buffer (and associated copy) should be removed (mdk)
  unsigned int buf[128];
  msg->marshall(buf);

  // mutex_lock(&portal_data->reg_mutex);
  // mutex_unlock(&portal_data->reg_mutex);
#ifdef MMAP_HW
  if (0) {
    volatile unsigned int *addr = (volatile unsigned int *)req_reg_base;
    fprintf(stderr, "requestFiredCount=%x outOfRangeWriteCount=%x\n",addr[0], addr[1]);
    //addr[2] = 0xffffffff;
  }
#endif
  for (int i = msg->size()/4-1; i >= 0; i--) {
    unsigned int data = buf[i];
#ifdef MMAP_HW
    unsigned long addr = ((unsigned long)req_fifo_base) + msg->channel * 256;
    //fprintf(stderr, "%08lx %08x\n", addr, data);
    *((volatile unsigned int*)addr) = data;
#else
    unsigned int addr = req_fifo_base + msg->channel * 256;
    write_portal(&p, addr, data, name);
    //fprintf(stderr, "(%s) sendMessage\n", name);
#endif
  }
#ifdef MMAP_HW
  if (0)
  for (int i = 0; i < 3; i++) {
    volatile unsigned int *addr = (volatile unsigned int *)req_reg_base;
    fprintf(stderr, "requestFiredCount=%x outOfRangeWriteCount=%x getWordCount=%x putWordCount=%x putEnable=%x\n",addr[0], addr[1], addr[7], addr[8], addr[2]);
  }
#endif
  return 0;
}

PortalWrapper::PortalWrapper(int id) 
  : Portal(id)
{
  registerInstance();
}

PortalWrapper::PortalWrapper(const char *devname, unsigned int addrbits)
  : Portal(devname,addrbits)
{
  registerInstance();
}

PortalWrapper::~PortalWrapper()
{
  unregisterInstance();
}

PortalProxy::PortalProxy(int id)
  : Portal(id)
{
}

PortalProxy::PortalProxy(const char *devname, unsigned int addrbits)
  : Portal(devname,addrbits)
{
}

PortalProxy::~PortalProxy()
{
}

int PortalWrapper::unregisterInstance()
{
  int i = 0;
  while(i < numFds)
    if(portal_fds[i].fd == this->fd)
      break;
    else
      i++;

  while(i < numFds-1){
    portal_fds[i] = portal_fds[i+1];
    portal_wrappers[i] = portal_wrappers[i+1];
  }

  numFds--;
  portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
  portal_wrappers = (PortalWrapper **)realloc(portal_wrappers, numFds*sizeof(PortalWrapper *));  
  return 0;
}

int PortalWrapper::registerInstance()
{
    numFds++;
    portal_wrappers = (PortalWrapper **)realloc(portal_wrappers, numFds*sizeof(PortalWrapper *));
    portal_fds = (struct pollfd *)realloc(portal_fds, numFds*sizeof(struct pollfd));
    portal_wrappers[numFds-1] = this;
    struct pollfd *pollfd = &portal_fds[numFds-1];
    memset(pollfd, 0, sizeof(struct pollfd));
    pollfd->fd = this->fd;
    pollfd->events = POLLIN;
    return 0;
}

PortalMemory::PortalMemory(const char *devname, unsigned int addrbits)
  : PortalProxy(devname, addrbits)
  , handle(1)
  , sglistCallbackRegistered(false)
{
#ifndef MMAP_HW
  snprintf(p_fd.read.path, sizeof(p_fd.read.path), "fd_sock_rc");
  connect_socket(&(p_fd.read));
  snprintf(p_fd.write.path, sizeof(p_fd.write.path), "fd_sock_wc");
  connect_socket(&(p_fd.write));
#endif
  if (sem_init(&sglistSem, 1, 0)){
    fprintf(stderr, "failed to init sglistSem errno=%d:%s\n", errno, strerror(errno));
  }
  const char* path = "/dev/portalmem";
  this->pa_fd = ::open(path, O_RDWR);
  if (this->pa_fd < 0){
    ALOGE("Failed to open %s pa_fd=%ld errno=%d\n", path, (long)this->pa_fd, errno);
  }
}

PortalMemory::PortalMemory(int id)
  : PortalProxy(id),
    handle(1)
{
}

void *PortalMemory::mmap(PortalAlloc *portalAlloc)
{
  void *virt = ::mmap(0, portalAlloc->header.size, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, portalAlloc->header.fd, 0);
  return virt;
}

int PortalMemory::dCacheFlushInval(PortalAlloc *portalAlloc, void *__p)
{
#if defined(__arm__)
  int rc = ioctl(this->pa_fd, PA_DCACHE_FLUSH_INVAL, portalAlloc);
  if (rc){
    fprintf(stderr, "portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
#elif defined(__i386__) || defined(__x86_64__)
  // not sure any of this is necessary (mdk)
  for(int i = 0; i < portalAlloc->header.size; i++){
    char foo = *(((volatile char *)__p)+i);
    asm volatile("clflush %0" :: "m" (foo));
  }
  asm volatile("mfence");
#else
#error("dCAcheFlush not defined for unspecified architecture")
#endif
  fprintf(stderr, "dcache flush\n");
  return 0;

}

int PortalMemory::reference(PortalAlloc* pa)
{
  int id = handle++;
#ifdef MMAP_HW
  int ne = pa->header.numEntries;
  assert(ne < 32);
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries;
  sglist(0, 0, 0);
  for(int i = 0; i <= pa->header.numEntries; i++){
    assert(i<32); // the HW has defined SGListMaxLen as 32
    fprintf(stderr, "PortalMemory::sglist(id=%08x, i=%d dma_addr=%08lx, len=%08lx)\n", id, i, pa->entries[i].dma_address, pa->entries[i].length);
    sglist(id, pa->entries[i].dma_address, pa->entries[i].length);
    if (sglistCallbackRegistered)
      sem_wait(&sglistSem);
    else
      sleep(1); // ugly hack.  should use a semaphore for flow-control (mdk)
  }
#else
  sock_fd_write(p_fd.write.s2, pa->header.fd);
  paref(id, pa->header.size);
  if (sglistCallbackRegistered)
    sem_wait(&sglistSem);
  else
    sleep(1); // ugly hack.  should use a semaphore for flow-control (mdk)
#endif
  return id;
}
void PortalMemory::sglistResp(unsigned long channelId)
{
  sem_post(&sglistSem);
}

int PortalMemory::alloc(size_t size, PortalAlloc **ppa)
{
  PortalAlloc *portalAlloc = (PortalAlloc *)malloc(sizeof(PortalAlloc));
  memset(portalAlloc, 0, sizeof(PortalAlloc));
  portalAlloc->header.size = size;
  int rc = ioctl(this->pa_fd, PA_ALLOC, portalAlloc);
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  fprintf(stderr, "alloc size=%ld rc=%d fd=%d numEntries=%d\n", 
	  (long)portalAlloc->header.size, rc, portalAlloc->header.fd, portalAlloc->header.numEntries);
  portalAlloc = (PortalAlloc *)realloc(portalAlloc, sizeof(PortalAlloc)+((portalAlloc->header.numEntries+1)*sizeof(DMAEntry)));
  rc = ioctl(this->pa_fd, PA_DMA_ADDRESSES, portalAlloc);
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  *ppa = portalAlloc;
  return 0;
}

int Portal::setClockFrequency(int clkNum, long requestedFrequency, long *actualFrequency)
{
    if (!numFds) {
	ALOGE("%s No fds open\n", __FUNCTION__);
	return -ENODEV;
    }

    PortalClockRequest request;
    request.clknum = clkNum;
    request.requested_rate = requestedFrequency;
    int status = ioctl(portal_fds[0].fd, PORTAL_SET_FCLK_RATE, (long)&request);
    if (status == 0 && actualFrequency)
	*actualFrequency = request.actual_rate;
    if (status < 0)
	status = errno;
    return status;
}

void* portalExec(void* __x)
{
#ifdef MMAP_HW
    long rc;
    int timeout = 100; // interrupts not working yet on zynq 
#ifndef ZYNQ
    timeout = 100; // interrupts not working yet on PCIe
#endif
    if (!numFds) {
        ALOGE("portalExec No fds open numFds=%d\n", numFds);
        return (void*)-ENODEV;
    }
#ifndef ZYNQ
    if (0)
    for (int i = 0; i < numFds; i++) {
      PortalWrapper *instance = portal_wrappers[i];
      fprintf(stderr, "Portal::enabling interrupts portal %d\n", i);
      *(volatile int *)(instance->ind_reg_base+0x1) = 1;
    }
#endif
    while ((rc = poll(portal_fds, numFds, timeout)) >= 0) {
      for (int i = 0; i < numFds; i++) {
	  if (!portal_wrappers) {
	    fprintf(stderr, "No portal_instances but rc=%ld revents=%d\n", rc, portal_fds[i].revents);
	  }
	
	PortalWrapper *instance = portal_wrappers[i];
	
	// sanity check, to see the status of interrupt source and enable
	unsigned int int_src = *(volatile int *)(instance->ind_reg_base+0x0);
	unsigned int int_en  = *(volatile int *)(instance->ind_reg_base+0x1);
	unsigned int ind_count  = *(volatile int *)(instance->ind_reg_base+0x2);
	unsigned int queue_status = *(volatile int *)(instance->ind_reg_base+0x6);
	if(0)
	  fprintf(stderr, "(%d) about to receive messages int=%08x en=%08x qs=%08x\n", i, int_src, int_en, queue_status);

	// handle all messasges from this portal instance
	while (queue_status) {
	  if(0)
	  fprintf(stderr, "queue_status %d\n", queue_status);
	  instance->handleMessage(queue_status-1);
	  int_src = *(volatile int *)(instance->ind_reg_base+0x0);
	  int_en  = *(volatile int *)(instance->ind_reg_base+0x1);
	  ind_count  = *(volatile int *)(instance->ind_reg_base+0x2);
	  queue_status = *(volatile int *)(instance->ind_reg_base+0x6);
	  if (0)
	    fprintf(stderr, "%d: int_src=%08x int_en=%08x ind_count=%08x queue_status=%08x\n",
		    __LINE__, int_src, int_en, ind_count, queue_status);
	}
	
	// rc of 0 indicates timeout
	if (rc == 0) {
	  // do something if we timeout??
	}
	// re-enable interupt which was disabled by portal_isr
	// *(instance->ind_reg_base+0x1) = 1;
      }
    }
    // return only in error case
    fprintf(stderr, "poll returned rc=%ld errno=%d:%s\n", rc, errno, strerror(errno));
    return (void*)rc;
#else // BSIM
    fprintf(stderr, "about to enter bsim while(true), numFds=%d\n", numFds);
    while (true){
      for(int i = 0; i < numFds; i++){
	PortalWrapper *instance = portal_wrappers[i];
	unsigned int int_status_addr = instance->ind_reg_base+0x0;
	unsigned int int_status = read_portal(&(instance->p), int_status_addr, instance->name);
	if(int_status){
	  unsigned int queue_status_addr = instance->ind_reg_base+0x18;
	  unsigned int queue_status = read_portal(&(instance->p), queue_status_addr, instance->name);
	  if (queue_status){
	    //fprintf(stderr, "(%s) queue_status : %08x\n", instance->name, queue_status);
	    instance->handleMessage(queue_status-1);	
	  } else {
	    fprintf(stderr, "WARNING: int_status and queue_status are incoherent (%s)\n", instance->name);
	  }
	}
      }
    }
#endif
}

Directory::Directory() : Portal("fpga0", 16){}

unsigned int Directory::fpga(unsigned int id)
{
#ifdef MMAP_HW
  volatile unsigned int *ptr = req_fifo_base+128;
  unsigned int numportals,i;
  ptr++;
  ptr++;
  numportals = *ptr;
  ptr++;
  ptr++;
  for(i = 0; (i < numportals) && (i < 32); i++){
    unsigned int ifcid = *ptr;
    ptr++;
    unsigned int ifctype = *ptr;
    ptr++;
    if(ifcid == id)
      return i+1;
  }
#else
  unsigned int ptr = 128*4;
  unsigned int numportals,i;
  ptr += 4;
  ptr += 4;
  numportals = read_portal(&p, ptr, name);
  ptr += 4;
  ptr += 4;
  for(i = 0; (i < numportals) && (i < 32); i++){
    unsigned int ifcid = read_portal(&p, ptr, name);
    ptr += 4;
    unsigned int ifctype = read_portal(&p, ptr, name);
    ptr += 4;
    if(ifcid == id)
      return i+1;
  }
#endif
  fprintf(stderr, "Directory::fpga(id=%d) id not found\n", id);
}

unsigned int Directory::addrbits(unsigned int id)
{
#ifdef MMAP_HW
  volatile unsigned int *ptr = req_fifo_base+128;
  ptr++;
  ptr++;
  ptr++;
  return *ptr;
#else
  unsigned int ptr = 128*4;
  ptr += 4;
  ptr += 4;
  ptr += 4;
  return read_portal(&p, ptr, name);
#endif
}

void Directory::print()
{
  fprintf(stderr, "Directory::print(%s)\n", name);
#ifdef MMAP_HW
  volatile unsigned int *ptr = req_fifo_base+128;
  unsigned int numportals,i;
  fprintf(stderr, "version=%08x\n",  *ptr);
  ptr++;
  long int timestamp = (long int)*ptr;
  fprintf(stderr, "timestamp=%s", ctime(&timestamp));
  ptr++;
  numportals = *ptr;
  fprintf(stderr, "numportals=%08x\n", numportals);
  ptr++;
  fprintf(stderr, "addrbits=%08x\n", *ptr);
  ptr++;
  for(i = 0; (i < numportals) && (i < 32); i++){
    unsigned int ifcid = *ptr;
    ptr++;
    unsigned int ifctype = *ptr;
    ptr++;
    fprintf(stderr, "portal[%d]: ifcid=%d, ifctype=%08x\n", i, ifcid, ifctype);
  }
  fprintf(stderr, "interrupt_mux=%08x\n", *(req_fifo_base+0x00004000));
#else
  unsigned int ptr = 128*4;
  unsigned int numportals,i;
  fprintf(stderr, "version=%d\n",  read_portal(&p, ptr, name));
  ptr += 4;
  long int timestamp = (long int)read_portal(&p, ptr, name);
  fprintf(stderr, "timestamp=%s", ctime(&timestamp));
  ptr += 4;
  numportals = read_portal(&p, ptr, name);
  fprintf(stderr, "numportals=%d\n", numportals);
  ptr += 4;
  fprintf(stderr, "addrbits=%d\n", read_portal(&p, ptr, name));
  ptr += 4;
  for(i = 0; (i < numportals) && (i < 32); i++){
    unsigned int ifcid = read_portal(&p, ptr, name);
    ptr += 4;
    unsigned int ifctype = read_portal(&p, ptr, name);
    ptr += 4;
    fprintf(stderr, "portal[%d]: ifcid=%d, ifctype=%08x\n", i, ifcid, ifctype);
  }
  fprintf(stderr, "interrupt_mux=%08x\n", read_portal(&p, 0x00004000, name));
#endif
}

