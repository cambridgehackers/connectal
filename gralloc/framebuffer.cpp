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

#include <sys/mman.h>

#include <dlfcn.h>

#include <cutils/ashmem.h>
#include <cutils/log.h>

#include <hardware/hardware.h>
#include <hardware/gralloc.h>

#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <string.h>
#include <stdlib.h>

#include <cutils/log.h>
#include <cutils/atomic.h>

#if HAVE_ANDROID_OS
#include <linux/fb.h>
#endif

#include "gralloc_priv.h"
#include "gr.h"

/*****************************************************************************/

// numbers of buffers for page flipping
#define NUM_BUFFERS 2


enum {
    PAGE_FLIP = 0x00000001,
    LOCKED = 0x00000002
};

static int override_xres = 800;
static int override_yres = 400;

/*****************************************************************************/

static int fb_setSwapInterval(struct framebuffer_device_t* dev,
            int interval)
{
    framebuffer_device_t* ctx = (framebuffer_device_t*)dev;
    if (interval < dev->minSwapInterval || interval > dev->maxSwapInterval)
        return -EINVAL;
    // FIXME: implement fb_setSwapInterval
    return 0;
}

static int fb_setUpdateRect(struct framebuffer_device_t* dev,
        int l, int t, int w, int h)
{
    if (((w|h) <= 0) || ((l|t)<0))
        return -EINVAL;
        
    framebuffer_device_t* ctx = (framebuffer_device_t*)dev;
    private_gralloc_module_t* m = reinterpret_cast<private_gralloc_module_t*>(
            dev->common.module);
    m->info.reserved[0] = 0x54445055; // "UPDT";
    m->info.reserved[1] = (uint16_t)l | ((uint32_t)t << 16);
    m->info.reserved[2] = (uint16_t)(l+w) | ((uint32_t)(t+h) << 16);
    return 0;
}

static int fb_post(struct framebuffer_device_t* dev, buffer_handle_t buffer)
{
    if (private_handle_t::validate(buffer) < 0)
        return -EINVAL;

    framebuffer_device_t* ctx = (framebuffer_device_t*)dev;

    private_handle_t const* hnd = reinterpret_cast<private_handle_t const*>(buffer);
    private_gralloc_module_t* m = reinterpret_cast<private_gralloc_module_t*>(
            dev->common.module);

    if (0 && (hnd->flags & private_handle_t::PRIV_FLAGS_FRAMEBUFFER)) {
        const size_t offset = hnd->base - m->framebuffer->base;
        m->info.activate = FB_ACTIVATE_VBL;
        m->info.yoffset = offset / m->finfo.line_length;
        if (ioctl(m->framebuffer->fd, FBIOPUT_VSCREENINFO, &m->info) == -1) {
            ALOGE("FBIOPUT_VSCREENINFO failed");
            m->base.unlock(&m->base, buffer); 
            return -errno;
        }
        m->currentBuffer = buffer;
        
    } else {
        // If we can't do the page_flip, just copy the buffer to the front 
        // FIXME: use copybit HAL instead of memcpy
        
        void* fb_vaddr;
        void* buffer_vaddr;
        
        m->base.lock(&m->base, m->framebuffer, 
                     GRALLOC_USAGE_SW_WRITE_RARELY, 
                     0, 0, m->info.xres, m->info.yres,
                     &fb_vaddr);

        m->base.lock(&m->base, buffer, 
                     GRALLOC_USAGE_SW_READ_RARELY, 
                     0, 0, m->info.xres, m->info.yres,
                     &buffer_vaddr);

        char *dst_vaddr = (char*)fb_vaddr;
        char *src_vaddr = (char*)buffer_vaddr;
        size_t src_row_bytes = override_xres * (m->info.bits_per_pixel >> 3);
        if (0)
        ALOGI("%s:%d line_length=%d size=%d smem_len=%d src_row_bytes=%d\n",
              __FILE__, __LINE__,
              m->finfo.line_length,
              m->finfo.line_length * override_yres,
              m->finfo.smem_len,
              src_row_bytes);

        if (0) {
            memcpy(dst_vaddr, buffer_vaddr, m->finfo.smem_len);
        } else {
            for (int row = 0; row < override_yres; row++) {
                if (0)
                ALOGI("%s:%d row=%d dst_vaddr=%p src_vaddr=%p\n",
                      __FILE__, __LINE__,
                      row,
                      dst_vaddr, src_vaddr);
                memcpy(dst_vaddr, src_vaddr, src_row_bytes);
                dst_vaddr += m->finfo.line_length;
                src_vaddr += src_row_bytes;
            };
        }
        
        m->base.unlock(&m->base, buffer); 
        m->base.unlock(&m->base, m->framebuffer); 
    }
    
    return 0;
}

/*****************************************************************************/

int mapFrameBufferLocked(struct private_gralloc_module_t* module)
{
    // already initialized...
    if (module->framebuffer) {
        return 0;
    }
        
    char const * const device_template[] = {
            "/dev/graphics/fb%u",
            "/dev/fb%u",
            0 };

    int fd = -1;
    int i=0;
    char name[64];

    while ((fd==-1) && device_template[i]) {
        snprintf(name, 64, device_template[i], 0);
        fd = open(name, O_RDWR, 0);
        i++;
    }
    if (fd < 0)
        return -errno;

    struct fb_fix_screeninfo finfo;
    if (ioctl(fd, FBIOGET_FSCREENINFO, &finfo) == -1)
        return -errno;

    struct fb_var_screeninfo info;
    if (ioctl(fd, FBIOGET_VSCREENINFO, &info) == -1)
        return -errno;

    info.reserved[0] = 0;
    info.reserved[1] = 0;
    info.reserved[2] = 0;
    info.xoffset = 0;
    info.yoffset = 0;
    info.activate = FB_ACTIVATE_NOW;

    /*
     * Request NUM_BUFFERS screens (at lest 2 for page flipping)
     */
    //info.xres = info.xres_virtual / 2;
    //info.yres = info.yres_virtual / 2;
    //info.xres_virtual = info.xres;
    info.yres_virtual = info.yres * 1; //NUM_BUFFERS;

    uint32_t flags = PAGE_FLIP;
    if ((ioctl(fd, FBIOPUT_VSCREENINFO, &info) == -1) || 1) {
        //info.yres_virtual = info.yres;
        flags &= ~PAGE_FLIP;
        ALOGW("FBIOPUT_VSCREENINFO failed, page flipping not supported");
    } else {
        ALOGI("page flipping seems to be supported");
    }

    if (info.yres_virtual < info.yres * 2) {
        // we need at least 2 for page-flipping
        //info.yres_virtual = info.yres;
        flags &= ~PAGE_FLIP;
        ALOGW("page flipping not supported (yres_virtual=%d, requested=%d)",
              info.yres_virtual, info.yres*2);
    } else {
        ALOGI("page flipping seems to be supported (yres_virtual=%d, requested=%d)",
              info.yres_virtual, info.yres*2);
    }

    //override_xres = info.xres;
    //override_yres = info.yres;

    if (ioctl(fd, FBIOGET_VSCREENINFO, &info) == -1)
        return -errno;

    uint64_t  refreshQuotient =
    (
            uint64_t( info.upper_margin + info.lower_margin + info.yres )
            * ( info.left_margin  + info.right_margin + info.xres )
            * info.pixclock
    );

    /* Beware, info.pixclock might be 0 under emulation, so avoid a
     * division-by-0 here (SIGFPE on ARM) */
    int refreshRate = refreshQuotient > 0 ? (int)(1000000000000000LLU / refreshQuotient) : 0;

    if (refreshRate == 0) {
        // bleagh, bad info from the driver
        refreshRate = 60*1000;  // 60 Hz
    }

    if (int(info.width) <= 0 || int(info.height) <= 0) {
        // the driver doesn't return that information
        // default to 160 dpi
        info.width  = ((info.xres * 25.4f)/160.0f + 0.5f);
        info.height = ((info.yres * 25.4f)/160.0f + 0.5f);
    }

    float xdpi = (info.xres * 25.4f) / info.width;
    float ydpi = (info.yres * 25.4f) / info.height;
    float fps  = refreshRate / 1000.0f;

    ALOGI(   "using (fd=%d)\n"
            "id           = %s\n"
            "xres         = %d px\n"
            "yres         = %d px\n"
            "xres_virtual = %d px\n"
            "yres_virtual = %d px\n"
            "bpp          = %d\n"
            "r            = %2u:%u\n"
            "g            = %2u:%u\n"
            "b            = %2u:%u\n",
            fd,
            finfo.id,
            info.xres,
            info.yres,
            info.xres_virtual,
            info.yres_virtual,
            info.bits_per_pixel,
            info.red.offset, info.red.length,
            info.green.offset, info.green.length,
            info.blue.offset, info.blue.length
    );

    ALOGI(   "width        = %d mm (%f dpi)\n"
            "height       = %d mm (%f dpi)\n"
            "refresh rate = %.2f Hz\n",
            info.width,  xdpi,
            info.height, ydpi,
            fps
    );


    if (ioctl(fd, FBIOGET_FSCREENINFO, &finfo) == -1)
        return -errno;

    if (finfo.smem_len <= 0)
        return -errno;


    module->flags = flags;
    module->info = info;
    module->finfo = finfo;
    module->xdpi = xdpi;
    module->ydpi = ydpi;
    module->fps = fps;

    /*
     * map the framebuffer
     */

    int err;
    size_t fbSize = roundUpToPageSize(finfo.smem_len);
    module->framebuffer = new private_handle_t(dup(fd), fbSize, 0);

    // calculate from smem_len / (yres_vsize * xres_vsize * bits_per_pixel/8)
    module->numBuffers = 1; //info.yres_virtual / info.yres;
    module->bufferMask = 0;

    void* vaddr = mmap(0, fbSize, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if (vaddr == MAP_FAILED) {
        ALOGE("Error mapping the framebuffer shared (%s)", strerror(errno));
        return -errno;
    }
    module->framebuffer->base = intptr_t(vaddr);
    memset(vaddr, 0, fbSize);
    return 0;
}

static int mapFrameBuffer(struct private_gralloc_module_t* module)
{
    pthread_mutex_lock(&module->lock);
    int err = mapFrameBufferLocked(module);
    pthread_mutex_unlock(&module->lock);
    return err;
}


/*****************************************************************************/

