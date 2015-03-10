
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
#include "drivers/zynqportal/zynqportal.h"
#else
#include "drivers/pcieportal/pcieportal.h"
#endif
#endif

#include "GeneratedTypes.h" // generated in project directory

static int trace_memory = 1;

#include "dmaSendFd.h"

void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *dmaDevice, PortalInternal *sglDevice)
{
  memset(priv, 0, sizeof(*priv));
  priv->dmaDevice = dmaDevice;
  priv->sglDevice = sglDevice;
  init_portal_memory();
  if (sem_init(&priv->sglIdSem, 0, 0)){
    PORTAL_PRINTF("failed to init sglIdSem\n");
  }
  if (sem_init(&priv->confSem, 0, 0)){
    PORTAL_PRINTF("failed to init confSem\n");
  }
}

void DmaManager_dereference(DmaManagerPrivate *priv, int ref)
{
  MMURequest_idReturn(priv->sglDevice, ref);
}

int DmaManager_reference(DmaManagerPrivate *priv, int fd)
{
  int id = 0;
  int rc = 0;
  init_portal_memory();
  MMURequest_idRequest(priv->sglDevice, (SpecialTypeForSendingFd)fd);
  sem_wait(&priv->sglIdSem);
  id = priv->sglId;
#if  !defined(BSIM) && !defined(__KERNEL__)
#ifdef ZYNQ
  PortalSendFd sendFd;
  sendFd.fd = fd;
  sendFd.id = id;
  rc = ioctl(priv->sglDevice->fpga_fd, PORTAL_SEND_FD, &sendFd);
#else
  tSendFd sendFd;
  sendFd.fd = fd;
  sendFd.id = id;
  rc = ioctl(priv->sglDevice->fpga_fd, PCIE_SEND_FD, &sendFd);
#endif
  if (!rc)
    sem_wait(&priv->confSem);
  rc = id;
#else // defined(BSIM) || defined(__KERNEL__)
  rc = send_fd_to_portal(priv->sglDevice, fd, id, global_pa_fd);
  if (rc <= 0) {
    //PORTAL_PRINTF("%s:%d sem_wait\n", __FUNCTION__, __LINE__);
    sem_wait(&priv->confSem);
  }
#endif // defined(BSIM) || defined(__KERNEL__)
  return rc;
}
