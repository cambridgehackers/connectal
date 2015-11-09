
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
#ifndef __KERNEL__
#include <string.h>
#include <errno.h>
#include <sys/ioctl.h>
#ifdef ZYNQ
#include "drivers/zynqportal/zynqportal.h"
#else
#include "drivers/pcieportal/pcieportal.h"
#endif
#endif
#if defined(SIMULATION)
#include "dmaSendFd.h"
#endif
#include "GeneratedTypes.h"

#ifndef __KERNEL__
static pthread_mutex_t dma_mutex;
pthread_once_t mutex_once = PTHREAD_ONCE_INIT;
static void dmaManagerOnce(void)
{
  fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
  pthread_mutex_init(&dma_mutex, 0);
}
#endif

void DmaManager_init(DmaManagerPrivate *priv, PortalInternal *sglDevice)
{
    memset(priv, 0, sizeof(*priv));
    priv->sglDevice = sglDevice;
#ifndef __KERNEL__
    pthread_once(&mutex_once, dmaManagerOnce);
#endif
    initPortalMemory();
    if (sem_init(&priv->sglIdSem, 0, 0)){
        PORTAL_PRINTF("failed to init sglIdSem\n");
    }
    if (sem_init(&priv->confSem, 0, 0)){
        PORTAL_PRINTF("failed to init confSem\n");
    }
}

void DmaManager_dereference(DmaManagerPrivate *priv, int ref)
{
#if  !defined(SIMULATION) && !defined(__KERNEL__)
  pthread_mutex_lock(&dma_mutex);
#ifdef ZYNQ
    int rc = ioctl(priv->sglDevice->fpga_fd, PORTAL_DEREFERENCE, ref);
#else
    int rc = ioctl(priv->sglDevice->fpga_fd, PCIE_DEREFERENCE, ref);
#endif
  pthread_mutex_unlock(&dma_mutex);
    if (rc != 0)
      fprintf(stderr, "[%s:%d] dereference ioctl error %d\n", __FUNCTION__, __LINE__, errno);
#else
    MMURequest_idReturn(priv->sglDevice, ref);
#endif
}

int DmaManager_reference(DmaManagerPrivate *priv, int fd)
{
    int id = 0;
    int rc = 0;
    pthread_mutex_lock(&dma_mutex);
    initPortalMemory();
    MMURequest_idRequest(priv->sglDevice, (SpecialTypeForSendingFd)fd);
    if (priv->poll) {
        int rc = priv->poll(priv->shared_mmu_indication, &priv->sglId);
        fprintf(stderr, "[%s:%d] return after idrequest %d %d\n", __FUNCTION__, __LINE__, rc, priv->sglId);
    }
    else
        sem_wait(&priv->sglIdSem);
    id = priv->sglId;
#if  !defined(SIMULATION) && !defined(__KERNEL__)
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
    if (!rc) {
        if (priv->poll) {
            uint32_t ret;
            int rc = priv->poll(priv->shared_mmu_indication, &ret);
            fprintf(stderr, "[%s:%d] return after ioctl %d %d\n", __FUNCTION__, __LINE__, rc, ret);
        }
        else
            sem_wait(&priv->confSem);
    }
    rc = id;
#else // defined(SIMULATION) || defined(__KERNEL__)
    rc = send_fd_to_portal(priv->sglDevice, fd, id, global_pa_fd);
    if (rc >= 0) {
        //PORTAL_PRINTF("%s:%d sem_wait\n", __FUNCTION__, __LINE__);
        if (priv->poll) {
            uint32_t ret;
            int rc = priv->poll(priv->shared_mmu_indication, &ret);
            fprintf(stderr, "[%s:%d] return after sendfd %d %d\n", __FUNCTION__, __LINE__, rc, ret);
        }
        else
            sem_wait(&priv->confSem);
    }
#endif // defined(SIMULATION) || defined(__KERNEL__)
    pthread_mutex_unlock(&dma_mutex);
    return rc;
}

void DmaManager_idresp(DmaManagerPrivate *priv, uint32_t sglId)
{
    priv->sglId = sglId;
#ifndef __KERNEL__
    sem_post(&priv->sglIdSem);
#endif
}

void DmaManager_confresp(DmaManagerPrivate *priv, uint32_t channelId)
{
#ifndef __KERNEL__
    //fprintf(stderr, "configResp %d\n", channelId);
    sem_post(&priv->confSem);
#endif
}
