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

#include "EchoRequestSW.h"
#include "EchoIndicationSW.h"
#include "SecondRequest.h"
#include "SecondIndication.h"
#include "ThirdRequest.h"
#include "ThirdIndication.h"

static sem_t semEcho;
EchoRequestSWProxy *sEcho;

class EchoIndication : public EchoIndicationSWWrapper
{
public:
    virtual void heard(uint32_t v) {
        fprintf(stderr, "heard an s: %d\n", v);
	sEcho->say2(v, 2*v);
    }
    virtual void heard2(uint16_t a, uint16_t b) {
        sem_post(&semEcho);
        //fprintf(stderr, "heard an s2: %ld %ld\n", a, b);
    }
    EchoIndication(unsigned int id, PortalTransportFunctions *item, void *param) : EchoIndicationSWWrapper(id, item, param) {}
};

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    sEcho->say(v);
    sem_wait(&semEcho);
}

static void call_say2(int v, int v2)
{
    sEcho->say2(v, v2);
    sem_wait(&semEcho);
}

//static sem_t semSecond;
SecondRequestProxy *sSecond;

class SecondIndication : public SecondIndicationWrapper
{
public:
    virtual void heard(uint32_t v, uint32_t a) {
        fprintf(stderr, "Secondheard an s: %d %d\n", v, a);
    }
    SecondIndication(unsigned int id, PortalTransportFunctions *item, void *param) : SecondIndicationWrapper(id, item, param) {}
};

//static sem_t semThird;
ThirdRequestProxy *sThird;

class ThirdIndication : public ThirdIndicationWrapper
{
public:
    virtual void heard() {
        fprintf(stderr, "Thirdheard\n");
    }
    ThirdIndication(unsigned int id, PortalTransportFunctions *item, void *param) : ThirdIndicationWrapper(id, item, param) {}
};

int main(int argc, const char **argv)
{
    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    Portal *mcommon = new Portal(0, 0, sizeof(uint32_t), portal_mux_handler, NULL, &transportSocketInit, &paramSocket, 0);
    param.pint = &mcommon->pint;
    EchoIndication sIndication(IfcNames_EchoIndicationH2S, &transportMux, &param);
    sEcho = new EchoRequestSWProxy(IfcNames_EchoRequestS2H, &transportMux, &param);
    SecondIndication sSecondIndication(IfcNames_SecondIndication, &transportMux, &param);
    sSecond = new SecondRequestProxy(IfcNames_SecondRequest, &transportMux, &param);
    ThirdIndication sThirdIndication(IfcNames_ThirdIndication, &transportMux, &param);
    sThird = new ThirdRequestProxy(IfcNames_ThirdRequest, &transportMux, &param);

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
sSecond->say(v*99, v * 1000000000L, v*55);
    call_say(v*5);
sThird->say();
    call_say(v*17);
    call_say(v*93);
    call_say2(v, v*3);
    printf("TEST TYPE: SEM\n");
    sEcho->setLeds(9);
    return 0;
}
