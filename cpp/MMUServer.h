/* Copyright (c) 2014 Quanta Research Cambridge, Inc
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

#include "MMURequest.h"
#include "MMUIndication.h"

#define MAX_SERVER_AREAS 20
static int trace_mmuserver;// = 1;

class MMUServer : public MMURequestWrapper
{
    struct {
        int fd;
        void *ptr;
        int len;
    } memoryAreas[MAX_SERVER_AREAS];
    int memoryAreasIndex;
    PortalInternal *ifcarr[MAX_SERVER_AREAS];
    MMUIndicationProxy *mIndicationProxy;
public:
    void sglist (const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len ) {
        if (trace_mmuserver)
            fprintf(stderr, "daemon[%s:%d](%x, %x, %lx, %x)\n", __FUNCTION__, __LINE__, sglId, sglIndex, addr, len);
        memoryAreas[sglId].len += len;
    }
    void region (const uint32_t sglId, const uint64_t barr12, const uint32_t index12, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 ) {
        memoryAreas[sglId].ptr = portalMmap(memoryAreas[sglId].fd, memoryAreas[sglId].len);
        //if (trace_mmuserver)
            fprintf(stderr, "daemon[%s:%d] fd %d ptr %p len %x\n", __FUNCTION__, __LINE__, memoryAreas[sglId].fd, memoryAreas[sglId].ptr, memoryAreas[sglId].len);
        mIndicationProxy->configResp(0);
    }
    void idRequest(SpecialTypeForSendingFd fd) {
        memoryAreas[memoryAreasIndex].fd = fd;
        memoryAreas[memoryAreasIndex].ptr = NULL;
        memoryAreas[memoryAreasIndex].len = 0;
        //if (trace_mmuserver)
        fprintf(stderr, "daemon[%s:%d] fd %d\n", __FUNCTION__, __LINE__, fd);
        if (fd <= 0) {
            fprintf(stderr, "[%s:%d] bogus fd value %d\n", __FUNCTION__, __LINE__, fd);
            exit(1);
        }

        mIndicationProxy->idResponse(memoryAreasIndex++);
    }
    void setInterface(uint32_t interfaceId, uint32_t sglId) {
        if (trace_mmuserver)
            fprintf(stderr, "[%s:%d] ifc %d sgl %d\n", __FUNCTION__, __LINE__, interfaceId, sglId);
        ifcarr[interfaceId]->map_base = (volatile unsigned int *)memoryAreas[sglId].ptr;
    }
    void idReturn (const uint32_t sglId ) {
        if (trace_mmuserver)
            fprintf(stderr, "daemon[%s:%d] sglId %d\n", __FUNCTION__, __LINE__, sglId);
    }
    void *getPtr (const uint32_t sglId ) {
        return memoryAreas[sglId].ptr;
    }
    void registerInterface(uint32_t interfaceId, PortalInternal *p) {
        ifcarr[interfaceId] = p;
    }
    MMUServer(unsigned int id, MMUIndicationProxy *mind, PortalTransportFunctions *transport, void *param) :
        MMURequestWrapper(id, transport, param), memoryAreasIndex(1), mIndicationProxy(mind) {}
};
