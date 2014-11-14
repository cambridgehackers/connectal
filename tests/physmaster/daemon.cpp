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

EchoIndicationProxy *sIndicationProxy;
static int daemon_trace = 1;

class EchoRequest : public EchoRequestWrapper
{
public:
    void say ( const uint32_t v ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        sIndicationProxy->heard(v);
    }
    void say2 ( const uint32_t a, const uint32_t b ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        sIndicationProxy->heard2(a, b);
    }
    void setLeds ( const uint32_t v ) {
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        sleep(1);
        exit(1);
    }
    EchoRequest(unsigned int id, PortalItemFunctions *item, void *param) : EchoRequestWrapper(id, item, param) {}
};

int main(int argc, const char **argv)
{
    sIndicationProxy = new EchoIndicationProxy(IfcNames_EchoIndication, &socketfuncResp, NULL);
    EchoRequest *sRequest = new EchoRequest(IfcNames_EchoRequest, &socketfuncResp, NULL);

    portalExec_start();
    printf("[%s:%d] daemon sleeping...\n", __FUNCTION__, __LINE__);
    while(1)
        sleep(100);
    return 0;
}
