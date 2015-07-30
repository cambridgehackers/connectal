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
#include "sock_utils.h"
#include "EchoRequest.h"
#include "EchoIndication.h"

EchoRequestProxy *echoRequestProxy;
EchoIndicationProxy *sIndicationProxy;
EchoIndicationProxy *sIndicationProxy2;
static int daemon_trace = 1;

class EchoIndication : public EchoIndicationWrapper
{
public:
    void heard(uint32_t id, uint32_t v) {
        if (daemon_trace)
        fprintf(stderr, "daemon: heard an echo: %u %u\n", id, v);
		if (id == 1) {
        	sIndicationProxy->heard(id, v);
		} else if (id == 2) {
        	sIndicationProxy2->heard(id, v);
		} else {
			fprintf (stderr, "id is wrong (%u)", id);
		}
    }
    void heard2(uint32_t id, uint16_t a, uint16_t b) {
        if (daemon_trace)
        fprintf(stderr, "daemon: heard an echo2: %u %d %d\n", id, a, b);
		if (id == 1) {
        	sIndicationProxy->heard2(id, a, b);
		} else if (id == 2) {
        	sIndicationProxy2->heard2(id, a, b);
		} else {
			fprintf (stderr, "id is wrong (%u)", id);
		}
    }
    EchoIndication(unsigned int id, PortalTransportFunctions *item, void *param) : EchoIndicationWrapper(id, item, param) {}
};

class EchoRequest : public EchoRequestWrapper
{
public:
    void say (const uint32_t id, const uint32_t v ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s:%d] %u %u\n", __FUNCTION__, __LINE__, id, v);
        echoRequestProxy->say(id, v);
    }
    void say2 (const uint32_t id, const uint16_t a, const uint16_t b ) {
        if (daemon_trace)
        fprintf(stderr, "daemon[%s:%d] %u %u %u\n", __FUNCTION__, __LINE__, id, a, b);
        echoRequestProxy->say2(id, a, b);
    }
    void setLeds (const uint32_t id, const uint8_t v ) {
        fprintf(stderr, "daemon[%s:%d]\n", __FUNCTION__, __LINE__);
        echoRequestProxy->setLeds(id, v);
        sleep(1);
        exit(1);
    }
    EchoRequest(unsigned int id, PortalTransportFunctions *item, void *param) : EchoRequestWrapper(id, item, param) {}
};

int main(int argc, const char **argv)
{

    sIndicationProxy = new EchoIndicationProxy(IfcNames_EchoIndicationH2S, &transportSocketResp, NULL);
    sIndicationProxy2 = new EchoIndicationProxy(IfcNames_EchoIndication2H2S, &transportSocketResp, NULL);
    EchoRequest sRequest(IfcNames_EchoRequestS2H, &transportSocketResp, NULL);
    EchoRequest sRequest2(IfcNames_EchoRequest2S2H, &transportSocketResp, NULL);
    EchoIndication echoIndication(IfcNames_EchoIndicationH2S, NULL, NULL);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequestS2H);

    printf("[%s:%d] daemon sleeping...\n", __FUNCTION__, __LINE__);
    while(1)
        sleep(100);
    return 0;
}
