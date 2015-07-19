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
#include <pthread.h>    /* POSIX Threads */
#include "EchoRequest.h"
#include "EchoIndication.h"


/****************** client1 ******************/
EchoRequestProxy *sRequestProxy;
static sem_t sem_heard;

class EchoIndication : public EchoIndicationWrapper
{
public:
    void heard(uint32_t id, uint32_t v) {
        fprintf(stderr, "[client1] heard an s: %d\n", v);
        sRequestProxy->say2(id, v, 2*v);
    }
    void heard2(uint32_t id, uint16_t a, uint16_t b) {
        sem_post(&sem_heard);
        //fprintf(stderr, "heard an s2: %ld %ld\n", a, b);
    }
    EchoIndication(unsigned int id, PortalTransportFunctions *item, void *param) : EchoIndicationWrapper(id, item, param) {}
};

EchoIndication *sIndication;

static void call_say(int v)
{
    printf("[client1] [%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    sRequestProxy->say(1, v);
    sem_wait(&sem_heard);
}

static void call_say2(int v, int v2)
{
    printf("[client1] [%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    sRequestProxy->say2(1, v, v2);
    sem_wait(&sem_heard);
}

void* client1 (void *ptr)
{
    int v = 42;
    fprintf(stderr, "[client1] Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    call_say2(v, v*3);
    fprintf(stderr, "[client1] sleeping...\n");
    portal_disconnect(&sRequestProxy->pint);
    sleep(5);
    pthread_exit(0); /* exit */
}


/****************** client2 ******************/
EchoRequestProxy *sRequestProxy2;
static sem_t sem_heard2;

class EchoIndication2 : public EchoIndicationWrapper
{
public:
    void heard(uint32_t id, uint32_t v) {
        fprintf(stderr, "[client2] heard an s: %d\n", v);
        sRequestProxy2->say2(id, v, 2*v);
    }
    void heard2(uint32_t id, uint16_t a, uint16_t b) {
        sem_post(&sem_heard2);
        //fprintf(stderr, "heard an s2: %ld %ld\n", a, b);
    }
    EchoIndication2(unsigned int id, PortalTransportFunctions *item, void *param) : EchoIndicationWrapper(id, item, param) {}
};

EchoIndication2 *sIndication2;

static void call2_say(int v)
{
    printf("[client2] [%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    sRequestProxy2->say(2, v);
    sem_wait(&sem_heard2);
}

static void call2_say2(int v, int v2)
{
    printf("[client2] [%s:%d] %d\n", __FUNCTION__, __LINE__, v);
    sRequestProxy2->say2(2, v, v2);
    sem_wait(&sem_heard2);
}

void* client2 (void *ptr)
{
    int v = 42;
    fprintf(stderr, "[client2] Saying2 %d\n", v);
    call2_say(v);
    call2_say(v);
    call2_say(v*5);
    call2_say(v*17);
    call2_say(v*93);
    call2_say2(v, v*3);
    fprintf(stderr, "[client2] sleeping...\n");
    portal_disconnect(&sRequestProxy2->pint);
    sleep(5);
    pthread_exit(0); /* exit */
}

int main(int argc, const char **argv)
{
    pthread_t thread1, thread2;  /* thread variables */

    printf ("*** Two clients version ***\n");
    sleep(2);
    sIndication = new EchoIndication(IfcNames_EchoIndicationH2S, &transportSocketInit, NULL);
    sRequestProxy = new EchoRequestProxy(IfcNames_EchoRequestS2H, &transportSocketInit, NULL);
    sIndication2 = new EchoIndication2(IfcNames_EchoIndication2H2S, &transportSocketInit, NULL);
    sRequestProxy2 = new EchoRequestProxy(IfcNames_EchoRequest2S2H, &transportSocketInit, NULL);

    pthread_create (&thread1, NULL, client1, (void*)NULL);
    pthread_create (&thread2, NULL, client2, (void*)NULL);
    printf ("main: before pthread_join\n");
    pthread_join (thread1, NULL);
    pthread_join (thread2, NULL);
    printf ("main: done\n");
    exit(0);
}

#ifdef COMMENT
int main(int argc, const char **argv)
{
    PortalSocketParam param;

    printf ("*** version 2 ***\n");
    // Client 1
    EchoIndication *sIndication = new EchoIndication(IfcNames_EchoIndication, &transportSocketInit, NULL);
    sRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest, &transportSocketInit, NULL);
    // Client 2
    EchoIndication *sIndication2 = new EchoIndication(IfcNames_EchoIndication2, &transportSocketInit, NULL);
    sRequestProxy2 = new EchoRequestProxy(IfcNames_EchoRequest2, &transportSocketInit, NULL);

    int v = 42;
    fprintf(stderr, "Saying %d\n", v);
    call_say(v);
    call_say(v*5);
    call_say(v*17);
    call_say(v*93);
    call_say2(v, v*3);
    printf("TEST TYPE: SEM\n");
    //sRequestProxy->setLeds(9);
    printf ("-----------------------\n");
    call2_say(v);
    call2_say(v);
    call2_say(v*5);
    call2_say(v*17);
    call2_say(v*93);
    call2_say2(v, v*3);
    //freeaddrinfo(param.addr);
    return 0;
}
#endif
