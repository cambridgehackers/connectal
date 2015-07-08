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
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <cutils/ashmem.h>
#include <cutils/log.h>
#include <cutils/atomic.h>
#include <cutils/properties.h>
#include <hardware/hardware.h>
#include <hardware/gralloc.h>

#include "gralloc_priv.h"
#include "gr.h"

#include "MemServerRequest.h"
#include "SGListConfigRequest.h"
#include "DmaIndication.h"
#include "HdmiDisplayRequest.h"
#include "HdmiInternalRequest.h"
#include "HdmiInternalIndication.h"
#include "dmaManager.h"
#include "i2chdmi.h"

class TestHdmiIndication : public HdmiInternalIndicationWrapper {
public:
    virtual void vsync ( unsigned long long v ) {
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    }
};

/*****************************************************************************/

struct gralloc_context_t {
    alloc_device_t  device;
    /* our private data here */
    volatile int vsync;
    pthread_mutex_t vsync_lock;
    pthread_cond_t vsync_cond;
    PortalPoller *poller;
    HdmiDisplayRequestProxy *hdmiDisplay;
    HdmiInternalRequestProxy *hdmiInternal;
    SGListConfigRequestProxy *dmap;
    DmaManager *dma;
    SGListConfigIndication *dmaIndication;
    unsigned int ref_srcAlloc;
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
        fd = portalAlloc(size, 0);
        ctx->ref_srcAlloc = ctx->dma->reference(fd);
        //ptr = portalMmap(fd, size);
    }
    if (fd < 0) {
        ALOGE("couldn't create ashmem (%s)", strerror(-errno));
        err = -errno;
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
            bpp = 2;
            break;
        default:
	  ALOGE("unknown pixel format %x in gralloc_alloc\n", format);
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
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    if (private_handle_t::validate(handle) < 0)
        return -EINVAL;

    private_handle_t const* hnd = reinterpret_cast<private_handle_t const*>(handle);
    gralloc_module_t* module = reinterpret_cast<gralloc_module_t*>(dev->common.module);
    struct gralloc_context_t *ctx = reinterpret_cast<gralloc_context_t*>(dev);

    private_handle_t *private_handle = const_cast<private_handle_t*>(hnd);
    if (ctx->hdmiDisplay) {
        ALOGD("freeing portal buffer fd %d\n", private_handle->fd);
        close(private_handle->fd);
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
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
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
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    framebuffer_device_t* ctx = (framebuffer_device_t*)dev;
    if (interval < dev->minSwapInterval || interval > dev->maxSwapInterval)
        return -EINVAL;
    // FIXME: implement fb_setSwapInterval
    return 0;
}

class GrallocHdmiDisplayIndications : public HdmiInternalIndicationWrapper {
    virtual void vsync(unsigned long long v) {
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
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
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    if (private_handle_t::validate(buffer) < 0)
        return -EINVAL;

    private_handle_t const* hnd = reinterpret_cast<private_handle_t const*>(buffer);
    private_gralloc_module_t* m = reinterpret_cast<private_gralloc_module_t*>(
            dev->common.module);

    if (gralloc_dev && gralloc_dev->hdmiDisplay) {
        ALOGD("fb_post segmentNumber=%d\n", hnd->segmentNumber);
        pthread_mutex_lock(&gralloc_dev->vsync_lock);
        gralloc_dev->vsync = 0;
        gralloc_dev->hdmiInternal->waitForVsync(0);
        gralloc_dev->hdmiDisplay->startFrameBuffer(gralloc_dev->ref_srcAlloc,
						   hnd->size/4);
        gralloc_dev->hdmiInternal->waitForVsync(0);
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
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    portalExec(0);
    return data;
}

static int fb_close(struct hw_device_t *dev)
{
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    pthread_kill(fb_thread, SIGTERM);
    if (dev) {
        free(dev);
    }
    return 0;
}

int gralloc_device_open(const hw_module_t* module, const char* name,
        hw_device_t** device)
{
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    int status = -EINVAL;
    ALOGD( "gralloc_device_open: name=%s\n", name);
    init_i2c_hdmi();
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
	dev->poller = new PortalPoller();
        dev->hdmiDisplay = new HdmiDisplayRequestProxy(IfcNames_HdmiDisplayRequest, dev->poller);
        dev->hdmiInternal = new HdmiInternalRequestProxy(IfcNames_HdmiInternalRequest, dev->poller);
        dev->dma = platformInit();
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
            /* This table is from CEA-861-D, Table 2: Video Format Timings */
            static struct {
               int code;
               int hactive;
               int vactive;
               int hblank;
               int vblank;
            } screen_types[] = { /* table only contains progressive types */
                { 1, 640, 480, 160, 45}, // Weird
                { 2, 720, 480, 138, 45}, { 3, 720, 480, 138, 45},
                { 4, 1280, 720, 370, 30},
                { 8, 1440, 240, 276, 22}, { 9, 1440, 240, 276, 22},
                {12, 2880, 240, 552, 22}, {13, 2880, 240, 552, 22}, // Weird
                {14, 1440, 480, 276, 45}, {15, 1440, 480, 276, 45}, // Failed
                {16, 1920, 1080, 280, 45},
                {17, 720, 576, 144, 49}, {18, 720, 576, 144, 49},
                {19, 1280, 720, 700, 30}, // Failed
                {23, 1440, 288, 288, 24}, {24, 1440, 288, 288, 24}, // Weird
                {27, 2880, 288, 576, 24}, {28, 2880, 288, 576, 24},
                {29, 1440, 576, 288, 49}, {30, 1440, 576, 288, 49},
                {31, 1920, 1080, 720, 45},
                {32, 1920, 1080, 830, 45},
                {33, 1920, 1080, 720, 45},
                {34, 1920, 1080, 280, 45},
                {35, 2880, 480, 552, 45}, {36, 2880, 480, 552, 45}, // Failed
                {37, 2880, 576, 576, 49}, {38, 2880, 576, 576, 49}, // Failed
                {41, 1280, 720, 700, 30}, // Failed
                {42, 720, 576, 144, 49}, {43, 720, 576, 144, 49},
                {47, 1280, 720, 370, 30}, // Weird
                {48, 720, 480, 138, 45}, {49, 720, 480, 138, 45},
                {52, 720, 576, 144, 49}, {53, 720, 576, 144, 49},
                {56, 720, 480, 138, 45}, {57, 720, 480, 138, 45}, {0, 0, 0, 0, 0}};
            int format = HAL_PIXEL_FORMAT_RGBX_8888;
            unsigned short vsyncwidth = 5;
            static char screenprop[PROPERTY_VALUE_MAX];
            int index = 0;

            unsigned short nlines = 480;
            unsigned short npixels = 720;
            unsigned short lmin = 45;
            unsigned short pmin = 138;
            property_get("rw.screencode", screenprop, "2");
            int screen_code = atoi(screenprop);
            while (screen_types[index].code && screen_types[index].code != screen_code)
                index++;
            if (screen_types[index].code) {
                nlines = screen_types[index].vactive;
                npixels = screen_types[index].hactive;
                lmin = screen_types[index].vblank;
                pmin = screen_types[index].hblank;
            }
            ALOGD("[%s:%d] code %d: %d x %d blank %d x %d\n", __FUNCTION__, __LINE__, screen_types[index].code, nlines, npixels, lmin, pmin);
            unsigned short stridebytes = (npixels * 4 + 31) & ~31;
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

vsyncwidth = 0;
            gralloc_dev->hdmiInternal->setDeLineCountMinMax (lmin - vsyncwidth, lmin + nlines - vsyncwidth, (lmin + lmin + nlines) / 2 - vsyncwidth);
            gralloc_dev->hdmiInternal->setDePixelCountMinMax (pmin, pmin + npixels, pmin + npixels / 2);
	    ALOGD("setting clock frequency %ld\n", 60l * (long)(pmin + npixels) * (long)(lmin + nlines));
	    setClockFrequency(1, 60l * (long)(pmin + npixels) * (long)(lmin + nlines), 0);
            *device = &dev->common;
        }
    }
    return status;
}
