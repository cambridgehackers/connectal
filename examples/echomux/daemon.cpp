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
#include <netdb.h>
#include "EchoRequest.h"
#include "EchoIndication.h"
#include "EchoRequestSW.h"
#include "EchoIndicationSW.h"

EchoRequestProxy *echoRequestProxy;
EchoIndicationSWProxy *sIndicationProxy;
static int daemon_trace = 1;

class EchoIndication : public EchoIndicationWrapper
{
public:
    void heard(uint32_t id, uint32_t v) {
        if (daemon_trace)
        fprintf(stderr, "daemon: heard an echo: %d\n", v);
        this->pint.request_index = id;
        sIndicationProxy->heard(v);
    }
    void heard2(uint32_t id, uint32_t a, uint32_t b) {
        if (daemon_trace)
        fprintf(stderr, "daemon: heard an echo2: %d %d\n", a, b);
        this->pint.request_index = id;
        sIndicationProxy->heard2(a, b);
    }
    EchoIndication(unsigned int id, PortalItemFunctions *item, void *param) : EchoIndicationWrapper(id, item, param) {}
};

class EchoRequest : public EchoRequestSWWrapper
{
public:
    void say ( const uint32_t v ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s] %d\n", __FUNCTION__, v);
        echoRequestProxy->say(this->pint.indication_index, v);
    }
    void say2 ( const uint32_t a, const uint32_t b ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s] %d %d\n", __FUNCTION__, a, b);
        echoRequestProxy->say2(this->pint.indication_index, a, b);
    }
    void setLeds ( const uint32_t v ) {
        fprintf(stderr, "daemon[%s] %d\n", __FUNCTION__, __LINE__, v);
        echoRequestProxy->setLeds(this->pint.indication_index, v);
        //sleep(1);
        //exit(1);
    }
    EchoRequest(unsigned int id, PortalItemFunctions *item, void *param) : EchoRequestSWWrapper(id, item, param) {}
};

int main(int argc, const char **argv)
{
    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    Portal *mcommon = new Portal(0, sizeof(uint32_t), NULL, NULL, &socketfuncResp, &paramSocket, 0);
    param.pint = &mcommon->pint;
    sIndicationProxy = new EchoIndicationSWProxy(IfcNames_EchoIndication, &muxfunc, &param);
    EchoRequest *sRequest = new EchoRequest(IfcNames_EchoRequest, &muxfunc, &param);

    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication, NULL, NULL);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);

    portalExec_start();
    printf("[%s:%d] daemon sleeping...\n", __FUNCTION__, __LINE__);
    while(1)
        sleep(100);
    return 0;
}
