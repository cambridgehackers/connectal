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
#include "MMUServer.h"

static EchoRequestProxy *echoRequestProxy;
static EchoIndicationProxy *sIndicationProxy;
static int daemon_trace;// = 1;

class EchoIndication : public EchoIndicationWrapper
{
public:
    void heard(uint32_t v) {
        if (daemon_trace)
        fprintf(stderr, "daemon: heard an echo: %d\n", v);
        sIndicationProxy->heard(v);
    }
    void heard2(uint16_t a, uint16_t b) {
        if (daemon_trace)
        fprintf(stderr, "daemon: heard an echo2: %d %d\n", a, b);
        sIndicationProxy->heard2(a, b);
    }
    EchoIndication(unsigned int id, PortalTransportFunctions *item, void *param) : EchoIndicationWrapper(id, item, param) {}
};

class EchoRequest : public EchoRequestWrapper
{
public:
    void say ( const uint32_t v ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        echoRequestProxy->say(v);
    }
    void say2 ( const uint16_t a, const uint16_t b ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        echoRequestProxy->say2(a, b);
    }
    void setLeds ( const uint8_t v ) {
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        echoRequestProxy->setLeds(v);
        sleep(1);
        exit(0);
    }
    EchoRequest(unsigned int id, PortalTransportFunctions *item, void *param) : EchoRequestWrapper(id, item, param) {}
};

static EchoRequest *sRequest;

int main(int argc, const char **argv)
{
    EchoIndication echoIndication(IfcNames_EchoIndicationH2S, NULL, NULL);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequestS2H);
    sRequest = new EchoRequest(IfcNames_EchoRequestS2H, &transportShared, NULL);
    sIndicationProxy = new EchoIndicationProxy(IfcNames_EchoIndicationH2S, &transportShared, NULL);

    MMUServer *mServer = new MMUServer(IfcNames_MMURequestS2H,
        new MMUIndicationProxy(IfcNames_MMUIndicationH2S, &transportSocketResp, NULL), &transportSocketResp, NULL);
    mServer->registerInterface(IfcNames_EchoRequestS2H, &sRequest->pint);
    mServer->registerInterface(IfcNames_EchoIndicationH2S, &sIndicationProxy->pint);

    printf("[%s:%d] daemon sleeping...\n", __FUNCTION__, __LINE__);
    while(1)
        sleep(100);
    return 0;
}
