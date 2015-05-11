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
#include "EchoIndication.h"
#include "EchoRequest.h"
#include "GeneratedTypes.h"
#include "topEnum.h"

static EchoRequestProxy *echoRequestProxy = 0;
static sem_t sem_heard2;

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(EchoHeard v) {
        EchoSay2 tmp = {v.v, 2*v.v};
        printf("heard an echo: %d\n", v.v);
        echoRequestProxy->say2(tmp);
    }
    virtual void heard2(EchoHeard2 v) {
        sem_post(&sem_heard2);
        //printf("heard an echo2: %ld %ld\n", a, b);
    }
    EchoIndication(unsigned int id) : EchoIndicationWrapper(id) {}
};

static void call_say(fixed32 v)
{
    EchoSay tmp = {v};
    printf("[%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    echoRequestProxy->say(tmp);
    sem_wait(&sem_heard2);
}

static void call_say2(fixed32 v, fixed32 v2)
{
    EchoSay2 tmp = {v, v2};
    echoRequestProxy->say2(tmp);
    sem_wait(&sem_heard2);
}

int main(int argc, const char **argv)
{
    EchoIndication echoIndication(IfcNames_EchoIndicationH2S);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequestS2H);

    int v = 42;
    printf("Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    call_say2(v, v*3);
    printf("TEST TYPE: SEM\n");
    EchoLeds tmp = {9};
    echoRequestProxy->setLeds(tmp);
    return 0;
}
