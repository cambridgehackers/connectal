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
unsigned int *srcBuffer;
void memdump(unsigned char *p, int len, const char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                printf("\n");
            printf("%s: ",title);
        }
        printf("%02x ", *p++);
        i++;
        len--;
    }
    printf("\n");
}

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
memdump((unsigned char *)srcBuffer, 64, "RDATA");
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
static int srcAlloc;
static int alloc_sz = 1000;
class MMUConfigRequest : public MMUConfigRequestWrapper
{
public:
    void sglist (const uint32_t sglId, const uint32_t sglIndex, const uint64_t addr, const uint32_t len ) {
printf("daemon[%s:%d](%x, %x, %lx, %x)\n", __FUNCTION__, __LINE__, sglId, sglIndex, addr, len);
    }
    void region (const uint32_t sglId, const uint64_t barr8, const uint32_t index8, const uint64_t barr4, const uint32_t index4, const uint64_t barr0, const uint32_t index0 ) {
       srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
printf("daemon[%s:%d] ptr %p\n", __FUNCTION__, __LINE__, srcBuffer);
       sRequest->pint.map_base = (volatile unsigned int *)srcBuffer;
       sIndicationProxy->pint.map_base = (volatile unsigned int *)srcBuffer;
memdump((unsigned char *)srcBuffer, 64, "RDATA");
       mIndicationProxy->configResp(0);
    }
    void idRequest(SpecialTypeForSendingFd fd) {
       srcAlloc = fd;
printf("daemon[%s:%d] fd %d\n", __FUNCTION__, __LINE__, fd);
       mIndicationProxy->idResponse(44);
    }
    void idReturn (const uint32_t sglId ) {
printf("daemon[%s:%d] sglId %d\n", __FUNCTION__, __LINE__, sglId);
    }
    MMUConfigRequest(unsigned int id, PortalItemFunctions *item) : MMUConfigRequestWrapper(id, item) {}
};

int main(int argc, const char **argv)
{
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication, NULL);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);

    sRequest = new EchoRequest(IfcNames_EchoRequest, &sharedfuncResp);
    sIndicationProxy = new EchoIndicationProxy(IfcNames_EchoIndication, &sharedfuncResp);

    MMUConfigRequest *mRequest = new MMUConfigRequest(IfcNames_MMUConfigRequest, &socketfuncResp);
    mIndicationProxy = new MMUConfigIndicationProxy(IfcNames_MMUConfigIndication, &socketfuncResp);

    defaultPoller->portalExec_timeout = 100;
    portalExec_start();
    defaultPoller->portalExec_timeout = 100;
    printf("[%s:%d] daemon sleeping...\n", __FUNCTION__, __LINE__);
    while(1)
        sleep(100);
    return 0;
}
