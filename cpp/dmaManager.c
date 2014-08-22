
// Copyright (c) 2013,2014 Quanta Research Cambridge, Inc.

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

#include "dmaManager.h"
#include "sock_utils.h"

#ifndef __KERNEL__
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#if defined(__arm__)
#include "zynqportal.h"
#else
#include "pcieportal.h"
#endif
#endif

#if 1 //def NO_CPP_PORTAL_CODE
#include "GeneratedTypes.h" // generated in project directory
#define DMAGetMemoryTraffic(P,A) DmaConfigProxy_getMemoryTraffic((P), (A))
#else
#include "DmaConfigProxy.h" // generated in project directory
#define DMAGetMemoryTraffic(P,A) ((DmaConfigProxy *)((P)->parent))->getMemoryTraffic((A))
#endif

#define KERNEL_REFERENCE

static int trace_memory = 1;

#include "dmaSendFd.h"

void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *argDevice)
{
  memset(priv, 0, sizeof(*priv));
  priv->device = argDevice;
#ifndef __KERNEL__
  init_portal_memory();
#endif
  if (sem_init(&priv->confSem, 0, 0)){
    PORTAL_PRINTF("failed to init confSem\n");
  }
  if (sem_init(&priv->mtSem, 0, 0)){
    PORTAL_PRINTF("failed to init mtSem\n");
  }
  if (sem_init(&priv->dbgSem, 0, 0)){
    PORTAL_PRINTF("failed to init dbgSem\n");
  }
}

uint64_t DmaManager_show_mem_stats(DmaManagerPrivate *priv, ChannelType rc)
{
  uint64_t rv = 0;
  DMAGetMemoryTraffic(priv->device, rc);
  sem_wait(&priv->mtSem);
  rv += priv->mtCnt;
  return rv;
}

int DmaManager_reference(DmaManagerPrivate *priv, int fd)
{
  int id = priv->handle++;
  int rc = 0;
#if defined(KERNEL_REFERENCE) && !defined(BSIM) && !defined(__KERNEL__)
#ifdef ZYNQ
  PortalSendFd sendFd;
  sendFd.fd = fd;
  sendFd.id = id;
  rc = ioctl(priv->device->fpga_fd, PORTAL_SEND_FD, &sendFd);
#else
  tSendFd sendFd;
  sendFd.fd = fd;
  sendFd.id = id;
  rc = ioctl(priv->device->fpga_fd, PCIE_SEND_FD, &sendFd);
#endif
  if (!rc)
    sem_wait(&priv->confSem);
  rc = id;
#else // KERNEL_REFERENCE 
  init_portal_memory();
  rc = send_fd_to_portal(priv->device, fd, id, global_pa_fd);
  if (rc <= 0) {
    //PORTAL_PRINTF("%s:%d sem_wait\n", __FUNCTION__, __LINE__);
    sem_wait(&priv->confSem);
  }
#endif // KERNEL_REFERENCE
  return rc;
}
