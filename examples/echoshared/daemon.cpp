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

#include <stdio.h>
#include "EchoRequest.h"
#include "EchoIndication.h"
#include "MMUConfigRequest.h"
#include "MMUConfigIndication.h"

static EchoRequestProxy *echoRequestProxy;
static EchoIndicationProxy *sIndicationProxy;
static MMUConfigIndicationProxy *mIndicationProxy;
#define MAX_AREAS 20

class EchoIndication : public EchoIndicationWrapper
{
public:
    void heard(uint32_t v) {
        fprintf(stderr, "daemon: heard an echo: %d\n", v);
        sIndicationProxy->heard(v);
    }
    void heard2(uint32_t a, uint32_t b) {
        fprintf(stderr, "daemon: heard an echo2: %d %d\n", a, b);
        sIndicationProxy->heard2(a, b);
    }
    EchoIndication(unsigned int id, PortalItemFunctions *item) : EchoIndicationWrapper(id, item) {}
};

class EchoRequest : public EchoRequestWrapper
{
public:
    void say ( const uint32_t v ) {
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        echoRequestProxy->say(v);
    }
    void say2 ( const uint32_t a, const uint32_t b ) {
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        echoRequestProxy->say2(a, b);
    }
    void setLeds ( const uint32_t v ) {
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        echoRequestProxy->setLeds(v);
        sleep(1);
        exit(1);
    }
    EchoRequest(unsigned int id, PortalItemFunctions *item) : EchoRequestWrapper(id, item) {}
};

static EchoRequest *sRequest;
class MMUConfigRequest : public MMUConfigRequestWrapper
{
    struct {
        int fd;
        void *ptr;
        int len;
    } memoryAreas[MAX_AREAS];
    int memoryAreasIndex;
public:
    void sglist (const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len ) {
printf("daemon[%s:%d](%x, %x, %lx, %x)\n", __FUNCTION__, __LINE__, sglId, sglIndex, addr, len);
        memoryAreas[sglId].len = 1000;
    }
    void region (const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 ) {
       memoryAreas[sglId].ptr = portalMmap(memoryAreas[sglId].fd, memoryAreas[sglId].len);
       printf("daemon[%s:%d] ptr %p\n", __FUNCTION__, __LINE__, memoryAreas[sglId].ptr);
       sRequest->pint.map_base = (volatile unsigned int *)memoryAreas[sglId].ptr;
       sIndicationProxy->pint.map_base = (volatile unsigned int *)memoryAreas[sglId].ptr + (memoryAreas[sglId].len/2)/sizeof(uint32_t);
       mIndicationProxy->configResp(0);
    }
    void idRequest(SpecialTypeForSendingFd fd) {
       memoryAreas[memoryAreasIndex].fd = fd;
       memoryAreas[memoryAreasIndex].ptr = NULL;
       memoryAreas[memoryAreasIndex].len = 0;
       printf("daemon[%s:%d] fd %d\n", __FUNCTION__, __LINE__, fd);
       mIndicationProxy->idResponse(memoryAreasIndex++);
    }
    void idReturn (const uint32_t sglId ) {
       printf("daemon[%s:%d] sglId %d\n", __FUNCTION__, __LINE__, sglId);
    }
    void *getPtr (const uint32_t sglId ) {
        return memoryAreas[sglId].ptr;
    }
    MMUConfigRequest(unsigned int id, PortalItemFunctions *item) : MMUConfigRequestWrapper(id, item), memoryAreasIndex(1) {}
};

int main(int argc, const char **argv)
{
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication, NULL);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);

    sRequest = new EchoRequest(IfcNames_EchoRequest, &sharedfuncResp);
    sIndicationProxy = new EchoIndicationProxy(IfcNames_EchoIndication, &sharedfuncResp);

    MMUConfigRequest *mRequest = new MMUConfigRequest(IfcNames_MMUConfigRequest, &socketfuncResp);
    mIndicationProxy = new MMUConfigIndicationProxy(IfcNames_MMUConfigIndication, &socketfuncResp);

    portalExec_start();
    printf("[%s:%d] daemon sleeping...\n", __FUNCTION__, __LINE__);
    while(1)
        sleep(100);
    return 0;
}
