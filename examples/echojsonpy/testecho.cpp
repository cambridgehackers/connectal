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

EchoRequestProxy *sRequestProxy;
static sem_t sem_heard;
static sem_t sem_heard2;

class EchoIndication : public EchoIndicationWrapper
{
public:
  virtual void heard(uint32_t v) {
    fprintf(stderr, "heard an s: %d\n", v);
    sem_post(&sem_heard);
  }
  virtual void heard2(uint32_t a, uint32_t b) {
    fprintf(stderr, "heard an s2: %ld %ld\n", (long)a, (long)b);
    sem_post(&sem_heard2);
  }
  EchoIndication(unsigned int id, PortalItemFunctions *item, void *param) : EchoIndicationWrapper(id, item, param, &EchoIndicationJson_handleMessage, 1000) {}
};

static void call_say(int v)
{
  sRequestProxy->say(v);
  //sem_wait(&sem_heard);
}

static void call_say2(int v, int v2)
{
  sRequestProxy->say2(v, v2);
  //sem_wait(&sem_heard2);
}

static void set_leds(int v)
{
  sRequestProxy->setLeds(v);
}

int main(int argc, const char **argv)
{
  sem_init(&sem_heard, 1,0);
  sem_init(&sem_heard2, 1,0);
  PortalSocketParam param = {0};
  
  int rc = getaddrinfo("127.0.0.1", "5000", NULL, &param.addr);
  EchoIndication *sIndication = new EchoIndication(IfcNames_EchoIndicationH2S, &socketfuncInit, &param);
  rc = getaddrinfo("127.0.0.1", "5001", NULL, &param.addr);
  sRequestProxy = new EchoRequestProxy(IfcNames_EchoRequestS2H, &socketfuncInit, &param, &EchoRequestJsonProxyReq, 1000);
  portalExec_start();
  
  int v = 42;
  call_say(v);
  sleep(1);
  call_say2(v,v+1);
  sleep(1);
  set_leds(v);
  sleep(1);
  portalExec_end();
  return 0;
}
