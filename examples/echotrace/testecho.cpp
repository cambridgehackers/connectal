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
#include "dmaManager.h"
#include "EchoIndication.h"
#include "EchoRequest.h"

static EchoRequestProxy *echoRequestProxy, *echoRequestTrace;
static sem_t sem_heard2;

static void memdump(uint8_t *p, int len, const char *title)
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
    virtual void heard(uint32_t v) {
        printf("heard an echo: %d\n", v);
	echoRequestProxy->say2(v, 2*v);
	echoRequestTrace->say2(v, 2*v);
    }
    virtual void heard2(uint16_t a, uint16_t b) {
        sem_post(&sem_heard2);
        //printf("heard an echo2: %ld %ld\n", a, b);
    }
    EchoIndication(unsigned int id) : EchoIndicationWrapper(id) {}
};

static void call_say(int v)
{
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    echoRequestProxy->say(v);
    echoRequestTrace->say(v);
    sem_wait(&sem_heard2);
}

static void call_say2(int v, int v2)
{
    echoRequestProxy->say2(v, v2);
    echoRequestTrace->say2(v, v2);
    sem_wait(&sem_heard2);
}

int main(int argc, const char **argv)
{
    EchoIndication echoIndication(IfcNames_EchoIndicationH2S);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequestS2H);
    int alloc_sz = 1000;
    PortalSharedParam param = {{NULL}, (uint32_t)alloc_sz};
    echoRequestTrace = new EchoRequestProxy(IfcNames_EchoRequestS2H, &transportTrace, &param);

    int v = 42;
    printf("Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    call_say2(v, v*3);
    printf("TEST TYPE: SEM\n");
    echoRequestProxy->setLeds(9);
    echoRequestTrace->setLeds(9);

    volatile unsigned int *p = echoRequestTrace->pint.map_base;
    printf("[%s] Dump trace buffer: limit %d write %d read %d start %d\n", __FUNCTION__,
        p[SHARED_LIMIT], p[SHARED_WRITE], p[SHARED_READ], p[SHARED_START]);
    uint32_t current = p[SHARED_WRITE];
    while (current != p[SHARED_READ]) {
        unsigned int hdr = p[current-1];
        current -= (hdr & 0xffff);
        printf ("W[%3d] %08x", current, hdr);
        memdump((uint8_t *)&p[current], ((hdr & 0xffff)-1) * sizeof(uint32_t), "");
    }
    return 0;
}
