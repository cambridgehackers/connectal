/*
 * Copyright (C) 2008 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <limits.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>

#include <cutils/ashmem.h>
#include <cutils/log.h>
#include <cutils/atomic.h>

#include <ion/ion.h>

#include <hardware/hardware.h>
#include <hardware/gralloc.h>

#include "gralloc_priv.h"
#include "gr.h"

#include "HdmiDisplay.h"

/*****************************************************************************/

struct gralloc_context_t {
    alloc_device_t  device;
    /* our private data here */
    volatile int vsync;
    pthread_mutex_t vsync_lock;
    pthread_cond_t vsync_cond;
    HdmiDisplay *hdmiDisplay;
    uint32_t nextSegmentNumber;
};

static gralloc_context_t *gralloc_dev = 0;

static int gralloc_alloc_buffer(alloc_device_t* dev,
                                size_t size, size_t stride, int usage, buffer_handle_t* pHandle);

/*****************************************************************************/

int fb_device_open(hw_module_t const* module, const char* name,
                   hw_device_t** device);

static int gralloc_device_open(const hw_module_t* module, const char* name,
        hw_device_t** device);

extern int gralloc_lock(gralloc_module_t const* module,
        buffer_handle_t handle, int usage,
        int l, int t, int w, int h,
        void** vaddr);

extern int gralloc_unlock(gralloc_module_t const* module, 
        buffer_handle_t handle);

extern int gralloc_register_buffer(gralloc_module_t const* module,
        buffer_handle_t handle);

extern int gralloc_unregister_buffer(gralloc_module_t const* module,
        buffer_handle_t handle);

/*****************************************************************************/

static struct hw_module_methods_t gralloc_module_methods = {
        open: gralloc_device_open
};

struct private_gralloc_module_t HAL_MODULE_INFO_SYM = {
    base: {
        common: {
            tag: HARDWARE_MODULE_TAG,
            version_major: 1,
            version_minor: 0,
            id: GRALLOC_HARDWARE_MODULE_ID,
            name: "Graphics Memory Allocator Module",
            author: "The Android Open Source Project",
            methods: &gralloc_module_methods,
            dso: 0,
            reserved: {0}
        },
        registerBuffer: gralloc_register_buffer,
        unregisterBuffer: gralloc_unregister_buffer,
        lock: gralloc_lock,
        unlock: gralloc_unlock,
        perform: 0,
    },
    lock: PTHREAD_MUTEX_INITIALIZER,
    currentBuffer: 0,
};

/*****************************************************************************/

static int gralloc_alloc_buffer(alloc_device_t* dev,
                                size_t size, size_t stride, int usage, buffer_handle_t* pHandle)
{
    int err = 0;
    int fd = -1;
    int segmentNumber = 0;

    size = roundUpToPageSize(size);
    
    struct gralloc_context_t *ctx = reinterpret_cast<gralloc_context_t*>(dev);

    if (ctx->hdmiDisplay != 0) {
        PortalAlloc portalAlloc;
        memset(&portalAlloc, 0, sizeof(portalAlloc));
        portal.alloc(size, &fd, &portalAlloc);

        if (usage & GRALLOC_USAGE_HW_FB) {
            ALOGD("adding translation table entries\n");
            segmentNumber = ctx->nextSegmentNumber;
            ctx->nextSegmentNumber += portalAlloc.numEntries;
            ctx->hdmiDisplay->beginTranslationTable(segmentNumber);
            for (int i = 0; i < portalAlloc.numEntries; i++) {
                ALOGD("adding translation entry %lx %lx", portalAlloc.entries[i].dma_address, portalAlloc.entries[i].length);
                ctx->hdmiDisplay->addTranslationEntry(portalAlloc.entries[i].dma_address >> 12,
                                              portalAlloc.entries[i].length >> 12);
            }
        }
        //ptr = mmap(0, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);

    }
    if (fd < 0) {
        fd = ashmem_create_region("gralloc-buffer", size);
        if (fd < 0) {
            ALOGE("couldn't create ashmem (%s)", strerror(-errno));
            err = -errno;
        }
    }

    if (err == 0) {
        private_handle_t* hnd = new private_handle_t(fd, size, 0);
        hnd->stride = stride;
        gralloc_module_t* module = reinterpret_cast<gralloc_module_t*>(
                dev->common.module);
        hnd->segmentNumber = segmentNumber;
        err = mapBuffer(module, hnd);
        if (err == 0) {
            *pHandle = hnd;
        }
    }
    
    ALOGE_IF(err, "gralloc failed err=%s", strerror(-err));
    
    return err;
}

/*****************************************************************************/

static int gralloc_alloc(alloc_device_t* dev,
        int w, int h, int format, int usage,
        buffer_handle_t* pHandle, int* pStride)
{
    if (!pHandle || !pStride)
        return -EINVAL;

    size_t size, stride;

    int align = 32;
    int bpp = 0;
    switch (format) {
        case HAL_PIXEL_FORMAT_RGBA_8888:
        case HAL_PIXEL_FORMAT_RGBX_8888:
        case HAL_PIXEL_FORMAT_BGRA_8888:
            bpp = 4;
            break;
        case HAL_PIXEL_FORMAT_RGB_888:
            bpp = 3;
            break;
        case HAL_PIXEL_FORMAT_RGB_565:
        case HAL_PIXEL_FORMAT_RGBA_5551:
        case HAL_PIXEL_FORMAT_RGBA_4444:
            bpp = 2;
            break;
        default:
            return -EINVAL;
    }
    size_t bpr = (w*bpp + (align-1)) & ~(align-1);
    size = bpr * h;
    stride = bpr / bpp;

    int err;
    err = gralloc_alloc_buffer(dev, size, stride, usage, pHandle);

    if (err < 0) {
        return err;
    }

    *pStride = stride;
    return 0;
}

static int gralloc_free(alloc_device_t* dev,
                        buffer_handle_t handle)
{
    if (private_handle_t::validate(handle) < 0)
        return -EINVAL;

    private_handle_t const* hnd = reinterpret_cast<private_handle_t const*>(handle);
    gralloc_module_t* module = reinterpret_cast<gralloc_module_t*>(dev->common.module);
    struct gralloc_context_t *ctx = reinterpret_cast<gralloc_context_t*>(dev);

    private_handle_t *private_handle = const_cast<private_handle_t*>(hnd);
    if (ctx->hdmiDisplay) {
        ALOGD("freeing ion buffer fd %d\n", private_handle->fd);
        portal.free(private_handle->fd);
    } else {
        ALOGD("freeing ashmem buffer %p\n", private_handle);
        terminateBuffer(module, private_handle);
    }

    close(hnd->fd);
    delete hnd;
    return 0;
}

/*****************************************************************************/

static int gralloc_close(struct hw_device_t *dev)
{
    gralloc_context_t* ctx = reinterpret_cast<gralloc_context_t*>(dev);
    if (ctx) {
        /* TODO: keep a list of all buffer_handle_t created, and free them
         * all here.
         */
        free(ctx);
    }
    return 0;
}

static int fb_setSwapInterval(struct framebuffer_device_t* dev,
            int interval)
{
    framebuffer_device_t* ctx = (framebuffer_device_t*)dev;
    if (interval < dev->minSwapInterval || interval > dev->maxSwapInterval)
        return -EINVAL;
    // FIXME: implement fb_setSwapInterval
    return 0;
}

class GrallocHdmiDisplayIndications : public HdmiDisplayIndications {
    virtual void vsync(unsigned long long v) {
        if (1)
            ALOGD("vsync %llx\n", v);
        pthread_mutex_lock(&gralloc_dev->vsync_lock);
        gralloc_dev->vsync = 1;
        pthread_cond_signal(&gralloc_dev->vsync_cond);
        pthread_mutex_unlock(&gralloc_dev->vsync_lock);
    }
};

static int fb_post(struct framebuffer_device_t* dev, buffer_handle_t buffer)
{
    if (private_handle_t::validate(buffer) < 0)
        return -EINVAL;

    private_handle_t const* hnd = reinterpret_cast<private_handle_t const*>(buffer);
    private_gralloc_module_t* m = reinterpret_cast<private_gralloc_module_t*>(
            dev->common.module);

    if (gralloc_dev && gralloc_dev->hdmiDisplay) {
        ALOGD("fb_post segmentNumber=%d\n", hnd->segmentNumber);
        pthread_mutex_lock(&gralloc_dev->vsync_lock);
        gralloc_dev->vsync = 0;
        gralloc_dev->hdmiDisplay->waitForVsync(0);
        gralloc_dev->hdmiDisplay->startFrameBuffer0(hnd->segmentNumber);
        while (!gralloc_dev->vsync) {
            pthread_cond_wait(&gralloc_dev->vsync_cond, &gralloc_dev->vsync_lock);
        }
        pthread_mutex_unlock(&gralloc_dev->vsync_lock);
        ALOGD("fb posted\n");
    }

    return 0;
}

static pthread_t fb_thread;
static void *fb_thread_routine(void *data)
{
    PortalInterface::exec(0);
    return data;
}

static int fb_close(struct hw_device_t *dev)
{
    pthread_kill(fb_thread, SIGTERM);
    if (dev) {
        free(dev);
    }
    return 0;
}


int gralloc_device_open(const hw_module_t* module, const char* name,
        hw_device_t** device)
{
    int status = -EINVAL;
    fprintf(stderr, "gralloc_device_open: name=%s\n", name);
    if (!strcmp(name, "gpu0")) {
        gralloc_context_t *dev;
        dev = (gralloc_context_t*)malloc(sizeof(*dev));
        gralloc_dev = dev;

        /* initialize our state here */
        memset(dev, 0, sizeof(*dev));

        /* initialize the procs */
        dev->device.common.tag = HARDWARE_DEVICE_TAG;
        dev->device.common.version = 0;
        dev->device.common.module = const_cast<hw_module_t*>(module);
        dev->device.common.close = gralloc_close;

        dev->device.alloc   = gralloc_alloc;
        dev->device.free    = gralloc_free;

        *device = &dev->device.common;

        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutex_init(&dev->vsync_lock, &attr);
        pthread_condattr_t condattr;
        pthread_condattr_init(&condattr);
        pthread_cond_init(&dev->vsync_cond, &condattr);
        dev->hdmiDisplay = HdmiDisplay::createHdmiDisplay("fpga0", new GrallocHdmiDisplayIndications);
        dev->nextSegmentNumber = 0;

        status = 0;
    } else if (!strcmp(name, GRALLOC_HARDWARE_FB0)) {
        alloc_device_t* gralloc_device;
        status = gralloc_open(module, &gralloc_device);
        if (status < 0)
            return status;

        /* initialize our state here */
        framebuffer_device_t *dev = (framebuffer_device_t*)malloc(sizeof(*dev));
        memset(dev, 0, sizeof(*dev));

        /* initialize the procs */
        dev->common.tag = HARDWARE_DEVICE_TAG;
        dev->common.version = 0;
        dev->common.module = const_cast<hw_module_t*>(module);
        dev->common.close = fb_close;
        dev->setSwapInterval = fb_setSwapInterval;
        dev->post            = fb_post;
        dev->setUpdateRect = 0;

        pthread_t thread;
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        pthread_create(&thread, &attr, fb_thread_routine, 0);

        private_gralloc_module_t* m = (private_gralloc_module_t*)module;
        //status = mapFrameBuffer(m);
        status = 0;
        if (status >= 0) {
            int format = HAL_PIXEL_FORMAT_RGBX_8888;
            unsigned short nlines = 480;
            unsigned short npixels = 720;
            unsigned short vsyncwidth = 5;
            unsigned short stridebytes = (npixels * 4 + 31) & ~31;
            unsigned short lmin = 40;
            unsigned short lmax = lmin + nlines;
            unsigned short pmin = 192;
// this is the value from CEA-861-D needed for 480P
pmin=138;
            unsigned short pmax = pmin + npixels;

            const_cast<uint32_t&>(dev->flags) = 0;
            const_cast<uint32_t&>(dev->width) = npixels;
            const_cast<uint32_t&>(dev->height) = nlines;
            const_cast<int&>(dev->stride) = stridebytes;
            const_cast<int&>(dev->format) = format;
            const_cast<float&>(dev->xdpi) = 100;
            const_cast<float&>(dev->ydpi) = 100;
            const_cast<float&>(dev->fps) = 60;
            const_cast<int&>(dev->minSwapInterval) = 1;
            const_cast<int&>(dev->maxSwapInterval) = 1;

            gralloc_dev->hdmiDisplay->hdmiLinesPixels((pmin + npixels) << 16 | (lmin + vsyncwidth + nlines));
            gralloc_dev->hdmiDisplay->hdmiStrideBytes(stridebytes);
            gralloc_dev->hdmiDisplay->hdmiLineCountMinMax(lmax << 16 | lmin);
            gralloc_dev->hdmiDisplay->hdmiPixelCountMinMax(pmax << 16 | pmin);
	    ALOGD("setting clock frequency %ld\n", 60l * (long)(pmin + npixels) * (long)(lmin + vsyncwidth + nlines));
	    int status = PortalInterface::setClockFrequency(1,
							    60l * (long)(pmin + npixels) * (long)(lmin + vsyncwidth + nlines),
							    0);
	    ALOGD("setClockFrequency returned %d", status);
            *device = &dev->common;
        }
    }
    return status;
}
