/* Copyright (c) 2016 Connectal Project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#ifndef _DMA_BUFFER_H_
#define _DMA_BUFFER_H_

#include "dmaManager.h"

class DmaBuffer {
    const int size;
    const bool cached;
    int fd;
    char *buf;
    int ref;
    static DmaManager *mgr;
    static void initDmaManager();
public:
    // Allocates a portal memory object of specified size and maps it into user process
    DmaBuffer(int size, bool cached=true);
    // Dereferences and deallocates the portal memory object
    // if destructor is not called, the object is automatically
    // unreferenced and freed when the process exits
    ~DmaBuffer();
    // returns the address of the mapped buffer
    char *buffer() {
	return buf;
    }
    // returns the reference to the object
    //
    // Sends the address translation table to hardware MMU if necessary.
    uint32_t reference();
    // Removes the address translation table from the hardware MMU
    void dereference();
    // invalidate and optionally flush from the dcache
    void cacheInvalidate(int size=0, int flush=0);
};


#endif // _DMA_BUFFER_H_
