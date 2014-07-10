// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include "GeneratedTypes.h"
#include "portal.h"

static int v1a = 42;
static int v2a = 2;
static int v2b = 4;
static PortalInternal *intarr[2];

static int indication_handleMessage(volatile unsigned int* map_base, unsigned int channel)
{    
    unsigned int buf[1024];
    switch (channel) {
    case CHAN_NUM_SimpleIndicationWrapper_heard1: 
    { 
        struct {
            uint32_t v:32;
        } payload;
        for (int i = (4/4)-1; i >= 0; i--)
            buf[i] = map_base[PORTAL_IND_FIFO(CHAN_NUM_SimpleIndicationWrapper_heard1)];
        int i = 0;
        payload.v = (uint32_t)(((buf[i])&0xfffffffful));
        i++;
        fprintf(stderr, "heard1(%d)\n", payload.v);
        break;
    }
    case CHAN_NUM_SimpleIndicationWrapper_heard2: 
    { 
        struct {
            uint32_t a:32;
            uint32_t b:32;
        } payload;
        for (int i = (8/4)-1; i >= 0; i--)
            buf[i] = map_base[PORTAL_IND_FIFO(CHAN_NUM_SimpleIndicationWrapper_heard2)];
        int i = 0;
        payload.b = (uint32_t)(((buf[i])&0xfffffffful));
        i++;
        payload.a = (uint32_t)(((buf[i])&0xfffffffful));
        i++;
        fprintf(stderr, "heard2(%d %d)\n", payload.a, payload.b);
        break;
    }
    default:
        printf("SimpleIndicationWrapper::handleMessage: unknown channel 0x%x\n", channel);
        return 0;
    }
    return 0;
}
static int request_handleMessage(volatile unsigned int* map_base, unsigned int channel)
{    
    unsigned int buf[1024];
    switch (channel) {
    case CHAN_NUM_SimpleRequestProxyStatus_putFailed: 
    { 
        struct {
            uint32_t v:32;
        } payload;
        for (int i = (4/4)-1; i >= 0; i--)
            buf[i] = map_base[PORTAL_IND_FIFO(CHAN_NUM_SimpleRequestProxyStatus_putFailed)];
        int i = 0;
        payload.v = (uint32_t)(((buf[i])&0xfffffffful));
        i++;
        const char* methodNameStrings[] = {"say1", "say2"};
        fprintf(stderr, "putFailed: %s\n", methodNameStrings[payload.v]);
        break;
    }
    default:
        printf("SimpleRequestProxyStatus::handleMessage: unknown channel 0x%x\n", channel);
        return 0;
    }
    return 0;
}

static void manual_event(void)
{
    for (int i = 0; i < 2; i++) {
      PortalInternal *instance = intarr[i];
      volatile unsigned int *map_base = instance->map_base;
      unsigned int queue_status;
      while ((queue_status= map_base[IND_REG_QUEUE_STATUS])) {
        unsigned int int_src = map_base[IND_REG_INTERRUPT_FLAG];
        unsigned int int_en  = map_base[IND_REG_INTERRUPT_MASK];
        unsigned int ind_count  = map_base[IND_REG_INTERRUPT_COUNT];
        fprintf(stderr, "(%d:%s) about to receive messages int=%08x en=%08x qs=%08x\n", i, instance->name, int_src, int_en, queue_status);
        if (i == 0)
            indication_handleMessage(instance->map_base, queue_status-1);
        else
            request_handleMessage(instance->map_base, queue_status-1);
      }
    }
}
int main(int argc, const char **argv)
{
   intarr[0] = new PortalInternal(IfcNames_SimpleIndication);
   intarr[1] = new PortalInternal(IfcNames_SimpleRequest);

  fprintf(stderr, "Main::calling say1(%d)\n", v1a);
  //device->say1(v1a);  
  {
    struct {
        uint32_t v:32;
    } payload;
    payload.v = v1a;
    //device->sendMessage(&msg);
    unsigned int buf[128];
    int i = 0;
    buf[i++] = payload.v;
    for (int i = 4/4-1; i >= 0; i--)
      intarr[1]->map_base[PORTAL_REQ_FIFO(CHAN_NUM_SimpleRequestProxy_say1)] = buf[i];
  };
  manual_event();

  fprintf(stderr, "Main::calling say2(%d, %d)\n", v2a,v2b);
  //device->say2(v2a,v2b);
  {
    struct {
        uint32_t a:32;
        uint32_t b:32;
    } payload;
    payload.a = v2a;
    payload.b = v2b;
    //device->sendMessage(&msg);
    unsigned int buf[128];
    int i = 0;
    buf[i++] = payload.b;
    buf[i++] = payload.a;
    for (int i = 8/4-1; i >= 0; i--)
      intarr[1]->map_base[PORTAL_REQ_FIFO(CHAN_NUM_SimpleRequestProxy_say2)] = buf[i];
  };
  manual_event();
}
